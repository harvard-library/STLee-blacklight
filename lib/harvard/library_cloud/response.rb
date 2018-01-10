module Harvard::LibraryCloud

  class Response < Blacklight::Solr::Response

    # require_dependency 'blacklight/solr/response/facets'
    include Harvard::LibraryCloud::Facets
    include Harvard::LibraryCloud

    # def initialize(data, request_params, options = {})
    #   # super(data, request_params, options)
    #   self
    # end

    def response
      result = self[:items] ? self[:items][:mods] || {} : {}
      result.is_a?(Hash) ? [result] : result
    end

    def documents
      @documents ||= (response || []).collect{|doc| document_model.new(doc, self) }
    end
    alias_method :docs, :documents

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

    alias_method :docs, :documents

  end

end


