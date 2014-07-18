Stripeon::Engine.routes.draw do
  resources :plans, only: :index

  get 'billing' => 'billing_settings#show', as: :billing_settings
  resources :credit_cards,       only: [:new, :create]
  resources :subscriptions,      only: [:new, :create]

  resource :subscription, only: [:destroy, :update] do
    get 'cancel'  => "subscription_cancelations#new"
    get 'upgrade' => "subscription_upgrades#new"
  end

  resources :payments, only: [:index, :show]

  namespace :webhooks do
    resources :stripe_events, only: :create
  end
end
