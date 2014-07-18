class User < ActiveRecord::Base
  include ::Stripeon::Customer

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
