
apt_repository "ceph" do
  uri "http://ceph.newdream.net/debian/"
  distribution node['lsb']['codename'] 
  components ["main"]
  key "https://raw.github.com/ceph/ceph/master/keys/release.asc"
  action :add
end

package "ceph" 
package "ceph-common"

ceph_config "/etc/ceph/ceph.conf"
