require 'rails_helper'

module Stripeon
  # TODO: Correct subject for describe so it is name of concern and not of the included class
  RSpec.describe ::User, type: :model do
    let(:customer) { create :user }

    it { should have_many :subscriptions }
    it { should have_many :credit_cards  }
    it { should have_many(:transactions).through(:credit_cards) }

    it { should validate_uniqueness_of :id_on_stripe }

    describe "#subscribed?" do
      subject { customer }

      context "when customer has active subscription" do
        before { create :stripeon_subscription, customer: customer }
        it { should be_subscribed }
      end

      context "when customer has only inactive subscription" do
        before { create :stripeon_subscription, :expired, customer: customer }
        it { should_not be_subscribed }
      end

      context "when customer doesn't have any subscriptions" do
        before { customer.stub subscriptions: Subscription.none }
        it { should_not be_subscribed }
      end
    end

    describe "#current_card" do
      it "returns last created credit card" do
        credit_card = double :credit_card

        customer.stub_chain(:credit_cards, :order_by_creation, :last).and_return credit_card
        expect(customer.current_card).to eql credit_card
      end
    end

    describe "#subscription" do
      let(:customer) { create :user }

      subject { customer.subscription }
      before { customer.stub current_active_subscription: double(:subscription) }

      it { should eql customer.send(:current_active_subscription) }
    end

    describe "#current_active_subscription" do
      it "returns last created active subscription" do
        subscription = double :subscription

        customer.stub_chain(:subscriptions, :active, :order_by_creation, :last).and_return subscription
        expect(customer.send :current_active_subscription).to eql subscription
      end
    end

    describe "#on_stripe" do
      let(:customer) { create :user, id_on_stripe: nil }

      context "when id_on_stripe is empty" do
        subject { customer.on_stripe }

        it { should be_nil }
      end

      context "when id_on_stripe is not empty" do
        context "and it correct" do
          it "returns stripe object" do
            stripe_object = double :stripe_object
            customer.stub id_on_stripe: 'id_on_stripe'

            expect(
                Stripe::Customer
            ).to receive(:retrieve).with(customer.id_on_stripe).and_return(stripe_object)

            expect(customer.on_stripe).to eql stripe_object
          end
        end

        context "and it incorrect/expired" do
          it "returns nil" do
            customer.stub id_on_stripe: 'id_on_stripe'
            Stripe::Customer.stub(:retrieve) { raise "Stripe error reason" }

            expect(customer.on_stripe).to be_nil
          end
        end
      end
    end
  end
end
