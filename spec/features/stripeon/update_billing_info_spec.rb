require 'rails_helper'

feature 'Update billing info', %{
  As a Speaker with active subscription
  I can update my billing info
} do

  given(:user) { create :user }

  background do
    login_as user, scope: :user
    visit stripeon.billing_settings_path
  end

  context "User without subscription" do
    background { User.any_instance.stub subscribed?: false }

    scenario "Attempting to update billing info" do
      visit stripeon.new_credit_card_path

      expect(page).to have_error("You don't have an active subscription")
      expect(current_path).to eql stripeon.plans_path
    end
  end

  context "User with subscription", js: true do
    given(:user)          { create :user, :with_credit_card }
    given!(:subscription) { create :stripeon_subscription, customer: user }

    background { User.any_instance.stub subscribed?: true }

    context "User with not renewable (canceled) subscription" do
      let!(:subscription) { create :stripeon_subscription, :canceled, customer: user }

      scenario "Viewing billing setting page" do
        visit stripeon.billing_settings_path

        expect(page).not_to have_link "Update Billing Info"
      end

      scenario "Attempting to update billing info" do
        visit stripeon.new_credit_card_path

        expect(page).to have_error(
          "You should have active recurring subscription to perform this action"
        )
        expect(current_path).to eql stripeon.billing_settings_path
      end
    end

    context "User with renewable (not canceled) subscription" do
      scenario "Viewing billing setting page" do
        visit stripeon.billing_settings_path

        expect(page).to have_link "Update Billing Info"
      end

      describe "Correct page title" do
        background do
          visit stripeon.billing_settings_path
          click_link 'Update Billing Info'
        end

        subject { page }
        it { should have_title "Stripeon | Update billing information" }
      end

      describe "Successful update of billing information" do
        given(:user) { create :user, :on_stripe, :with_active_subscription, :with_credit_card }

        scenario "Updating billing info successfully" do
          expect {
            update_billing_info number: '5555555555554444', cvc: 321, year: 2020

            expect(page).to have_notice("Your credit card information has been updated")
          }.to change(user.credit_cards, :count).by(1)
        end
      end

      describe "Fail to update billing info" do
        context "Because user is not registered on Stripe" do
          scenario "See error asking to try later" do
            expect {
              update_billing_info

              expect(page).to have_error("Failed to update credit card information. Please try later.")
            }.not_to change(user.credit_cards, :count)
          end
        end

        context "Because of Stripe communication error" do
          scenario "See error asking to try later" do
            # TODO: replace with context when done
            User.any_instance.stub(:on_stripe) { raise "Some communication error" }
            expect {
              update_billing_info

              expect(page).to have_error "Failed to update credit card information. Please try later."
              expect(current_path).to eql billing_settings_path
            }.not_to change(user.credit_cards, :count)
          end
        end

        context "Because of not valid credit card" do
          scenario "See error about invalid credit card number" do
            expect {
              update_billing_info number: '12345'

              expect(page).to have_error "This card number looks invalid"
            }.not_to change(user.credit_cards, :count)
          end

          scenario "See error about credit card number not passing Luhn's check" do
            expect {
              update_billing_info number: '4242424242424241'

              expect(page).to have_error "Your card number is incorrect"
            }.not_to change(user.credit_cards, :count)
          end

          scenario "See error about not valid cvv/cvc code" do
            expect {
              update_billing_info cvc: '12'

              expect(page).to have_error "Your card's security code is invalid"
            }.not_to change(user.credit_cards, :count)
          end

          # Test if card validation fails on server side here
          #
          # scenario "Attempting to update billing info" do
          #   error = "Card error details"

          #   update_billing_info

          #   expect(current_path).to eql #billing_path
          #   expect(
          #     page.find '.alert-error'
          #   ).to have_content("Failed to update credit card information: #{error}")
          # end
        end
      end
    end
  end

  private
  def update_billing_info(card_options = {})
    visit stripeon.billing_settings_path
    click_link 'Update Billing Info'

    fill_in_credit_card card_options
    click_button 'Update Credit Card'
  end
end
