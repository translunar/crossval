# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091210220002) do

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment",                        :default => ""
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"

  create_table "entries", :force => true do |t|
    t.integer "i",                      :null => false
    t.integer "j"
    t.integer "matrix_id",              :null => false
    t.string  "type",      :limit => 9, :null => false
  end

  add_index "entries", ["i", "j", "matrix_id"], :name => "index_entries_on_i_and_j_and_matrix_id", :unique => true

  create_table "entry_infos", :force => true do |t|
    t.string "row_title",    :limit => 20, :default => "gene",      :null => false
    t.string "column_title", :limit => 20, :default => "phenotype", :null => false
  end

  add_index "entry_infos", ["row_title", "column_title"], :name => "index_entry_infos_on_row_title_and_column_title", :unique => true

  create_table "experiments", :force => true do |t|
    t.integer  "predict_matrix_id",                                              :null => false
    t.string   "method",            :limit => 200, :default => "naivebayes",     :null => false
    t.string   "distance_measure",  :limit => 200, :default => "hypergeometric", :null => false
    t.string   "validation_type",                  :default => "row",            :null => false
    t.integer  "k",                                :default => 1
    t.string   "arguments",         :limit => 200, :default => "-k 1"
    t.integer  "run_result"
    t.decimal  "total_auc"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "experiments", ["predict_matrix_id"], :name => "index_experiments_on_predict_matrix_id"

  create_table "matrices", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "cardinality"
    t.string   "row_species",    :limit => 3,   :default => "Hs", :null => false
    t.string   "column_species", :limit => 3,   :default => "Hs", :null => false
    t.integer  "row_count",                     :default => 0
    t.integer  "column_count",                  :default => 0
    t.string   "title",          :limit => 300,                   :null => false
    t.integer  "entry_info_id",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "matrices", ["parent_id", "cardinality"], :name => "index_matrices_on_parent_id_and_cardinality", :unique => true

  create_table "roc_group_items", :force => true do |t|
    t.integer  "roc_group_id",  :null => false
    t.integer  "experiment_id", :null => false
    t.string   "legend"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roc_group_items", ["roc_group_id"], :name => "index_roc_group_items_on_roc_group_id"

  create_table "roc_groups", :force => true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rocs", :force => true do |t|
    t.integer "experiment_id",   :null => false
    t.integer "column",          :null => false
    t.decimal "auc",             :null => false
    t.integer "true_positives",  :null => false
    t.integer "false_positives", :null => false
    t.integer "true_negatives",  :null => false
    t.integer "false_negatives", :null => false
  end

  add_index "rocs", ["column", "experiment_id"], :name => "index_rocs_on_column_and_experiment_id", :unique => true

  create_table "sources", :force => true do |t|
    t.integer "experiment_id",    :null => false
    t.integer "source_matrix_id", :null => false
  end

  add_index "sources", ["source_matrix_id", "experiment_id"], :name => "index_sources_on_source_matrix_id_and_experiment_id", :unique => true

end
