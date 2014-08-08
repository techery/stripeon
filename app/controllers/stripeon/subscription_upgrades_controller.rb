module Stripeon
  class SubscriptionUpgradesController < BaseController
    before_filter :find_plan
    before_filter :require_upgradable_subscription!

    def new
      @subscription = current_customer.subscription
      @current_plan = @subscription.plan.decorate
      @new_plan = @plan

      content_for :page_title, I18n.t('page_titles.stripeon.upgrade_to_plan', plan: @new_plan.name)

      unless @current_plan.upgradable_to? @new_plan
        flash[:error] = I18n.t 'errors.subscription.is_not_upgradeable_to_plan', plan: @new_plan.name
        redirect_to :billing_settings and return
      end

      @estimated_upgrade_cost = @subscription.decorate.upgrade_cost_in_dollars(@new_plan)
    end
  end
end
