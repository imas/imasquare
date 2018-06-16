Rails.application.routes.draw do
  root to: 'home#welcome'
  get 'home', to: 'home#index'

  resources :users, only: %i(index show)
  resources :teams do
    post :join, on: :collection
    resources :entries, only: :create
  end
  resources :entries, except: %i(index destroy)

  namespace :admin do
    root to: 'admin#index'
    resources :entries, only: %i(update destroy)
    resources :teams, only: :destroy
  end

  get '/auth/:provider/callback' => 'omniauth_callbacks#callback'
  get '/auth/:provider/destroy' => 'omniauth_callbacks#destroy'
end
