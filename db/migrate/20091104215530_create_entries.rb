class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries, :force => true do |t|
      t.integer :i, :null => false
      t.integer :j
      t.references :matrix, :null => false
      t.string :type, :limit => 9, :null => false
    end
    add_index :entries, [:i, :j, :matrix_id], :unique => true
  end

  def self.down
    remove_index :entries, [:i, :j, :matrix_id]
    drop_table :entries, [:entry_id, :matrix_id, :mask]
  end
end
