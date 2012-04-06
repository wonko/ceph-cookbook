action :create do
  directory "/var/lib/ceph/mon/ceph-#{@new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end

  if @new_resource.index == 0
    # we are the first mon - lets be the "master" who will hold the initial monmap
    node.set[:ceph][:master] = true

    ceph_keyring "client.admin" do
      action [:create, :add, :store]
      not_if "test -e /etc/ceph/client.admin.keyring"
    end
  end
end

action :initialize do 
  i = @new_resource.index

  if i == 0
    ceph_keyring "mon.#{i}" do
      action [:create, :add, :store]
      keyname "mon." # WTF?
    end
  else
    ceph_keyring "mon.#{i}" do
      secret get_master_mon_secret
      action [:create, :add, :store]
      keyname "mon." # WTF?
    end
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

  # execute "Creating an osdmap" do
  #   command "/usr/bin/osdmaptool --clobber --create-from-conf /tmp/mon-init/osdmap -c /etc/ceph/ceph.conf"
  #   action :run
  # end

  # either we are the first mon (master), either we are a backup mon (not master)
  if i == 0
    execute "CEPH MASTER INIT: Preparing the monmap" do
      command "/sbin/mkcephfs -d /tmp/mon-init -c /etc/ceph/ceph.conf --prepare-monmap"
    end

    ruby_block "Store fsid for the master mon" do
      block do
        node.set[:ceph][:monfsid] = `monmaptool --print /tmp/mon-init/monmap  | grep fsid | cut -d' ' -f2`.strip
        node.save
      end
      action :create
    end

    execute "Prepare the monitors file structure" do
#      command "/usr/bin/ceph-mon -c /etc/ceph/ceph.conf --mkfs -i #{i} --monmap /tmp/mon-init/monmap --osdmap /tmp/mon-init/osdmap -k /etc/ceph/mon.#{i}.keyring"
      command "/usr/bin/ceph-mon -c /etc/ceph/ceph.conf --mkfs -i #{i} --monmap /tmp/mon-init/monmap -k /etc/ceph/mon.#{i}.keyring"
      action :run
    end
  else
    # not master
    monfsid = get_master_mon_fsid
    
    execute "Prepare the monitors file structure" do
      command "/usr/bin/ceph-mon -c /etc/ceph/ceph.conf --mkfs -i #{i} --fsid '#{monfsid}' -k /etc/ceph/mon.#{i}.keyring"
      action :run
    end

  end

end

action :set_all_permissions do
  # setting all the capabilities for the osds and mdss
  mdss = search("node", "ceph_mds_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

  mdss.each do |mds|
    execute "Adding #{mds} as an MDS to the monitor" do
      command "/usr/bin/ceph-authtool -n mds.#{mds[:ceph][:mds][:index]} --add-key #{mds[:ceph][:mds][:secret]} /etc/ceph/keyring.mon  --cap mon 'allow rwx' --cap osd 'allow *' --cap mds 'allow'"
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