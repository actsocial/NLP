# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150619065851) do

  create_table "daily_threads", :id => false, :force => true do |t|
    t.string   "thread_id", :limit => 765
    t.string   "title",     :limit => 6000
    t.datetime "date"
  end

  create_table "fn_contents", :force => true do |t|
    t.string   "tag_id"
    t.integer  "fn_count"
    t.text     "content"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "test_volume"
    t.float    "value"
  end

  create_table "fnfps", :force => true do |t|
    t.integer  "post_id"
    t.string   "tag_id"
    t.string   "flag"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.float    "value"
  end

  create_table "fp_contents", :force => true do |t|
    t.string   "tag_id"
    t.integer  "fp_count"
    t.text     "content"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "test_volume"
    t.float    "value"
  end

  create_table "likelihoods", :force => true do |t|
    t.string   "tag_id"
    t.string   "feature"
    t.float    "likelihood"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "post_features", :force => true do |t|
    t.integer  "post_id"
    t.string   "feature"
    t.integer  "occurrence"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "post_features", ["post_id"], :name => "post_id"

  create_table "post_tags", :force => true do |t|
    t.integer  "post_id"
    t.string   "tag_id"
    t.integer  "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "posts", :force => true do |t|
    t.text     "content"
    t.boolean  "is_test"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "precises", :force => true do |t|
    t.string   "tag_id"
    t.float    "precise"
    t.float    "recall"
    t.float    "true_positive"
    t.float    "false_positive"
    t.float    "true_negative"
    t.float    "false_negative"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "test_volume"
  end

  create_table "priors", :force => true do |t|
    t.string   "tag_id"
    t.float    "prior"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id", :length => {"session_id"=>191}
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tags", :force => true do |t|
    t.string   "tag_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "terms", :force => true do |t|
    t.string   "post_id"
    t.string   "word"
    t.datetime "post_time"
    t.integer  "count"
    t.string   "scope"
  end

  add_index "terms", ["post_id", "count", "post_time", "word"], :name => "id_date_count"

  create_table "thread_source", :force => true do |t|
    t.string   "thread_id", :limit => 120,  :null => false
    t.string   "title",     :limit => 2000
    t.datetime "date"
  end

  create_table "topic_dates", :force => true do |t|
    t.string   "topic"
    t.date     "date"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
