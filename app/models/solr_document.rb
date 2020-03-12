# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

  include ApplicationHelper

  def initialize(source_doc={}, response=nil)
    super self.mods_to_doc(source_doc), response
  end

  # Populate fields on doc from LC JSON response. 
  # Called on both the item details and listing pages.
  def mods_to_doc doc
    result = {}
    if !doc.empty?
      result[:identifier] = identifier_from_doc doc
	    if result[:identifier].nil?
        return
      end
      puts 'ID=' + result[:identifier]
      result[:title] = title_from_doc doc, true

      #extended title is used for item details page
      result[:title_extended] = extended_title_from_doc doc, title_from_doc(doc, false)
      result[:abstract] = abstract_from_doc doc
      result[:resource_type] = resource_type_from_doc doc
      
      result[:digital_format] = field_values_from_node_by_path doc, '$.extension..librarycloud.digitalFormats.digitalFormat', '<br/>', false
      result[:repository] = facet_links_from_node_by_path doc, '$..physicalLocation[?(@["@displayLabel"]=="Harvard repository")]["#text"]', 'physicalLocation', '<br/>', false
      result[:genre] = facet_links_from_node_by_path doc, '$..genre', 'genre', '<br/>', false
      result[:publisher] = facet_links_from_node_by_path doc, '$..publisher', 'publisher', '<br/>', false
      result[:edition] = field_values_from_node_by_path doc, '$..edition', '<br/>', false
      result[:culture] = field_values_from_node_by_path doc, '$.extension..cultureWrap.culture', '<br/>', false
      result[:style] = field_values_from_node_by_path doc, '$.extension..styleWrap.style', '<br/>', false
      result[:owner_code] = extension_field_from_doc doc, :ownerCode
      result[:owner_display] = extension_field_from_doc doc, :ownerCodeDisplayName
      result[:place] = place_from_doc doc
      result[:description] = description_from_doc doc
    
	    result[:name] = name_from_doc doc
	    result[:language] = language_from_doc doc
	    result[:origin] = origin_from_doc doc
	    result[:date] = date_from_doc doc
	    result[:permalink] = permalink_from_doc doc
	    result[:notes] = notes_from_doc doc
      result[:series] = series_from_doc doc
      result[:subjects] = subjects_from_doc doc
      result[:preview] = preview_from_doc doc
      result[:raw_object] = raw_object_from_doc doc
      result[:funding] = field_values_from_node_by_path doc, '$..note[?(@["@type"]=="funding")]["#text"]', '<br/>', false
      
      result[:hollis_links] = hollis_links_from_doc doc
      result[:hollis_image_links] = hollis_image_links_from_doc doc
      result[:finding_aid_links] = finding_aid_links_from_doc doc
      result[:digital_collections_links] = digital_collections_links_from_doc doc
      result[:additional_digital_items] = additional_digital_items_from_doc doc
      result[:drs_file_id] = drs_file_id_from_raw_object result[:raw_object] 
      result[:delivery_service] = delivery_service_from_raw_object result[:raw_object]
      
      result[:id] = result[:identifier]
    end

    result
  end

  def identifier_from_doc doc
    path = JsonPath.new("$.recordInfo.recordIdentifier['#text']")
    path.on(doc).first
  end

  def identifier_source_from_doc doc
    path = JsonPath.new("$.recordInfo.recordIdentifier['@source']")
    path.on(doc).first
  end

  def title_from_doc doc, useAltTitle
    title = ''
    
    nodes_from_path(doc, '$.titleInfo').each do |x|
      node_to_array(x).each do |y|
        unless y['@type']
		      if title != ''
  			    title += '; '
		      end
          title += title_from_node y
        end
      end
    end
                    
	  relatedTitle = related_title_from_doc doc
    if relatedTitle != ''
      title = relatedTitle + title
    end

    #some titles need to be prefixed with a series or collection title 
    archival_title = archival_title_from_node doc, title
    if archival_title != ''
      title = archival_title + ' ' + title 
    end

    #if title is not set, get alternative title
    if title == '' && useAltTitle
      node_to_array(doc[:titleInfo]).each do |x|
        if !x['@type'].nil? && x['@type'] != ''
          title = title_from_node x
		      #pull first alt title
          if title != ''
            break
          end
        end
      end
    end

    title
  end

  #get title of parent collection or series
  def archival_title_from_node node, title
    archival_title = ''
    nodes_from_path(node, '$.relatedItem[?(@["@type"]=="host")]').each do |x|
      title_part = ''

      nodes_from_path(x, '$.titleInfo').each do |y|
        title_part += title_from_node y
      end

      if title_part != ''
        if archival_title != ''
          archival_title += ', '
        end
        archival_title += title_part
      end

      if archival_title != '' && archival_title == title
        archival_title = archival_title_from_node x, title
      end
    end

    archival_title
  end

  #extended title includes related title and alternative titles
  def extended_title_from_doc doc, title
    alternativeTitle = alternative_title_from_doc doc
    if alternativeTitle != ''
      title += '<br/><br/>' + alternativeTitle
    end

    title
  end

  def title_from_node node
    title = ''
    title = nonsort_from_node(node) + field_values_from_node_by_path(node, '$.title', ', ', true) + subtitle_from_node(node) + partnumber_from_node(node) + partname_from_node(node)
    title
  end

  def related_title_from_doc doc
	  relatedTitle = ''

    source = identifier_source_from_doc(doc)
    if source != 'MH:VIA'
      return relatedTitle
    end 

    node_to_array(doc[:relatedItem]).each do |x|
	  	if x['@type'] == 'constituent' && x[:titleInfo] 
			  if x[:titleInfo].kind_of?(Array)
				  x[:titleInfo].each do |z|
					  relatedTitle += title_from_node(z) + ". "
				  end
			  else
				  relatedTitle += title_from_node(x[:titleInfo]) + ". "
			  end
		  end
	  end
	  relatedTitle
  end

  def alternative_title_from_doc doc
    alternativeTitle = ''
    title_info_items = nodes_from_path doc, '$..titleInfo'
    node_to_array(title_info_items).each do |x|
      node_to_array(x).each do |y|  
        if (!y['@type'].nil? && y['@type'] != '') || (!y['@displayLabel'].nil? && (y['@displayLabel'] == 'Common Name' || y['@displayLabel'] == 'Original Name'))
          title = title_from_node y
		      if title != '' && alternativeTitle != ''
		        alternativeTitle += '<br/><br/>'
		      end

          alternativeTitle += '<span class="alternative-title">' + sub_label_for_field('Alternative Title', title) + '</span>'
        end
      end
    end

    alternativeTitle
  end

  def subtitle_from_node node
    subTitle = field_values_from_node_by_path(node, '$.subTitle', ', ', true)
    if subTitle != ''
      subTitle = '. ' + subTitle
    end
    subTitle
  end

  # get title part number
  def partnumber_from_node node
    partNumber = field_values_from_node_by_path(node, '$.partNumber', ', ', true)
    if partNumber != ''
      partNumber = '. ' + partNumber
    end
    partNumber
  end

  #get title part name
  def partname_from_node node
    partName = field_values_from_node_by_path(node, '$.partName', ', ', true)
    if partName != ''
      partName = '. ' + partName
    end
    partName
  end

  #get title nonSort
  def nonsort_from_node node
    field_values_from_node_by_path(node, '$.nonSort', ', ', true)
  end

  #get person name, such as creator
  def name_from_doc doc
    name = ''
    names = nodes_from_path doc, '$..name'
    names.each do |x|
      node_to_array(x).each do |y|
        roleTerm = nodes_from_path y, '$..roleTerm'
        node_to_array(roleTerm).each do |z|
          if !z.nil? && field_value_from_node(z, ',', false) == 'creator'
            if name != ''
              name += ', '
            end
            name += name_from_node y, true
            altName = ''
            translatedNames = ''
            
            #get any translated names by matching altRepGroup attribute
            if !y['@altRepGroup'].nil? && y['@altRepGroup'] != ''
              altNames = nodes_from_path doc, '$..name[?(@["@altRepGroup"] == "' + y['@altRepGroup'] + '")]'
              altNames.each do |m|
                altName = name_from_node m, true
                if name != altName
                  translatedNames += ', ' + altName
                end
              end
            end

            if translatedNames != ''
              name += translatedNames
            end

            break
          end
        end
      end
    end

	  name
  end

  def name_from_node node, includeRole
	  name = ''
		namepart = ''
    node_to_array(node).each do |x|
      node_to_array(x[:namePart]).each do |z|
			  if !z.nil?
          if namepart != ''
				    namepart += ', '
			    end 
			    if z.kind_of?(String)
				    namepart += z
			    else	
            namepart += z['#text']
			    end
        end
		  end

      if name != '' && namepart != ''
        name += '<br/>'
      end

		  name += namepart
      if includeRole
        name += roleterm_from_role x[:role]
      end

    end
		
	  name
  end
  
  def roleterm_from_role node
	  role = ''

	  if node.nil?
		  return role
	  end
	
		node_to_array(node).each do |z|
      roleTerm = ''

      if !z[:roleTerm].nil?		
				if z[:roleTerm].kind_of?(String)		
					roleTerm = z[:roleTerm]
				else
					roleTerm = z[:roleTerm]['#text']
				end

        #exclude creator from list of roles displayed
        if roleTerm == 'creator'
          roleTerm = ''
        end
			end

      if roleTerm != ''
			  if role != ''
				  role += ', '
			  else
				  role = ' ['
			  end

        role += roleTerm
			end
		end

    if role != ''
	    role += ']'
    end
    
    role
  end
  
  def language_from_doc doc
    nodes = nodes_from_path doc, '$..language.languageTerm[?(@["@type"] == "text")]["#text"]'
    facet_link_from_node nodes, 'language', '<br/>', false
  end

  def date_from_doc doc
    date = ''

    dateNodes = nodes_from_path doc, '$..["dateIssued","dateCreated","dateCaptured","dateOther","copyrightDate"]'

    node_to_array(dateNodes).each do |x|
      date = date_from_date_node x
      if date != ''
        return date
      end
    end
    
	  date
  end
  
  def date_from_date_node node
	  date = ''

    if node.nil?
      return date
    end

		if node.kind_of?(Array) 
      node.each do |x|
        date = date_from_date_node x
        if date != ''
          return date
        end
      end
    elsif node.kind_of?(String) || node.kind_of?(Integer)
			date = node.to_s
    elsif !node['#text'].nil? && node['#text'] != '' && node['@point'].nil?
			date = node['#text']
		end

	  date
  end

  def origin_from_doc doc
    origin = ''

    nodes = nodes_from_path doc, '$..originInfo..place..placeTerm'
		node_to_array(nodes).each do |x|
      if x.kind_of?(String)
        if origin != ''
          origin += '<br/>'
        end
        origin += facet_link_from_node x, 'originPlace', '<br/>', false
      else
        node_to_array(x).each do |y|
          if !y['#text'].nil? && y['#text'] != '' && (y['@type'].nil? || y['@type'] == 'text')
            if origin != ''
              origin += '<br/>'
            end
            origin += facet_link_from_node y['#text'], 'originPlace', '<br/>', false
          end
        end
      end
    end

	  origin
  end

  def permalink_from_doc doc
		field_values_from_node_by_path doc, '$..url[?(@["@displayLabel"] == "Harvard Digital Collections" && @["@access"] == "object in context")]', '<br/>', false
  end

  def notes_from_doc doc
    notes = ''
    attribution = ''
    funding = ''
    organization = ''

    items = nodes_from_path doc, '$..note'
    node_to_array(items).each do |x|
      if x.kind_of?(String)
        if notes != ''
          notes += '<br/>'
        end
        notes += x
      else
        node_to_array(x).each do |y|
          if y.kind_of?(String)
            if notes != ''
              notes += '<br/>'
            end
            notes += y
          else
            #separate out particular types of notes
            if !y['@type'].nil? && y['@type'] == 'statement of responsibility'
              attribution += y['#text'].to_s  
            elsif !y['@type'].nil? && y['@type'] == 'funding'
              funding += y['#text'].to_s  
            elsif !y['@type'].nil? && y['@type'] == 'organization'
              organization += y['#text'].to_s  
            else 
              if notes != ''
                notes += '<br/>'
              end
              notes += y['#text'].to_s  
            end
          end
        end
      end
    end

    if attribution != ''
      if notes != ''
        notes += '<br/>'
      end
      notes += sub_label_for_field  'Attribution', attribution
    end
    
    if funding != ''
      if notes != ''
        notes += '<br/>'
      end
      notes += sub_label_for_field 'Funding', funding
    end

    access_condition = field_values_from_node_by_path doc, '$..accessCondition', '<br/>', false
    if access_condition != ''
      if notes != ''
        notes += '<br/>'
      end
      notes += sub_label_for_field 'Rights', access_condition
    end

	  notes
  end

  def abstract_from_doc doc
    abstract = ''

    abstract_items = nodes_from_path doc, '$..abstract'
    abstract = field_value_from_node abstract_items, '<br/>', false

    toc_items = nodes_from_path doc, '$..tableOfContents'

    toc = field_value_from_node toc_items, '<br/>', false
    if toc != ''
      if abstract != ''
        abstract += '<br/>'
      end
      abstract += toc
    end

    abstract
  end

  def description_from_doc doc
    description = ''
    extent = field_values_from_node_by_path doc, '$..extent', '<br/>', false
    if extent != ''
      if description != ''
        description += '<br/>'
      end
      description += sub_label_for_field 'Extent', extent
    end

    materials = field_values_from_node_by_path doc, '$.extension..indexingMaterialsTechSet.termMaterialsTech', '<br/>', false
    otherMaterials = field_values_from_node_by_path doc, '$..physicalDescription..form[?(@["@type"] == "materialsTechniques" || @["@type"] == "support")]', '<br/>', false

    if materials != '' && otherMaterials != ''
      materials += '<br/>'
    end
    materials += otherMaterials

    if materials != ''
      if description != ''
        description += '<br/>'
      end
      description += sub_label_for_field 'Materials/Techniques', materials
    end

    form_items = nodes_from_path doc, '$..physicalDescription..form'
    if !form_items.nil?
      form_values = ''
      form_items.each do |x|
        node_to_array(x).each do |y|
          if y['@type'].nil?
            form_values += field_value_from_node y, '<br/>', false
          end
        end
      end

      if form_values != ''
        if description != ''
          description += '<br/>'
        end
        description += form_values
      end
    end

    description
  end

  def place_from_doc doc
    place = ''

    physical_items = nodes_from_path doc, '$..physicalLocation'

    places = []
    node_to_array(physical_items).each do |x|
      if (!x.nil? && (x["@displayLabel"].nil? || x["@displayLabel"] != "Harvard repository")) && (x["@type"].nil? || x["@type"] != "container")
        place_item = field_value_from_node x, '<br/>', false
        if place_item != "" && place_item != "FIG"
          places.push link_tag_for_facet place_item, 'physicalLocation'
        end
      end
    end

    if places.length > 0
      places.uniq!
      place = places.join('<br/>')
    end

    geography_items = nodes_from_path doc, '$..hierarchicalGeographic.*'
    geography = ''
    geography_items.each do |x|
      x.each do |key, value|
        if geography != ''
          geography += '--'
        end
        
        geography += value
      end
    end

    if geography != ''
      if place != ''
        place += '<br/>'
      end
      place += geography
    end 

    place
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

  def series_from_doc doc
    series_items = []
    series_nodes = nodes_from_path(doc, '$..relatedItem[?(@["@type"] == "series")]')

    series_nodes.each do |x|
      series = ''
      title = title_from_node x['titleInfo']
      name = name_from_node x['name'], true
      
      series = title
      series += ' ' + name
      series_items.push(link_tag_for_facet(series, 'seriesTitle'))
    end

    series_items.join('<br/>')
  end

  def subjects_from_doc doc
    subject_items = []
    subjects = ''
    
    subject_nodes = nodes_from_path(doc, '$..subject')

    subject_nodes.each do |x|
      node_to_array(x).each do |y|    
        if !y['name'].nil?
          #handle subjects that contain names
          subject = name_from_node y['name'], false
          if subject != ''
            subject_items.push(link_tag_for_facet subject, 'subject')
          end
        else
          subject = subject_from_node y, ''
          if subject['subject'] != ''
            subject_text = ''
            #prepend prefix
            if subject['prefix'] != ''
              subject_text = '<span class="prefix">' + subject['prefix'] + '</span>: '
            end
            #hyperlink on subject
            subject_text += link_tag_for_facet subject['subject'], 'subject'
            
            subject_items.push(subject_text)
          end
        end
      end
    end

    #add any names that have the role "subject"
    names = nodes_from_path doc, '$..name'
    names.each do |x|
      node_to_array(x).each do |y|
        name = ''
        roleTerm = nodes_from_path y, '$..roleTerm'
        node_to_array(roleTerm).each do |z|
          if !z.nil? && field_value_from_node(z, ',', false) == 'subject'
            if name != ''
              name += ', '
            end
            name += name_from_node y, false
            break
          end
        end

        if name != ''
          subject_items.push(name)
        end
      end
    end

    subject_items.uniq!
    subjects = subject_items.join('<br/>')
	  subjects
  end

  #return object with prefix and subject  
  def subject_from_node node, field_name
    #subjects can have prefixes
    subject_item = {"subject" => "", "prefix" => ""}
    subject_part = {"subject" => "", "prefix" => ""}

    if node.kind_of?(Hash)
      node.each do |key, value|
        if key == "geographicCode" || key == '@authority' || key == '@altRepGroup' 
          next
        end
        subject_part = subject_from_node value, key
        subject_item = append_subject_part subject_item, subject_part
      end
    elsif node.kind_of?(Array)
      node.each do |x|
        subject_part = subject_from_node x, ''
        subject_item = append_subject_part subject_item, subject_part
      end
    elsif node.kind_of?(String) || node.kind_of?(Integer)
      #the display label should be treated as a prefix
      if field_name == '@displayLabel'
        subject_part["prefix"] = node.to_s()
      else
        subject_part["subject"] = node.to_s()
      end
      subject_item = append_subject_part subject_item, subject_part
    end
        
    subject_item
  end

  def append_subject_part subject_item, subject_part
    if !subject_item.nil? && !subject_part.nil?
      if subject_part["subject"] != ''
        if subject_item["subject"] != ''
          subject_item["subject"] += '--'
        end
        subject_item["subject"] += subject_part["subject"]
      end
      if subject_part["prefix"] != ''
        if subject_item["prefix"] != ''
          subject_item["prefix"] += ' '
        end
        subject_item["prefix"] += subject_part["prefix"]
      end
    end

    subject_item
  end


  def extension_field_from_doc doc, field
    x = hash_as_list(doc[:extension]).detect { |x| x.is_a?(Hash) and x.key?(:DRSMetadata) }
    x[:DRSMetadata][field] if x
  end

  def collection_title_from_doc doc
    result = []
    x = hash_as_list(doc[:extension]).detect { |x| x.is_a?(Hash) and x.key?(:collections) }
    hash_as_list(x[:collections]).map do |y|
      hash_as_list(y[:collection]).map do |z|
        result << z[:title]
      end if y[:collection]
    end if x and x[:collections]
    result
  end

  #get preview (thumbnail url)
  def preview_from_doc doc
    preview = ''

    preview = JsonPath.new('$..location..url[?(@["@access"] == "preview")]["#text"]').first(doc)

    if preview.nil?
      preview = ''
    end

    preview = preview.gsub(/http:/,'https:') 
    preview
  end

  def raw_object_from_doc doc
    raw_object = ''

    raw_object = JsonPath.new('$..location..url[?(@["@access"] == "raw object")]["#text"]').first(doc)
    raw_object = fetch_ids_uri(raw_object)
    raw_object = raw_object.gsub(/http:/,'https:') 
    if (raw_object.include?('https://ids') && !raw_object.include?('?buttons=y'))
      separator = raw_object.include?('?') ? '&' : '?'
      raw_object = raw_object + separator + 'buttons=y'
    end
    
    raw_object
  end

  def drs_file_id_from_raw_object url
      end_of_url = url.split('/')[-1]
      end_of_url.split('?')[0].match('([0-9]*)')[1]
  end

  def delivery_service_from_raw_object url
      # 'https://sds...' will be split into 3 elements: ['https', '', 'sds...']
      begin_of_url = url.split('/')[2]
      begin_of_url.split('.')[0]
  end

  def hollis_links_from_doc doc
    related_urls_by_type doc, 'HOLLIS record', 'HOLLIS Record', ''
  end

  def hollis_image_links_from_doc doc
    related_urls_by_type doc, 'HOLLIS Images record', 'HOLLIS Images Record', ''
  end

  def finding_aid_links_from_doc doc
    related_urls_by_type doc, 'Finding Aid', 'Finding Aid', ''
  end
  
  def digital_collections_links_from_doc doc
    object_in_context_urls_from_doc doc, 'Item Record'
  end

  #return an array of objects with url, link text, and label
  def related_urls_by_type doc, type, link_text, label
    link_urls = []
    link_items = nodes_from_path doc, '$..relatedItem[?(@["@otherType"] == "' + type + '")]'
    link_items.each do |x|
      node_to_array(x['location']).each do |y|
        link_urls.push related_link_to_obj(y['url'], link_text, label)
      end
    end

    link_urls
  end

  def related_link_to_obj url, link_text, label
    obj = {}
    obj[:url] = url
    obj[:link_text] = link_text
    obj[:label] = label
    obj
  end

  def object_in_context_urls_from_doc doc, label
    link_urls = []
    link_items = nodes_from_path doc, '$..url[?(@["@access"] == "object in context")]'
    link_items.each do |x|      
      if x['@displayLabel'] != "Harvard Digital Collections" && x['#text'] != ""
        link_urls.push related_link_to_obj(x['#text'], 'Item Record', x['@displayLabel'])
      end
    end

    link_urls
  end

  def additional_digital_items_from_doc doc
    additional_digital_items = ''
    nodes = nodes_from_path doc, '$..location..url[?(@["@access"] == "raw object")]'
    
    if !nodes.nil? && nodes.kind_of?(Array) && nodes.count > 1
      for i in 0..(nodes.count-1)
        if i > 0
          if !nodes[i]['#text'].nil?
            if additional_digital_items != ''
              additional_digital_items += '<br/>'
            end
          
            additional_digital_items += link_tag_for_url nodes[i]['#text'], nodes[i]['#text'], true
          end
        end
      end
    end

    additional_digital_items 
  end

  def related_link_tag_for_url url, link_text, label, new_window
    link_tag = link_tag_for_url url, link_text, new_window
    if label.to_s != ''
      link_tag += ' ' + label
    end
    link_tag
  end

  def link_tag_for_facet facet_value, facet_field
    url = '/catalog?f%5B' + URI::escape(facet_field) + '%5D%5B%5D=' + URI::escape(facet_value)
    link_tag_for_url url, facet_value, false
  end

  def link_tag_for_url url, link_text, new_window
    link_tag = '<a href="' + url + '" '
    if new_window
      link_tag += ' target="_blank"'
    end
    link_tag += '>' + link_text + '</a>'
    link_tag
  end

  def fetch_ids_uri(uri_str)
    if (uri_str =~ /urn-3/)
      response = Net::HTTP.get_response(URI.parse(uri_str))['location']
    elsif (uri_str.include?('?'))
      uri_str = uri_str.slice(0..(uri_str.index('?')-1))
    else
      uri_str
    end
  end

  
  def facet_link_from_node node, facet_field, separator, allowDuplicates
    field_value = ''
    field_values = field_value_from_node_to_array node

    if field_values.length > 0 && !allowDuplicates
      field_values.uniq!
    end
    
    for i in 0..(field_values.length - 1)
      field_values[i] = link_tag_for_facet field_values[i], facet_field
    end

    field_value = field_values.join(separator)
    field_value
  end

  def field_value_from_node node, separator, allowDuplicates
    field_value = ''
    field_values = field_value_from_node_to_array node

    if field_values.length > 0 && !allowDuplicates
      field_values.uniq!
    end
    field_value = field_values.join(separator)
    field_value
  end

  # return array of values
  def field_value_from_node_to_array node
    field_values = []
    field_value = ''
    if node.nil?
      return field_values
    end

    if node.kind_of?(Array)
      node.each do |x|
        values2 = field_value_from_node_to_array x
        field_values = append_to_values field_values, values2
      end
    else
      if node.kind_of?(String) || node.kind_of?(Integer)
        field_values.push node.to_s
      else
        values2 = field_value_from_node_to_array node['#text']
        field_values = append_to_values field_values, values2
      end
    end

    field_values
  end

  #append values to array
  def append_to_values values, node
    if node.kind_of?(Array)
      node.each do |x|
        values = append_to_values values, x
      end
    elsif node.kind_of?(String) || node.kind_of?(Integer)
      values.push node.to_s
    end

    values
  end
  
  def nodes_from_path doc, path
    return JsonPath.new(path).on(doc)
  end

  def facet_links_from_node_by_path node, path, facet_field, separator, allowDuplicates
    fieldValue = ''
    field_nodes = nodes_from_path node, path

    if !field_nodes.nil?
      fieldValue = facet_link_from_node field_nodes, facet_field, separator, allowDuplicates
    end
    fieldValue
  end

  def field_values_from_node_by_path node, path, separator, allowDuplicates
    fieldValue = ''
    field_nodes = nodes_from_path node, path

    if !field_nodes.nil?
      fieldValue = field_value_from_node field_nodes, separator, allowDuplicates
    end
    fieldValue
  end

  def first_field_value_from_doc_by_path node, path, separator, allowDuplicates
    fieldValue = ''
    field_items = JsonPath.new(path).first(node)
    
    fieldValue = field_value_from_node field_items, separator, allowDuplicates
    fieldValue
  end

  def node_to_array node
	  arr = []

	  if !node.nil?
		  if node.kind_of?(Array)
			  arr = node
		  else
			  arr.push(node)
		  end
	  end
	
	  arr
  end

  def sub_label_for_field label, field_value
    '<strong>' + label + '</strong>: ' + field_value
  end


  # BEGIN DEFAULT CODE FROM THE SAMPLE SolrDocument

  # The following shows how to setup this blacklight document to display marc documents
  # extension_parameters[:marc_source_field] = :marc_display
  # extension_parameters[:marc_format_type] = :marcxml
  # use_extension( Blacklight::Solr::Document::Marc) do |document|
  #   document.key?( :marc_display  )
  # end

  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )



  self.unique_key = 'identifier'

  # # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension(Blacklight::Document::Email)
  #
  # # SMS uses the semantic field mappings below to generate the body of an SMS email.
  # SolrDocument.use_extension(Blacklight::Document::Sms)
  #
  # # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # # Semantic mappings of solr stored fields. Fields may be multi or
  # # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # # and Blacklight::Document::SemanticFields#to_semantic_values
  # # Recommendation: Use field names from Dublin Core
  # use_extension(Blacklight::Document::DublinCore)

  # ENDDEFAULT CODE FROM THE SAMPLE SolrDocument
end
