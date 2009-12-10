require Rails.root + "../phenologdb/lib/phenomatrix_generator.rb"
require Rails.root + 'app/models/matrix'
require 'logger'

# Adapts a matrix to a directory structure.
class MatrixAdapter

  attr_reader :experiment_adapters, :matrix

  def initialize(matrix, options = {})
    opts = {
      :only_source_dir => false
    }.merge options

    @matrix = matrix

    if opts[:only_source_dir]
      Rails.logger.info("Building source matrix input files and copying to #{opts[:only_source_dir]}")
      inputs = self.prepare_constant_inputs_in_dir
      self.copy_files_to_dir inputs, opts[:only_source_dir]

    else
      
      Rails.logger.info("Building matrix directory structure for id #{matrix.id}.")

      new_matrix_directory = !self.prepare_path
      new_experiment_directory = new_matrix_directory

      puts "self.root = #{self.root}"

      @experiment_adapters = []
      @matrix.experiments.each do |experiment|

        if experiment.total_auc.nil?
          # Only create an adapter if AUC has not been calculated yet.
          experiment_adapter = ExperimentAdapter.new(self, experiment)
          new_experiment_directory = true if experiment_adapter.new_experiment?

          @experiment_adapters << experiment_adapter
        end
      end

      inputs = []
      if new_matrix_directory
        Rails.logger.info("Building input files for matrix #{matrix.id}.")
        # Prepare input files for the phenomatrix binary.
        inputs      = self.prepare_constant_inputs
        inputs.concat self.prepare_crossval_inputs
      else
        inputs      = self.contents
      end

      if new_experiment_directory
        Rails.logger.info("Copying input files for matrix #{matrix.id} to experiments.")
        self.copy_inputs_to_experiments(inputs)

        # This has to be run only after the other inputs are created.
        @experiment_adapters.each do |experiment_adapter|
          experiment_adapter.prepare_inputs
        end
      end
    end
  end

  # Get the working directory for analyses (where all the matrix dirs are)
  def self.root
    Rails.root + "tmp/work"
  end

  # Get the directory for this matrix
  def root
    @root ||= MatrixAdapter.root + "matrix_#{@matrix.id}"
  end

  def child_prefix
    "testset"
  end

  def find_experiment_adapter(experiment_id)
    @experiment_adapters.each do |experiment_adapter|
      return experiment_adapter if experiment_adapter.experiment.id == experiment_id
    end
    nil
  end

protected

  # Makes sure directories exist. Returns false if anything has to be created.
  def prepare_path
    res = true
    
    unless File.exists?(MatrixAdapter.root)
      puts "MatrixAdapter.root = #{MatrixAdapter.root} does not exist."
      Dir.mkdir(MatrixAdapter.root)
      res = false
    end
    
    unless File.exists?(self.root)
      puts "root = #{self.root} does not exist."
      Dir.mkdir(self.root)
      res = false
    end

    puts "Returning #{res}"
    res
  end


  # Call this instead of prepare_constant_inputs if you don't want any changing
  # of directories.
  def prepare_constant_inputs_in_dir
    predict_species               = @matrix.species
    predict_genes_filename        = "genes.#{predict_species}"
    predict_genes_phenes_filename = "genes_phenes.#{predict_species}"
    
    unless File.exists?(predict_genes_filename)
      Rails.logger.info("Writing predict matrix: #{predict_genes_filename}")
      @matrix.write_rows predict_genes_filename
    end

    unless File.exists?(predict_genes_phenes_filename)
      Rails.logger.info("Writing predict_matrix: #{predict_genes_phenes_filename}")
      @matrix.write predict_genes_filename, :header => false
    end

    [predict_genes_filename, predict_genes_phenes_filename]
  end


  # Make sure files exist
  def prepare_constant_inputs
    res = nil
    Dir.chdir(self.root) do
      res = self.prepare_constant_inputs_in_dir
    end
    
    res
  end


  def prepare_crossval_inputs
    files = []
    @matrix.children.each do |child|
      filename = "#{self.child_prefix}.#{@matrix.divisions.to_i}-#{child.cardinality.to_i}"
      child.write("#{self.root + filename}", :force_not_masked => true)

      files << filename
    end
    files
  end


  def copy_inputs_to_experiments files
    Rails.logger.info("Copying files to experiment directories.")
    # Copy each of the created files to the adapter.
    @experiment_adapters.each do |experiment_adapter|
      self.copy_files_to_dir files, experiment_adapter.root
      #files.each do |file|
      #  FileUtils.cp(self.root + file, experiment_adapter.root, :verbose => true)
      #end if experiment_adapter.new_experiment?
    end
    Rails.logger.info("Done copying.")
  end

  def copy_files_to_dir files, dir
    Rails.logger.info("Copying #{files.size} files (#{files.to_sentence}) to directory #{dir}.")
    
    # Copy each of the created files to the adapter.
    files.each do |file|

      if File.exists?(dir+file)
        Rails.logger.info("File #{dir+file} already exists. Not copying.")
      else
        FileUtils.cp(self.root + file, dir, :verbose => true)
      end

    end
    Rails.logger.info("Done copying.")
  end

  
  # Get the contents of this matrix's directory.
  def contents
    Dir.entries(root).delete_if { |x| x == "." || x == ".." || x =~ /^experiment_[0-9]*$/}
  end
end
