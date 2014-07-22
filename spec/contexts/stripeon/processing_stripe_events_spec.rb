require 'rails_helper'

module Stripeon
  RSpec.describe ProcessingStripeEvents do
    let(:event) { create :stripeon_event }
    let(:handler) { double(:handler) }

    let(:handlers) { { event.type => handler } }

    context "When handler of event is not known" do
      let(:handlers) { { 'other_event_type' => handler } }

      it "ignores event" do
        expect(
          Rails.logger
        ).to receive(:error).with("Don't know how to handle Stripeon::Event (id=#{event.id}; handlers=#{handlers.to_s})")
        expect(handler).not_to receive :process

        process_event
      end
    end

    context "When event has not been found on Stripe" do
      context "because of any general error" do
        it "leaves event not processed" do
          Stripe::Event.stub(:retrieve) { raise "General error" }
          expect(handler).not_to receive :process

          process_event
          expect(event).not_to be_processed
        end
      end

      context "because of 404 error" do
        before do
          Stripe::Event.stub(:retrieve) { raise Stripe::InvalidRequestError.new("Not Found!", {}, 404) }
        end

        it "logs error and skips processing of event" do
          expect(
            Rails.logger
          ).to receive(:error).with("Ignoring Event which wasn't found on Stripe (id=#{event.id})")

          expect(handler).not_to receive :process

          process_event
          expect(event).to be_processed
        end
      end
    end

    context "When event has been found on Stripe" do
      before { Stripe::Event.stub retrieve: double(:event_on_stripe).as_null_object }

      describe "Successful processing" do
        it "updates status of event to processed" do
          handler.stub process: true

          process_event
          expect(event).to be_processed
        end
      end

      describe "Failed processing" do
        it "leaves event unprocessed" do
          handler.stub process: false

          process_event
          expect(event).not_to be_processed
        end
      end
    end

    describe "Performing processing" do
      let(:event_on_stripe)  { double :event_on_stripe }
      let(:handler_instance) { double :handler_instance }
      let(:stripe_object)    { double :stripe_object }

      before do
        event_on_stripe.stub_chain(:data, :object).and_return stripe_object
        handler.stub(:new).with(stripe_object).and_return(handler_instance)
        Stripe::Event.stub retrieve: event_on_stripe
      end

      it "instantiates handler and executes perform successfully" do
        expect(handler_instance).to receive(:perform).and_return(true)

        process_event
        expect(event).to be_processed
      end

      it "leaves event unprocessed if handler failed" do
        handler_instance.stub(:perform) { raise "Handler failed" }

        process_event
        expect(event).not_to be_processed
      end
    end

    private
    def process_event
      ProcessingStripeEvents.new([event], handlers).perform
    end
  end
end