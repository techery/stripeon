require 'rails_helper'

module Stripeon
  RSpec.describe HandlingSubscriptionExpiration do
    let(:stripe_subscription) { stripe_subscription_object }

    describe "Handling not canceled Stripe subscription" do
      before { stripe_subscription.stub status: 'active' }
      let!(:subscription) { create :stripeon_subscription, id_on_stripe: stripe_subscription.id }

      it "returns false" do
        expect(handle_expired_subscription).to be false
      end

      it "does not change subscription status in our DB" do
        handle_expired_subscription

        expect(subscription.reload).to be_active
      end
    end

    describe "Handling canceled Stripe subscription" do
      context "When subscription was found in DB" do
        it "handles already expired subscription correctly" do
          subscription = create :stripeon_subscription, :expired, id_on_stripe: stripe_subscription.id
          expect(handle_expired_subscription).to be true

          expect(subscription.reload).to be_expired
        end

        it "expires not expired subscription and notify owner via email" do
          subscription = create :stripeon_subscription, id_on_stripe: stripe_subscription.id

          expect {
            expect(handle_expired_subscription).to be true
          }.to change(ActionMailer::Base.deliveries, :count).by(1)
          expect(subscription.reload).to be_expired
        end

        context "Handle upgraded and duplicated subscriptions correctly" do
          let!(:subscription_upgraded) { create :stripeon_subscription, :upgraded, id_on_stripe: stripe_subscription.id }
          let!(:subscription_active)   { create :stripeon_subscription, id_on_stripe: stripe_subscription.id }
          let!(:subscription_active2)  { create :stripeon_subscription, id_on_stripe: stripe_subscription.id }

          before { handle_expired_subscription }

          it "don't change upgraded subscription status" do
            expect(subscription_upgraded.reload).to be_upgraded
          end

          it "expire all active subscriptions" do
            expect(subscription_active.reload ).to be_expired
            expect(subscription_active2.reload).to be_expired
          end
        end
      end

      context "When subscription was not found in DB" do
        it "returns false" do
          expect(handle_expired_subscription).to be false
        end
      end
    end

    def handle_expired_subscription
      HandlingSubscriptionExpiration.new(stripe_subscription).perform
    end

    def stripe_subscription_object
      subscription_json = <<-subscription
        {
          "id": "sub_00000000000000",
          "plan": {
            "interval": "month",
            "name": "Paid Plan 50",
            "created": 1391166223,
            "amount": 2500,
            "currency": "usd",
            "id": "plan_00000000000000",
            "object": "plan",
            "livemode": false,
            "interval_count": 1,
            "trial_period_days": null,
            "metadata": {
            }
          },
          "object": "subscription",
          "start": 1391538253,
          "status": "canceled",
          "customer": "cus_00000000000000",
          "cancel_at_period_end": false,
          "current_period_start": 1391538253,
          "current_period_end": 1393957453,
          "ended_at": 1391489417,
          "trial_start": null,
          "trial_end": null,
          "canceled_at": null,
          "quantity": 1,
          "application_fee_percent": null,
          "discount": null
        }
      subscription

      Stripe::Util.convert_to_stripe_object JSON.parse(subscription_json).symbolize_keys, Stripe.api_key
    end
  end
end
