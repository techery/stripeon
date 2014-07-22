module Stripeon
  class ProcessingStripeEvents
    include DCI::Context

    attr_reader :events_to_process
    attr_reader :handlers

    def initialize(events, handlers)
      @handlers = handlers.map { |event, handler| [event, handler.extend(Processor)] }.to_h
      @events_to_process = events.map { |event| event.extend Processable }
    end

    def perform
      in_context do
        events_to_process.each do |event|
          handler = handlers[event.type]

          unless handler.nil?
            event.process_with handler
          else
            Rails.logger.error "Don't know how to handle #{event.class.name} (id=#{event.id}; handlers=#{handlers.to_s})"
          end
        end
      end
    end

    module Processable
      def process_with(handler)
        handler.process(event_on_stripe) && mark_processed! if received_from_stripe?
      end

      def received_from_stripe?
        !!event_on_stripe
      end

      def event_on_stripe
        @event_on_stripe ||= Stripe::Event.retrieve(id_on_stripe)
      rescue => e
        if e.try(:http_status) == 404
          log_error_and_skip_processing "Ignoring Event which wasn't found on Stripe (id=#{self.id})"
        end

        nil
      end

      def log_error_and_skip_processing(error)
        Rails.logger.error error
        mark_processed!
      end
    end

    module Processor
      def process(stripe_event)
        self.new(stripe_event.data.object).perform
      rescue
        false
      end
    end
  end
end
