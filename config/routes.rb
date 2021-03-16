Rails.application.routes.draw do
  
  devise_for :users
  
  resources :customers

  resources :accounts

  root "customers#index"
end
