class RocGroupItem < ActiveRecord::Base
  belongs_to :roc_group
  belongs_to :experiment
end
