module ApplicationHelper

  def hash_as_list val
    val.kind_of?(Hash) ? [val] : val
  end

end
