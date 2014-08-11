require 'rails_helper'

feature 'Cancel subscription', %{
  As a Speaker
  I can cancel my subscription rebills if I opted-in for rebills
} do

  given!(:economy_plan) { create :stripeon_plan, name: "Economy", price: "2500" }
  given!(:premium_plan) { create :stripeon_plan, name: "Premium", price: "7500" }
  given!(:subscription) { create :stripeon_subscription, plan: premium_plan }

  given(:user) { subscription.customer }

  background { login_as_customer user }

  context "When user is paid" do
    context "With active subscription" do

      describe "Cancelation is successful" do
        scenario "Requesting cancelation confirmation" do
          visit stripeon.billing_settings_path

          expect(page).to have_link("Cancel Subscription", href: stripeon.cancel_subscription_path)

          click_link "Cancel Subscription"

          expect(page).to have_css 'h2', text: "Cancel Subscription"
          expect(page).to have_content(
            "Your current subscription will be active till #{subscription.current_period_end_at.strftime("%B %d, %Y")}"
          )
          expect(page).to have_content "This action can not be undone"

          cancel_link = find_link("Cancel my subscription", href: stripeon.subscription_path)
          expect(cancel_link["data-method"]).to eql "delete"
        end

        scenario "Canceling subscription" do
          Stripeon::Subscription.any_instance.stub cancel_on_stripe: true
          cancel_subscription

          expect(current_path).to eql stripeon.billing_settings_path
          expect(page).to have_notice "Your subscription has been successfully canceled"
          expect(page).not_to have_link "Cancel Subscription"
          expect(subscription.reload).to be_canceled
        end
      end

      describe "Cancelation fails" do
        context "When user does not have active subscription" do
          given(:user) { create :user }

          scenario "See error message" do
            cancel_subscription

            expect(current_path).to eql stripeon.plans_path
            expect(page).to have_error "You don't have an active subscription"
          end
        end

        context "When Stripe communication fails" do
          scenario "Are not canceling subscription" do
            Stripeon::Subscription.any_instance.stub(cancel_on_stripe: false)
            cancel_subscription

            expect(current_path).to eql stripeon.billing_settings_path
            expect(page).to have_error "Failed to cancel subscription. Please try later"
            expect(subscription.reload).not_to be_canceled
          end
        end
      end
    end

    context "With cancelled subscription" do
      given!(:subscription) { create :stripeon_subscription, :canceled, plan: premium_plan }

      scenario "Not allowing to cancel subscription second time" do
        cancel_subscription

        expect(current_path).to eql stripeon.billing_settings_path
        expect(page).to have_error "Your subscription is already canceled"
      end

      scenario "Not showing cancelation link" do
        visit stripeon.billing_settings_path

        expect(page).not_to have_link("Cancel Subscription", href: stripeon.cancel_subscription_path)
      end

      scenario "Not showing cancelation confirmation request" do
        visit stripeon.cancel_subscription_path

        expect(current_path).to eql stripeon.billing_settings_path
        expect(page).to have_error "Your subscription is already canceled"
      end
    end
  end

  private

  def cancel_subscription
    page.driver.submit :delete, stripeon.subscription_path, {}
  end
end
