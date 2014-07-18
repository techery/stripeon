module Stripeon
  class SubscriptionMailer < BaseMailer

    [:create_subscription_mail, :expire_subscription_mail].each do |mail_function|
      define_method "#{mail_function}" do |user_id, subscription_id|
        @subscription = Subscription.find subscription_id
        user = User.find user_id

        mail(to: user.email)
      end
    end

    def upgrade_subscription_mail(user_id, subscription_id, upgrade_cost_in_dollars)
      @upgrade_cost_in_dollars = upgrade_cost_in_dollars
      @subscription = Subscription.find subscription_id
      user = User.find user_id

      mail(to: user.email)
    end

  end
end
