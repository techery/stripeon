module Stripeon
  class HomeController < BaseController
    def show
      if current_user.subscribed?
        redirect_to billing_settings_path
      else
        redirect_to plans_path
      end
    end
  end
end