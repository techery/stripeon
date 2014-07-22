module Stripeon
  class SubscriptionCancelationsController < BaseController
    before_filter :require_cancelable_subscription!

    def new
      @subscription = current_user.subscription
    end
  end
end