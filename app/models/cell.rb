class Cell < Entry
  # validates_uniqueness_of :i, :scope => [:j, :matrix_id], :message => "cell row value {{value}} is a duplicate"
  # validates_presence_of :i, :j, :matrix_id

  def self.find_or_create!(new_i, new_j, new_matrix_id)
    r = EmptyRow.find(:first, :conditions => {:i => new_i, :matrix_id => new_matrix_id})
    
    c = nil
    if r.nil?
      c = Cell.find(:first, :conditions => {:i => new_i, :j => new_j, :matrix_id => new_matrix_id} )
    else
      r.destroy
    end
    
    c = Cell.create!(:i => new_i, :j => new_j, :matrix_id => new_matrix_id) if c.nil?
    c
  end
end