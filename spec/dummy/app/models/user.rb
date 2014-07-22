class User < ActiveRecord::Base
  include ::Stripeon::Customer

  def email
    'to@example.com'
  end
end
