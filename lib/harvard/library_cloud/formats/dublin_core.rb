module Harvard::LibraryCloud::Formats

  class DublinCore < Harvard::LibraryCloud::Response

    def response
      self[:items][:dc] || {}
    end

    def documents
      @documents ||= (response || []).collect{|doc| document_model.new(doc, self) }
    end

  end

end


