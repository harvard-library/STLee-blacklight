module Harvard::LibraryCloud::Formats

  class Mods < Harvard::LibraryCloud::Response

    include ApplicationHelper

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
        result[:title_alternative] = alternative_title_from_doc doc
        result[:abstract] = abstract_from_doc doc
        result[:resource_type] = resource_type_from_doc doc
        result[:owner_code] = owner_code_from_doc doc
        result[:owner_display] = owner_display_from_doc doc
        result[:collection_title] = collection_title_from_doc doc
        result[:preview] = preview_from_doc doc
        result[:identifier] = identifier_from_doc doc
      end

      result
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

    def resource_type_from_doc doc
      type_of_resource = doc[:typeOfResource]
      result = []
      if type_of_resource.kind_of?(Hash)
        result << type_of_resource['#text']
        result << 'manuscript' if type_of_resource.key?('@manuscript')
        result << 'collection' if type_of_resource.key?('@collection')
      else
        type_of_resource
      end
      result
    end

    def owner_code_from_doc doc
      x = doc[:extension].detect { |x| x.is_a?(Hash) and x.key?(:DRSMetadata) }
      x[:DRSMetadata][:ownerCode] if x
    end

    def owner_display_from_doc doc
      x = doc[:extension].detect { |x| x.is_a?(Hash) and x.key?(:DRSMetadata) }
      x[:DRSMetadata][:ownerCodeDisplayName] if x
    end

    def collection_title_from_doc doc
      result = []
      x = doc[:extension].detect { |x| x.is_a?(Hash) and x.key?(:collections) }
      hash_as_list(x[:collections]).map do |y|
        hash_as_list(y[:collection]).map do |z|
          result << z[:title]
        end if y[:collection]
      end if x and x[:collections]
      result
    end

    def preview_from_doc doc
      location = hash_as_list(doc[:location] || []).detect{ |x| x.key?(:url) }
      hash_as_list(location[:url]).each do |x|
        if x['@access'] == 'preview'
          return x['#text']
        end
      end if location
      nil
    end

  end

end


