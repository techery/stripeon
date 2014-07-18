module Stripeon
  class HandlingSubscriptionRenewal
    include DCI::Context

    attr_reader :stripe_subscription

    def initialize(stripe_subscription)
      @stripe_subscription = stripe_subscription.extend Renewable
    end

    def perform
      in_context do
        stripe_subscription.renew_if_exists
      end
    end

    module Renewable
      def renew_if_exists
        if exists_locally?
          renew_local_subscription
          true
        else
          false
        end
      end

      def exists_locally?
        !!local_subscription
      end

      def renew_local_subscription
        local_subscription.update current_period_end_at: Time.at(current_period_end)
      end

      def local_subscription
        @local_subscription ||= Subscription.where(status: :active).find_by id_on_stripe: id
      end
    end
  end
end
