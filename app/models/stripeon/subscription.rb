module Stripeon
  class Subscription < ActiveRecord::Base
    attr_accessor :event_source

    belongs_to :customer, class_name: Stripeon.config.customer_model
    belongs_to :plan, counter_cache: true
    has_many   :invoices
    has_many   :subscription_status_transitions

    validates :plan, :customer, :status, presence: true

    delegate :price, to: :plan, allow_nil: true

    state_machine :status, initial: :active do
      store_audit_trail context_to_log: :event_source

      event(:cancel)  { transition active: :canceled }
      event(:upgrade) { transition active: :upgraded }
      event(:expire) do
        transition active: :expired
        transition canceled: :expired
        transition upgraded: :expired
      end

      before_transition on: :cancel, do: :cancel_on_stripe
    end

    scope :active, -> {
      where(
        "(status = 'active') OR (status = 'canceled' AND current_period_end_at > ?)",
        Time.now
      )
    }

    scope :order_by_creation, -> { order created_at: :asc }

    def current_period_duration
      return nil if current_period_start_at.nil? || current_period_end_at.nil?

      current_period_end_at - current_period_start_at
    end

    def remaining_in_current_period
      return nil if current_period_start_at.nil? || current_period_end_at.nil?

      current_period_end_at - Time.now
    end

    def upgrade_cost(new_plan)
      return 0 if new_plan.price < price

      (
        (new_plan.decorate.price - plan.decorate.price).to_f *
        (remaining_in_current_period / current_period_duration)
      ).ceil
    end

    def cancel_on_stripe
      unless id_on_stripe.nil?
        customer.on_stripe.subscriptions.retrieve(id_on_stripe).delete at_period_end: true
      end

      true
    rescue => e
      Rails.logger.error "Can't cancel subscription on Stripe: '#{e.message}'"
      return false
    end
  end
end
