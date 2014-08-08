module Stripeon
  class EventsHandlingWorker
    include Sidekiq::Worker
    sidekiq_options queue: :events

    def perform
      Event.unprocessed.of_type(processible_event_types).find_in_batches do |events|
        ProcessingStripeEvents.new(events, handlers_map).perform
      end
    end

    private
    def handlers_map
      {
        'charge.failed'                 => HandlingTransactionCreation,
        'charge.succeeded'              => HandlingTransactionCreation,
        'customer.subscription.deleted' => HandlingSubscriptionExpiration,
        'customer.subscription.updated' => HandlingSubscriptionRenewal
      }
    end

    def processible_event_types
      handlers_map.keys
    end
  end
end
