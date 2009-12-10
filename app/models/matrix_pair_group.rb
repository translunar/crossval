require 'matrix_pair'

# Convert a list of MatrixPair ids to Matrix ids.
def pair_id_list_to_matrix_id_list pair_id_list
  to_matrix_id_list   = Set.new
  from_matrix_id_list = Set.new

  pair_id_list.each do |pair_id|
    matrix_pair = MatrixPair.find(pair_id)

    to_matrix_id_list   << matrix_pair.to_id
    from_matrix_id_list << matrix_pair.from_id
  end

  raise(ArgumentError, "Multiple destination matrices is not allowed in the list of pairs") if to_matrix_id_list.size > 1

  # Return the destination as the first item, along with all the sources.
  to_matrix_id_list.to_a.concat((from_matrix_id_list - to_matrix_id_list).to_a)
end

# A temporary object which handles SQL queries for a set of matrix pairs.
class MatrixPairGroup
  # Set up a group as a temporary object using a bunch of MatrixPair objects.
  # These pairs should all have the same to_id.
  def initialize pair_id_list
    raise(ArgumentError, "Requires list or set of matrix pair IDs") unless pair_id_list.is_a?(Array) || pair_id_list.is_a?(Set)
    raise(ArgumentError, "At least one matrix pair required") unless pair_id_list.size > 1
    @matrix_id_list = pair_id_list_to_matrix_id_list(pair_id_list.uniq)
  end
  
  def destination_matrix_id
    @matrix_id_list.first
  end
  alias :predict_matrix_id :destination_matrix_id

  def destination_matrix
    Matrix.find(self.destination_matrix_id)
  end
  alias :predict_matrix :destination_matrix

  def source_matrix_ids
    @matrix_id_list - self.destination_matrix_id
  end

  def source_matrices
    self.source_matrix_ids.collect { |id| Matrix.find(id) }
  end

  

  # Get a list of unique rows in the matrix.
#  def unique_rows
#    Matrix.connection.select_values(self.unique_row_sql)
#  end
#  alias :uniq_rows :unique_rows
#
#  # Get unique columns in the matrix (identical to unique_rows, but columns instead).
#  def unique_columns
#    Matrix.connection.select_values(self.unique_column_sql)
#  end
#  alias :uniq_columns :unique_columns
#  alias :uniq_cols    :unique_columns
#  alias :unique_cols  :unique_columns
#
#private
#  # Used for returning either row or column of every entry corresponding to a matrix
#  # involved in this pair.
#  # TODO: Consider sanitizing this one and the ones in Matrix and MatrixPair.
#  def unique_entry_value_sql(field)
#    sql = <<SQL
#SELECT DISTINCT "#{field}" FROM #{Matrix.table_name}
#INNER JOIN #{MatrixEntry.table_name} ON (#{MatrixEntry.table_name}.matrix_id = #{Matrix.table_name}.id)
#INNER JOIN #{Entry.table_name} ON (#{MatrixEntry.table_name}.entry_id = #{Entry.table_name}.id)
#WHERE #{Matrix.table_name}.id IN (#{@matrix_id_list.join(",")})
#SQL
#  end
#
#protected
#  def unique_row_sql
#    unique_entry_value_sql("row")
#  end
#
#  def unique_column_sql
#    unique_entry_value_sql("column")
#  end
end