class RocGroupItem < ActiveRecord::Base
  belongs_to :roc_group
  belongs_to :experiment

  validates_presence_of :experiment_id
end
