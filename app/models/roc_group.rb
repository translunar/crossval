class RocGroup < ActiveRecord::Base
  has_many :items, :foreign_key => :roc_group_id, :dependent => :destroy, :class_name => "RocGroupItem"
  has_many :experiments, :through => :roc_group_items
  accepts_nested_attributes_for :roc_group_items, :allow_destroy => true
end
