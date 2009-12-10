class EmptyRow < Entry
  # validates_uniqueness_of :i, :scope => :matrix_id
  attr_protected :j
  # validates_presence_of :i, :matrix_id
end