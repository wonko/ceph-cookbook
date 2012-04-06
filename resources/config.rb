actions :create

attribute :config_path, :kind_of => String, :default => '/etc/ceph/ceph.conf'
attribute :i_am_a_mds, :default => false
attribute :i_am_a_osd, :default => false

def initialize(*args)
 super
 @action = :create
end