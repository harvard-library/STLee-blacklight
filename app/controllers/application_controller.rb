class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  protect_from_forgery with: :exception

  protected

  def after_sign_in_path_for(resource)
    "/catalog?search_field=all_fields&q="
  end

  def after_sign_out_path_for(resource)
    "/catalog?search_field=all_fields&q="
  end
end
