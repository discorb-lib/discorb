require 'base64'

module Discorb
  class Image
    def initialize(bytes, type)
      @bytes = bytes
      @type = type
    end

    def to_s
      "data:image/#{@type};base64,#{Base64.strict_encode64(@bytes)}"
    end
  end
end
