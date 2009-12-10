class Entry < ActiveRecord::Base
  validates_presence_of :row
  validates_uniqueness_of :row, :scope => [:column, :entry_info_id]
  
  belongs_to :entry_info, :class_name => "EntryInfo"
  delegate :row_title, :column_title, :to => :entry_info

  def self.find_or_create!(row, column, entry_info_id)
    entry = self.find(:first, :conditions => {:row => row, :column => column, :entry_info_id => entry_info_id})
    entry = self.create!(:row => row, :column => column, :entry_info_id => entry_info_id) if entry.nil?
    entry
  end

  def self.find_or_create_empty_row!(row, entry_info_id)
    Entry.find_or_create!(row, nil, entry_info_id)
  end

  def to_s_without_header(sep = "\t")
    str  =  self.row
    str  << sep << self.column if self.column?
    str
  end

  def to_s(header = false)
    str = String.new
    str << self.entry_info << "\n" if header
    str << self.to_s_without_header
    str
  end

  def write(open_file)
    open_file.puts( self.to_s_without_header )
    open_file
  end

  def is_row?
    self.column.nil?
  end

  def is_cell?
    !self.is_empty_row?
  end
end
