FactoryGirl.define do
  factory :stripeon_plan, class: 'Stripeon::Plan' do
    sequence(:price) { |n| 1000 * n  }

    name         { |p| "Plan #{p.price} #{Time.now.to_i}" }
    id_on_stripe { |p| "#{p.name.underscore}_fake" }

    active true

    trait(:inactive) { active false }
    trait(:with_stripe_call) { id_on_stripe nil }
  end
end
