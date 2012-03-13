action :create do
  directory "/ceph/mon/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end
  
  puts "This mon has no index assigned - searching for one"
  max_index = -1

  other_mons = search("node", "(ceph_mon_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}) NOT hostname:#{node[:hostname]}", "X_CHEF_id_CHEF_X asc") || []

  other_mons.each do |mon|
    max_index = mon[:ceph][:mon][:index] if mon[:ceph][:mon][:index] > max_index
  end unless other_mons.empty?

  node.set[:ceph][:mon][:index] = max_index + 1
  node.save

  puts "Assigned index is #{node[:ceph][:mon][:index]}"
  
end

action :add_secret_to_attributes do
  # storing the key in the secret attribute
  node.set[:ceph][:mon][:secret] = `/usr/bin/ceph-authtool -p -n mon. /etc/ceph/keyring.mon`.strip  
end

action :initialize do 
  master_mons = search("node", "(ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment})", "X_CHEF_id_CHEF_X asc") || []
  
  admin_secret = master_mons.first[:ceph][:admin_secret]
  
  #admin_secret node[:ceph][:admin_secret] ? node[:ceph][:admin_secret] : master_mons.first[:ceph][:admin_secret]
  
  
  execute "Adding the client.admin key to the monitor keyring" do
    command "/usr/bin/ceph-authtool --create-keyring -n client.admin --add-key #{admin_secret} --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' /etc/ceph/keyring.mon"
    action :run
  end

  execute "Create a new monitor key for mon." do
    command "/usr/bin/ceph-authtool --gen-key -n mon. /etc/ceph/keyring.mon"
    action :run
  end
  
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

  execute "Prepare the monitors file structure" do
    command "/usr/bin/ceph-mon -c /etc/ceph/ceph.conf --mkfs -i #{node[:ceph][:mon][:index]} --monmap /tmp/mon-init/monmap --osdmap /tmp/mon-init/osdmap -k /etc/ceph/keyring.mon"
    action :run
  end

  ceph_mon node[:ceph][:mon][:index] do 
    action :add_secret_to_attributes
  end
end

action :make_master do
  # force rewrite
  ceph_config "Default ceph config" do
    action :create
    i_am_a_mon true
  end

  # mon 0 is special - it is the start of a cluster config, lets do some work...
  directory "/tmp/mon-init" do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end

  execute "CEPH INIT: Preparing the monmap" do
    command "/sbin/mkcephfs -d /tmp/mon-init -c /etc/ceph/ceph.conf --prepare-monmap"
    action :run
  end

  execute "CEPH INIT: Creating an osdmap" do
    command "/usr/bin/osdmaptool --clobber --create-from-conf /tmp/mon-init/osdmap -c /etc/ceph/ceph.conf"
    action :run
  end

  execute "CEPH INIT: Creating admin keyring" do
    command "/usr/bin/ceph-authtool --create-keyring --gen-key -n client.admin /etc/ceph/keyring.admin"
    action :run
  end

  # get the admin key with this server
  admin_secret = `/usr/bin/ceph-authtool -p -n client.admin /etc/ceph/keyring.admin`.strip

  # we are the master, make it permanent
  node.set[:ceph][:master] = true
  node.set[:ceph][:admin_secret] = admin_secret
  node.save
end