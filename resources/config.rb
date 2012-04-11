actions :create

attribute :config_file, :kind_of => String, :default => '/etc/ceph/ceph.conf',  :name_attribute => true
attribute :i_am_a_mds, :default => false
attribute :i_am_a_osd, :default => false
attribute :osd_data, :default => [], :kind_of => Array

def initialize(*args)
 super
 @action = :create
end