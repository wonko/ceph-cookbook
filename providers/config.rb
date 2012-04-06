action :create do

  search_restrictions = " AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}"
  search_myself = " OR hostname:#{node[:hostname]}"

  mdss = search("node", "(ceph_mds_enabled:true" + (@new_resource.i_am_a_mds ? search_myself : "") + ")" + search_restrictions, "X_CHEF_id_CHEF_X asc")
  osds = search("node", "(ceph_osd_enabled:true" + (@new_resource.i_am_a_osd ? search_myself : "") + ")" + search_restrictions, "X_CHEF_id_CHEF_X asc")

  template "/etc/ceph/ceph.conf" do
          path            "/etc/ceph/ceph.conf"
          source          "ceph.conf"
          mode            "0644"
          action          :create
          variables( 
            :mdss => mdss,
            :osds => osds
          )
  end
end
