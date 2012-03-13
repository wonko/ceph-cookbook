# makes the node a Ceph monitor
node[:ceph][:mon][:enabled] = true
node.save
 
include_recipe "ceph::default"

# set an index, if not already set
mons = search("node", "(ceph_mon_enabled:true OR hostname:#{node[:hostname]}) AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
master_mons = search("node", "(ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}) NOT hostname:#{node[:hostname]}", "X_CHEF_id_CHEF_X asc") || []

ceph_mon node[:ceph][:mon][:index] do
  action :create
end unless node.ceph.mon.attribute?(:index)

ceph_mon node[:ceph][:mon][:index] do
  action :make_master
end if node[:ceph][:mon][:index] == 0 && !node.ceph.attribute?(:master) && master_mons.size == 0


ceph_mon node[:ceph][:mon][:index] do
  action :initialize
end


