Rails.application.routes.draw do
  root to: 'player#show'
  get 'ui(/:action)', controller: 'ui'

  post '/player/update', to: 'player#update'
  post '/player/generate_lineup', to: 'player#generate_lineup'
end
