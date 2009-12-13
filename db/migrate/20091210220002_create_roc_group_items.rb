class CreateRocGroupItems < ActiveRecord::Migration
  def self.up
    create_table :roc_group_items do |t|
      t.references :roc_group, :null => false
      t.references :experiment, :null => false
      t.string :legend

      t.timestamps
    end
    add_index :roc_group_items, :roc_group_id
  end

  def self.down
    drop_table :roc_group_items
  end
end
