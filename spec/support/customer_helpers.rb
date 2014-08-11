module CustomerHelper
  def login_as_customer(customer)
    Stripeon::BaseController.any_instance.stub(:current_customer) { customer }
  end
end

RSpec.configure do |c|
  c.include CustomerHelper
end
