class CreateStripeonSubscriptions < ActiveRecord::Migration
  def change
    create_table :stripeon_subscriptions do |t|
      t.references :customer,            null: false
      t.references :plan,                null: false

      t.datetime :current_period_end_at, null: false
      t.string   :id_on_stripe
      t.string   :status, default: 'active'
      t.datetime :current_period_start_at

      t.timestamps
    end
  end
end
