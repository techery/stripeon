class CreateStripeonEvents < ActiveRecord::Migration
  def change
    create_table :stripeon_events do |t|
      t.string   :id_on_stripe, null: false
      t.string   :request_id
      t.string   :type,         null: false, limit: 50
      t.string   :ip_address,   null: false, limit: 15
      t.text     :payload
      t.boolean  :processed,    null: false, default: false
      t.datetime :fired_at

      t.timestamps
    end
  end
end
