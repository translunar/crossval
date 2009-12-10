class CreateMatrices < ActiveRecord::Migration
  def self.up
    create_table :matrices, :force => true do |t|
      # For submatrices
      t.references :parent, :default => nil
      t.integer :cardinality, :default => nil

      # For parent matrices
      t.integer :divisions, :default => nil # DELETE THIS.
      t.string  :row_species, :default => "Hs", :limit => 3, :null => false
      t.string  :column_species, :default => "Hs", :limit => 3, :null => false
      t.integer :row_count, :default => 0
      t.integer :column_count, :default => 0

      # For all matrices
      t.string  :title, :null => false, :limit => 300, :unique => true
      t.references :entry_info, :null => false

      t.timestamps
    end
    add_index :matrices, [:parent_id, :cardinality], :unique => true
  end

  def self.down
    remove_index :matrices, [:parent_id,:cardinality]
    drop_table :matrices
  end
end
