Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/signup", to: "authentication#signup"
      post "auth/login", to: "authentication#login"

      resources :groups, only: [:index, :show, :create] do
        post "members", to: "members#create"
        get "balances", to: "groups#balances"
        resources :expenses, only: [:index, :create]
        resources :settlements, only: [:index, :create]
      end
    end
  end
end
