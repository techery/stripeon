require 'rails_helper'

module Stripeon
  RSpec.describe '/webhooks/stripe_events', type: :request do
    let(:url)   { '/stripeon/webhooks/stripe_events' }
    let(:event) { build :stripeon_event }

    let(:requester_ip) { Faker::Internet.ip_v4_address }

    let(:event_timestamp) { Time.now.to_i }
    let(:event_data) {
      {
        id:       event.id_on_stripe,
        type:     event.type,
        object:   'event',
        request:  event.request_id,
        created:  event_timestamp,
        data:     { lorem: Faker::Lorem.paragraph(5) }
      }
    }

    let(:dummy_worker) { double(:events_handling_worker).as_null_object }
    before { stub_const "Stripeon::EventsHandlingWorker", dummy_worker }

    describe 'POST' do
      context "when event is already registered" do
        before { event.save }

        it "ignores event" do
          expect { post_event }.not_to change(Event, :count)

          expect(response.status).to eql 200
          expect(response.body).to   eql '42'
        end

        it "doesn't launch event handling worker" do
          # This is a stupid hack to test that webhook doesn't start worker
          dummy_worker.stub(:perform_async) { raise "Unexpected perform_async called" }

          post_event

          expect(response.status).to eql 200
          expect(response.body).to   eql '42'
        end
      end

      context "when event not registered yet" do
        it "registers event" do
          expect { post_event }.to change(Event, :count).by(1)

          expect(response.status).to eql 200
          expect(response.body).to   eql '42'

          created_event = Stripeon::Event.find_by id_on_stripe: event.id_on_stripe

          expect(created_event.type).to          eql event.type
          expect(created_event.request_id).to    eql event.request_id
          expect(created_event.ip_address).to    eql requester_ip
          expect(created_event.fired_at.to_i).to eql event_timestamp

          expect(created_event.payload).to eql event_data.to_json
        end

        it "launches event handling worker" do
          expect(dummy_worker).to receive(:perform_async).once
          post_event
        end
      end
    end

    private
    def post_event
      post url, event_data.to_json, { 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => requester_ip }
    end
  end
end
