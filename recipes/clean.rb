# clear all ceph settings/...
# 
# DO NOT APPLY THIS RECIPE UNLESS YOU REALLY WANT TO REMOVE EVERYTHING
#

# stop all running servers
service "ceph" do
  action [:stop, :disable]
  ignore_failure true
end

execute "Killall ceph" do
  command "killall -9 ceph-mon ceph-osd"
  action :run
  ignore_failure true
end


# remove the packages
%w(ceph ceph-common ceph-fuse libcephfs1 librados2 librbd1 librgw1).each do |pkg|
  package pkg do
    action :remove 
    options "--purge"
  end
end

file "/etc/init.d/ceph" do
  action :delete
end

# clean directories
directory "/etc/ceph" do
  recursive true
  action :delete
end

directory "/var/lib/ceph" do
  recursive true
  action :delete
end

# remove all the magic markers from the filesystems - this invalidates the datasets
file "/ceph/mon/#{node['ceph']['mon']['index']}/magic" do
  action :delete
end if node['ceph']['mon']

%w(magic fsid ceph_fsid whoami store_version).each do |filename|
  file "/ceph/osd/#{node['ceph']['osd']['index']}/#{filename}" do
    action :delete
  end
end
  
file "/ceph/osdjournals/#{node['ceph']['osd']['index']}/journal" do
  action :delete
end if node['ceph']['osd']

# umount all possible mounts in /ceph, a bit brutal
execute "umount all possible mounts in /ceph/" do
  command "cat /proc/mounts | grep ' /ceph/' | cut -d' ' -f 2 | xargs umount"
  only_if "cat /proc/mounts | grep ' /ceph/'"
end

directory "/ceph" do
  recursive true
  action :delete
end

# umount all possible mounts in /var/lib/ceph, a bit brutal
execute "umount all possible mounts in /var/lib/ceph/" do
  command "cat /proc/mounts | grep ' /var/lib/ceph/' | cut -d' ' -f 2 | xargs umount"
  only_if "cat /proc/mounts | grep ' /var/lib/ceph/'"
end

directory "/var/lib/ceph" do
  recursive true
  action :delete
end

# clean all the node attributes for ceph
node.delete('ceph')

# all done?