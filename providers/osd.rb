# OSD provider

action :create do
  i = index(:osd)

  ceph_keyring "osd.#{i}" do
    force_overwrite true
    action [:create, :add, :store]
  end
end

action :format do
  # force ourselfs to be present in the config file
  ceph_config "Default ceph config" do
    action :create
    i_am_a_osd true
  end

  # we need a monmap - the master has this
  # we get the admin key - store it - use it to extract the monmap
  master_mons = search("node", "(ceph_mon_enabled:true AND ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment})", "X_CHEF_id_CHEF_X asc") || []
  master = master_mons.first
  master_secret = master[:ceph][:admin_secret]

  execute "Create the client.admin keyring" do
    command "/usr/bin/ceph-authtool --create-keyring -n client.admin --add-key #{master_secret} /etc/ceph/client.admin.keyring"
    action :run
    not_if "test -e /etc/ceph/client.admin.keyring"
  end

  execute "Extract the monmap" do
    command "/usr/bin/ceph mon getmap -o /etc/ceph/monmap"
    action :run
  end
  
  # create the mount points for OSD
  # the journal folder - if you want this mounted, it is up to you
  directory "/ceph/osdjournals/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end

  directory "/ceph/osd/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end  

  execute "format the datadevice #{node[:ceph][:osd][:datadevice]}" do
    command "/sbin/mkfs.ext4 -F -q #{node[:ceph][:osd][:datadevice]}"
    action :run
    not_if "mount | grep '#{node[:ceph][:osd][:datadevice]}'"
  end

  mount "/ceph/osd/#{node[:ceph][:osd][:index]}" do
    device node[:ceph][:osd][:datadevice]
    fstype "ext4"
    options "user_xattr"
    action [:enable, :mount]
  end

  execute "Create the FS for osd.#{node[:ceph][:osd][:index]}" do
    command "/usr/bin/ceph-osd -c /etc/ceph/ceph.conf --monmap /etc/ceph/monmap -i #{node[:ceph][:osd][:index]} --mkfs"
    action :run
  end
  
  execute "Inform the mon(s) of our existance" do
    command "/usr/bin/ceph auth add osd.#{node[:ceph][:osd][:index]} osd 'allow *' mon 'allow rwx' -i /etc/ceph/osd.#{node[:ceph][:osd][:index]}.keyring"
    action :run
  end
end
