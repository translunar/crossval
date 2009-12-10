class CreateEntryInfos < ActiveRecord::Migration
  def self.up
    create_table :entry_infos do |t|
      t.string :row_title, :default => 'gene', :null => false, :limit => 20
      t.string :column_title, :default => 'phenotype', :null => false, :limit => 20
    end
    add_index :entry_infos, [:row_title, :column_title], :unique => true
  end

  def self.down
    remove_index :entry_infos, [:row_title, :column_title]
    drop_table :entry_infos
  end
end
