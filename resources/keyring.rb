actions :create, :add, :store

attribute :name, :kind_of => String, :name_attribute => true
attribute :keyring, :kind_of => String
attribute :secret, :kind_of => String, :default => ''
attribute :force_overwrite, :default => false
attribute :authtool_options, :kind_of => String, :default => ''
attribute :keyname, :kind_of => String

def initialize(*args)
 super
 @action = :create
end