class RocGroup < ActiveRecord::Base
  has_many :roc_group_items, :dependent => :destroy
  has_many :experiments, :through => :roc_group_items
  accepts_nested_attributes_for :roc_group_items, :allow_destroy => true
end
