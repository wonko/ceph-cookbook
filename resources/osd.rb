# OSD resource

actions :create

attribute :index, :kind_of => String, :name_attribute => true
attribute :datadevice,     :kind_of => String
attribute :journaldevice,  :kind_of => String

def initialize(*args)
  super
  @action = :create
end