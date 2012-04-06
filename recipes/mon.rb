# makes the node a Ceph monitor, if it is in the monitor list
unless node['ceph']['mons'].include? node['fqdn']
  puts "Bailing out: mon recipe applied, but #{node['fqdn']} not part of the mon list (#{node['ceph']['mons'].join(',')})"
  return
end

node[:ceph][:mon][:enabled] = true
node.save

include_recipe "ceph::default"

my_index = node['ceph']['mons'].index(node['fqdn'])

ceph_mon "creating mon" do
  index my_index
  action :create
end 

ceph_mon "Initializing the monitor FS" do
  index my_index
  action :initialize
  not_if "test -f /var/lib/ceph/mon/ceph-#{my_index}/magic"
end

if node[:ceph][:master]
  # resize the cluster if needed
  number_of_osds = search("node", "ceph_osd_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc").size

  return if number_of_osds == 0

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

service "mon.#{my_index}" do
  supports :restart => true
  start_command "/etc/init.d/ceph start mon.#{my_index}"
  stop_command "/etc/init.d/ceph stop mon.#{my_index}"
  restart_command "/etc/init.d/ceph restart mon.#{my_index}"
  action [:start]
end