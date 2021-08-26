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
    # @param [#read] source The source of the image.
    # @param [String] type The MIME type of the image.
    # @overload
    #   @param [String] source The file path of the source.
    #   @param [String] type The MIME type of the image.
    #
    def initialize(source, type = nil)
      if source.respond_to?(:read)
        @bytes = source.read
        @type = type || MIME::Types.type_for(source.path).first.content_type
      elsif ::File.exist?(source)
        ::File.open(source, "rb") do |file|
          @bytes = file.read
        end
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
      "data:#{@type};base64,#{Base64.strict_encode64(@bytes)}"
    end
  end
end
