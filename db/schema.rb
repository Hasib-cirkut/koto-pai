# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_09_195057) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chain_participants", force: :cascade do |t|
    t.bigint "chain_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id", "user_id"], name: "index_chain_participants_on_chain_id_and_user_id", unique: true
    t.index ["chain_id"], name: "index_chain_participants_on_chain_id"
    t.index ["user_id"], name: "index_chain_participants_on_user_id"
  end

  create_table "chains", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.bigint "lender_id"
    t.bigint "borrower_id"
    t.bigint "creator_id", null: false
    t.integer "lent_money", null: false
    t.integer "outstanding", null: false
    t.string "currency", default: "BDT", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["borrower_id"], name: "index_chains_on_borrower_id"
    t.index ["creator_id"], name: "index_chains_on_creator_id"
    t.index ["lender_id"], name: "index_chains_on_lender_id"
  end

  create_table "checkpoints", force: :cascade do |t|
    t.bigint "chain_id", null: false
    t.bigint "created_by_id", null: false
    t.integer "amount", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chain_id"], name: "index_checkpoints_on_chain_id"
    t.index ["created_by_id"], name: "index_checkpoints_on_created_by_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chain_participants", "chains"
  add_foreign_key "chain_participants", "users"
  add_foreign_key "chains", "users", column: "borrower_id"
  add_foreign_key "chains", "users", column: "creator_id"
  add_foreign_key "chains", "users", column: "lender_id"
  add_foreign_key "checkpoints", "chains"
  add_foreign_key "checkpoints", "users", column: "created_by_id"
end
