actions :create

attribute :index, :kind_of => Integer, :name_attribute => true

def initialize(*args)
  super
  @action = :create
end