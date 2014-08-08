require 'rails_helper'

module Stripeon
  RSpec.describe EventsHandlingWorker do
    subject(:worker) { EventsHandlingWorker.new }

    let(:events_to_process) { [double(:stripe_event)] }
    let(:handlers_map) do
      {
        'test.event'             => double(:test_event_handler),
        'test.event.cancelation' => double(:test_event_cancelation)
      }
    end

    describe "Handling rules" do
      subject { worker.send(:handlers_map).to_a }

      [
        ['charge.failed',                 HandlingTransactionCreation],
        ['charge.succeeded',              HandlingTransactionCreation],
        ['customer.subscription.deleted', HandlingSubscriptionExpiration]
      ].each do |(event, handler)|
        context "handles '#{event}' with '#{handler}'" do
          it { should include [event, handler] }
        end
      end
    end

    describe "Handling process" do
      before { worker.stub handlers_map: handlers_map }

      it "Selects unprocessed events in batches" do
        unprocessed_events = double :unprocessed_events
        Event.stub unprocessed: unprocessed_events

        expect(
          unprocessed_events
        ).to receive(:of_type).with(handlers_map.keys).and_return events_to_process
        expect(events_to_process).to receive :find_in_batches

        worker.perform
      end

      it "Sends events to event processing context" do
        events_handler = double :events_handler

        events_to_process.stub(:find_in_batches).and_yield(events_to_process)
        Event.stub_chain(:unprocessed, :of_type).and_return events_to_process

        expect(
          ProcessingStripeEvents
        ).to receive(:new).with(events_to_process, handlers_map).and_return events_handler
        expect(events_handler).to receive :perform

        worker.perform
      end
    end
  end
end
