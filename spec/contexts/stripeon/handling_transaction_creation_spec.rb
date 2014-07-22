require 'rails_helper'

module Stripeon
  RSpec.describe HandlingTransactionCreation do
    let(:charge) { stripe_charge_object }

    context "When corresponding card was found in DB" do
      let!(:card) { create :stripeon_credit_card, id_on_stripe: charge.card.id }

      it "creates transaction linked to card" do
        expect { handle_transaction }.to change(card.transactions, :count).by(1)

        created_transaction = card.transactions.last

        expect(created_transaction.id_on_stripe).to eql charge.id
        expect(created_transaction.amount).to eql charge.amount
      end

      it "returns created transaction" do
        created_transaction = handle_transaction

        expect(created_transaction).to be_persisted
        expect(created_transaction.id_on_stripe).to eql charge.id
      end
    end

    context "When corresponding card was now found in DB" do
      it "doesn't create any transaction record" do
        expect { handle_transaction }.not_to change(Transaction, :count)
      end

      it "returns false" do
        expect(handle_transaction).to be false
      end
    end

    private
    def handle_transaction
      HandlingTransactionCreation.new(charge).perform
    end

    def stripe_charge_object
      charge_json = <<-charge
        {
          "id": "ch_00000000000000",
          "object": "charge",
          "created": 1391440219,
          "livemode": false,
          "paid": true,
          "amount": 2500,
          "currency": "usd",
          "refunded": false,
          "card": {
            "id": "card_00000000000000",
            "object": "card",
            "last4": "0341",
            "type": "Visa",
            "exp_month": 12,
            "exp_year": 2017,
            "fingerprint": "hURwqEfVYnXGnhW2",
            "customer": "cus_00000000000000",
            "country": "US",
            "name": null,
            "address_line1": null,
            "address_line2": null,
            "address_city": null,
            "address_state": null,
            "address_zip": null,
            "address_country": null,
            "cvc_check": "pass",
            "address_line1_check": null,
            "address_zip_check": null
          }
        }
      charge

      Stripe::Util.convert_to_stripe_object JSON.parse(charge_json).symbolize_keys, Stripe.api_key
    end
  end
end
