class MatrixPair < ActiveRecord::Base
  belongs_to :predict_matrix, :foreign_key => :to_id,   :class_name => "Matrix"
  belongs_to :source_matrix,  :foreign_key => :from_id, :class_name => "Matrix"

  def is_phenomatrix_pair?
    self.predict_matrix.entry_info_id == self.source_matrix.entry_info_id && self.source_matrix.is_phenomatrix?
  end

  # Returns the number of unique rows which exist in the two matrices, keeping in
  # mind that the source matrix is a bottleneck. That is, we can't predict anything
  # in the predict_matrix that does not exist in the source_matrix.
#  def unique_rows
#    raise #TODO: Fix. Do we really need this function?
#    MatrixPair.connection.select_values(self.unique_row_sql)
#  end
#  alias :uniq_rows :unique_rows
#
#  def total_unique_rows
#    MatrixPair.connection.select_values(self.total_unique_row_sql)
#  end
#  alias :total_uniq_rows :total_unique_rows
#
#  # Returns the total number of unique columns across the two matrices.
#  def unique_columns
#    MatrixPair.connection.select_values(self.unique_column_sql)
#  end
#  alias :uniq_columns :unique_columns
#  alias :uniq_cols    :unique_columns
#  alias :unique_cols  :unique_columns

#private
#  # Used for returning either row or column of every entry corresponding to a matrix
#  # involved in this pair.
#  def unique_entry_value_sql(field)
#    sql = <<SQL
#SELECT DISTINCT "#{field}" FROM #{MatrixPair.table_name}
#INNER JOIN #{MatrixEntry.table_name} ON (#{MatrixEntry.table_name}.matrix_id = #{MatrixPair.table_name}.from_id OR #{MatrixEntry.table_name}.matrix_id = #{MatrixPair.table_name}.to_id)
#INNER JOIN #{Entry.table_name} ON (#{MatrixEntry.table_name}.entry_id = #{Entry.table_name}.id)
#WHERE #{MatrixPair.table_name}.id = #{self.id}
#SQL
#  end
#
#protected
#
#  def unique_column_sql
#    unique_entry_value_sql("column")
#  end
#
#  def total_unique_row_sql
#    unique_entry_value_sql("row")
#  end
  
end
