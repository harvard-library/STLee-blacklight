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

  def generate_tour_modal_link(documentType)
    if documentType == 'pds'
        ('<div id="take-a-tour" style:"display:block;"><p><a id="take-a-tour-link" data-toggle="modal" data-target="#take_a_tour_modal">Take a tour of the viewer</a></p></div>').html_safe
    end
  end

  def generate_tour_modal_html(documentType)
    if documentType == 'pds'
      ('<div class="modal fade" id="take_a_tour_modal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-header no-border">
              <div class="modal-title" id="exampleModalLabel">Tour the viewer</div>
              <button type="button" class="close modal-button" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body" id="modal-body-content">
              <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRtpx-naAyksS0J5Jboe84367F4WXnS4gKabW0LiEihlft5HZCoO9dalZhrMVw7SUgvBDYEDrNpYvh1/embed?start=true&loop=true&delayms=10000" id="embedded-viewer-tour-presentation" frameborder="0" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
            </div>
          </div>
        </div>
      </div>').html_safe
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
            base_img_url = res['sequences'][0]['canvases'][0]['thumbnail']['@id']
          end
        end
      end
      (twitter_meta_tags % base_img_url).html_safe
    end
end
