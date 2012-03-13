actions :create, :add_secret_to_attributes, :initialize, :make_master

attribute :index, :kind_of => Integer, :name_attribute => true
attribute :admin_secret, :kind_of => String

def initialize(*args)
  super
  @action = :create
end