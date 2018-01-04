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
        result[:title] = self.title_from_doc doc
        result[:title_alternative] = self.alternative_title_from_doc doc
        result[:abstract] = self.abstract_from_doc doc
        result[:format] = 'text'
        result[:identifier] = identifier_from_doc doc
      end

      result
    end

    def abstract_from_doc doc
      if doc[:abstract].kind_of?(Array)
        doc[:abstract].each do |x|
          if x['@type'] == 'Summary'
            return x['#text']
          end
        end
        ''
      else
        doc[:abstract]['#text'] if doc[:abstract]
      end
    end

    def identifier_from_doc doc
      doc[:recordInfo][:recordIdentifier]['#text']
    end

    def title_from_doc doc
      if doc[:titleInfo].kind_of?(Array)
        doc[:titleInfo].each do |x|
          unless x['@type']
            return nonsort_from_node(x) + x[:title] + subtitle_from_node(x)
          end
        end
      else
        nonsort_from_node(doc[:titleInfo]) + doc[:titleInfo][:title]
      end
    end

    def alternative_title_from_doc doc
      if doc[:titleInfo].kind_of?(Array)
        doc[:titleInfo].each do |x|
          if x['@type'] == 'alternative'
            return x[:title] + subtitle_from_node(x)
          end
        end
      end
      ''
    end

    def subtitle_from_node node
      node[:subTitle] ?  '; ' + node[:subTitle] : ''
    end

    def nonsort_from_node node
      node[:nonSort] ? node[:nonSort] : ''
    end
  end

end


