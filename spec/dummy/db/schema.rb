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

ActiveRecord::Schema.define(version: 20140722144708) do

  create_table "stripeon_credit_cards", force: true do |t|
    t.integer  "customer_id",                                null: false
    t.string   "id_on_stripe",                               null: false
    t.string   "last4",        limit: 4,                     null: false
    t.integer  "exp_month",                                  null: false
    t.integer  "exp_year",                                   null: false
    t.string   "type",                   default: "Unknown", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripeon_events", force: true do |t|
    t.string   "id_on_stripe",                            null: false
    t.string   "request_id"
    t.string   "type",         limit: 50,                 null: false
    t.string   "ip_address",   limit: 15,                 null: false
    t.text     "payload"
    t.boolean  "processed",               default: false, null: false
    t.datetime "fired_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripeon_plans", force: true do |t|
    t.string   "name"
    t.integer  "price",               default: 0,    null: false
    t.boolean  "active",              default: true, null: false
    t.string   "id_on_stripe"
    t.integer  "subscriptions_count", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripeon_subscription_status_transitions", force: true do |t|
    t.integer  "subscription_id"
    t.string   "event"
    t.string   "from"
    t.string   "to"
    t.string   "event_source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripeon_subscriptions", force: true do |t|
    t.integer  "customer_id",                                null: false
    t.integer  "plan_id",                                    null: false
    t.datetime "current_period_end_at",                      null: false
    t.string   "id_on_stripe"
    t.string   "status",                  default: "active"
    t.datetime "current_period_start_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stripeon_transactions", force: true do |t|
    t.integer  "credit_card_id"
    t.string   "id_on_stripe",                       null: false
    t.integer  "amount",         default: 0,         null: false
    t.boolean  "successful",     default: false,     null: false
    t.string   "type",           default: "unknown", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "id_on_stripe"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
