FactoryGirl.define do
  factory :stripeon_event, class: 'Stripeon::Event' do
    type         { 'test.event' }
    ip_address   { Faker::Internet.ip_v4_address }
    id_on_stripe { "evt_test_#{SecureRandom.hex(8)}" }
    request_id   { "iar_test_#{SecureRandom.hex(8)}" }

    processed false

    trait :processed do
      processed true
    end
  end
end
