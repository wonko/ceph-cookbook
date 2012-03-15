action :create do
  name = @new_resource.name  
  keyring = @new_resource.keyring ? @new_resource.keyring : "/etc/ceph/#{name}.keyring"
  
  if @new_resource.force_overwrite
    execute "Creating the keyring for #{name} in #{keyring}" do
      command "/usr/bin/ceph-authtool --create-keyring #{keyring}"
      action :run
    end
  else
    execute "Creating the keyring for #{name} in #{keyring}" do
      command "/usr/bin/ceph-authtool --create-keyring #{keyring}"
      action :run
      not_if "test -f #{keyring}"
    end
  end

end

action :add do 
  name = @new_resource.name  
  keyring = @new_resource.keyring ? @new_resource.keyring : "/etc/ceph/#{name}.keyring"

  if @new_resource.secret.size == 0
    execute "Generate a secret for #{name} into #{keyring}" do
      command "/usr/bin/ceph-authtool --gen-key -n #{name} #{keyring}"
      action :run
      only_if "test -e #{keyring}"
    end
  else
    execute "Adding the secret #{new_resource.secret} for #{name} into #{keyring}" do
      command "/usr/bin/ceph-authtool --add-key '#{new_resource.secret}' -n #{name} #{keyring}"
      action :run
      only_if "test -e #{keyring}"
    end
  end
end

action :store do
  name = @new_resource.name  
  keyring = @new_resource.keyring ? @new_resource.keyring : "/etc/ceph/#{name}.keyring"

  ruby_block "Store secret from the keyring to the attributes for #{name}" do
    block do
      node.set[:ceph][:secrets][name] = `/usr/bin/ceph-authtool -p -n #{name} #{keyring}`.strip
    end
    only_if "test -e #{keyring}"
    action :create
  end
end
