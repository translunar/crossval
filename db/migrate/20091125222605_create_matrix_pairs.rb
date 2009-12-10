class CreateMatrixPairs < ActiveRecord::Migration
  def self.up
    create_table :matrix_pairs, :force => true do |t|
      t.references :to, :null => false
      t.references :from, :null => false

      t.timestamps
    end
    add_index :matrix_pairs, [:to_id, :from_id], :unique => true
  end

  def self.down
    remove_index :matrix_pairs, [:to_id, :from_id]
    drop_table :matrix_pairs
  end
end
