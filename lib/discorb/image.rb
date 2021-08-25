# frozen_string_literal: true

require "base64"
require "mime/types"

module Discorb
  class Image
    def initialize(source, type = nil)
      if ::File.exist?(source)
        ::File.open(source, "rb") do |file|
          @bytes = file.read
        end
        @type = MIME::Types.type_for(source).first.to_s
      elsif type.nil?
        raise ArgumentError, "File not found and type is not specified"
      else
        @bytes = bytes
        @type = "image/#{type}"
      end
    end

    def to_s
      "data:#{@type};base64,#{Base64.strict_encode64(@bytes)}"
    end
  end
end
