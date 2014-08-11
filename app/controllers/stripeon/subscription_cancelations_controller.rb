module Stripeon
  class SubscriptionCancelationsController < BaseController
    before_filter :require_cancelable_subscription!

    def new
      @subscription = current_customer.subscription
    end
  end
end