def index type

  if !node[:ceph][type].attribute?(:index)
    max_index = -1

    other_nodes = search("node", "(ceph_#{type}_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}) NOT hostname:#{node[:hostname]}", "X_CHEF_id_CHEF_X asc") || []

    other_nodes.each do |n|
      max_index = n[:ceph][type][:index] if n[:ceph][type][:index] > max_index
    end unless other_nodes.empty?

    node.normal[:ceph][type][:index] = max_index + 1
    node.save

    puts "This #{type} had no index assigned - created #{type}.#{max_index + 1}"
  end

  node[:ceph][type][:index]
end

def get_master_secret
  master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  
  if (master_mons.size == 0) # allow chef server to reindex my data...
    sleep 5
    master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  end

  master = master_mons.first
  
  master[:ceph][:secrets]['client.admin']
end