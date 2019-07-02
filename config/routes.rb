Rails.application.routes.draw do
  
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  mount Blacklight::Engine => '/'
  Blacklight::Marc.add_routes(self)
  root to: "application#home"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog', constraints: { id: /[^\/]+/ } do
    concerns :exportable
  end

  # Add an additional route for the "Track" action which allows IDs to contains periods
  Blacklight::Engine.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
    post "/catalog/:id/track", to: 'catalog#track', as: 'track_search_context_override', constraints: { id: /[^\/]+/ }

    resources :suggest, only: :index, defaults: { format: 'json' }
  end

  match '/catalog/:id/add_to_collection' => 'catalog#add_to_collection', as: 'add_to_collection_catalog', via: [:get, :post]

  resources :bookmarks do
    concerns :exportable
    collection do
      delete 'clear'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
