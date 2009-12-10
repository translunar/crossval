class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments, :force => true do |t|
      t.references :predict_matrix, :null => false
      t.string :method, :null => false, :limit => 200, :default => "naivebayes"
      t.string :distance_measure, :null => false, :limit => 200, :default => "hypergeometric"
      t.string :validation_type, :default => "row", :null => false
      t.integer :k, :default => 1
      t.string :arguments, :limit => 200, :default => "-k 1" # Beyond :method and :distance_measure

      # These are only used when experiments/analyses are run.
      t.integer :run_result # Gives the result of a call to the shell.
      t.decimal :total_auc
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :experiments, :predict_matrix_id
  end

  def self.down
    drop_table :experiments
  end
end
