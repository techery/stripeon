require 'rails_helper'

module Stripeon
  RSpec.describe Event, type: :model do
    it { should validate_presence_of :id_on_stripe }
    it { should validate_presence_of :type }
    it { should validate_presence_of :ip_address }

    it { should_not validate_presence_of :request_id }

    context "uniqueness validations" do
      before { FactoryGirl.create :stripeon_event }

      it { should validate_uniqueness_of :id_on_stripe }
      it { should_not validate_uniqueness_of :request_id }
    end

    describe ".unprocessed" do
      let!(:unprocessed_event) { create :stripeon_event }
      let!(:processed_event)   { create :stripeon_event, :processed }

      subject { Event.unprocessed }

      it { should_not include processed_event }
      it { should include  unprocessed_event }
    end

    describe ".of_type" do
      let!(:charge_failed_event)    { create :stripeon_event, type: 'charge.failed' }
      let!(:charge_succeeded_event) { create :stripeon_event, type: 'charge.succeeded' }
      let!(:charge_updated_event)   { create :stripeon_event, type: 'charge.updated' }
      let!(:charge_captured_event)  { create :stripeon_event, type: 'charge.captured' }
      let!(:charge_refunded_event)  { create :stripeon_event, type: 'charge.refunded' }
      let!(:irrelevant_event)       { create :stripeon_event, type: 'irrelevant' }

      subject { Event.of_type ['charge.failed', 'charge.succeeded'] }

      it { should include charge_succeeded_event }
      it { should include charge_failed_event }

      it { should_not include charge_refunded_event }
      it { should_not include charge_captured_event }
      it { should_not include charge_updated_event }
      it { should_not include irrelevant_event }
    end


    describe ".mark_processed!" do
      subject(:event) { FactoryGirl.create :stripeon_event }
      before { event.mark_processed! }

      it { should be_processed }
    end
  end
end
