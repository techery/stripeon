module Stripeon
  class Webhooks::StripeEventsController < ApplicationController

    skip_before_filter :authenticate_user!

    protect_from_forgery with: :null_session

    def create
      payload    = request.body.read
      event_json = JSON.parse payload

      event = StripeEvent.create(
        id_on_stripe: event_json['id'],
        type:         event_json['type'],
        ip_address:   request.remote_ip,
        request_id:   event_json['request'],

        payload:  payload,
        fired_at: Time.at(event_json['created'].to_i)
      )

      EventsHandlingWorker.perform_async if event.persisted?

      render text: 42, status: :ok
    end
  end
end