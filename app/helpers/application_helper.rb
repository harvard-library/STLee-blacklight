module ApplicationHelper

  include Harvard::LibraryCloud::Collections

  def hash_as_list val
    val.kind_of?(Hash) ? [val] : val
  end

  def retrieve_still_image_json_metadata url
  	response = Net::HTTP.get_response(URI.parse(url))
  	if response.is_a? Net::HTTPOK
  		JSON.parse response.body
  	end
  end

  def generate_metadata_crowdsourcing_elems(fieldname, field)
    creds_file_name = 'metadata_crowdsourcing_credentials.json'

    if(File.exist?('metadata_crowdsourcing_credentials.json'))  
      json_res = JSON.parse(File.read(creds_file_name))
      json_res.each do |key, value|
        fieldname_to_check = key
        if fieldname_to_check.downcase == fieldname.downcase
          response = check_field_value_and_make_qualtrics_api_call(field, value)
          if not response.nil? and response.kind_of? Net::HTTPSuccess
            response_json = JSON.parse(response.body)
            #creating a field code to get unique ids for each "improve this record" button and modal.
            field_code = fieldname.downcase[0,3]
            form = parse_qualtrics_survey_into_modal(response_json['result']['questions'][0], response_json['result']['sessionId'], field_code)
            modal_id = 'improve_record_modal_%s'%field_code
            return ('<button type="button" class="btn btn-improve-record" data-toggle="modal" data-target="#%s" >Improve this record</button>'%modal_id).html_safe, generate_modal_code(modal_id, 'What value should this field hold?', form)
          end
        end
      end
    end
    return nil, nil  
  end

  def check_field_value_and_make_qualtrics_api_call(field, infos)
    #we need to retrieve all the required info for the API call with qualtrix from the local credential file we created.
    fieldvalue_to_check = infos['field value']
    api_token = infos['api-token']
    base_url = infos['base url']
    survey_id = infos['survey id']
    something_is_nil = (fieldvalue_to_check.nil? or api_token.nil? or base_url.nil? or survey_id.nil?)
    response = nil
    unless something_is_nil 
      require 'nokogiri'
      new_field = Nokogiri::HTML.fragment(field).text
      if new_field.downcase == fieldvalue_to_check.downcase
        #setup for the http request.
        uri = URI(base_url + survey_id + '/sessions')
        #post request is necessary in order to retrieve a session Id from qualtrics
        req = Net::HTTP::Post.new(uri) 
        req['x-api-token'] = api_token
        req['Content-Type'] = 'application/json'
        req.body = ({language: 'EN'}).to_json
        
        #actual request being made using https
        Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
          response = http.request(req)
        }
      end
    end
    return response
  end

  def parse_qualtrics_survey_into_modal(json_survey, sessionId, fieldcode)
    form_name = 'crowdsourcing_metadata_%s' % fieldcode
    form = '<form name="%s">' % form_name
    json_survey['choices'].each do |obj|
      input_type = obj['textual'] ? 'text' : 'checkbox'
      form += '<div class="crowdsource_elem"><input type="%s" name="%s"/> <label>%s</label></div>' % [input_type, obj['choiceId'], obj['display'], obj['display']]
    end
    (form + '</form><button type="button" class="btn btn-save-feedback" onclick="retrieveAndSendMetadataFormValues(\'%s\')">Send feedback</button>'%form_name).html_safe
  end

  def retrieve_hasocr_info drs_file_id
    url = 'https://iiif.lib.harvard.edu/proxy/hasocr/%d?callback=' % [drs_file_id]
    response = Net::HTTP.get_response(URI.parse(url))
    if response.is_a? Net::HTTPOK
      # for some reason, the answer even though is JSON, is embedded in paranthesis and closed by a semicolon.
      stripped_response = response.body.gsub(/[\(\);]/, '')
      parsed = JSON.parse stripped_response
      if parsed['hasocr']
        parsed['hasocr']
      end
    end
  end

  def generate_tour_modal_link(documentType)
    if documentType == 'pds'
        ('<div id="take-a-tour" style:"display:block;"><p><a id="take-a-tour-link" data-toggle="modal" data-target="#take_a_tour_modal">Take a tour of the viewer</a></p></div>').html_safe
    end
  end

  def generate_tour_modal_html(documentType)
    if documentType == 'pds'
      generate_modal_code('take_a_tour_modal', 'Tour the viewer', '<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRtpx-naAyksS0J5Jboe84367F4WXnS4gKabW0LiEihlft5HZCoO9dalZhrMVw7SUgvBDYEDrNpYvh1/embed?start=true&loop=true&delayms=10000" id="embedded-viewer-tour-presentation" frameborder="0" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>')
    end
  end

  def generate_modal_code(id, title, content)
    ('<div class="modal fade" id="%s" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-header no-border">
              <div class="modal-title" id="exampleModalLabel">%s</div>
              <button type="button" class="close modal-button" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body" id="modal-body-content">
              %s
            </div>
          </div>
        </div>
      </div>' % [id, title, content]).html_safe
  end

  def generate_twitter_meta_tags
    twitter_meta_tags = '<!-- BEGIN TWITTER SUMMARY CARD -->
                          <meta name="twitter:card" content="summary_large_image">
                          <meta name="twitter:title" content="Harvard Digital Collections">
                          <meta name="twitter:site" content="@harvardlibrary">
                          <meta name="twitter:url" content="https://digitalcollections.library.harvard.edu">
                          <meta name="twitter:image" content="%s">'
    base_img_url = 'https://library.harvard.edu/sites/default/files/home-background-eclipse.jpg'
    if defined?(@document) and @document[:drs_file_id] 
      ids_download_url = 'https://ids.lib.harvard.edu/ids/iiif/%d/full/1200,/0/default.jpg'
      if @document[:delivery_service] == 'ids'
        base_img_url = ids_download_url % @document[:drs_file_id]
      elsif @document[:delivery_service] == 'pds'
        #in the case of multiple image content, we need to get the ids id of the cover image using the iiif manifest data.
        manifest_url = 'https://iiif.lib.harvard.edu/manifests/drs:'+@document[:drs_file_id]
        res = retrieve_still_image_json_metadata manifest_url
        if res
          #the cover image manifest url will always be the first element from the array 'canvases'
          cover_img_manifest_url = res['structures'][0]['canvases'][0]
          if cover_img_manifest_url
            matches = cover_img_manifest_url.match('canvas-(.*).json')
            if matches[1]
              base_img_url = ids_download_url % matches[1]
            end
          end
        end
      end
    end
    (twitter_meta_tags % base_img_url).html_safe
  end
end
