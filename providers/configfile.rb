action :create do

  directory "/etc/ceph/ceph.conf.d" do
    owner "root"
    group "root"
    mode "0755"
    recursive true
    action :create
  end

  execute "remove old config parts" do
    command "rm -f /etc/ceph/ceph.conf.d/*"
  end

  # gather some data
  mons = search("node", "ceph_mon_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  mdss = search("node", "ceph_mds_enabled:true AND ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []
  osds = config = data_bag_item('ceph', node['ceph']['clustername'])["osds"]
  

  # write out parts of the config
  # defaults
  template "/etc/ceph/ceph.conf.d/00_globals" do
    source          "00_globals"
    mode            "0644"
    action          :create
  end

  # mons
  mons.each_with_index do |mon, index|
    template "/etc/ceph/ceph.conf.d/10_mon_#{index}" do
      source          "10_mon"
      mode            "0644"
      action          :create
      variables(
      :index => index,
      :hostname => mon[:hostname].split('.').first,
      :ipaddress => mon[:ipaddress],
      :port => node[:ceph][:mon][:port].to_s
      )
    end
  end

  # osds - from databag, so osdconfig['foo'], not osdconfig[:foo] !!!
  osds.each do |index, osdconfig|
    template "/etc/ceph/ceph.conf.d/20_osd_#{index}" do
      source          "20_osd"
      mode            "0644"
      action          :create
      variables(
      :index => index,
      :hostname => osdconfig['node'].split('.').first,
      :osdconfig => osdconfig
      )
    end
  end

  # mds
  mdss.each_with_index do |mds, index|
    template "/etc/ceph/ceph.conf.d/30_mds_#{index}" do
      source          "30_mds"
      mode            "0644"
      action          :create
      variables(
      :index => index,
      :hostname => mds[:hostname].split('.').first
      )
    end
  end
  
  # assemble them all  
  execute "Assemble the ceph.conf file" do
    command "cat /etc/ceph/ceph.conf.d/00* /etc/ceph/ceph.conf.d/10* /etc/ceph/ceph.conf.d/20* /etc/ceph/ceph.conf.d/30* > /etc/ceph/ceph.conf"
  end
end