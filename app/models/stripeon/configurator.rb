module Stripeon
  class Configurator
    cattr_accessor :customer_model
    cattr_accessor :current_customer

    def self.stripe_api_key=(api_key)
      Stripe.api_key = api_key
    end

    def self.stripe_api_key
      Stripe.api_key
    end
  end
end