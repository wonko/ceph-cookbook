# OSD resource

actions :initialize, :start

attribute :description, :name_attribute => true
attribute :index, :kind_of => Integer, :default => -1
attribute :path, :kind_of => String

