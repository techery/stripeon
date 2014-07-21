module Stripeon
  class SubscriptionStatusTransition < ActiveRecord::Base
    belongs_to :subscription
  end
end
