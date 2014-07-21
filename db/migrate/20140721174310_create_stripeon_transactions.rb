class CreateStripeonTransactions < ActiveRecord::Migration
  def change
    create_table :stripeon_transactions do |t|
      t.references :credit_card

      t.string  :id_on_stripe,                   null: false
      t.integer :amount,     default: 0,         null: false
      t.boolean :successful, default: false,     null: false
      t.string  :type,       default: 'unknown', null: false

      t.timestamps
    end
  end
end
