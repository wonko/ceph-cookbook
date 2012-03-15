# makes the node a Ceph OSD 

# we need at least a master...
master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

if master_mons.size == 0
  puts "No master found - not configuring this OSD"
end

node[:ceph][:osd][:enabled] = true

include_recipe "ceph::default"

ceph_osd "Create the ceph OSD" do
  action :create
end

ceph_osd "Format the ceph OSD" do
  action :format
  index node[:ceph][:osd][:index]
  not_if "test -e /ceph/osd/#{node[:ceph][:osd][:index]}/magic"
end 
