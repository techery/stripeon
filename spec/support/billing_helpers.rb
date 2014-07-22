module BillingHelpers
  def fill_in_credit_card(number: '4242424242424242',
                          cvc:   '123',
                          month: '12',
                          year:  Date.today.year + 3)

    fill_in 'Credit card number', with: number
    fill_in 'Security Code',      with: cvc
    find("#expiry-month").select month
    find("#expiry-year" ).select year.to_s
  end

  def pay_now_with_card(card_options = {}, price = 25)
    fill_in_credit_card card_options
    click_button "Subscribe Now for $#{price}"
  end
end

RSpec.configure do |c|
  c.include BillingHelpers, :type => :feature
end
