class Experiment < ActiveRecord::Base
  AVAILABLE_METHODS = {"Naive Bayes (JOW)" => "naivebayes", "Partial Bayes (JOW)" => "partialbayes"}
  AVAILABLE_DISTANCE_MEASURES = {"Hypergeometric" => "hypergeometric",
      "Manhattan" => "manhattan",
      "Euclidean" => "euclidean"}

  acts_as_commentable
  belongs_to :predict_matrix, :class_name => "Matrix", :readonly => true
  delegate :column_species, :to => :predict_matrix
  alias :predict_species :column_species
  has_many :sources, :dependent => :destroy
  has_many :source_matrices, :through => :sources, :foreign_key => :source_matrix_id, :class_name => "Matrix", :readonly => true
  has_many :rocs
  accepts_nested_attributes_for :sources

  named_scope :not_run, :conditions => {:total_auc => nil}

  # Print a title for this experiment
  def title
    self.argument_string
  end


  # Copy input files from each of the source matrices and the predict matrix.
  def prepare_inputs
    unless self.root_exists?
      logger.info("Preparing new inputs for experiment #{self.id}")
      
      self.prepare_dir

      cell_files = self.copy_source_matrix_inputs

      # Generate predict_rows file and put the testsets in the right place.
      self.generate_row_file(cell_files)
      self.copy_testsets

      # Only copy the predict matrix cells file if it didn't come from one of the
      # source matrices.
      unless cell_files.include?(self.predict_matrix.cell_file_path)
        FileUtils.cp(self.predict_matrix.cell_file_path, self.root)
      end
      
    end
  end

  # Copy the inputs from the source matrices. Returns a list of cell files so we
  # can compute the rows that we're capable of predicting (e.g., predict_genes).
  def copy_source_matrix_inputs(dir = self.root)
    cell_files = []
    self.source_matrices.each do |source_matrix|
      FileUtils.cp(source_matrix.row_file_path, self.root)
      FileUtils.cp(source_matrix.cell_file_path, self.root)

      # Also keep track of genes files.
      cell_files << source_matrix.cell_filename
    end
    cell_files
  end

  def row_filename
    "predict_" + self.predict_matrix.row_title.pluralize
  end

  def column_filename
    "predict_" + self.predict_matrix.column_title.pluralize
  end

  def column_file_path
    self.root + self.column_filename
  end

  def row_file_path
    self.root + self.row_filename
  end

  def column_file_exists?
    File.exists?(self.column_file_path)
  end

  def row_file_exists?
    File.exists?(self.row_file_path)
  end

  def dir_exists? dir
    File.exists?(dir)
  end

  def root_exists?
    dir_exists?(self.root)
  end

  def root
    self.predict_matrix.root + "experiment_#{self.id}"
  end

  def source_species
    self.sources.collect{ |m| m.source_species }.sort{ |a,b| Species.new(b) <=> Species.new(a) }
  end

  def source_species_to_s
    self.source_species.join(",")
  end

  def command_string
    "#{self.bin_path} #{self.argument_string}"
  end

  def command_string_with_pipes
    "#{self.command_string} 2>> #{self.error_log_file} 1>> #{self.log_file}"
  end

  # Get the points that make up the ROC plot for this experiment
  def roc_line
    roc_y_values = self.rocs.collect { |r| r.auc }
    roc_x_values = Array.new(roc_y_values.size) { |r| r / roc_y_values.size.to_f }
    roc_x_values.zip roc_y_values.sort
  end

  # To be called by a Worker object, usually.
  def run
    self.started_at = Time.now
    self.save_without_timestamping!

    Dir.chdir(self.root) do
      STDERR.puts("Command: #{self.command_string}")
      `#{self.command_string_with_pipes}`

      # Get the exit status when the bin finishes.
      self.run_result = $?.to_i
    end
    # Expect a great deal of time between the beginning of this function and the
    # end. That's why we're saving again -- because the binary will have returned
    # 0 or aborted or who knows what.
    self.save_without_timestamping!

    if self.run_result == 0
      self.sort_results

      # Calculating the AUCs also marks the task as completed and saves the record.
      self.calculate_rocs!
    else
      logger.error("Execution error for binary. Returned: #{self.run_result}")
    end
  end

  # Clean out the temporary variables used for a run.
  # Be careful doing this -- particularly if this is being run in parallel, e.g.
  # jobs on different machines.
  def reset_for_new_run!
    self.started_at   = nil
    self.completed_at = nil
    self.run_result   = nil
    self.total_auc    = nil
    self.save_without_timestamping!

    self.clean_predictions_dirs
    self.clean_temporary_files

    self # allow chaining
  end

  def reset_inputs
    `rm -rf #{self.root}`
    self.prepare_inputs unless self.sources.size == 0
  end

  # Remove intermediate predictions files
  def clean_predictions_dirs
    Dir.chdir(self.root) do
      `rm -rf predictions*`
    end
  end

  # Remove intermediate distance and common items files.
  def clean_temporary_files
    Dir.chdir(self.root) do
      `rm -f *.distances *.pdistances *.common *.pcommon`
    end
  end

  def log_file
    "log.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def error_log_file
    "error_log.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def aucs_file
    "aucs.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def results_dir
    "results.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def results_path
    self.root + self.results_dir
  end

  def bin_path
    Rails.root + "bin/phenomatrix"
  end

  def sort_bin_path
    Rails.root + "bin/sortall.pl"
  end

  def aucs_bin_path
    Rails.root + "bin/calculate_aucs.py"
  end

  def argument_string
    str = "-m #{self.read_attribute(:method)} -d #{self.distance_measure} -n #{self.predict_matrix.children.count} -S #{self.predict_species} -s #{self.source_species_to_s} -t #{self.validation_type} -k #{self.k} "
    str << self.arguments
    str
  end

  def sort_results
    Dir.chdir(self.root) do
      `#{self.sort_bin_path} #{self.results_dir} predictions* 2>> #{self.error_log_file} 1>> #{self.log_file}`
    end
  end

  def calculate_rocs!
    aucs = []
    Roc.calculate(self.id, self.results_path).each do |roc|
      roc.save!
      aucs << roc.auc
    end

    self.total_auc = mean aucs
    self.completed_at = Time.now
    self.save_without_timestamping!
  end

  def calculate_aucs_old
    Dir.chdir(self.root) do
      aucs_file = self.aucs_file
      `#{self.aucs_bin_path} #{self.results_dir} 1>> #{aucs_file} 2>> #{self.error_log_file}`
      self.total_auc = calculate_average_auc(read_aucs(aucs_file))
    end
    
    self.completed_at = Time.now
    self.save_without_timestamping!
  end

  def has_been_run?
    !self.total_auc.nil?
  end

protected

  # Takes an absolute path, mind you. Creates a directory. By default, creates
  # the directory for this experiment.
  def prepare_dir(dir = self.root)
    Dir.mkdir(dir) unless dir_exists?(dir)
  end

  # Generate the file for rows to be predicted (e.g., predict_genes)
  def generate_row_file(cell_files)
      Dir.chdir(self.root) do
        `cut -f 1 #{cell_files.join(" ")} |sort|uniq > #{self.row_filename}`
        `cut -f 2 #{self.predict_matrix.cell_file_path} |sort|uniq > #{self.column_filename}`
      end
  end

  # Copy testsets from the predict_matrix to the experiment directory.
  def copy_testsets(prefix = "testset")
    # Copy testsets if applicable
    self.predict_matrix.children_file_paths(prefix).each do |child_path|
      FileUtils.cp(child_path, self.root)
    end
  end

  # Force a save without updating timestamps.
  # Used to update total_auc, which is not technically part of the model.
  # Also -- for completed_at and started_at
  def save_without_timestamping!
    class << self
      def record_timestamps; false; end
    end
    save!
    class << self
      remove_method :record_timestamps
    end
  end
end


def time_to_file_suffix t
  t.utc.strftime("%Y%m%d%H%M%S")
end

def calculate_average_auc hash_of_aucs
  total = 0.0
  hash_of_aucs.values.each { |value| total += value }
  total / hash_of_aucs.size.to_f
end

def read_aucs file
  f = File.new(file, "r")
  h = {}
  while line = f.gets
    line.chomp!
    fields = line.split("\t")

    # Insert in the hash
    h[ fields[0].to_i ]   =    fields[1].to_f
  end
  f.close

  h
end

def mean l
  total = 0
  l.each { |x| total += x }
  total / l.size.to_f
end