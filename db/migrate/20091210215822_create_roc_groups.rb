class CreateRocGroups < ActiveRecord::Migration
  def self.up
    create_table :roc_groups do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :roc_groups
  end
end
