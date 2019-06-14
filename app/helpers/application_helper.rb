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

  def generate_report_button_if_metadata_match(fieldname, field, fieldname_to_check, fieldvalue_to_check, qualtrics_link)
    if fieldname == fieldname_to_check and field == fieldvalue_to_check 
      ('<button type="button" class="btn btn-dark dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Report this record</button>').html_safe
    end
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
