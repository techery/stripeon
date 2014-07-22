require 'rails_helper'
include ActionView::Helpers::NumberHelper

feature "See plans table on billing setting page", %{
  As a Speaker
  I can see list of plans on billing setting page
  So that I can upgrade to higher tier
} do
  given(:user) { FactoryGirl.create :user }

  let!(:economy_plan)  { create :stripeon_plan, name: "Economy", price: "2500"  }
  let!(:plus_plan)     { create :stripeon_plan, name: "Plus",    price: "5000"  }
  let!(:extreme_plan)  { create :stripeon_plan, name: "Extreme", price: "10000" }
  let!(:premium_plan)  { create :stripeon_plan, name: "Premium", price: "7500"  }

  let!(:inactive_plan) { create :stripeon_plan, :inactive, name: 'Inactive Plan' }

  let!(:subscription) { create :stripeon_subscription, customer: user, plan: premium_plan }

  let(:plans_table) { page.find('table.billing-plans') }
  let(:rows) { plans_table.find("tbody").all('tr') }

  background do
    login_as user, scope: :user

    visit billing_settings_path
  end

  describe "Correct page title" do
    subject { page }

    it { should have_title "Stripeon | Plans and Billing" }
  end

  scenario 'Does not displaying special plans'  do
    expect(plans_table).not_to have_content 'Special Plan'
  end

  scenario "Showing explanatory heading for table" do
    expect(page).to have_css 'h2', "Available plans"

    titles = plans_table.find('thead').all('th')

    expect(titles.size).to eql 3
    expect(titles[0]).to have_content 'Plan'
    expect(titles[1]).to have_content 'Price'
    expect(titles[2].text).to be_empty
  end

  scenario "Listing all paid plans sorted descending by price " do
    plans = [extreme_plan, premium_plan, plus_plan, economy_plan]

    rows.each_with_index do |row, i|
      next if plans[i].nil?
      values = row.all('td')

      expect(values[0]).to have_content plans[i].name
      expect(values[1]).to have_content number_to_currency(plans[i].price / 100, precision: 0)
    end
  end

  scenario "Aren't listing inactive plans" do
    expect(rows.size).to eql 4
    expect(plans_table).not_to have_content('Inactive Plan')
  end

  scenario "Indicating user's current subscription's plan as active" do
    row = plans_table.find('tr', text: premium_plan.name)

    expect(row.all('td')[2]).to have_content "Your Plan"

    [economy_plan, plus_plan, extreme_plan].each do |other_plan|
      row = plans_table.find('tr', text: other_plan.name)
      expect(row.all('td')[2]).not_to have_content "Your Plan"
    end
  end

  context "When user subscription is active" do
    scenario "Showing upgrade button for plans larger than current" do
      rows.each do |row|
        columns = row.all('td')
        if columns[0].has_content? "Extreme" # Can upgrade only to Extreme
          expect(columns[2]).to have_link 'Upgrade', upgrade_subscription_path
        else
          expect(columns[2]).not_to have_link 'Upgrade'
        end
      end
    end
  end

  context "When subscription is canceled" do
    let!(:subscription) { create :stripeon_subscription, :canceled, customer: user, plan: premium_plan }

    scenario "Not showing upgrade button" do
      rows.each do |row|
        expect(row.all('td')[2]).not_to have_link 'Upgrade'
      end
    end
  end
end
