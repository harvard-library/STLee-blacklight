module ImagesHelper
  # Example usage:
  #
  #   image_set_tag_3x "foo@1x.png", alt: "foo"
  #
  # Will assume there is a 2x and 3x version and provide those automagically.
  #
  # Based on https://gist.github.com/mrreynolds/4fc71c8d09646567111f
  # From https://gist.github.com/henrik/2ddcc6ab8c66e7c49305
  def image_set_tag_3x(source, options = {})
    x = [ 2, 3 ].map { |num|
      name = source.sub('@1x.', "@#{num}x.")
      "#{path_to_image(name)} #{num}x"
    }

    srcset = x.join(", ")

    image_tag(source, options.merge(srcset: srcset))
  end
end