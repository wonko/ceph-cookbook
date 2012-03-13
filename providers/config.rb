action :create do

  search_restrictions = " AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}"
  search_myself = " OR hostname:#{node[:hostname]}"

  mdss = search("node", "(ceph_mds_enabled:true" + (@new_resource.i_am_a_mds ? search_myself : "") + ")" + search_restrictions, "X_CHEF_id_CHEF_X asc")
  mons = search("node", "(ceph_mon_enabled:true" + (@new_resource.i_am_a_mon ? search_myself : "") + ")" + search_restrictions, "X_CHEF_id_CHEF_X asc")
  osds = search("node", "(ceph_osd_enabled:true" + (@new_resource.i_am_a_osd ? search_myself : "") + ")" + search_restrictions, "X_CHEF_id_CHEF_X asc")

  template "/etc/ceph/ceph.conf" do
          path            "/etc/ceph/ceph.conf"
          source          "ceph.conf"
          mode            "0644"
          action          :create
          variables( 
            :mdss => mdss,
            :mons => mons,
            :osds => osds
          )
  end
end

# crazy me - what was i thinking
# action :index_nodes do
#   groupnodes = search("node", "ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
# 
#   puts "Nodes to index: #{groupnodes.size}"
# 
#   max_osd = max_mds = max_mon = -1
#   osd_to_index = mds_to_index = mon_to_index = []
# 
#   # search unindexed nodes, and the max indexes
#   groupnodes.each do |gnode|
#     if gnode[:ceph][:mon][:enabled]
#       if gnode[:ceph][:mon][:index] && gnode[:ceph][:mon][:index] > max_mon 
#         max_mon = gnode[:ceph][:mon][:index]
#       else
#         puts "Adding #{gnode} to be indexed as mon"
#         mon_to_index << gnode
#       end
#     end
# 
#     if gnode[:ceph][:osd][:enabled]
#       if gnode[:ceph][:osd][:index] && gnode[:ceph][:osd][:index] > max_osd 
#         max_osd = gnode[:ceph][:osd][:index]
#       else
#         puts "Adding #{gnode} to be indexed as osd"
#         osd_to_index << gnode
#       end
#     end
# 
#     if gnode[:ceph][:mds][:enabled]
#       if gnode[:ceph][:mds][:index] && gnode[:ceph][:mds][:index] > max_mds 
#         max_mds = gnode[:ceph][:mds][:index]
#       else
#         puts "Adding #{gnode} to be indexed as mds"
#         mds_to_index << gnode
#       end
#     end
#   end
#   
#   # assign indexes
#   mon_to_index.each do |inode|
#     inode.set[:ceph][:mon][:index] = max_mon = max_mon + 1
#     puts "MON: Assigned index #{max_mon} to #{inode}"
#     inode.save
#   end unless mon_to_index.empty?
#   
#   osd_to_index.each do |inode|
#     inode.set[:ceph][:osd][:index] = max_osd = max_osd + 1
#     puts "OSD: Assigned index #{max_osd} to #{inode}"
#     inode.save
#   end unless osd_to_index.empty?
#   
#   mds_to_index.each do |inode|
#     inode.set[:ceph][:mds][:index] = max_mds = max_mds + 1
#     puts "MDS: Assigned index #{max_mds} to #{inode}"
#     inode.save
#   end unless mds_to_index.empty?  
# end