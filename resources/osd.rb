# OSD resource

actions :create, :add_secret_to_attributes

attribute :index, :kind_of => Integer, :name_attribute => true
attribute :datadevice,     :kind_of => String
attribute :journaldevice,  :kind_of => String

def initialize(*args)
  super
  @action = :create
end