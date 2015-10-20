Rails.application.routes.draw do
  root to: 'ui#optimize_page'
  get 'ui(/:action)', controller: 'ui'
end
