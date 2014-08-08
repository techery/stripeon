Stripeon.config.customer_model   = User
Stripeon.config.current_customer = Proc.new { User.first || FactoryGirl.create(:user) }