class Source < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :source_matrix, :class_name => "Matrix"
  delegate :column_species, :to => :source_matrix
  alias :source_species :column_species

  validates_presence_of :source_matrix_id
  validates_uniqueness_of :source_matrix_id, :scope => :experiment_id
  validates_associated :experiment
end
