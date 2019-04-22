# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog
  include Harvard::LibraryCloud::Collections


  configure_blacklight do |config|

    ## Class for sending and receiving requests from a search index
    config.repository_class = Harvard::LibraryCloud::Repository

    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = Harvard::LibraryCloud::SearchBuilder

    ## Model that maps search index responses to the blacklight response model
    config.response_model = Harvard::LibraryCloud::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # The name of the query paramater to request an item by unique ID through LibraryCloud
    config.document_unique_id_param = 'recordIdentifier'

    # Actions
    config.show.document_actions.delete(:bookmark)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:email)
    config.index.document_actions.delete(:bookmark)

    # Add the "Add to collection" action to the individual document page
    add_show_tools_partial(:add_to_collection, define_method: false)
    add_results_document_tool(:add_to_collection_index)

    # Define the partials to be displayed on index and item pages
    config.index.partials = [:thumbnail, :index_header, :index]
    config.show.partials = [ :show_header, :show_original, :show]

    # Path which will be added to the API base url before the other API params.
    config.solr_path = 'items.json'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [12,24,48,96]

    # solr field configuration for search results/index views
    config.index.title_field = 'title'
    config.index.thumbnail_field = 'preview'

    # solr field configuration for document/show views
    config.show.title_field = 'title'
    config.show.thumbnail_field = 'preview'

    # Facets
    config.add_facet_field 'digitalFormat', label: 'Digital Format', single: true, limit: 10
    config.add_facet_field 'repository', label: 'Repository',  single: true, limit: 10

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # Fields to be displayed in the index (search results) view
    # The ordering of the field names is the order of the display
    #config.add_index_field 'content_model', label: 'Type'
    #config.add_index_field 'owner_display', label: 'Harvard Repository'
    #config.add_index_field 'abstract', label: 'Abstract'
	config.add_index_field 'date', label: 'Date'

    # Fields to be displayed in the show (single result) view
    # The ordering of the field names is the order of the display
    #config.add_show_field 'title_display', label: 'Title'
  config.add_show_field 'title_extended', label: 'Title'
	config.add_show_field 'name', label: 'Creator/Contributor'
	config.add_show_field 'date', label: 'Date'
	config.add_show_field 'description', label: 'Description'
  config.add_show_field 'language', label: 'Language'
	config.add_show_field 'origin', label: 'Place of Origin'
	config.add_show_field 'permalink', label: 'Permalink'
	config.add_show_field 'notes', label: 'Notes'
  config.add_show_field 'abstract', label: 'Abstract'
	config.add_show_field 'digital_format', label: 'Digital Format'
  config.add_show_field 'repository', label: 'Repository'
  config.add_show_field 'genre', label: 'Genre'
  config.add_show_field 'publisher', label: 'Publisher'
  config.add_show_field 'edition', label: 'Edition'
  config.add_show_field 'culture', label: 'Culture'
  config.add_show_field 'style', label: 'Style'
  
  config.add_show_field 'place', label: 'Place'
  config.add_show_field 'subjects', label: 'Subjects'
  config.add_show_field 'series', label: 'Series'
  
  
    #config.add_show_field 'resource_type', label: 'Format'
    #config.add_show_field 'content_model', label: 'Type'
    #config.add_show_field 'owner_display', label: 'Harvard Repository'
    #config.add_show_field 'owner_code', label: 'Repository Code'
    #config.add_show_field 'setName', label: 'Collection'
    #config.add_show_field 'abstract', label: 'Abstract'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    config.add_search_field 'all_fields', label: 'All Fields'
    config.add_search_field 'title', label: 'Title'

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field '', label: 'relevance'
    # config.add_sort_field 'dateCreated', label: 'date'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor.
    # This must be disabled when using the LibraryCloud API, since it does not have autocomplete suggest functionality
    config.autocomplete_enabled = false
    config.autocomplete_path = 'suggest'
  end


end
