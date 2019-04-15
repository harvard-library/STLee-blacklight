module Harvard::LibraryCloud

  require 'faraday'
  require 'json'

  class API

    def initialize base_uri = 'https://api.lib.harvard.edu/v2/'
      @base_uri = base_uri
    end

    def get_base_uri
      @base_uri
    end

    def send_and_receive path, opts
      connection = build_request path, opts
      execute connection
    end

    # +build_request+ accepts a path and options hash,
    # then prepares a normalized hash to return for sending
    # to a solr connection driver.
    # +build_request+ sets up the uri/query string
    # and converts the +data+ arg to form-urlencoded,
    # if the +data+ arg is a hash.
    # returns a hash with the following keys:
    #   :method
    #   :params
    #   :headers
    #   :data
    #   :uri
    #   :path
    #   :query
    def build_request path, opts
      raise "path must be a string or symbol, not #{path.inspect}" unless [String,Symbol].include?(path.class)
      path = path.to_s
      opts[:method] ||= :get
      raise "The :data option can only be used if :method => :post" if opts[:method] != :post and opts[:data]

      if opts[:params][:preserve_original]
        params = opts[:params]
      else
        params = params_to_lc(opts[:params]) unless opts[:params].empty?
      end

      Faraday.new(:url => @base_uri + path) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.params = params ||= {}
      end
    end

    def execute connection
      raw_response = begin
        response = connection.get
        { status: response.status.to_i, headers: response.headers, body: response.body.force_encoding('utf-8') }
      rescue Errno::ECONNREFUSED, Faraday::Error::ConnectionFailed
        raise RSolr::Error::ConnectionRefused, connection.inspect
      rescue Faraday::Error => e
        raise RSolr::Error::Http.new(connection, e.response)
      end
      # We are assuming the response is JSON
      adapt_response(connection, raw_response) unless raw_response.nil?
    end

    def params_to_lc params
      results = {}
      # Restrict all results
      results[:inDRS] = 'true'
      results[:accessFlag] = 'P'
      # Don't support sort parameters for now
      # results[:sort] = sort_params_to_lc(params[:sort]) if params[:sort]
      if params[:search_field] == 'all_fields'
        results[:q] = params[:q] if params[:q]
      else
        results[params[:search_field]] = params[:q] if params[:q]
      end
      results[:start] = params[:start] if params[:start]
      results[:limit] = params[:rows] if params[:rows]
      results[:facets] = facet_params_to_lc(params['facet.field']) if params['facet.field']
      results[:recordIdentifier] = params['recordIdentifier'] if params['recordIdentifier']
      results.merge!(facet_query_params_to_lc(params[:fq])) if params[:fq]
      results
    end

    def facet_params_to_lc facet_field
	  if facet_field.kind_of?(Array)
		  facet_field.map do |x|
			# "{!ex=genre_single}genre"
			m = facet_param_formatted(x)
		  end.join(',')
	  else
		facet_param_formatted(facet_field)
	  end 
    end

	def facet_param_formatted facet_field
		m = /\{.*\}(\S+)$/.match(facet_field)
		m[1] if m
	end

    def facet_query_params_to_lc fq
      results = {}
      fq.each do |x|
        m = /\{!term f=(\S*).*\}(.*)$/.match(x)
        results[m[1] + '_exact'] = m[2]
      end if fq
      results
    end

    def sort_params_to_lc sort
      sort
    end

    def adapt_response connection, raw_response
      JSON.parse raw_response[:body]
    end


  end

end
