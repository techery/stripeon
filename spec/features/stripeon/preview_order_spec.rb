require 'rails_helper'

feature 'Preview order', %{
  As a Speaker
  I can preview my order
} do

  given(:user) { create :user }
  given(:user_with_active_subscription) { create :user, :with_active_subscription }
  given!(:plan) { create :stripeon_plan, name: "Economy", price: "2500" }

  context "When have no active subscription" do
    background do
      login_as_customer user
    end

    scenario "Previewing order" do
      visit stripeon.plans_url
      pricing_table = page.all('ul.pricing-table').last
      click_link pricing_table.find('a', text: "Buy now").text
      order_section = page.find('.order')

      expect(page).to have_title "Subscribe to Economy plan"

      expect(page).to have_content('Subscribe Now for $25')
    end

    scenario "Previewing order with not active plan" do
      visit stripeon.new_subscription_path(plan_id: 100500)

      expect(page).to have_content I18n.t('activerecord.errors.plan_not_found')
      expect(page).not_to have_selector('.order')
      expect(current_path).to eql stripeon.plans_path
    end
  end

  context "When have active subscription" do
    scenario "Redirecting to billing settings page with error" do
      login_as_customer user_with_active_subscription
      visit stripeon.new_subscription_path(plan_id: plan.id)

      expect(current_path).to eql stripeon.billing_settings_path
      expect(page).to have_content I18n.t('errors.already_subscribed')
    end
  end
end
