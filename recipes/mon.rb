# makes the node a Ceph monitor
node[:ceph][:mon][:enabled] = true
node.save
 
include_recipe "ceph::default"

# set an index, if not already set
mons = search("node", "(ceph_mon_enabled:true OR hostname:#{node[:hostname]}) AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
master_mons = search("node", "(ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}) NOT hostname:#{node[:hostname]}", "X_CHEF_id_CHEF_X asc") || []

ceph_mon "Indexing and creating mon"  do
  action :create
  index node[:ceph][:mon][:index]
end unless node.ceph.mon.attribute?(:index)

ceph_mon "Initializing the monitor FS" do
  action :initialize
  not_if "test -f /ceph/mon/#{node[:ceph][:mon][:index]}/magic"
end

ceph_mon "Storing the monitors secret" do 
  action :add_secret_to_attributes
end unless node.ceph.mon.attribute?(:secret) && node[:ceph][:mon][:secret].size > 0
