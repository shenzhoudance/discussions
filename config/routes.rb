Rails.application.routes.draw do

  resources :channels
  resources :discussions
  devise_for :users, controllers: { registrations: 'registrations' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'discussions#index'
end
