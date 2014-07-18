require 'rails_helper'

module Stripeon
  RSpec.describe Subscription, type: :model do
    let(:subscription) { build :stripeon_subscription }

    it { should belong_to :customer }
    it { should belong_to :plan }
    it { should have_many :subscription_status_transitions }

    it { should validate_presence_of :customer }
    it { should validate_presence_of :plan }
    it { should validate_presence_of :status }

    describe ".active" do
      let!(:upgraded) { create :stripeon_subscription, :upgraded }
      let!(:expired)  { create :stripeon_subscription, :expired }

      let!(:active_not_ended) { create :stripeon_subscription }
      let!(:active_ended)     { create :stripeon_subscription, :ended }

      let!(:canceled_not_ended) { create :stripeon_subscription, :canceled }
      let!(:canceled_ended)     { create :stripeon_subscription, :canceled, :ended }

      subject { Subscription.active }

      it { should include active_not_ended }
      it { should include active_ended }
      it { should include canceled_not_ended }
      it { should_not include canceled_ended }
      it { should_not include expired }
      it { should_not include upgraded }
    end

    describe ".order_by_creation" do
      let!(:oldest) { create :stripeon_subscription, created_at: 1.month.ago }
      let!(:older)  { create :stripeon_subscription, created_at: 1.week.ago }
      let!(:newest) { create :stripeon_subscription }

      subject { Subscription.order_by_creation.to_a }

      it { should eql [oldest, older, newest] }
    end

    describe "#price" do
      it "is delegated to plan" do
        subscription.stub plan: double(:plan)

        expect(subscription.plan).to receive :price
        subscription.price
      end
    end

    describe "#current_period_duration" do
      subject { subscription.current_period_duration }

      context "when current_period_start_at is nil" do
        before { subscription.stub current_period_start_at: nil }
        it { should be_nil }
      end

      context "when current_period_end_at is nil" do
        before { subscription.stub current_period_end_at: nil }
        it { should be_nil }
      end

      context "when current_period_start_at and current_period_end_at are not nil" do
        let(:period_start) { double :current_period_start_at }
        let(:period_end)   { double :current_period_end_at }

        let(:period_duration) { double :period_duration }

        before do
          subscription.stub current_period_start_at: period_start
          subscription.stub current_period_end_at:   period_end

          period_end.stub(:-).with(period_start).and_return period_duration
        end

        it { should eql period_duration }
      end
    end

    describe "#remaining_in_current_period" do
      subject { subscription.remaining_in_current_period }

      context "when current_period_start_at is nil" do
        before { subscription.stub current_period_start_at: nil }
        it { should be_nil }
      end

      context "when current_period_end_at is nil" do
        before { subscription.stub current_period_end_at: nil }
        it { should be_nil }
      end

      context "when current_period_start_at and current_period_end_at are not nil" do
        let(:current_time) { Time.at 42 }
        let(:period_start) { double :current_period_start_at }
        let(:period_end)   { double :current_period_end_at }

        let(:time_to_period_end) { double :time_to_period_end }

        before do
          Time.stub now: current_time
          subscription.stub current_period_start_at: period_start
          subscription.stub current_period_end_at:   period_end

          period_end.stub(:-).with(current_time).and_return time_to_period_end
        end

        it { should eql time_to_period_end }
      end
    end

    describe "status transitions" do
      describe "to :canceled" do
        context "when id_on_stripe is not empty" do
          let(:subscription) { create :stripeon_subscription, :with_stripe_id }
          let!(:customer) { subscription.customer }

          context "and it correct" do
            it "returns true and change state" do
              stripe_subscription = double :stripe_subscription
              customer.stub_chain(:on_stripe, :subscriptions, :retrieve).and_return stripe_subscription
              expect(stripe_subscription).to receive(:delete).with(at_period_end: true).and_return(true)

              expect(subscription.cancel).to be true
              expect(subscription).to be_canceled
            end
          end

          context "and it incorrect/expired" do
            it "returns false and do not change state" do
              customer.stub_chain(:on_stripe, :subscriptions, :retrieve, :delete) do
                raise "Stripe exception"
              end

              expect(subscription.cancel).to be false
              expect(subscription).not_to be_canceled
            end
          end
        end

        context "when id_on_stripe is empty" do
          subject { create :stripeon_subscription }
          before { subject.cancel }

          it { should be_canceled }
        end
      end

      it "should be initialized with status :active by default" do
        expect(Subscription.new).to be_active
      end

      context "from :active" do
        subject(:subscription) { create :stripeon_subscription }

        it "can be canceled and logs transition" do
          expect(subscription.cancel).to be true
          expect(subscription).to be_canceled
        end

        it "can be expired and logs transition" do
          expect(subscription.expire).to be true
          expect(subscription).to be_expired
        end

        it "can be upgraded and logs transition" do
          expect(subscription.upgrade).to be true
          expect(subscription).to be_upgraded
        end
      end

      context "from :canceled" do
        subject(:subscription) { create :stripeon_subscription, :canceled }

        it "can not be canceled again" do
          expect(subscription.cancel).to be false
          expect(subscription).to be_canceled
        end

        it "can be expired" do
          expect(subscription.expire).to be true
          expect(subscription).to be_expired
        end

        it "can not be upgraded" do
          expect(subscription.upgrade).to be false
          expect(subscription).to be_canceled
        end
      end

      context "from :expired" do
        subject(:subscription) { create :stripeon_subscription, :expired }

        it "can not be canceled" do
          expect(subscription.cancel).to be false
          expect(subscription).to be_expired
        end

        it "can not be expired again" do
          expect(subscription.expire).to be false
          expect(subscription).to be_expired
        end

        it "can not be upgraded" do
          expect(subscription.upgrade).to be false
          expect(subscription).to be_expired
        end
      end

      context "from :upgraded" do
        subject(:subscription) { create :stripeon_subscription, :upgraded }

        it "can not be canceled" do
          expect(subscription.cancel).to be false
          expect(subscription).to be_upgraded
        end

        it "can be expired" do
          expect(subscription.expire).to be true
          expect(subscription).to be_expired
        end

        it "can not be upgraded again" do
          expect(subscription.upgrade).to be false
          expect(subscription).to be_upgraded
        end
      end
    end

    describe "#upgrade_cost(plan)" do
      let(:plan) { create :stripeon_plan, price: 5000 }
      let(:subscription) { create :stripeon_subscription, plan: plan }

      context "new plan price is bigger than current" do
        let(:new_plan) { create :stripeon_plan, price: 10000 }
        subject { subscription.upgrade_cost new_plan }

        it { should eql 5000 }
      end

      context "new plan price is lower than current" do
        let(:new_plan) { create :stripeon_plan, price: 1000 }
        subject { subscription.upgrade_cost new_plan }

        it { should be_zero }
      end
    end
  end
end
