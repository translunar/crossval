class Matrix < ActiveRecord::Base
  acts_as_tree :order => "cardinality"
  acts_as_commentable

  belongs_to :entry_info
  has_many :empty_rows, :dependent => :destroy
  has_many :cells, :dependent => :destroy
  has_many :entries, :dependent => :destroy
  has_many :experiments, :foreign_key => :predict_matrix_id

  delegate :row_title, :to => :entry_info
  delegate :column_title, :to => :entry_info


  # Make a copy of the matrix (does not include its children).
  def copy
    matrix_copy = self.clone
    matrix_copy.title = self.title + " copy"
    self.cells.each do |cell|
      matrix_copy.cells.build(cell.attributes.delete_if { |k,v| k == "matrix_id"})
    end
    self.empty_rows.each do |empty_row|
      matrix_copy.empty_rows.build(empty_row.attributes.delete_if { |k,v| k == "matrix_id"})
    end
    matrix_copy
  end

  def copy_and_save
    matrix_copy = self.clone
    matrix_copy.save!
  end

  def make_empty_copy uqr = nil
    matrix_copy = self.clone
    matrix_copy.title = self.title + " copy"


    # Get the rows and columns
    uqr = self.unique_rows if uqr.nil?

    # First create empty rows
    uqr.each do |row|
      matrix_copy.empty_rows.build(:i => row)
    end
    matrix_copy.row_count    = uqr.size
    matrix_copy.column_count = 0
    matrix_copy
  end

  # Note that this function only works for very sparse matrices. Once columns
  # start to be dense enough for lots of collisions, this gets exponentially
  # slower.
  def copy_and_randomize
    # Get the rows and columns
    uqr = self.unique_rows

    # Make an empty copy and to help it along give it the rows (one less db op)
    matrix_copy = self.make_empty_copy uqr
    matrix_copy.title = self.title + "r"
    matrix_copy.column_species = self.column_species + "r"

    # Now we have to save the copy in order to do the randomization.
    matrix_copy.save!

    # Now go through and
    self.number_of_rows_by_column.each_pair do |col, num|

      rand_column_contents = Set.new
      # draw num from uqr for this column
      while rand_column_contents.size < num
        rand_column_contents << uqr[rand(uqr.size)]
      end

      rand_column_contents.each do |row|
        matrix_copy.find_or_create_cell!(row, col)
      end
    end

    # Now save the matrix copy and update the column count
    matrix_copy.update_column_count!
    matrix_copy
  end

  # Gives a metric describing the number of cells in the matrix as a fraction of
  # the size -- in terms of the number of cells per column.
  def density
    cc = self.column_count
    cc = self.parent.column_count if cc == 0
    (self.number_of_unmasked_cells / cc.to_f).round
  end

  # Get a hash of the column identifiers to the number of rows that have non-zero
  # values in that column.
  def number_of_rows_by_column
    num_rows_by_column = {}
    Matrix.connection.select_rows(<<SQL
SELECT j, COUNT(DISTINCT entries.i) AS count_i FROM matrices
INNER JOIN entries ON (entries.matrix_id = matrices.id)
WHERE entries.type = 'Cell' AND matrices.id = #{self.id} GROUP BY j
SQL
    ).each do |row|
      num_rows_by_column[row[0].to_i] = row[1].to_i
    end
    num_rows_by_column
  end


  # Order the columns by the number of rows and build as a list of lists, for
  # plotting with flotomatic.
  def row_distribution
    num_rows_by_col = self.number_of_rows_by_column.values.sort
    num_rows_by_col.each_index do |i|
      val = num_rows_by_col[i]
      num_rows_by_col[i] = [i, val]
    end
    num_rows_by_col
  end


  # Get all columns or all columns with row i
  def columns(i = nil)
    self.cells_by_row_or_column(:i, :j, i)
  end

  # Get all rows or all those with column j
  def rows(j = nil)
    self.cells_by_row_or_column(:j, :i, j)
  end

  def cells_by_row_or_column(sym, other_sym, val = nil)
    if val.nil?
      self.entries.collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
    else
      self.entries.find(:all, :conditions => {sym => val}).collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
    end
  end

  # Prepare working directory for all matrices and their experiments.
  def self.prepare_inputs
    Matrix.all.each do |m|
      m.prepare_inputs unless m.mask?
    end

    # Only create experiments after matrices have been created
    Matrix.all.each do |m|
      m.experiments.each { |exp| exp.prepare_inputs } unless m.mask?
    end
  end

  # Prepare working directory for the matrix
  def prepare_inputs
    self.make_inputs(self.row_filename, self.cell_filename) unless self.root_exists?
  end

  def row_filename
    self.entry_info.row_filename(self.column_species)
  end

  def row_file_path
    self.root + self.row_filename
  end

  def cell_filename
    # This seems counter-intuitive, but it is correct. Hopefully.
    self.entry_info.cell_filename(self.column_species)
  end

  def cell_file_path
    self.root + self.cell_filename
  end

  # Use this when displaying the matrix, e.g. through Rails. Will return all
  # cells, but
  def cells_for_display
    self.mask? ? cells_for_display_as_masked : cells_for_display_as_not_masked
  end


  def number_of_unmasked_cells
    if self.mask?
      self.parent.cells.count - self.cells.count
    else
      self.cells.count
    end
  end

  def number_of_empty_rows
    if self.parent_id.nil?
      self.empty_rows.count
    else
      self.parent.number_of_empty_rows + self.empty_rows.count
    end
  end

  def number_of_rows
    if self.parent_id.nil?
      self.row_count
    else
      self.parent.row_count
    end
  end

  # If this is a submatrix, does it mask another matrix? Only the leaf matrices
  # are masks.
  def mask?
    self.children.count == 0 && !self.parent_id.nil? ? true : false
  end


  # If this is true, we can run a meta-analysis (the second-stage crossvalidation).
  def children_have_been_run?
    res = true
    res = false  if self.children.size == 0

    self.children.each do |child|
      res &&= child.has_been_run?
      return res unless res
    end
    
    res
  end

  # Returns true if all experiments have been run for a matrix.
  def has_been_run?
    res = true
    res = false  if self.experiments.size == 0

    self.experiments.each do |experiment|
      res &&= experiment.has_been_run?
      return res unless res
    end

    res
  end

  # Create a randomized matrix from the matrix m passed in as an argument.
#  def self.create_randomized!(m)
#    new_matrix = Matrix.create!(
#      :title => m.title + " (randomized)",
#      :entry_info_id => m.entry_info_id,
#      :species => m.species,
#      :randomized => true)
#  end


  # Creates a new matrix from two files, one consisting of a list of rows, and
  # the other a list of cells with true values.
  def self.create_from_file_pair!(row_filename, cell_filename, attributes = {})
    m = self.create_from_file!(row_filename, attributes)
    m.read_entries_from_file!(cell_filename)
    m
  end

  # Calls create_from_file_pair! for each pair of filenames.
  # In each pair should be a row file and a cell file.
  # Returns the matrices that were created.
  def self.create_from_file_pairs!(row_and_cell_filenames)
    matrices = []
    row_and_cell_filenames.each do |file_pair|
      matrices << Matrix.create_from_file_pair!(file_pair[0], file_pair[1])
    end
    matrices
  end


  # Creates a new matrix from a file (path/string, not stream).
  # File should contain either a list of rows or a set of pairs which denote cells
  # with true values.
  # In certain cases, these cells can also mask a parent matrix -- namely, if this
  # matrix itself has no children, but does have a parent.
  def self.create_from_file!(filename, attributes = {})
    
    # Infer as much information as possible.
    attributes[:row_species] = (infer_species_from_filename(filename.to_s) || "Hs") unless attributes.has_key?(:row_species)
    attributes[:column_species] = "Hs" unless attributes.has_key?(:column_species)
    attributes[:entry_info_id] = EntryInfo.find_or_create!("gene", "phenotype").id unless attributes.has_key?(:entry_info_id)
    attributes[:title] = filename.to_s unless attributes.has_key?(:title)
    
    m = Matrix.create!(attributes)
    m.read_entries_from_file!(filename)
    m
  end

  # Creates several new matrices from a series of files.
  def self.create_from_files!(list_of_files)
    res = []
    list_of_files.each do |file|
      res << Matrix.create_from_file!(file)
    end
    res
  end

  # Given a file stream or filename, read into this matrix.
  def read_entries_from_file!(file)
    if file.is_a?(String) || file.is_a?(Pathname)
      read_entries_from_open_file!(File.new(file, "r"))
    elsif file.is_a?(File)
      read_entries_from_open_file!(file)
    else
      raise ArgumentError, "Expected filename or file as argument"
      false
    end
  end

  # Get a list of unique rows in the matrix.
  def unique_rows
    Matrix.connection.select_values(self.unique_row_sql).collect { |x| x.to_i }
  end
  alias :uniq_rows :unique_rows
  
  # Get unique columns in the matrix (identical to unique_rows, but columns instead).
  def unique_columns
    Matrix.connection.select_values(self.unique_column_sql).collect { |x| x.to_i }
  end
  alias :uniq_columns :unique_columns
  alias :uniq_cols    :unique_columns
  alias :unique_cols  :unique_columns

  def unique_rows_by_column(which_j)
    Matrix.connection.select_values(self.unique_vector_sql(:i, which_j)).collect { |x| x.to_i }
  end

  def count_unique_rows_by_column(which_j)
    Matrix.connection.select_values(self.unique_vector_sql(:i, which_j, true)).first
  end

  def unique_columns_by_row(which_i)
    Matrix.connection.select_values(self.unique_vector_sql(:j, which_i)).collect { |x| x.to_i }
  end

  def count_unique_rows_by_column(which_i)
    Matrix.connection.select_values(self.unique_vector_sql(:j, which_i, true)).first
  end

  def count_unique_columns
    Matrix.connection.select_values(self.unique_column_sql(true)).first.to_i
  end

  def count_unique_rows
    Matrix.connection.select_values(self.unique_row_sql(true)).first.to_i
  end


  # Write all row indeces to a file.
  def write_rows!(file)
    self.save! if self.changed?
    self.write_saved_rows(file)
  end

  # Write a single matrix's row indeces.
  def write_rows(file, options = {})
    opts = self.write_options options
    
    if self.changed?
      raise NotImplementedError, "Sorry, you need to save the matrix before trying to write its contents. Call write_rows! instead if you want to force a save."
    else
      self.write_saved_rows(file)
    end
  end

  # Write a single matrix, not its children.
  def write(file, options = {})
    opts = self.write_options options
    
    if self.changed?
      raise NotImplementedError, "Sorry, you need to save the matrix before trying to write its contents. Call write! instead if you want to force a save."
    else
      self.write_saved(file, opts)
    end
  end

  # Depends on entry_infos -- genes and phenotypes as the row and column titles
  # indicate phenomatrix.
  def is_phenomatrix?
    self.entry_info.row_title == "gene" && self.entry_info.column_title == "phenotype"
  end

  # Force a save before writing; otherwise, same as write
  def write!(file, options = {})
    opts = self.write_options options
    
    self.save! if self.changed?
    self.write_saved(file, opts)
  end

  def write_children_if_masks file_prefix
    if !self.children.first.nil? && self.children.first.mask?
      self.children.each do |child|
        Dir.chdir(self.root) do
          child.write( self.child_filename_internal(file_prefix, child), :force_not_masked => true )
        end
      end
    end
  end

  def child_filename file_prefix, child_matrix
    raise(ArgumentError, "Matrix #{child_matrix.id} is not a mask and is therefore not located in the same directory as its parent.") unless child_matrix.mask?
    self.child_filename_internal(file_prefix, child_matrix)
  end

  def children_filenames file_prefix
    l = []
    if self.children.first.mask?
      self.children.each do |child|
        l << self.child_filename_internal(file_prefix, child)
      end
    end
    l
  end

  def children_file_paths file_prefix
    self.children_filenames(file_prefix).collect { |x| self.root + x }
  end

  def has_experiments_to_run?
    self.experiments.not_run.count > 0
  end

  
  # Get the number of stages of cross-validation this matrix is set up for.
  def stages
    return 0 if self.children.count == 0
    self.children.first.stages + 1 # recursive.
  end


  # Create n random subsets of this matrix, each of size (s * (n-1 / n)). If
  # supplied with a list, repeats recursively for each of the subsets.
  # If supplied with an integer, creates subsets which are of size (s / n),
  # which serve as masks.
  def fractalize(folds, methods, shuffle=true)

    if folds.is_a?(Array)
      fold    = folds.shift
      meth    = methods.shift

      STDERR.puts("fold is #{fold}, meth is #{meth}")
      
      raise(ArgumentError, "folds and methods must be the same size") unless folds.size == methods.size

      if folds.size >= 1
        self.fractalize_internal(fold, meth, shuffle)
        # recurse
        self.children.each do |child|
          child.fractalize(folds, methods, shuffle)
        end
      else
        self.mask_fractalize_internal fold, meth, shuffle
      end
    else
      self.mask_fractalize_internal folds, methods, shuffle
    end
  end

  def list_children
    self.children.collect { |x| x.id }.join(", ")
  end

  # Generate two files in the current directory, one containing the row indeces,
  # the other containing the cells in the matrix.
  def make_inputs rows_filename, cells_filename, file_prefix = "testset", dest_dir = self.root
    Dir.mkdir(dest_dir) unless File.exists?(dest_dir)
    Dir.chdir(dest_dir) do
      self.make_inputs_internal rows_filename, cells_filename
      self.write_children_if_masks file_prefix
    end
  end

  def self.work_root
    Rails.root + "tmp/work"
  end

  def root
    Matrix.work_root + "matrix_#{self.id}"
  end

  def dir_exists? dir
    File.exists?(dir)
  end

  def root_exists?
    dir_exists?(self.root)
  end

protected
  # Used for returning either row or column of every entry corresponding to this matrix.
  def unique_entry_value_sql(field, count = false)
    sql = "SELECT "
    if count
      sql << "COUNT(DISTINCT #{Entry.table_name}.#{field}) "
    else
      sql << "DISTINCT #{Entry.table_name}.#{field} "
    end
    sql << <<SQL
FROM #{Matrix.table_name}
INNER JOIN #{Entry.table_name} ON (#{Entry.table_name}.matrix_id = #{Matrix.table_name}.id)
WHERE #{Matrix.table_name}.id = #{self.id}
SQL
    sql
  end

  #
  def unique_vector_sql(field, at, count = false)
    vf = field == "i" ? "j" : "i"
    sql = self.unique_entry_value_sql(field, count)
    sql << " AND #{Entry.table_name}.#{vf} = #{at}"
    sql
  end



  def child_filename_internal file_prefix, child_matrix
    "#{file_prefix}.#{self.children.count.to_s}-#{child_matrix.cardinality}"
  end

  def make_inputs_internal rows_filename, cells_filename
    self.write_rows(rows_filename)
    self.write(cells_filename)
  end
  
  def unique_row_sql(count = false)
    unique_entry_value_sql("i", count)
  end

  def unique_column_sql(count = false)
    unique_entry_value_sql("j", count)
  end


  # Returns the default options for write() and the functions it calls.
  def write_options options = {}
    {
      :header => false,
      :force_not_masked => false
    }.merge options
  end

  # See write_saved
  def write_saved_rows file
    writelines(file, self.unique_rows)
  end

  # Use this to force writing of a matrix that has already been saved. It may work
  # with an unsaved file, but behavior could be unpredictable and it would likely
  # be a bad idea.
  def write_saved(file, options)
    
    f = file
    f = File.new(file, "w") if file.is_a?(String) || file.is_a?(Pathname)

    # write the header
    f.puts(matrix_info.to_s) if options[:header]

    self.write_contents(f, options)

    f.close
    f.path
  end

  # When writing, treat this matrix as a mask of the parent -- in other words,
  # print the parent's cells less the cells found in this child.
  def write_as_masked(open_file)
    parent_cells = Matrix.find(self.parent_id).cells
    my_cells     = self.cells

    # Subtract the mask from the parent cells and we get the remainder,
    # which we want to print.
    (parent_cells - my_cells).each do |entry|
      entry.write(open_file)
    end

    open_file
  end

  # Print the stuff in this matrix whether or not it's a mask of a parent.
  def write_as_not_masked(open_file)
    self.cells.each do |entry|
      entry.write(open_file)
    end
    open_file
  end

  # Write the contents of the matrix, keeping in mind that it may be a mask or
  # the full matrix. This should really never be called externally.
  def write_contents(open_file, options)
    if self.mask? && !options[:force_not_masked]
      write_as_masked(open_file)      # Complex case.
    else
      write_as_not_masked(open_file)  # Simple case.
    end
    
    open_file
  end

  # Get the set of cells or rows to fractalize. Called only by mask_fractalize_internal
  # and fractalize_internal.
  def set_to_fractalize meth, shuffle
    my_set = nil
    if meth == :cell
      my_set = self.cells.dup
      my_set.shuffle! if shuffle
    elsif meth == :row
      my_set = self.rows
      my_set.shuffle!
    else
      raise ArgumentError, "method #{meth} not recognized"
    end
    my_set
  end


  # Fractalize but build masks of this matrix (the parent) instead of building
  # whole matrices.
  # This function doesn't mess with empty row entries, only cell entries.
  def mask_fractalize_internal fold, meth, shuffle
    # self.divisions = fold
    
    divs     = split_set(self.set_to_fractalize(meth, shuffle), fold)
    self.build_submatrices! fold

    if meth == :cell
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        puts "cell div count is #{divs[n].size}"
        divs[n].each do |cell|
          self.children[n].cells.build(:i => cell.i, :j => cell.j)
        end
      end
    elsif meth == :row
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        puts "row div count is #{divs[n].size}"
        divs[n].each do |row|
          self.cells_by_row(row).each do |cell|
            self.children[n].cells.build(:i => cell.i, :j => cell.j)
          end
        end
      end
    end

    self.children
  end
  

  # Returns n new matrices, each with (s * (n - 1) / n) items.
  # Empty rows are copied into child matrices. If deletion of cells creates new
  # empty rows, those are created in the child as well.
  def fractalize_internal fold, meth, shuffle
    # self.divisions = fold

    divs     = split_set(self.set_to_fractalize(meth, shuffle), fold)
    self.build_submatrices! fold

    if meth == :cell
      (0...fold).each do |n|
        # Get the union of all but one of the divisions.
        puts "cell union count is #{divs[n].size}"
        combine_all_but_one(divs, n).each do |cell|
          self.children[n].cells.build(:i => cell.i, :j => cell.j)
        end
      end
    elsif meth == :row
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        puts "row union count is #{divs[n].size}"
        combine_all_but_one(divs, n).each do |row|
          self.cells_by_row(row).each { |cell| self.children[n].cells.build(:i => cell.i, :j => cell.j) }
        end
      end
    end

    self.children
  end

  
  def cells_by_row i
    self.cells.find(:all, :conditions => {:i => i})
  end


  def make_submatrix_title n, total
    self.title + " (" + (n+1).to_s + "/" + total.to_s + ")"
  end

  def build_submatrices! num
    (0...num).each do |n|
      self.children.build(:cardinality  =>  n,
        :title          =>   self.make_submatrix_title(n,num),
        :entry_info_id  =>   self.entry_info_id        )
    end
  end

  def find_or_create_cell!(i, j)
    Cell.find_or_create!(i, j, self.id)
  end

  def create_empty_row!(i)
    self.empty_rows.create!(:i => i)
  end

  def update_row_count
    self.row_count = self.count_unique_rows
  end

  def update_row_count!
    self.update_row_count
    self.save!
  end

  def update_column_count
    self.column_count = self.count_unique_columns
  end

  def update_column_count!
    self.update_column_count
    self.save!
  end


  # Read a list of cells or rows. If a single entry in a line, it's an empty row
  # (meaning no cells in that row). If two entries, it's a cell with a true value
  # in it.
  def read_entries_from_open_file!(file)
    while line = file.gets
      line.chomp!
      fields = line.split("\t")

      if fields.size == 1 # List of rows.
        # Create a row.
        self.create_empty_row!(fields[0])
      else
        # Convert a row to a cell (or just create a cell).
        self.find_or_create_cell!(fields[0].to_i, fields[1].to_i)
      end
    end

    self.update_column_count!
    self.update_row_count!
  end

  def cells_for_display_as_masked(res = {})
    parent_cells   = self.parent.cells
    child_cells    = self.cells
    unmasked_cells = parent_cells    -    child_cells

    unmasked_cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new
    end
    child_cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new(true) # masked
    end

    res
  end

  def cells_for_display_as_not_masked(res = {})
    self.cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new(false)
    end

    res
  end

end


# opposite of readlines. Not sure why it even needs to be added here, should
# be built in.
def writelines(path, data)
  File.open(path, "wb") do |file|
    file.puts(data)
  end
end

# See if we can infer species information from the filename.
def infer_species_from_filename fn
  fields = fn.split(".")
  fields.last =~ /^[A-Z][a-z]{1,2}$/ ? fields.last : nil
end

def split_set item_set, num_pieces
  num_per_piece  = Array.new(num_pieces)
  results        = Array.new(num_pieces)
  startpos       = 0

  # Figure out the sizes of the splits
  (0...num_pieces).each do |piece|
    num_per_piece[piece]  =  item_set.size / num_pieces
    # Uneven division: need to increase the first set's size.
    num_per_piece[piece] += 1 if piece < item_set.size % num_pieces

    results[piece]        = item_set.slice(startpos, num_per_piece[piece])
    startpos             += num_per_piece[piece]
  end

  results
end

def combine_all_but_one item_sets, leave_out
  item_set = []
  (0...item_sets.size).each do |n|
    next if n == leave_out
    item_set.concat item_sets[n]
  end

  item_set
end