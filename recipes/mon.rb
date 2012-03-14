# makes the node a Ceph monitor
node[:ceph][:mon][:enabled] = true
node.save
 
include_recipe "ceph::default"

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

if node[:ceph][:master]
  # resize the cluster if needed
  number_of_osds = search("node", "ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc").size

  execute "Set the number of OSDs to #{number_of_osds}" do
    command "/usr/bin/ceph osd setmaxosd #{number_of_osds + 1}"
    action :run
    not_if "ceph osd dump -o - 2>/dev/null | grep 'max_osd #{number_of_osds + 1}'"
  end

  execute "Load a new crushmap for all the OSDs" do
    command "/usr/bin/osdmaptool --createsimple #{number_of_osds} --clobber /tmp/osdmap.junk --export-crush /tmp/crush.new && /usr/bin/ceph osd setcrushmap -i /tmp/crush.new"
    action :run
    not_if "ceph osd dump -o - 2>/dev/null | grep 'max_osd #{number_of_osds + 1}'"    
  end
end