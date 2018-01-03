# frozen_string_literal: true
module Harvard::LibraryCloud

  class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  ##
  # @example Adding a new step to the processor chain

    self.default_processor_chain += [:add_custom_data_to_query]

    def add_custom_data_to_query(solr_parameters)
      solr_parameters[:search_field] = blacklight_config.search_fields[blacklight_params[:search_field]].key
    end

  end

end
