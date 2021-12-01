# frozen_string_literal: true

require "base64"
require "mime/types"

module Discorb
  #
  # Represents an image.
  #
  class Image
    #
    # Initializes a new Image.
    #
    # @param [#read, String] source The IO source or path of the image.
    # @param [String] type The MIME type of the image.
    #
    def initialize(source, type = nil)
      if source.respond_to?(:read)
        @io = source
        @type = type || MIME::Types.type_for(source.path).first.content_type
      elsif ::File.exist?(source)
        @io = ::File.open(source, "rb")
        @type = MIME::Types.type_for(source).first.to_s
      else
        raise ArgumentError, "Couldn't read file."
      end
    end

    #
    # Formats the image as a Discord style.
    #
    # @return [String] The image as a Discord style.
    #
    def to_s
      "data:#{@type};base64,#{Base64.strict_encode64(@io.read)}"
    end

    def inspect
      "#<#{self.class} #{@type}>"
    end
  end
end
