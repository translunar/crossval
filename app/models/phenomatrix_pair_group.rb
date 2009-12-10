# Adds functions specific to Genes and Phenotypes to MatrixPairGroup.
# These functions are useful for generating inputs for the phenomatrix C++ bin.
# They assume that you've only loaded matrices with the proper parameters --
# that is, two known genes per phenotype (other phenotypes excluded). Also,
# all orthologs are given with the human ID.
class PhenomatrixPairGroup < MatrixPairGroup

  def initialize pair_id_list
    # Make sure each matrix is of the correct type.
    res = true
    pair_id_list.each do |pair_id|
      res &&= MatrixPair.find(pair_id).is_phenomatrix_pair?
    end
    raise(ArgumentError, "Requires phenomatrices only -- check column_title and row_title and see the requirements for is_phenomatrix? in Matrix class") unless res

    # Let MatrixPairGroup's constructor take over.
    super pair_id_list
  end

  def destination_genes
    self.destination_matrix.unique_rows
  end

  def destination_phenotypes
    self.destination_matrix.unique_columns
  end

  def source_genes
    self.source_matrices.collect { |m| m.unique_rows }.uniq
  end

  # Return all genes associated with the destination matrix that also exist in
  # the source matrices. Keep in mind that the source matrix is going to be
  # entirely composed of genes that also exist in the destination.
  def genes_with_orthologs
    self.destination_genes & self.source_genes
  end

  def genes_without_orthologs
    self.destination_genes - self.source_genes
  end
  alias :destination_genes_without_orthologs :genes_without_orthologs

  

end