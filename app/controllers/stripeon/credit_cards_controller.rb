module Stripeon
  class CreditCardsController < BaseController
    before_filter :require_active_subscription!
    before_filter :require_renewable_subscription!

    def new
      @credit_card = current_user.credit_cards.new
    end

    def create
      create_on_error and return if current_user.on_stripe.nil?

      # TODO: cover with acceptance test
      customer = current_user.on_stripe
      card = customer.cards.create card: params[:credit_card][:card_token]

      customer.default_card = card.id
      customer.save

      current_user.credit_cards.create(
        id_on_stripe: card.id,
        last4:        card.last4,
        exp_month:    card.exp_month,
        exp_year:     card.exp_year,
        type:         card.type
      )

      create_on_success and return
    rescue
      create_on_error and return
    end

    private
    def create_on_error
      redirect_to :billing_settings, alert: I18n.t('errors.credit_card.failed_to_update')
    end

    def create_on_success
      redirect_to :back, notice: I18n.t('messages.credit_card.has_been_updated')
    end
  end
end
