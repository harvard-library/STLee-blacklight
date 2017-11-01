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
      path = 'items.dc.json' #TODO: JL: Set this properly
      opts[:method] ||= :get
      raise "The :data option can only be used if :method => :post" if opts[:method] != :post and opts[:data]
      # opts[:params] = params_with_wt(opts[:params])
      # query = RSolr::Uri.params_to_solr(opts[:params]) unless opts[:params].empty?
      params = params_to_lc(opts[:params]) unless opts[:params].empty?
      # opts[:query] = query

      uri = Faraday.new @base_uri + path
      uri.ssl[:verify] = false
      uri.params = params ||= {}
      # opts[:uri] = @base_uri.merge(path.to_s + (query ? "?#{query}" : "")) if @base_uri

      uri
    end

    def execute connection
      raw_response = begin
        # response = connection.send(request_context[:method], request_context[:uri].to_s) do |req|
        #   req.body = request_context[:data] if request_context[:method] == :post and request_context[:data]
        #   req.headers.merge!(request_context[:headers]) if request_context[:headers]
        # end
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
      results
    end

    def adapt_response connection, raw_response
      JSON.parse raw_response[:body]
    end


  end

end


