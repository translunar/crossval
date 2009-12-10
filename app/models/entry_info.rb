class EntryInfo < ActiveRecord::Base
  validates_uniqueness_of :row_title, :scope => :column_title
  validates_presence_of :row_title, :column_title

  def self.find_or_create!(row_title = "gene", column_title = "phenotype")
    entry_info = self.find(:first, :conditions => { :row_title => row_title, :column_title => column_title })

    entry_info = self.create! do |info|
      info.row_title    = row_title
      info.column_title = column_title
    end if entry_info.nil?
    
    entry_info
  end

  def to_s
    self.row_title + "\t" + self.column_title
  end

  def write(open_file)
    open_file.puts(self.to_s)
    open_file
  end

  def row_filename suffix
    self.row_title.pluralize + "." + suffix
  end

  def cell_filename suffix
    if self.column_title == "phenotype"
      self.row_title.pluralize + "_phenes." + suffix
    else
      self.row_title.pluralize + "_" + self.column_title.pluralize + "." + suffix
    end
  end

end
