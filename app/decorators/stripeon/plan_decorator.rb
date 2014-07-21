module Stripeon
  class PlanDecorator < Draper::Decorator
    delegate_all

    def price_in_dollars
      price.to_f / 100
    end
  end
end
