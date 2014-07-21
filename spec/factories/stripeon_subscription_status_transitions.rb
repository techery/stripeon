FactoryGirl.define do
  factory :stripeon_subscription_status_transition, class: 'Stripeon::SubscriptionStatusTransition' do
    event 'MyString'
    from  'MyString'
    to    'MyString'

    association :subscription, factory: :stripeon_subscription
  end
end
