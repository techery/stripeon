require 'rails_helper'

feature "View list of active plans", %{
  As a Speaker
  I can view list of active plans
} do

  describe "When user logged in" do
    given(:user) { create :user }

    background do
      login_as(user, scope: :user)
      create :stripeon_plan, name: "Economy", price: "2500"
      create :stripeon_plan, name: "Plus",    price: "5000"
      create :stripeon_plan, name: "Extreme", price: "10000"
      create :stripeon_plan, name: "Premium", price: "7500"

      visit stripeon.plans_url
      @pricing_tables = page.all('ul.pricing-table')
    end

    scenario "Viewing list of available plans sorted ascending by price" do
      prices = @pricing_tables.map { |l| l.find('li.cta-button').text.delete('Buy now for ') }
      plans_prices_ascending = ["$25", "$50", "$75", "$100"]

      expect(prices).to eq plans_prices_ascending
    end


    scenario "Viewing list of available plans" do
      plans = Stripeon::Plan.ascending.decorate

      @pricing_tables.each_with_index do |table, i|
        expect(table).to have_selector(
          'li.title', text: "#{plans[i].name}"
        )

        expect(table).to have_link(
          "Buy now for $#{plans[i].price_in_dollars.to_i}",
          href: stripeon.new_subscription_path(plan_id: plans[i].id)
        )
      end
    end
  end

  describe "When user not logged in" do
    scenario "It redirects to login page" do
      visit stripeon.plans_url

      expect(current_path).to eql new_user_session_path
    end
  end
end
