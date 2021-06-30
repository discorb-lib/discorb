# frozen_string_literal: true

module Discorb
  class Attachment
    attr_reader :id, :filename, :content_type, :size, :url, :proxy_url, :height, :width

    def initialize(data)
      @id = Snowflake.new(data[:id])
      @filename = data[:filename]
      @content_type = data[:content_type]
      @size = data[:size]
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @height = data[:height]
      @width = data[:width]
    end

    def image?
      @content_type.start_with? "image/"
    end
  end
end
