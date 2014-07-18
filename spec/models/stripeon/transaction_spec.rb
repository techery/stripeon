require 'rails_helper'

module Stripeon
  RSpec.describe Transaction, type: :model do
    it { should belong_to :credit_card }
    it { should have_one :customer }

    it { should validate_presence_of :id_on_stripe }
    it { should validate_presence_of :type }
    it { should validate_presence_of :credit_card }
    it { should validate_presence_of :amount }

    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }

    it { should validate_uniqueness_of :id_on_stripe }

    # FIXME: https://github.com/thoughtbot/shoulda-matchers/issues/179
    it { should allow_value(true).for(:successful) }
    it { should allow_value(false).for(:successful) }
    it { should_not allow_value(nil).for(:successful) }
  end
end
