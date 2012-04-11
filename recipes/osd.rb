# initialize ceph nodes

# we need a master, and our mon-cluster needs to work...
master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

if master_mons.size == 0
  Chef::Log.error("No master server found in ceph cluster #{node[:ceph][:clustername]} - not initializing/configuring OSDs")
  return 
end

include_recipe "ceph::default"
package "util-linux"

c = ceph_keyring "client.admin" do
  secret get_master_secret
  action [:create, :add] 
end

# search for possible OSDs, labeled 
devices = %x(blkid -t LABEL="#{node[:ceph][:clustername]}.ceph" -c /dev/null -o device).split("\n")
Chef::Log.info "Devices: #{devices.join(',')}"

devices.each do |device|
  # /var/lib/ceph/$type/$cluster-$id
  # chicken-egg here - I don't know the index to mount this on - we'll go with the UUID for now (sorry TV)...  
  
  # /var/lib/ceph/$type/$cluster-$uuid ($id is unknown)
  uuid = %x(blkid -p -s UUID -o value #{device}).strip
  osd_path = "/var/lib/ceph/osd/#{node[:ceph][:clustername]}-#{uuid}"

  directory osd_path do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end
  
  mount osd_path do 
    device device
    fstype "btrfs"
    action [:enable, :mount]
  end
  
  # clumsy - I know
  ruby_block "Determine a new index for the OSD" do
    block do
      node[:ceph][:last_osd_index] = %x(/usr/bin/ceph osd create).match(/mon\.\d+ -> '(\d+)' \(\d+\)/).to_a[1].to_i
      node.save
    end
  end
  
  ceph_osd "Initializing new osd on #{device} - #{uuid}" do
    path osd_path
    action [:initialize]
    not_if "test -e #{osd_path}/whoami"
  end

  ceph_osd "Starting the osd from #{uuid}" do
    path osd_path
    action [:start]
  end
end if devices

