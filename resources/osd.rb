# OSD resource

actions :initialize, :start

attribute :description, :name_attribute => true
attribute :index, :kind_of => Integer, :default => -1
attribute :path, :kind_of => String
attribute :rack, :kind_of => String
attribute :host, :kind_of => String

