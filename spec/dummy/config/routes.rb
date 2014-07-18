Rails.application.routes.draw do
  devise_for :users
  mount Stripeon::Engine => "/stripeon"
end
