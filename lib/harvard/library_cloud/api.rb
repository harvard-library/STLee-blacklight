module Harvard::LibraryCloud

  require 'faraday'
  require 'json'

  class API

    def initialize base_uri = 'https://api.lib.harvard.edu/v2/'
      @base_uri = base_uri
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
      # opts[:params] = params_with_wt(opts[:params])
      # query = RSolr::Uri.params_to_solr(opts[:params]) unless opts[:params].empty?

      params = params_to_lc(opts[:params]) unless opts[:params].empty?

      # opts[:query] = query

      Faraday.new(:url => @base_uri + path) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
        faraday.ssl[:verify] = false
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
      results[:q] = params[:q] if params[:q]
      results[:start] = params[:start] if params[:start]
      results[:limit] = params[:rows] if params[:rows]
      results[:facets] = params['facet.field'].join(",") if params['facet.field']
      a = facet_query_params_to_lc(params[:fq])
      results.merge!(a)
      results
    end

    def facet_query_params_to_lc fq
      results = {}
      fq.each do |x|
        m = /\{!term f=(\S*).*\}(.*)$/.match(x)
        results[m[1] + '_exact'] = m[2]
      end

      results
    end

    def adapt_response connection, raw_response
      JSON.parse raw_response[:body]
    end


  end

end


#"{!term f=subject}United States"
