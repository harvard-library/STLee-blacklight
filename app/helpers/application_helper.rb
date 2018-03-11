module ApplicationHelper

  def hash_as_list val
    val.kind_of?(Hash) ? [val] : val
  end

  # There is probably a better way to do this. Blacklight is calling a function with this name to render
  # the path for the "Add to Collection" action, but I'm not 100% sure why. According to the documentation
  # we would expect this function to be named 'add_to_collection_catalog_path'.
  def add_to_collection_solr_document_path (arg)
    "/catalog/" << arg.id << "/add_to_collection"
  end


  # Helper method to get the collections that are available for adding an item to
  # This does not currently do any filtering by ownership, so it shows ALL collections
  def available_collections

    base_uri = 'https://api.lib.harvard.edu/v2/'
    path = 'collections'
    params = {}
    params[:limit] = 9999

    connection = Faraday.new(:url => base_uri + path) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
      faraday.params = params
    end

    raw_response = begin
      response = connection.get
      { status: response.status.to_i, headers: response.headers, body: response.body.force_encoding('utf-8') }
    rescue Errno::ECONNREFUSED, Faraday::Error::ConnectionFailed
      raise RSolr::Error::ConnectionRefused, connection.inspect
    rescue Faraday::Error => e
      raise RSolr::Error::Http.new(connection, e.response)
    end

    response = JSON.parse raw_response[:body]

    response.map {|n| [n['title'], n['identifier']]}
  end

end
