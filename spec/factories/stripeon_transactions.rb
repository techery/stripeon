FactoryGirl.define do
  factory :stripeon_transaction, class: 'Stripeon::Transaction' do
    id_on_stripe { "ch_#{SecureRandom.hex(8)}" }
    amount       { rand(100) * 100 }
    type         'charge'
    successful   true

    association :credit_card, factory: :stripeon_credit_card

    trait :failed do
      successful false
    end
  end
end
