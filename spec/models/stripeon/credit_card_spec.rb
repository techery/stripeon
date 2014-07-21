require 'rails_helper'

module Stripeon
  RSpec.describe CreditCard, type: :model do
    it { should belong_to :customer }

    it { should have_many :transactions }

    it { should validate_presence_of :id_on_stripe }
    it { should validate_presence_of :last4        }
    it { should validate_presence_of :exp_month    }
    it { should validate_presence_of :exp_year     }
    it { should validate_presence_of :type         }

    describe ".order_by_creation" do
      let!(:oldest) { create :stripeon_credit_card, created_at: 1.month.ago }
      let!(:older)  { create :stripeon_credit_card, created_at: 1.week.ago }
      let!(:newest) { create :stripeon_credit_card }


      subject { CreditCard.order_by_creation.to_a }

      it { should eql [oldest, older, newest] }
    end
  end
end
