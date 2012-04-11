# OSD provider

# todo: ceph osd crush add <$osdnum> <osd.$osdnum> <weight> host=foo rack=bar [...]

action :initialize do
#  osd_index = @new_resource.index
  osd_index = node[:ceph][:last_osd_index]
  osd_path = @new_resource.path

  Chef::Log.info("Index is #{osd_index}")

  journal_path = osd_path + "/journal"

  execute "Extract the monmap" do
    command "/usr/bin/ceph mon getmap -o /etc/ceph/monmap"
    action :run
  end

  execute "Create the fs for osd.#{osd_index}" do
    command "/usr/bin/ceph-osd -i #{osd_index} -c /dev/null --monmap /etc/ceph/monmap --osd-data=#{osd_path} --osd-journal=#{journal_path} --osd-journal-size=250 --mkfs --mkjournal"
    action :run
  end
  
  ceph_keyring "osd.#{osd_index}" do
    action [:create, :add, :store]
  end

  execute "Change the mon authentication to allow osd.#{osd_index}" do
    command "/usr/bin/ceph auth add osd.#{osd_index} osd 'allow *' mon 'allow rwx' -i /etc/ceph/osd.#{osd_index}.keyring"
    action :run
  end

  ceph_config "/etc/ceph/osd.#{osd_index}.conf" do
    osd_data [{:index => osd_index,
               :journal => journal_path,
               :journal_size => 250,
               :data => osd_path}]
  end
end

action :start do
  osd_path = @new_resource.path
  index = get_osd_index osd_path

  service "osd.#{index}" do
    supports :restart => true
    start_command "/etc/init.d/ceph -c /etc/ceph/osd.#{index}.conf start osd.#{index}"
    action [:start]
  end
  
end