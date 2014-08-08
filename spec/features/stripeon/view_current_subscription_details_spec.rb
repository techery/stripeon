require 'rails_helper'

feature "View current subscription details", %{
  As a Speaker
  I can view my current subscription details
} do

  # TODO: Add specs for coupon subscription

  given(:user_without_subscription)      { create :user }
  given(:user_with_active_subscription)  { create(:stripeon_subscription).customer }
  given(:user_with_expired_subscription) {
    create(:stripeon_subscription, current_period_end_at: Date.yesterday).customer
  }

  context "Any type of user" do
    # TODO: check validness of test for user_without_subscription

    [
      :user_without_subscription,
      :user_with_active_subscription,
      :user_with_expired_subscription
    ].each do |user_type|
      given(:user) { send user_type }

      background { login_as_customer user }

      scenario "Viewing current subscription plan details by #{user_type.to_s.humanize.downcase}" do
        visit stripeon.billing_settings_path
        subscription_details_block = page.find '.current-plan', visible: true

        expect(subscription_details_block).to(
          have_selector 'p', 'Your Plan'
        )

        expect(subscription_details_block).to(
          have_selector 'p.plan', text: "#{user.subscription.plan.name}"
        )
      end
    end
  end
end
