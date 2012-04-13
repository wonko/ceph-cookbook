
apt_repository "ceph" do
  uri "http://ceph.newdream.net/debian/"
  distribution node['lsb']['codename'] 
  components ["main"]
  key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
  action :add
end

%w(ceph ceph-common).each do |pkg|
  package pkg do
    action :upgrade
  end
end

ceph_config "/etc/ceph/ceph.conf"
