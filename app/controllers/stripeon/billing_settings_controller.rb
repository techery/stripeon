module Stripeon
  class BillingSettingsController < BaseController
    before_filter :require_active_subscription!

    def show
      @credit_card  = current_customer.current_card
      @subscription = current_customer.subscription
      @current_plan = @subscription.plan.decorate
    end
  end
end