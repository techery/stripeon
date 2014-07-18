class CreateStripeonPlans < ActiveRecord::Migration
  def change
    create_table :stripeon_plans do |t|
      t.string  :name
      t.integer :price,               default: 0,    null: false
      t.boolean :active,              default: true, null: false
      t.string  :id_on_stripe
      t.integer :subscriptions_count, default: 0

      t.timestamps
    end
  end
end
