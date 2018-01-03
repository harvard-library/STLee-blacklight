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
        result[:title] = self.extract_title doc
        result[:title_alternative] = self.extract_alternative_title doc
        result[:format] = 'text'
        result[:identifier] = doc[:recordInfo][:recordIdentifier]['#text']
      end

      result
    end

    def extract_title val
      if val[:titleInfo].kind_of?(Array)
        val[:titleInfo].each do |x|
          unless x['@type']
            return x[:title] + subtitle_to_add(x)
          end
        end
      else
        val[:titleInfo][:title]
      end
    end

    def extract_alternative_title val
      if val[:titleInfo].kind_of?(Array)
        val[:titleInfo].each do |x|
          if x['@type'] == 'alternative'
            return x[:title] + subtitle_to_add(x)
          end
        end
      end
    end

    def subtitle_to_add titleInfo
      if titleInfo[:subTitle]
        '; ' + titleInfo[:subTitle]
      else
        ''
      end
    end
  end

end


