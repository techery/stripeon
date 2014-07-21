module Stripeon
  class TransactionDecorator < Draper::Decorator
    delegate_all

    def amount_in_dollars
      amount.to_f / 100
    end

    def status_humanized
      successful ? 'Paid' : 'Declined'
    end
  end
end
