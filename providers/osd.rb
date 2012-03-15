# OSD provider

action :create do
  i = index(:osd)

  ceph_keyring "osd.#{i}" do
    action [:create, :add, :store]
  end
end

action :format do
  # force ourselfs to be present in the config file
  ceph_config "Default ceph config" do
    action :create
    i_am_a_osd true
  end

  ceph_keyring "client.admin" do
    secret get_master_secret
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
