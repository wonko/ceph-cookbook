def get_osd_index path
  osd_index = File.read("/#{path}/whoami").to_i
end

def get_master_secret
  master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  
  if (master_mons.size == 0) # allow chef server to reindex my data...
    sleep 10
    master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  end

  master = master_mons.first
  
  master[:ceph][:secrets]['client.admin']
end

def get_master_mon_secret
  master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  
  if (master_mons.size == 0) # allow chef server to reindex my data...
    sleep 10
    master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  end

  master = master_mons.first
  
  master[:ceph][:secrets]['mon.']
end

def get_master_mon_fsid
  master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  
  if (master_mons.size == 0) # allow chef server to reindex my data...
    sleep 10
    master_mons = search("node", "ceph_master:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  end

  master = master_mons.first
  
  master[:ceph][:monfsid]
end