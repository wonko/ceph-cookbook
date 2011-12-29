# OSD provider

action :create do
  # create the mount points for OSD
  directory "/ceph/osd/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end  

  # and the journal folder - if you want this mounted, it is up to you
  directory "/ceph/osdjournals/#{new_resource.index}" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end

  # ensure the content of fstab
  execute "Add the data dir to the fstab for OSD #{new_resource.index}" do
    command "echo '#{new_resource.datadevice} /ceph/osd/#{new_resource.index} btrfs defaults 0 0' >> /etc/fstab"
    not_if "grep '#{new_resource.datadevice}' /etc/fstab"
  end
end
