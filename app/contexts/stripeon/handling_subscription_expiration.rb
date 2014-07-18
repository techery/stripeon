module Stripeon
  class HandlingSubscriptionExpiration
    include DCI::Context

    attr_reader :stripe_subscription

    def initialize(stripe_subscription)
      @stripe_subscription = stripe_subscription.extend Expirable
    end

    def perform
      in_context do
        stripe_subscription.expire_locally_and_notify_owner_if_exists
      end
    end

    module Expirable
      def expire_locally_and_notify_owner_if_exists
        return false unless canceled_on_stripe?

        if exists_locally?
          if expire_local_subscriptions!
            notify_subscription_owner
            true
          else
            false
          end
        else
          any_expired_local_subscription?
        end
      end

      def notify_subscription_owner
        SubscriptionMailer.expire_subscription_mail(
          active_local_subscriptions.last.customer.id,
          active_local_subscriptions.last,
        ).deliver
      end

      def canceled_on_stripe?
        status == 'canceled'
      end

      def exists_locally?
        active_local_subscriptions.any?
      end

      def local_subscriptions
        @local_subscriptions ||= Subscription.where id_on_stripe: id
      end

      def active_local_subscriptions
        @active_local_subscriptions ||= local_subscriptions.active
      end

      def any_expired_local_subscription?
        local_subscriptions.where(status: :expired).any?
      end

      def expire_local_subscriptions!
        active_local_subscriptions.map(&:expire).all? { |s| s == true }
      end
    end
  end
end
