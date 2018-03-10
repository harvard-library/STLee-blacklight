module ApplicationHelper

  def hash_as_list val
    val.kind_of?(Hash) ? [val] : val
  end

  def add_to_collection_solr_document_path (arg)
    "hello"
  end

end
