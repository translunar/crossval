class CreateRocs < ActiveRecord::Migration
  def self.up
    create_table :rocs do |t|
      t.references :experiment, :null => false
      t.integer :column, :null => false
      t.decimal :auc, :null => false
      t.integer :true_positives, :null => false
      t.integer :false_positives, :null => false
      t.integer :true_negatives, :null => false
      t.integer :false_negatives, :null => false
    end

    add_index :rocs, [:column,:experiment_id], :unique => true
  end

  def self.down
    drop_table :rocs
  end
end
