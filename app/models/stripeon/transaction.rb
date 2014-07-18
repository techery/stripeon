module Stripeon
  class Transaction < ActiveRecord::Base
    self.inheritance_column = nil

    belongs_to :credit_card
    has_one :customer, through: :credit_card

    validates :credit_card, :type, presence: true
    validates :successful, inclusion: [true, false]
    validates :id_on_stripe, presence: true, uniqueness: true
    validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
