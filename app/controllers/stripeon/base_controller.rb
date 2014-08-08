module Stripeon
  class BaseController < ::ApplicationController
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception

    before_filter :set_page_title

    helper_method :current_customer

    def view_context
      super.tap do |view|
        (@view_content_for || {}).each do |name, content|
          view.content_for name, content
        end
      end
    end

    private

    def current_customer
      Stripeon.config.current_customer.call
    end

    def json_errors_for(resource)
      { errors: resource.errors.messages }
    end

    def content_for(name, content)
      @view_content_for ||= {}

      if @view_content_for[name].respond_to?(:<<)
        @view_content_for[name] << content
      else
        @view_content_for[name] = content
      end
    end

    def content_for?(name)
      @view_content_for[name].present?
    end

    def set_page_title
      qualified_controller_name = controller_path.gsub '/', '.'

      lookup_paths = [
        "page_titles.#{qualified_controller_name}.#{action_name}",
        "page_titles.#{qualified_controller_name}",
      ]

      title_options = I18n.t(lookup_paths, default: '').reject &:empty?
      content_for :page_title, title_options.first
    end

    def require_active_subscription!
      unless current_customer.subscribed?
        flash[:error] = I18n.t 'errors.no_active_subscription'
        redirect_to [stripeon, :plans]
      end
    end

    def require_cancelable_subscription!
      unless current_customer.subscription.can_cancel?
        flash[:error] = I18n.t 'errors.subscription.already_canceled'
        redirect_to [stripeon, :billing_settings]
      end
    end

    def require_upgradable_subscription!
      unless current_customer.subscription.can_upgrade?
        flash[:error] = I18n.t 'errors.subscription.is_not_upgradeable'
        redirect_to [stripeon, :billing_settings]
      end
    end

    def require_renewable_subscription!
      unless current_customer.subscription.active?
        flash[:error] = I18n.t 'errors.subscription.renewable_required'
        redirect_to [stripeon, :billing_settings]
      end
    end

    def find_plan(plan_id = params[:plan_id])
      @plan = Plan.active.find(plan_id).decorate
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t('activerecord.errors.plan_not_found')
      redirect_to [stripeon, :plans]
    end
  end
end
