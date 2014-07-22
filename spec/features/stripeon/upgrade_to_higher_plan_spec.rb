require 'rails_helper'

shared_examples "Handling bad subscription upgrade requests" do
  context "When subscription is canceled" do
    given!(:subscription) { create :stripeon_subscription, :canceled, customer: user, plan: current_plan }

    it { should be_on_path billing_settings_path }
    it { should have_error "We are sorry but your current subscription is not upgradeable" }
  end

  context "When requested plan does not exists" do
    let(:requested_plan_id) { 100500 }
    it { should have_error "The plan you requested was not found. Probably it is no longer active" }
  end

  context "When requested plan is not active" do
    given!(:requested_plan) { create :stripeon_plan, :inactive }
    it { should have_error "The plan you requested was not found. Probably it is no longer active" }
  end

  context "When requested plan is smaller than original" do
    given!(:requested_plan) { create :stripeon_plan, name: "Small", price: "1000" }
    it { should have_error 'We are sorry but your current subscription can not be upgraded to requested plan "Small"' }
  end
end

feature "Upgrade to higher plan", %{
  As a Speaker
  I can upgrade to a higher plan
} do
  subject { page }

  given(:user) { FactoryGirl.create :user }

  given!(:current_plan)   { create :stripeon_plan, name: "Economy", price: "2500" }
  given!(:requested_plan) { create :stripeon_plan, name: "Premium", price: "5000" }
  given!(:subscription)   { create :stripeon_subscription, customer: user, plan: current_plan }

  given(:requested_plan_id) { requested_plan.id }

  background { login_as user, scope: :user }

  describe "Request upgrade confirmation" do
    context "When subscription can be upgraded" do
      given(:period_start) { Time.parse "16:20:20 19 April, 2012" } # keep calm and rake drug:acid
      given(:current_time) { Time.parse "18:00:00 20 April, 2012" } # happy b-day

      given!(:subscription) {
        create :subscription,
               stripeon_: user,
               plan: current_plan,
               current_period_start_at: period_start
      }

      background { Time.stub now: current_time }

      scenario "Requesting upgrade confirmation" do
        visit billing_settings_path
        click_link "Upgrade"

        expect(page).to have_title "Upgrade to Premium plan"

        expect(page).to have_css 'h2', text: "Upgrade to Premium plan"
        expect(page).to have_content(
          "Your monthly bill will increase from $25 to $50 on #{subscription.current_period_end_at.strftime("%B %d, %Y")}"
        )
        expect(page).to have_content "Your plan will be upgraded from Economy to Premium"
        expect(page).to have_content "Plan changes are immediate"
        expect(page).to have_content "Your credit card will be charged for $24.50 immediately" # $24.108989197530864, but rounded to $24.50
      end
    end

    it_has_behavior_of "Handling bad subscription upgrade requests" do
      background { visit upgrade_subscription_path plan_id: requested_plan_id }
    end
  end

  describe "Upgrade process" do
    describe "Upgrade is successful" do
      background do
        # stub Strpe
        customer     = double(:customer).as_null_object
        subscription = double(:subscription).as_null_object
        invoice      = double(:invoice, paid: true).as_null_object

        User.any_instance.stub on_stripe: customer
        customer.stub_chain(:subscriptions, :retrieve).and_return subscription
        Stripe::Invoice.stub create: invoice
      end

      scenario "Upgrading user subscription" do
        previous_subscription = subscription

        expect {
          visit billing_settings_path
          click_link "Upgrade"
          click_button "Change my plan"
        }.to change(user.subscriptions, :count).by(1)

        expect(current_path).to eql billing_settings_path
        expect(page).to have_notice(
          "Your subscription has been successfuly upgraded to plan Premium"
        )

        new_subscription = user.subscription
        uniq_attributes = %w[id plan_id created_at updated_at]

        expect(new_subscription.plan).to eql requested_plan
        expect(
          new_subscription.attributes.except(*uniq_attributes).map &:to_s
        ).to eql previous_subscription.attributes.except(*uniq_attributes).map(&:to_s)
      end

      scenario "Sending confirmation email" do
        expect {
          visit billing_settings_path
          click_link "Upgrade"
          click_button "Change my plan"
        }.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)

        expect(Sidekiq::Extensions::DelayedMailer.jobs.last["args"][0]).to include "UserMailer"
        expect(Sidekiq::Extensions::DelayedMailer.jobs.last["args"][0]).to include "upgrade_subscription_mail"
      end
    end

    it_has_behavior_of "Handling bad subscription upgrade requests" do
      background { upgrade_subscription }
    end
  end

  private
  def upgrade_subscription
    page.driver.submit :put,
                       subscription_path,
                       { subscription: { new_plan_id: requested_plan_id } }
  end
end
