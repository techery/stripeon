module Stripeon
  class SubscriptionDecorator < Draper::Decorator
    delegate_all

    # http://stackoverflow.com/questions/3837182/a-better-ruby-implementation-of-round-decimal-to-nearest-0-5
    def upgrade_cost_in_dollars(new_plan)
      in_dollars = upgrade_cost(new_plan) / 100.0

      (in_dollars * 2).ceil / 2.0
    end
  end
end
