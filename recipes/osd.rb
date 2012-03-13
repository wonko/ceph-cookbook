# makes the node a Ceph OSD 
node[:ceph][:osd][:enabled] = true

include_recipe "ceph::default"

osds = search("node", "ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
other_osds = search("node", "(ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}) NOT hostname:#{node[:hostname]}", "X_CHEF_id_CHEF_X asc") || []

unless node.ceph.osd.attribute?(:index)
  puts "This osd has no index assigned - searching for one"
  max_index = -1

  other_osds.each do |osd|
    max_index = osd[:ceph][:osd][:index] if osd[:ceph][:osd][:index] > max_index
  end unless other_osds.empty?

  node.normal[:ceph][:osd][:index] = max_index + 1

  puts "Assigned index is #{node[:ceph][:osd][:index]}"

  node.save

  ceph_osd node[:ceph][:osd][:index] do
    action :create
  end
end

ceph_osd node[:ceph][:osd][:index] do
  action :add_secret_to_attributes
end
