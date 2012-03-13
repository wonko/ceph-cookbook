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
  
  # create a key
  execute "Creating a private key for OSD #{new_resource.index}" do
    command "/usr/bin/ceph-authtool --create-keyring --gen-key -n osd.#{new_resource.index} /etc/ceph/keyring.osd.#{new_resource.index}"
    action :run
    not_if "test -f /etc/ceph/keyring.osd.#{new_resource.index}"
  end
end

action :add_secret_to_attributes do
  # storing the key in the secret attribute
  node.set[:ceph][:osd][:secret] = `/usr/bin/ceph-authtool -p -n osd.#{new_resource.index} /etc/ceph/keyring.osd.#{new_resource.index}`.strip  
end
  

action :format do 
  # format the object store
  
end
