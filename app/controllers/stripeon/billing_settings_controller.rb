module Stripeon
  class BillingSettingsController < BaseController
    before_filter :require_active_subscription!

    def show
      @credit_card = current_user.current_card
      @subscription = current_user.subscription
      @current_plan = @subscription.plan.decorate
    end
  end
end