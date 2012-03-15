action :create do
  directory "/ceph/mon/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end

  i = index :mon

  if i == 0
    # we are the first mon - lets be the "master" who will hold the initial monmap
    node.set[:ceph][:master] = true

    ceph_keyring "client.admin" do
      action [:create, :add, :store]
      not_if "test -e /etc/ceph/client.admin.keyring"
    end
  end
end

action :initialize do 
  i = @new_resource.index ? @new_resource.index : index(:mon)

  puts "Mon::initialize: Index is #{i}"

  ceph_keyring "mon.#{i}" do
    action [:create, :add, :store]
    keyname "mon." # WTF?
  end

  ceph_keyring "mon.#{i}" do
    action :add
    secret get_master_secret
    keyname "client.admin"
    authtool_options "--set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'"
  end

  directory "/tmp/mon-init" do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end

  # either we are the first mon (master), either we are a backup mon (not master)
  if node[:ceph].attribute?(:master) && node[:ceph][:master]
    ceph_config "Default ceph config" do
      action :create
      i_am_a_mon true
    end

    execute "CEPH MASTER INIT: Preparing the monmap" do
      command "/sbin/mkcephfs -d /tmp/mon-init -c /etc/ceph/ceph.conf --prepare-monmap"
      action :run
    end

    execute "CEPH MASTER INIT: Creating an osdmap" do
      command "/usr/bin/osdmaptool --clobber --create-from-conf /tmp/mon-init/osdmap -c /etc/ceph/ceph.conf"
      action :run
    end
    
  else
    # get the monmap/osdmap from a running mon
    # TODO
  end
  
  execute "Prepare the monitors file structure" do
    command "/usr/bin/ceph-mon -c /etc/ceph/ceph.conf --mkfs -i #{node[:ceph][:mon][:index]} --monmap /tmp/mon-init/monmap --osdmap /tmp/mon-init/osdmap -k /etc/ceph/mon.#{node[:ceph][:mon][:index]}.keyring"
    action :run
  end
end

action :set_all_permissions do
  # setting all the capabilities for the osds and mdss
  mdss = search("node", "ceph_mds_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

  mdss.each do |mds|
    execute "Adding #{mds} as an MDS to the monitor" do
      command "/usr/bin/ceph-authtool -n mds.#{osd[:ceph][:mds][:index]} --add-key #{mds[:ceph][:mds][:secret]} /etc/ceph/keyring.mon  --cap mon 'allow rwx' --cap osd 'allow *' --cap mds 'allow'"
      action :run
      only_if mds.ceph.mds.attribute?(:secret)
    end    
  end

  osds = search("node", "ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  osds.each do |osd|
    execute "Adding #{osd} as an OSD to the monitor" do
      command "/usr/bin/ceph-authtool -n osd.#{osd[:ceph][:osd][:index]} --add-key #{osd[:ceph][:osd][:secret]} /etc/ceph/keyring.mon  --cap mon 'allow rwx' --cap osd 'allow *'"
      action :run
      only_if { osd.ceph.osd.attribute?(:secret) }
    end    
  end
end