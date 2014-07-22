module Stripeon
  class PlansController < BaseController
    def index
      @plans = Plan.ascending.decorate
    end
  end
end