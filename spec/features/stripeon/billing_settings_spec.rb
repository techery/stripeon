require 'rails_helper'
include ActionView::Helpers::NumberHelper

feature "Billing settings", %{
  As a Speaker
  I can view my billing settings
} do

  given(:user) { create :user }

  context "Access billing settings as logged in user" do
    background { login_as user, scope: :user }

    context 'With active subscription' do
      given(:user)          { create :user }
      given!(:subscription) { create :stripeon_subscription, customer: user }

      background { visit stripeon.billing_settings_path }

      describe "Correct page title" do
        subject { page }

        it { should have_title "Stripeon | Plans and Billing" }
      end

      scenario "Accessing billing settings" do
        expect(page).to have_css 'body.stripeon-billing-settings-show'
      end

      context 'With credit card' do
        given(:user) { create :user, :with_credit_card }

        scenario 'See credit card information' do
          card = user.current_card

          expect(page).to have_content "#{card.type} xxxx xxxx xxxx #{card.last4}"
          expect(page).to have_content "Expiration: #{card.exp_month}/#{card.exp_year}"
        end
      end

      context 'Without credit card' do
        scenario 'See page witout credt card information' do
          expect(page).to have_css 'body.stripeon-billing-settings-show'
          expect(status_code).to eql 200
        end
      end

      context 'When subscription is active' do
        scenario 'See price and date of next rebill' do
          subscription = user.subscription
          price = number_to_currency(subscription.plan.price / 100, precision: 0)
          rebill_date = subscription.current_period_end_at.strftime("%B %d, %Y")

          expect(page).to have_content "Your credit card will automatically be charged #{price}"
          expect(page).to have_content "on #{rebill_date}"
        end
      end

      context 'When subscription is canceled' do
        given!(:subscription) { create :stripeon_subscription, :canceled, customer: user }

        scenario 'See date of subscription end' do
          end_date = subscription.current_period_end_at.strftime("%B %d, %Y")

          expect(page).to have_content "Your subscription will automatically expire on #{end_date}"
        end
      end
    end

    scenario "Accessing billing settings as user without active subscription" do
      user.stub subscribed?: false
      visit stripeon.billing_settings_path

      expect(page).to have_error "You don't have an active subscription"
      expect(current_path).to eql stripeon.plans_path
    end
  end

  scenario "Attempting to access billing settings as guest" do
    visit stripeon.billing_settings_path

    expect(current_path).to eql new_user_session_path
    expect(page).to have_error "You need to sign in or sign up before continuing"
  end
end
