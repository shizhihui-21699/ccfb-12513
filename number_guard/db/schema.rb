# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_11_18_000000) do

  create_table "carrier_records", force: :cascade do |t|
    t.string "phone", null: false
    t.string "carrier_name", default: "中国移动", null: false
    t.datetime "activated_at", null: false
    t.string "status", default: "in_service", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["phone"], name: "index_carrier_records_on_phone", unique: true
  end

  create_table "login_attempts", force: :cascade do |t|
    t.integer "user_id"
    t.string "phone", null: false
    t.string "decision", null: false
    t.string "reason", null: false
    t.datetime "carrier_activated_at"
    t.datetime "phone_confirmed_at"
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["decision"], name: "index_login_attempts_on_decision"
    t.index ["user_id"], name: "index_login_attempts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "phone", null: false
    t.string "email"
    t.string "nickname"
    t.string "security_question"
    t.string "security_answer_digest"
    t.datetime "last_phone_confirmed_at", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["phone"], name: "index_users_on_phone", unique: true
  end

  create_table "verifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "login_attempt_id", null: false
    t.string "method"
    t.string "status", default: "pending", null: false
    t.text "payload"
    t.text "applicant_note"
    t.text "admin_note"
    t.datetime "reviewed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["login_attempt_id"], name: "index_verifications_on_login_attempt_id"
    t.index ["status"], name: "index_verifications_on_status"
    t.index ["user_id"], name: "index_verifications_on_user_id"
  end

  add_foreign_key "login_attempts", "users"
  add_foreign_key "verifications", "login_attempts"
  add_foreign_key "verifications", "users"
end
