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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151021133609) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "caches", force: :cascade do |t|
    t.integer  "cacheable_id"
    t.string   "cacheable_type"
    t.datetime "cached_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "players", force: :cascade do |t|
    t.string   "name"
    t.string   "position"
    t.string   "team"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projections", force: :cascade do |t|
    t.integer  "week"
    t.decimal  "average"
    t.decimal  "min"
    t.decimal  "max"
    t.string   "platform"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "salaries", force: :cascade do |t|
    t.integer  "value"
    t.string   "platform"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
