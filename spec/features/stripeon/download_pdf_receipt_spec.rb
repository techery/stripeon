require 'rails_helper'

feature "Transaction receipt", %{
  As a Speaker
  I can download PDF transaction receipt
} do

  given!(:user)       { create :user, :with_payment_history }
  given!(:other_user) { create :user, :with_payment_history }

  background do
    login_as_customer user
    visit stripeon.payments_path
    @payments_table = page.find('table.payments')
  end

  describe "Download receipt link is present" do
    context "For paid transactions" do
      scenario "Present" do
        transaction_ids = user.transactions.where(successful: true).order(created_at: :desc).map &:id
        transaction_ids.each do |id|
          expect(
            @payments_table
          ).to have_link "Download Receipt", href: stripeon.payment_path(id, format: :pdf)
        end
      end
    end

    context "For declined transactions" do
      scenario "Is not present" do
        transaction_ids = user.transactions.where(successful: false).order(created_at: :desc).map &:id
        transaction_ids.each do |id|
          expect(
            @payments_table
          ).not_to have_link "Download Receipt", href: stripeon.payment_path(id, format: :pdf)
        end
      end
    end
  end

  describe "Download only myself receipts" do
    context "Myself receipt" do
      context "Transaction is successful" do
        scenario "It downloads" do
          visit stripeon.payment_path(user.transactions.where(successful: true).last.id, format: :pdf)
          expect(page.status_code).to eql 200
          expect(page.response_headers['Content-Type']).to eql "application/pdf"
        end
      end

      context "Transaction failed" do
        scenario "It return fobidden error" do
          visit stripeon.payment_path(user.transactions.where(successful: false).last.id, format: :pdf)
          expect(page.status_code).to eql 403
          expect(page.response_headers['Content-Type']).not_to eql "application/pdf"
        end
      end
    end

    context "Other user receipt" do
      context "Transaction is successful" do
        scenario "It return fobidden error" do
          visit stripeon.payment_path(other_user.transactions.where(successful: true).last.id, format: :pdf)
          expect(page.status_code).to eql 403
          expect(page.response_headers['Content-Type']).not_to eql "application/pdf"
        end
      end

      context "Transaction failed" do
        scenario "It return fobidden error" do
          visit stripeon.payment_path(other_user.transactions.where(successful: false).last.id, format: :pdf)
          expect(page.status_code).to eql 403
          expect(page.response_headers['Content-Type']).not_to eql "application/pdf"
        end
      end
    end
  end
end
