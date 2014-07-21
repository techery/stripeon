class CreateStripeonCreditCards < ActiveRecord::Migration
  def change
    create_table :stripeon_credit_cards do |t|
      t.references :customer,   null: false

      t.string   :id_on_stripe, null: false
      t.string   :last4,        null: false, limit: 4
      t.integer  :exp_month,    null: false
      t.integer  :exp_year,     null: false
      t.string   :type,         null: false, default: 'Unknown'

      t.timestamps
    end
  end
end
