# makes the node a Ceph monitor 
include_recipe "ceph::default"

mons = search("node", "ceph_mon_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

unless node[:ceph][:mon][:enabled] && !node[:ceph][:mon][:index]
  node[:ceph][:mon][:enabled] = true
  node[:ceph][:mon][:index] = mons.size

  ceph_mon node[:ceph][:mon][:index] do
    action :create
  end
end
