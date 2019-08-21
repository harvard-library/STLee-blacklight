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
    require 'nokogiri'
    creds_file_name = 'metadata_crowdsourcing_credentials.json'

    if(File.exist?('metadata_crowdsourcing_credentials.json'))  
      json_res = JSON.parse(File.read(creds_file_name))
      fieldname_to_check = json_res['field name']
      fieldvalue_to_check = json_res['field value']
      api_token = json_res['api-token']
      base_url = json_res['base url']
      survey_id = json_res['survey id']
      is_something_nil = (fieldname_to_check.nil? or fieldvalue_to_check.nil? or api_token.nil? or base_url.nil? or survey_id.nil?)
      if not is_something_nil and fieldname.downcase == fieldname_to_check.downcase
        new_field = Nokogiri::HTML.fragment(field).text
        if new_field.downcase == fieldvalue_to_check.downcase
          uri = URI(base_url + survey_id)
          req = Net::HTTP::Get.new(uri) 
          req['x-api-token'] = api_token
          response = nil
          Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
            response = http.request(req)
          }
          if not response.nil? and response.kind_of? Net::HTTPSuccess
            form = parse_qualtrics_survey_into_hml_form(JSON.parse(response.body)['result']['questions']['QID1'])
            return ('<button type="button" class="btn btn-improve-record" data-toggle="modal" data-target="#improve_record_modal" >Improve this record</button>').html_safe, form
          end
        end
      end
    end  
  end

  def parse_qualtrics_survey_into_hml_form(json_survey)
    form = '<form>'
    json_survey['choices'].each do |key, value|
      input_type = value['textEntry'].nil? ? 'checkbox' : 'text' 
      form = form + '<input type="%s" name="%s" value="%s"/> %s' % [input_type, key, value['choiceText'], value['choiceText']]
    end
    (form + '</form>').html_safe
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
