FactoryGirl.define do
  factory :user do
    email    { Faker::Internet.email }
    password { "Password@123" }

    trait :on_stripe do
      before(:create) do |user|
        customer = Stripe::Customer.create email: user.email

        user.id_on_stripe = customer.id
      end
    end

    trait :with_active_subscription do
      after(:create) { |user| FactoryGirl.create :stripeon_subscription, customer: user }
    end

    trait :with_credit_card do
      after(:create) { |user| FactoryGirl.create :stripeon_credit_card,  customer: user }
    end

    trait :with_payment_history do
      after(:create) do |user|
        credit_card = FactoryGirl.create :stripeon_credit_card, customer: user
        3.times do
          FactoryGirl.create :stripeon_transaction, credit_card: credit_card
          FactoryGirl.create :stripeon_transaction, :failed, credit_card: credit_card
        end
      end
    end
  end
end
