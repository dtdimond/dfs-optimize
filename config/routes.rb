Rails.application.routes.draw do
  root to: 'players#show'
  get 'ui(/:action)', controller: 'ui'

  post '/players/update', to: 'players#update'
  post '/players/generate_lineup', to: 'players#generate_lineup'
end
