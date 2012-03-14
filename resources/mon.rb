actions :create, :make_master, :initialize,  :add_secret_to_attributes

attribute :description, :kind_of => String, :name_attribute => true
attribute :index, :kind_of => Integer
attribute :admin_secret, :kind_of => String

def initialize(*args)
  super
  @action = :create
end