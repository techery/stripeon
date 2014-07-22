module Stripeon
  class HandlingTransactionCreation
    include DCI::Context

    attr_reader :charge

    def initialize(charge)
      @charge = charge.extend Recordable
    end

    def perform
      in_context do
        charge.record_transaction_if_card_exists
      end
    end

    module Recordable
      def record_transaction_if_card_exists
        if card_exists?
          record_transaction
        else
          false
        end
      end

      def card_exists?
        !!local_credit_card
      end

      def local_credit_card
        @local_credit_card ||= CreditCard.find_by id_on_stripe: self.card.id
      end

      def record_transaction
        local_credit_card.transactions.create(
          type:         'charge',
          amount:       self.amount,
          successful:   self.paid,
          id_on_stripe: self.id
        )
      end
    end
  end
end