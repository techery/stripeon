require 'rails_helper'

module Stripeon
  RSpec.describe SubscriptionStatusTransition, type: :model do
    it { should belong_to :subscription }

    let(:subscription) { create :stripeon_subscription }

    it "logs status transition for event :cancel" do
      expect {
        subscription.cancel
      }.to change(subscription.subscription_status_transitions, :count).by(1)
    end

    it "logs status transition for event :expire" do
      expect {
        subscription.expire
      }.to change(subscription.subscription_status_transitions, :count).by(1)
    end

    it "logs status transition for event :upgrade" do
      expect {
        subscription.upgrade
      }.to change(subscription.subscription_status_transitions, :count).by(1)
    end

    it "stores event_source from subscription" do
      subscription.event_source = :spec
      subscription.expire

      logged_transitions = subscription.subscription_status_transitions.last

      expect(logged_transitions.event_source).to eql 'spec'
    end
  end
end
