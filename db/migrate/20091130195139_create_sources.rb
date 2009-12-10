class CreateSources < ActiveRecord::Migration
  def self.up
    create_table :sources do |t|
      t.references :experiment, :null => false
      t.references :source_matrix, :null => false
    end
    add_index :sources, [:source_matrix_id, :experiment_id], :unique => true
  end

  def self.down
    drop_table :sources
  end
end
