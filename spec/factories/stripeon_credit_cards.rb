FactoryGirl.define do
  card_types = ['Visa', 'American Express', 'MasterCard', 'Discover', 'JCB', 'Diners Club', 'Unknown']

  factory :stripeon_credit_card, class: 'Stripeon::CreditCard' do
    last4        { ('0000'..'9999').to_a.sample }
    exp_month    { (1..12).to_a.sample }
    exp_year     { (Date.today.year.next..(Date.today.year + 20)).to_a.sample }
    type         { card_types.sample }

    id_on_stripe { "card_#{SecureRandom.hex(8)}" }

    association :customer, factory: :user
  end
end
