module Stripeon
  class SubscriptionsController < BaseController
    before_filter :prevent_duplicate_subscription!, except: [:destroy, :update]
    before_filter :require_active_subscription!, only: :destroy
    before_filter :require_cancelable_subscription!, only: :destroy
    before_filter :require_upgradable_subscription!, only: :update
    before_filter except: :destroy do |c|
      find_plan if c.action_name == 'new'
      find_plan(params[:subscription][:plan_id])     if c.action_name == 'create'
      find_plan(params[:subscription][:new_plan_id]) if c.action_name == 'update'
    end

    def new
      content_for :page_title, I18n.t('page_titles.subscribe_to_plan', plan: @plan.name)
      @subscription = Subscription.new plan: @plan
    end

    def destroy
      subscription = current_user.subscription

      if subscription.cancel
        flash[:notice] = I18n.t('messages.subscription.canceled')
      else
        flash[:error] = I18n.t('errors.subscription.failed_to_cancel')
      end

      redirect_to [stripeon, :billing_settings]
    end

    def create
      # Register customer & card on Stripe
      if current_user.on_stripe.nil?
        customer = Stripe::Customer.create(
          email: current_user.email,
          card:  params[:subscription][:card_token]
        )
        current_user.update id_on_stripe: customer.id
        card = customer.cards.first
      else
        # TODO: cover with acceptance test
        customer = current_user.on_stripe
        card = customer.cards.create card: params[:subscription][:card_token]

        # Change Default card to newly added one
        customer.default_card = card.id
        customer.save
      end

      credit_card = current_user.credit_cards.create(
        id_on_stripe: card.id,
        last4:        card.last4,
        exp_month:    card.exp_month,
        exp_year:     card.exp_year,
        type:         card.type
      )
      # / Register customer & card on Stripe

      # Create subscription
      stripe_subscription = customer.subscriptions.create plan: @plan.id_on_stripe

      subscription = current_user.subscriptions.create(
        id_on_stripe:            stripe_subscription.id,
        plan:                    @plan,
        current_period_end_at:   Time.at(stripe_subscription.current_period_end),
        current_period_start_at: Time.now
      )
      # / Create subscription

      # Notifications(by email)
      UserMailer.delay.create_subscription_mail current_user.id, subscription.id
      # / Notifications(by email)

      create_on_success
    rescue Stripe::CardError => e
      Rails.logger.error e.inspect
      create_on_decline e.message
    rescue Redis::CannotConnectError
      create_on_success
    rescue => e
      Rails.logger.error e.inspect
      create_on_error e.message
    end

    def update
      current_subscription = current_user.subscription
      updated_subscription = current_subscription.dup

      unless current_subscription.plan.upgradable_to? @plan
        flash[:error] = I18n.t 'errors.subscription.is_not_upgradeable_to_plan', plan: @plan.name
        redirect_to :billing_settings and return
      end

      customer = current_user.on_stripe
      subscription = customer.subscriptions.retrieve current_subscription.id_on_stripe

      subscription.plan = @plan.id_on_stripe
      subscription.prorate = true
      subscription.save

      sleep 2 # for glory, ale and kittens!

      invoice = Stripe::Invoice.create customer: current_user.id_on_stripe
      invoice.pay

      if invoice.paid
        updated_subscription.plan = @plan
        updated_subscription.save
        current_subscription.upgrade!

        UserMailer.delay.upgrade_subscription_mail(
          current_user.id,
          updated_subscription.id,
          current_subscription.decorate.upgrade_cost_in_dollars(@plan)
        )

        flash[:notice] = I18n.t 'messages.subscription.upgraded', plan: @plan.name
        redirect_to :billing_settings
      else
        update_on_error "Please try later or contact customer support"
      end
    rescue => e
      Rails.logger.error e.inspect
      update_on_error e.message
    end

    def update_on_error(error_message)
      flash[:error] = I18n.t 'errors.subscription.failed_to_update', reason: error_message
      redirect_to :billing_settings
    end

    def create_on_success
      redirect_to :billing_settings, notice: I18n.t('messages.subscription.created')
    end

    def create_on_error(error_message)
      flash[:error] = error_message
      redirect_to :back
    end

    def create_on_decline(decline_reason)
      flash[:error] = "Your transaction has been declined: #{decline_reason}"
      redirect_to :back
    end

    private

    def prevent_duplicate_subscription!
      if current_user.subscribed?
        flash[:error] = I18n.t('errors.already_subscribed')

        redirect_to :root and return
      end
    end
  end
end