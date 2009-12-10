require 'logger'

class ExperimentAdapter

  attr_reader :experiment, :new_experiment

  def initialize matrix_adapter, experiment
    @matrix_adapter = matrix_adapter
    @experiment     = experiment
    
    Rails.logger.info("Building experiment directory structure for matrix id #{matrix_adapter.matrix.id}, experiment #{experiment.id}.")
    
    @new_experiment = !self.prepare_path
  end

  def new_experiment?
    @new_experiment
  end

  # Get the directory for this matrix
  def root
    @root ||= @matrix_adapter.root + "experiment_#{@experiment.id}"
  end

  def bin_root
    Rails.root + "bin/"
  end

  def bin_path
    self.bin_root + "phenomatrix"
  end

  def sort_path
    self.bin_root + "sortall.pl"
  end

  def calculate_aucs_path
    self.bin_root + "calculate_aucs.py"
  end

  # Path to the STDOUT log file.
  def log_path
    Rails.root + "log/phenomatrix.log"
  end

  # Path to the STDERR log file.
  def error_log_path
    Rails.root + "log/phenomatrix.error"
  end

  # Run the binary to perform the analysis, then process the results.
  def run
    Dir.chdir(self.root) do
      @experiment.run(self.bin_path, self.log_path, self.error_log_path)
      @experiment.sort_results(self.sort_path, self.log_path, self.error_log_path)
      @experiment.calculate_aucs(self.calculate_aucs_path, self.log_path)
    end
  end

  # Make sure input files exist. Return false if any directories have to be created.
  # The predict_matrix inputs are taken care of by MatrixAdapter.
  # This function needs to handle the source matrices, which it does by creating
  # a simple MatrixAdapter.
  def prepare_inputs
    res = self.prepare_path

    @experiment.sources.find(:all, :joins => :matrix).each do |source|

      # Create a matrix adapter for each source that only creates genes.Sp and
      # genes_phenes.Sp files -- without any changing of directories.
      MatrixAdapter.new(source.matrix, :only_source_dir => self.root)
    end

    res
  end

protected
  # Makes sure directories exist. Returns false if anything has to be created.
  def prepare_path
    res = @matrix_adapter.send :prepare_path
    
    if File.exists?(self.root)
      puts "ExperimentAdapter prepare_path returning #{res.to_s}"
      return res
    else
      Dir.mkdir(self.root)
      puts "ExperimentAdapter prepare_path returning false"
      return false
    end
  end
end