require 'rails_helper'

feature "Billing history", %{
  As a Speaker
  I can view my billing history
} do

  given(:customer) { create :user, :with_payment_history }

  background do
    login_as_customer customer
    visit stripeon.payments_path
    @payments_table = page.find('table.payments')
  end


  describe "Correct page title" do
    subject { page }

    it { should have_title "Stripeon | Payment History" }
  end

  scenario 'Viewing billing history of user ordered by creation date' do
    payments_dates = @payments_table.find('tbody').all('tr').map{ |row| row.all('td')[0].text }
    transactions_ordered = customer.transactions.order(created_at: :desc)
    payments_dates_ordered = transactions_ordered.map{ |t| t.created_at.strftime("%B %d, %Y") }

    expect(payments_dates).to eq payments_dates_ordered
  end
end
