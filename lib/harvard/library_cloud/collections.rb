module Harvard::LibraryCloud::Collections

  require 'faraday'
  require 'json'

  include Harvard::LibraryCloud

  # Logic for adding an item to a collection,
  def add_to_collection_action (collection, item)

    api = Harvard::LibraryCloud::API.new
    path = 'collections/' + collection

    connection = Faraday.new(:url => api.get_base_uri + path) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['X-LibraryCloud-API-Key'] = ENV["LC_API_KEY"]
    end

    raw_response = begin
      response = connection.post do |req|
        req.body = '[{"item_id": "' + item + '"}]'
      end
      { status: response.status.to_i, headers: response.headers, body: response.body.force_encoding('utf-8') }
    rescue Errno::ECONNREFUSED, Faraday::Error => e
      raise RSolr::Error::Http.new(connection, e.response)
    end
  end

  # This is the action that displays the contents of the "Add to Collection" dialog
  def add_to_collection

    if request.post?
      # Actually add the item to the collection
      add_to_collection_action(request.params[:collection], request.params[:id])

      # Don't render the default "Add to Collection" dialog - render the "Success!" dialog contents
      flash[:success] ||= "The item has been added to the collection"
      render 'catalog/add_to_collection_success'
    end

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
    api = API.new
    params = {:limit => 9999, :preserve_original => true}
    response = api.send_and_receive('collections', {:params => params})
    response.map {|n| [n['title'], n['identifier']]}
  end

end
