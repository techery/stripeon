class CreateStripeonSubscriptionStatusTransitions < ActiveRecord::Migration
  def change
    create_table :stripeon_subscription_status_transitions do |t|
      t.references :subscription

      t.string  :event
      t.string  :from
      t.string  :to
      t.string  :event_source

      t.timestamps
    end
  end
end
