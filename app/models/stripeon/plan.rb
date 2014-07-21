module Stripeon
  class Plan < ActiveRecord::Base
    has_many :subscriptions, dependent: :restrict_with_error

    validates :name,  presence: true, uniqueness: true
    validates :price, presence: true, numericality: { greater_than: 0 }

    validates :id_on_stripe, uniqueness: true, allow_blank: true
    validates :id_on_stripe, presence: true, on: :update

    scope :descending, -> { order price: :desc }
    scope :ascending,  -> { order price: :asc  }
    scope :active,     -> { where active: true }

    default_scope -> { active }

    before_create :create_on_stripe, unless: -> (p) { p.id_on_stripe.present? }
    before_update :update_on_stripe, if: -> (p) { p.name_changed? }
    after_destroy :delete_on_stripe

    def upgradable_to?(other)
      price < other.price
    end

    private
    def create_on_stripe
      self.id_on_stripe = name.parameterize.underscore
      Stripe::Plan.create(
        id:       id_on_stripe,
        name:     name,
        amount:   price,
        currency: 'usd',
        interval: 'month'
      )
    rescue => e
      errors.add :base, I18n.t("errors.models.plan.stripe.create", reason: e.message)
      return false
    end

    def update_on_stripe
      unless plan_on_stripe.nil?
        plan_on_stripe.name = name
        plan_on_stripe.save
      end
    rescue => e
      errors.add :base, I18n.t("errors.models.plan.stripe.update", reason: e.message)
      return false
    end

    def delete_on_stripe
      plan_on_stripe.delete unless plan_on_stripe.nil?
    rescue => e
      Rails.logger.error "Failed to delete plan on Stripe: '#{e.message}'"
    end

    def plan_on_stripe
      @plan_on_stripe ||= Stripe::Plan.retrieve id_on_stripe
    rescue => e
      Rails.logger.error "Plan on Stripe not found: '#{e.message}'"
      return nil
    end
  end
end
