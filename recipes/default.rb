# Ceph cookbooks - as the Ceph-people don't release theirs to work with...

# we use the official ceph repo
#include_recipe "apt"
#include_recipe "ceph::user_management"

puts "This is CEPH - clustername is #{node[:ceph][:clustername]}"

apt_repository "ceph" do
  uri "http://ceph.newdream.net/debian/"
  distribution node['lsb']['codename'] 
  components ["main"]
  key "https://raw.github.com/NewDreamNetwork/ceph/master/keys/release.asc"
  action :add
end

apt_repository "ceph-autobuild-master" do
  uri "http://ceph.newdream.net/debian-snapshot-amd64/master"
  distribution node['lsb']['codename'] 
  components ["main"]
  key "https://raw.github.com/NewDreamNetwork/ceph/master/keys/autobuild.asc"
  action :add
end

package "ceph"
package "ceph-common"

#group "ceph"
# user "ceph" do
#   comment "ceph user"
#   group "ceph"
# end

groupnodes = search("node", "ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
mdss = search("node", "ceph_mds_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
mons = search("node", "ceph_mon_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
osds = search("node", "ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

unless mons.size == 1 || mons.size == 3
  puts "WARNING: the size of the monitor cluster is not 1 or 3 nodes, but #{mons.size}!"
end

template "/etc/ceph/ceph.conf" do
        path            "/etc/ceph/ceph.conf"
        source          "ceph.conf"
        mode            "0644"
        action          :create
        variables( 
          :mdss => mdss,
          :mons => mons,
          :osds => osds
        )
end

return

config = data_bag_item('ceph', node['ceph']['clustername'])

config["osds"].each do |index, osdconfig|
  next unless osdconfig['node'] == node[:hostname] # only process the osd entries on this node

  puts "OSD #{index}: #{osdconfig['datadevice']}"
  ceph_osd index do 
    datadevice      osdconfig['datadevice']
    journaldevice   osdconfig['journaldevice']
  end
end

if node[:ceph][:mon][:enabled]
  my_index = mons.index {|n| n[:fqdn] == node[:fqdn]}
  puts "I am MON #{my_index}!"
  ceph_mon my_index 
else
  puts "Not doing MON stuff"
end

if node[:ceph][:mds][:enabled]
  my_index = mdss.index {|n| n[:fqdn] == node[:fqdn]}
  puts "I am MDS #{my_index}!"
else
  puts "Not doing MDS stuff"
end

ceph_configfile "/etc/ceph/ceph.conf"