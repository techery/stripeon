FactoryGirl.define do
  factory :stripeon_subscription, class: 'Stripeon::Subscription' do
    current_period_start_at { Time.now }
    current_period_end_at   { current_period_start_at + 1.month }

    status 'active'

    trait(:canceled) { status 'canceled' }
    trait(:expired)  { status 'expired' }
    trait(:upgraded) { status 'upgraded' }

    trait(:ended) { current_period_end_at { Time.now - 1.minute } }

    association :customer, factory: :user
    association :plan,     factory: :stripeon_plan

    trait(:with_stripe_id) { id_on_stripe "sub_fake_#{Time.now.to_i}" }
  end
end
