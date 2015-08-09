Rails.application.routes.draw do
  root 'welcome#index'

  get 'welcome/about', to: 'welcome#about', as: 'about'

  get 'article/:title', to: 'article#show', as: 'article'
end
