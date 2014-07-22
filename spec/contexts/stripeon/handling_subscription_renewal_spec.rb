require 'rails_helper'

module Stripeon
  RSpec.describe HandlingSubscriptionRenewal do
    let(:stripe_subscription) { stripe_subscription_object }

    context "When subscription was found in DB" do
      [:canceled, :expired, :upgraded].each do |subscription_status|
        it "handles #{subscription_status} subscription correctly" do
          subscription = create :stripeon_subscription, subscription_status, id_on_stripe: stripe_subscription.id
          current_period_end_at = subscription.current_period_end_at.to_i
          expect(handle_subscription_update).to be false

          subscription.reload

          expect(subscription.status).to eql subscription_status.to_s
          expect(subscription.current_period_end_at.to_i).to eql current_period_end_at
        end
      end

      it "renews active subscription" do
        subscription = create :stripeon_subscription, :ended, id_on_stripe: stripe_subscription.id
        expect(handle_subscription_update).to be true

        subscription.reload

        expect(subscription.current_period_end_at.to_i).to eql stripe_subscription.current_period_end
        expect(subscription).to be_active
      end
    end

    context "When subscription was not found in DB" do
      it "returns false" do
        expect(handle_subscription_update).to be false
      end
    end

    private
    def handle_subscription_update
      HandlingSubscriptionRenewal.new(stripe_subscription).perform
    end

    def stripe_subscription_object
      subscription_json = <<-subscription
        {
          "id": "sub_00000000000000",
          "object": "subscription",
          "plan": {
            "interval": "month",
            "name": "New plan name123",
            "created": 1386247539,
            "amount": 2000,
            "currency": "usd",
            "id": "gold21323_00000000000000",
            "object": "plan",
            "livemode": false,
            "interval_count": 1,
            "trial_period_days": null,
            "metadata": {
            }
          },
          "start": 1392222040,
          "status": "active",
          "customer": "cus_00000000000000",
          "cancel_at_period_end": false,
          "current_period_start": 1392222040,
          "current_period_end": 1394641240,
          "ended_at": null,
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
