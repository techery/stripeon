module Stripeon
  module Customer
    extend ActiveSupport::Concern

    included do
      has_many :subscriptions,
        class_name: 'Stripeon::Subscription',
        foreign_key: :customer_id
      has_many :credit_cards,
        class_name: 'Stripeon::CreditCard',
        foreign_key: :customer_id
      has_many :transactions,
        class_name: 'Stripeon::Transaction',
        through: :credit_cards

      validates :id_on_stripe, uniqueness: true, allow_blank: true
    end

    def subscription
      current_active_subscription
    end

    def subscribed?
      subscription.present?
    end

    def as_json(options = {})
      super options.merge(methods: [:subscription, :authentication_token])
    end

    def on_stripe
      @on_stripe ||= Stripe::Customer.retrieve id_on_stripe
    rescue => e
      Rails.logger.error "Customer on Stripe not found: '#{e.message}'"
      return nil
    end

    def current_card
      credit_cards.order_by_creation.last
    end

    private

    def current_active_subscription
      subscriptions.active.order_by_creation.last
    end
  end
end
