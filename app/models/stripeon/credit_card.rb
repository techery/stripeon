module Stripeon
  class CreditCard < ActiveRecord::Base
    self.inheritance_column = nil

    belongs_to :customer, class_name: Stripeon.config.customer_model
    has_many :transactions

    validates :id_on_stripe, presence: true
    validates :last4,        presence: true
    validates :exp_month,    presence: true
    validates :exp_year,     presence: true
    validates :type,         presence: true

    scope :order_by_creation, -> { order created_at: :asc }
  end
end
