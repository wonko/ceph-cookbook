# ceph user management

# We need to ensure that our root users have keypairs, 
# and that each other node is able to login (passwordless) towards the other boxes

my_home = node[:etc][:passwd]['root'][:dir]

e = execute "create ssh keypair for root" do
  command "ssh-keygen -t dsa -f #{my_home}/.ssh/id_dsa -N '' -C 'root@#{node[:fqdn]}-#{Time.now.strftime('%FT%T%z')}'"
  not_if "test -f #{my_home}/.ssh/id_dsa.pub"

  action :nothing
end
e.run_action(:run)

key = ::File.open(my_home + "/.ssh/id_dsa.pub").read.chop
node.set[:public_keys][:root] = key

groupnodes = search("node", "ceph_clustername:#{node['ceph']['clustername']} AND chef_environment:#{node.chef_environment}", "X_CHEF_id_CHEF_X asc") || []

groupnodes.each do |member|
  next if member[:fqdn] == node[:fqdn]
  next unless member.attribute?("public_keys") && member.public_keys.attribute?("root")

  execute "adding the key for root@#{member[:fqdn]}" do
    command "echo '#{member[:public_keys][:root]}' >> #{my_home}/.ssh/authorized_keys"
    not_if "grep '#{member[:public_keys][:root]}' #{my_home}/.ssh/authorized_keys"
  end
end

