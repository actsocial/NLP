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

ActiveRecord::Schema.define(:version => 0) do

  create_table "FEATURE_TAG_0", :id => false, :force => true do |t|
    t.string "tag_id"
    t.string "feature"
    t.string "value"
    t.float  "frequency"
  end

  create_table "FEATURE_TAG_1", :id => false, :force => true do |t|
    t.string "tag_id"
    t.string "feature"
    t.string "value"
    t.float  "frequency"
  end

  create_table "LIKELIHOOD", :id => false, :force => true do |t|
    t.string "tag_id"
    t.string "feature"
    t.float  "freq0"
    t.float  "freq1"
    t.float  "likelihood"
  end

  create_table "PRIOR", :id => false, :force => true do |t|
    t.string "tag_id"
    t.float  "prior"
  end

  create_table "TAG_STATS", :id => false, :force => true do |t|
    t.string  "tag_id"
    t.string  "value"
    t.integer "distinct_features_num", :limit => 8, :default => 0, :null => false
    t.integer "feature_num",           :limit => 8, :default => 0, :null => false
  end

  create_table "post_features", :id => false, :force => true do |t|
    t.string "id"
    t.string "post_id"
    t.string "feature"
    t.string "occurrence"
  end

  create_table "posts", :id => false, :force => true do |t|
    t.string "id"
    t.string "content"
    t.string "created_at"
  end

  create_table "posts_tags", :id => false, :force => true do |t|
    t.string "id"
    t.string "post_id"
    t.string "tag_id"
    t.string "value"
  end

  create_table "tags", :id => false, :force => true do |t|
    t.string "id"
  end

end
