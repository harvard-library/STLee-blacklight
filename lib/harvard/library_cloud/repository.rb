module Harvard::LibraryCloud

  class Repository < Blacklight::AbstractRepository

    ##
    # Find a single solr document result (by id) using the document configuration
    # @param [String] id document's unique key value
    # @param [Hash] params additional solr query parameters
    def find id, params = {}
      doc_params = params.reverse_merge(blacklight_config.default_document_solr_params)
                       .reverse_merge(qt: blacklight_config.document_solr_request_handler)
                       .merge(blacklight_config.document_unique_id_param => id)

      solr_response = send_and_receive blacklight_config.document_solr_path || blacklight_config.solr_path, doc_params
      raise Blacklight::Exceptions::RecordNotFound if solr_response.documents.empty?
      solr_response
    end

    ##
    # Execute a search query against solr
    # @param [Hash] params solr query parameters
    def search params = {}
      send_and_receive blacklight_config.solr_path, params.reverse_merge(qt: blacklight_config.qt)
    end

    ##
    # Execute a solr query
    # @see [RSolr::Client#send_and_receive]
    # @overload find(solr_path, params)
    #   Execute a solr query at the given path with the parameters
    #   @param [String] solr path (defaults to blacklight_config.solr_path)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @overload find(params)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @return [Blacklight::Solr::Response] the solr response object
    def send_and_receive(path, solr_params = {})
      benchmark("LibraryCloud API fetch", level: :debug) do
        #key = blacklight_config.http_method == :post ? :data : :params
        key = :params
        res = connection.send_and_receive(path, {key=>solr_params.to_hash, method: blacklight_config.http_method})

        api_response = blacklight_config.response_model.new(res, solr_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)

        api_response
      end

      rescue Errno::ECONNREFUSED => e
        raise Blacklight::Exceptions::ECONNREFUSED, "Unable to connect to Solr instance using #{connection.inspect}: #{e.inspect}"
      rescue RSolr::Error::Http => e
        raise Blacklight::Exceptions::InvalidRequest, e.message
    end

    protected

    def build_connection
      Harvard::LibraryCloud::API.new
    end

  end

end
