class Source < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :source_matrix, :class_name => "Matrix"
  delegate :column_species, :to => :source_matrix
  alias :source_species :column_species
end
