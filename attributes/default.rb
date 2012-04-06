# we set the clustername, it should not rely on the defaults once the node has been set up
default[:ceph][:clustername] = "ceph"

# is this node either a mds, a mon or a osd
default[:ceph][:mds][:enabled] = false
default[:ceph][:mon][:enabled] = false
default[:ceph][:osd][:enabled] = false

# defaults - should remain the same on the entire cluster !
# global
default[:ceph][:defaults][:global][:auth_supported] = "cephx"
default[:ceph][:defaults][:global][:keyring] = "/etc/ceph/$name.keyring"

# mon
default[:ceph][:defaults][:mon][:data] = "/var/lib/ceph/mon/ceph-$id"

# mds
#default[:ceph][:defaults][:mds][:] = ""

# osd
default[:ceph][:defaults][:osd][:data] = "/var/lib/ceph/osd/ceph-$id"
default[:ceph][:defaults][:osd][:journal] = "/var/lib/ceph/osdjournals/$id/journal"
default[:ceph][:defaults][:osd][:journal_size] = "1000"

# per node specific configurations
# mds configuration details

# mon configuration details
default[:ceph][:mon][:port] = 6789

# osd configuration details