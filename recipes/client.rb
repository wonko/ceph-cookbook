# we use the official ceph repo
include_recipe "apt"

apt_repository "ceph" do
  uri "http://ceph.newdream.net/debian/"
  distribution node['lsb']['codename'] 
  components ["main"]
  key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
  action :add
end

%w{ceph-common}.each do |name|
  package name
end
