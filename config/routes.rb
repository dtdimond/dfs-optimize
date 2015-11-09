Rails.application.routes.draw do
  root to: 'players#index'
  get 'ui(/:action)', controller: 'ui'

  post '/players/generate_lineup', to: 'players#generate_lineup'
  resources :players, only: [:index]
end
