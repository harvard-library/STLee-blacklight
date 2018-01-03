module Harvard::LibraryCloud::Formats

  class Mods < Harvard::LibraryCloud::Response

    def response
      result = self[:items] ? self[:items][:mods] || {} : {}
      result.is_a?(Hash) ? [result] : result
    end

    def documents
      @documents ||= (response || []).collect{|doc| document_model.new(self.mods_to_doc(doc), self) }
    end
    alias_method :docs, :documents

    def mods_to_doc doc
      result = {}
      if !doc.empty?
        # result[:title] = Array(doc[:titleInfo]).map {|x| x[:title]}.join
        result[:title] = self.extract_title doc
        result[:format] = 'text'
        result[:identifier] = doc[:recordInfo][:recordIdentifier]['#text']
      end

      result
    end

    def extract_title val
      if val[:titleInfo].kind_of?(Array)
        result = {}
        val[:titleInfo].each {|x| result.merge!(x.to_h)}
        result['title']
      else
        val[:titleInfo][:title]
      end
    end

  end

end


