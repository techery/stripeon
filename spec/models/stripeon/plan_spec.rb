require 'rails_helper'

module Stripeon
  RSpec.describe Plan, type: :model do
    let(:plan) { build :stripeon_plan }

    it { should have_many :subscriptions }

    describe 'validations' do
      # No need to call Stripe for validations
      before { Plan.any_instance.stub create_on_stripe: true }

      it { should validate_presence_of   :name }
      it { should validate_uniqueness_of :name }

      it { should validate_presence_of :price }
      it { should validate_numericality_of(:price).is_greater_than 0 }

      it { should_not validate_presence_of(:id_on_stripe).on(:create) }
      it { should allow_value("", nil).for(:id_on_stripe).on(:create) }
      it { should validate_presence_of(:id_on_stripe).on(:update) }
      it { should validate_uniqueness_of :id_on_stripe }
    end

    describe "sort" do
      let!(:plan_25) { create :stripeon_plan, price: 2500 } # $25
      let!(:plan_10) { create :stripeon_plan, price: 1000 } # $10
      let!(:plan_50) { create :stripeon_plan, price: 5000 } # $50

      context "ascending" do
        subject(:plans) { Plan.ascending }

        it { expect(plans.index plan_50).to be > plans.index(plan_25) }
        it { expect(plans.index plan_25).to be > plans.index(plan_10) }
      end

      context "descending" do
        subject(:plans) { Plan.descending }

        it { expect(plans.index plan_10).to be > plans.index(plan_25) }
        it { expect(plans.index plan_25).to be > plans.index(plan_50) }
      end
    end

    describe "#upgradable_to?" do
      subject(:plan) { build :stripeon_plan, price: 2500 }

      let(:smaller) { build :stripeon_plan, price: 1000 }
      let(:larger)  { build :stripeon_plan, price: 5000 }

      it { should be_upgradable_to larger }
      it { should_not be_upgradable_to smaller }
      it { should_not be_upgradable_to plan }
    end

    describe "#destroy" do
      let!(:plan) { create :stripeon_plan }

      context "when there are subscribers to this plan" do
        it "is forbidden" do
          create :stripeon_subscription, plan: plan

          expect { plan.destroy }.not_to change(Plan, :count)
          expect(plan).to be_persisted
        end
      end

      context "when plan is clean and not used" do
        it 'is allowed' do
          expect { plan.destroy }.to change(Plan, :count).by(-1)
        end
      end
    end

    describe ".active" do
      let!(:inactive_plan) { create :stripeon_plan, :inactive }

      before do
        3.times { create :stripeon_plan }
      end

      subject(:plans) { Plan.active }

      it { should_not include(inactive_plan) }
      it { expect(plans.count).to eql 3 }
    end

    describe "default_scope" do
      let!(:inactive_plan) { create :stripeon_plan, :inactive }

      before do
        3.times { create :stripeon_plan }
      end

      subject(:plans) { Plan.all }

      it { should_not include(inactive_plan) }
      it { expect(plans.count).to eql 3 }
    end

    describe "on create" do
      context "when id_on_stripe is not set" do
        it "creates plan on Stripe" do
          current_timestamp = Time.now.to_i
          plane_name = "Economy #{current_timestamp}"
          plan = build :stripeon_plan, :with_stripe_call, name: plane_name

          expect(Stripe::Plan).to(
            receive(:create).once.with(
              id:       plan.name.parameterize.underscore,
              name:     plan.name,
              amount:   plan.price,
              currency: 'usd',
              interval: 'month'
            )
          )

          plan.save

          expect(plan.id_on_stripe).to eql "economy_#{current_timestamp}"
        end

        it "shows proper error in case of exception" do
          Stripe::Plan.stub(:create) { raise "Stripe error reason" }
          plan = build :stripeon_plan, :with_stripe_call

          expect{ plan.save }.not_to change(Plan, :count)

          expect(
            plan.errors[:base]
          ).to include('Failed to create plan on Stripe: "Stripe error reason"')
        end
      end

      context "when id_on_stripe is provided manually" do
        it "doesn't send request to Stripe API" do
          expect(Stripe::Plan).not_to receive(:create)

          create :stripeon_plan
        end
      end
    end

    describe "on update" do
      let!(:plan) { create :stripeon_plan }

      context "name not changed" do
        it "doesn't send request to Stripe API" do
          expect(Stripe::Plan).not_to receive(:retrieve)

          plan.update active: !plan.active
        end
      end

      context "name changed" do
        context "when plan is found on Stripe" do
          it "updates plan on Stripe" do
            stripe_plan = double :stripe_plan

            expect(
              Stripe::Plan
            ).to receive(:retrieve).with(plan.id_on_stripe).and_return(stripe_plan)

            expect(stripe_plan).to receive(:name=).with("Other name")
            expect(stripe_plan).to receive(:save)

            plan.update name: "Other name"
          end
        end

        context "when plan not found on Stripe" do
          it "it updates" do
            Stripe::Plan.stub(:retrieve) { raise "Stripe error reason" }

            plan.update name: "Other name"

            expect(plan.reload.name).to eql "Other name"
          end
        end

        context "when plan wasn't updated on Stripe" do
          it "shows proper error" do
            stripe_plan = double(:stripe_plan).as_null_object
            stripe_plan.stub(:save) { raise "Stripe error reason" }

            expect(
              Stripe::Plan
            ).to receive(:retrieve).with(plan.id_on_stripe).and_return(stripe_plan)

            current_name = plan.name

            plan.update name: "Other name"

            expect(
              plan.errors[:base]
            ).to include('Failed to update plan on Stripe: "Stripe error reason"')
            expect(plan.reload.name).to eql current_name
          end
        end
      end
    end

    describe "#destroy" do
      let!(:plan) { create :stripeon_plan }

      context "when there are subscribers to this plan" do
        it "is forbidden" do
          create :stripeon_subscription, plan: plan

          expect { plan.destroy }.not_to change(Plan, :count)
        end
      end

      context "when there are no subscribers to this plan" do
        it "deletes plan from Stripe" do
          stripe_plan = double :stripe_plan

          expect(
            Stripe::Plan
          ).to receive(:retrieve).with(plan.id_on_stripe).and_return(stripe_plan)

          expect(stripe_plan).to receive(:delete)

          expect {
            plan.destroy
          }.to change(Plan, :count).by(-1)
        end

        it "ignores Stripe exceptions" do
          stripe_plan = double :stripe_plan

          Stripe::Plan.stub(:retrieve) { raise "Stripe error reason" }

          expect {
            plan.destroy
          }.to change(Plan, :count).by(-1)
        end
      end
    end
  end
end
