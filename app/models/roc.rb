class Roc < ActiveRecord::Base
  belongs_to :experiment

  delegate :predict_matrix, :predict_matrix_id, :to => :experiment

  # Calculates the ROC statistics for each column of the results for a given experiment.
  # Takes the experiment as an argument
  def self.calculate(experiment_id, results_path)

    rocs = []

    # Go to the experiment results directory.
    Dir.entries(results_path).each do |filename|
      next if filename == "roc" || filename == "." || filename == ".."

      rocs << Roc.new_by_calculating(experiment_id, filename.to_i, results_path)
    end

    rocs
  end

  # Creates a new Roc object by reading a file at path/column. In other words,
  # calculates the statistics for a given column (read: phenotype).
  def self.new_by_calculating experiment_id, column, path
    Roc.new(:experiment_id => experiment_id, :column => column).set_statistics(path)
  end

  # Calculates and sets the AUC value on an Auc object.
  # In order for this to work, experiment_id and column must already be set.
  def set_statistics(path)
    row_to_distance = self.read_column_file(path + self.column.to_s, 1) # 1 indicates no 'known' values in file.
    known_rows      = self.determine_known(row_to_distance.keys)
    # known_rows corresponds to Rocabilly's entrezids var
    # row_to_distance.keys corresponds to Rocabilly's candidates var, provided we
    # sort it first.

    # Do not use the roc_obj function to do this, as it computes the values differently.
    @roc_obj             = Statistics::ROC.new(:known_correct => known_rows, :guess_to_priority_hash => row_to_distance)
    self.auc             = @roc_obj.area_under_curve
    self.auc             = 0.0 if self.auc.nan?
    self.true_positives  = @roc_obj.true_positives
    self.true_negatives  = @roc_obj.true_negatives
    self.false_positives = @roc_obj.false_positives
    self.false_negatives = @roc_obj.false_negatives

    # Make sure to return self so we can chain, e.g. in new_by_calculating
    self
  end

  def roc_obj
    @roc_obj ||= Statistics::ROC.new(
      :tp => self.true_positives,
      :fp => self.false_positives,
      :tn => self.true_negatives,
      :fn => self.false_negatives)
  end

  def fpr; roc_obj.fpr; end
  def tpr; roc_obj.tpr; end
  def tnr; roc_obj.tnr; end
  def acc; roc_obj.acc; end
  def precision; roc_obj.precision; end
  def npv; roc_obj.npv; end
  def fdr; roc_obj.fdr; end
  def mcc; roc_obj.mcc; end
  def ppv; roc_obj.ppv; end

  alias :sensitivity :tpr
  alias :true_positive_rate :tpr
  alias :recall :tpr
  alias :hit_rate :tpr

  alias :false_positive_rate :fpr
  alias :fall_out :fpr
  alias :false_alarm_rate :fpr

  alias :true_negative_rate :tnr
  alias :specificity :tnr

  alias :precision :ppv
  alias :positive_predictive_value :ppv

  alias :negative_predictive_value :npv

  alias :false_discovery_rate :fdr

  alias :matthews :mcc
  alias :matthews_correlation_coefficient :mcc

  def negatives; roc_obj.negatives; end
  def positives; roc_obj.positives; end

protected

  # If this Auc object is for some column j, determine whether -- for each row i --
  # there is an Entry at i,j in the predict_matrix.
  # Returns a list of rows where i,j is true.
  def determine_known(rows)
    known_rows = []
    rows.each do |row|
      known_rows << row if self.known_entry?(row)
    end
    known_rows
  end

  # Determines whether a specific cell exists.
  def known_entry?(i)
    !Entry.find(:first, :conditions => {:matrix_id => self.predict_matrix_id, :i => i, :j => self.column}).nil?
  end

  # Open a column file, containing a list of rows and distances. Return a hash
  # from row to distance.
  def read_column_file(file_path, distance_column = 1, ignore_lines = 1)
    file = File.new(file_path, "r")
    self.read_open_column_file(file, distance_column, ignore_lines)
  end

  def read_open_column_file(file, distance_column, ignore_lines)
    row_to_distance = {}

    ignore_lines.times { file.gets }

    while line = file.gets
      line.chomp!
      fields = line.split("\t")
      row_to_distance[fields[0].to_i] = fields[distance_column].to_f
    end

    row_to_distance
  end
end


# Given a hash from row to distance, return the rows in sorted order (least to most likely)
def sort_rows_by_distance(row_to_distance)
  row_to_distance.sort { |b,a| a[1] <=> b[1] }.collect { |x| x.first }
end