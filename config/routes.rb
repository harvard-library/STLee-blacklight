Rails.application.routes.draw do
  
  mount Blacklight::Engine => '/'
  Blacklight::Marc.add_routes(self)
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog', constraints: { id: /[^\/]+/ } do
    concerns :exportable
  end

  # Add an additional route for the "Track" action which allows IDs to contains periods
  Blacklight::Engine.routes.draw do
    post "/catalog/:id/track", to: 'catalog#track', as: 'track_search_context_override', constraints: { id: /[^\/]+/ }

    resources :suggest, only: :index, defaults: { format: 'json' }
  end


  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
