Blacklight::Controller.module_eval do
  def render_bookmarks_control?
    Blacklight::CatalogHelperBehavior.enable_bookmarks?
  end
end 