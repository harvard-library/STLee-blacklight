module Harvard::LibraryCloud

  class Response < Blacklight::Solr::Response

    # require_dependency 'blacklight/solr/response/facets'
    include Harvard::LibraryCloud::Facets

    # def initialize(data, request_params, options = {})
    #   # super(data, request_params, options)
    #   self
    # end

    def response
      self[:items][:dc] || {}
    end

    # short cut to response['numFound']
    def total
        self[:pagination][:numFound].to_s.to_i
    end

    def start
      self[:pagination][:start].to_s.to_i
    end

    def empty?
      total.zero?
    end

    def documents
      @documents ||= (response || []).collect{|doc| document_model.new(doc, self) }
    end
    alias_method :docs, :documents

  end

end


