require 'rails_helper'

module Stripeon
  RSpec.describe PurchasingSubscription do
    pending "TODO: Refactor subscription creation process"

    # let(:customer) { FactoryGirl.build :user }
    # let(:plan)     { FactoryGirl.build :plan }
    # let(:params) do
    #   { card_token: double(:card_token) }
    # end

    # let(:listener) { double(:listener).as_null_object }

    # context "When charge was successful" do
    #   context "When customer is already registred on Stripe" do
    #     before do
    #       customer.stub on_stripe: double(:stripe_customer, cards: double(:cards).as_null_object)
    #     end

    #     it "does not register another customer on Stripe" do
    #       expect(Stripe::Customer).not_to receive(:create)
    #       purchase_subscription
    #     end

    #     it "links credit card to customer" do
    #       expect(customer.cards).to receive(:create).with(card: params[:card_token])
    #       purchase_subscription
    #     end
    #   end

    #   context "When customer is not registred on Stripe" do
    #     before { customer.stub on_stripe: nil }

    #     it "registers customer on Stripe with card" do
    #       expect(
    #         Stripe::Customer
    #       ).to receive(:create).with(card: params[:card_token], email: customer.email)

    #       purchase_subscription
    #     end
    #   end

    #   it "stores information about credit card"

    #   it "links credit card to customer"
    #   it "creates subscription on Stripe"
    #   it "stores information about subscription"
    #   it "stores information about transaction"
    #   it "sends email receipt"

    #   it "notifies listener about created subscription" do
    #     expect(listener).to receive(:create_on_success)
    #     purchase_subscription
    #   end
    # end

    # context "When charge has been declined" do
    #   it "notifies listener about decline reason" do
    #     decline_reason = "Insufficient funds"
    #     customer.stub(:subscribe_to) { raise DeclinedTransactionException.new, decline_reason }

    #     expect(listener).to receive(:create_on_decline).with(decline_reason)
    #     purchase_subscription
    #   end
    # end

    # context "When communication with Stripe fails" do
    #   it "notifies listener about general error" do
    #     general_error = "Something went wrong"
    #     customer.stub(:subscribe_to) { raise general_error }

    #     expect(listener).to receive(:create_on_error).with(general_error)
    #     purchase_subscription
    #   end
    # end

    # private
    # def purchase_subscription
    #   PurchasingSubscription.new(customer, plan, params, listener).purchase
    # end
  end
end