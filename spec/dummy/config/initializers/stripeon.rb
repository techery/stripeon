Stripeon.config.customer_model   = User
Stripeon.config.current_customer = Proc.new { User.first || FactoryGirl.create(:user) }
Stripeon.config.stripe_api_key   = ENV['STRIPE_SECRET_KEY']
