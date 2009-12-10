class Entry < ActiveRecord::Base
  belongs_to :matrix

  named_scope :for_matrix, lambda { |m_id| { :conditions => { :matrix_id => m_id } } }



  def to_s(sep = "\t")
    str  =  self.i.to_s
    str  << sep << self.j.to_s if self.j?
    str
  end

  def write(open_file)
    open_file.puts( self.to_s )
    open_file
  end
end
