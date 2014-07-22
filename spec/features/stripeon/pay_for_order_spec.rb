require 'rails_helper'

feature 'Pay for order', %{
  As a Speaker
  I can pay for my order
}, js: true do

  given(:user) { create :user }

  given!(:plan) { create :stripeon_plan, :with_stripe_call, price: 2500 }

  background do
    login_as user, scope: :user, run_callbacks: false
    visit stripeon.new_subscription_path(plan_id: plan.id)
  end

  context "With valid credit card" do
    feature "Receive purchase confirmation email", %{
      As a Speaker
      I can receive email purchase confirmation after successful charge
    } do
      scenario "Receiving email with purchase confirmation" do
        expect {
          pay_now_with_card
          expect(page).to have_notice "Thank you for your subscription!"
        }.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(ActionMailer::Base.deliveries.last).to eql 'Stripeon: Subscription Confirmation'

      end
    end

    context "When transaction has been processed" do
      background { pay_now_with_card }

      scenario "Subscription is created" do
        expect {
          expect(page).to have_notice "Thank you for your subscription!"
        }.to change(user.subscriptions, :count).by(1)

        subscription = user.reload.subscription

        expect(subscription.plan).to eql plan

        expect(subscription.current_period_end_at).to be > Time.now
        expect(subscription.current_period_start_at).to be_within(5.minutes).of(Time.now)
      end

      feature "See purchase confirmation", %{
        As a Speaker
        I can see order purchase confirmation after successful charge
      } do
        scenario "Seeing purchase confirmation" do
          expect(page).to have_notice "Thank you for your subscription!"
          expect(current_path).to eql stripeon.billing_settings_path
        end
      end
    end

    context "When transaction has been declined by Stripe" do
      # Charge of following cards will fail on Stripe
      [
        ['4000000000000341', "Your card was declined"],
        ['4000000000000119', "An error occurred while processing your card"],
        ['4000000000000127', "Your card's security code is incorrect"],
        ['4000000000000069', "Your card has expired"]
      ].each do |(card, error)|
        scenario "See empty payment form with decline reason for card #{card}" do
          pay_now_with_card number: card

          expect(page).to have_field('Credit card number', with: '')
          expect(page).to have_field('Security Code',      with: '')
          expect(page).to have_select('expiry-month', selected: 'Month')
          expect(page).to have_select('expiry-year',  selected: 'Year')

          expect(page).to have_error "Your transaction has been declined: #{error}"
        end
      end
    end
  end

  context "With invalid credit card details" do
    scenario "See error about invalid credit card number" do
      pay_now_with_card number: '12345'

      expect(page).to have_error "This card number looks invalid"
    end

    scenario "See error about credit card number not passing Luhn's check" do
      pay_now_with_card number: '4242424242424241'

      expect(page).to have_error "Your card number is incorrect"
    end

    scenario "See error about not valid cvv/cvc code" do
      pay_now_with_card cvc: '12'

      expect(page).to have_error "Your card's security code is invalid"
    end
  end
end
