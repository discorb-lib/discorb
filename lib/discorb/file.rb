# frozen_string_literal: true

require 'mime/types'

module Discorb
  class Attachment
    attr_reader :io, :id, :filename, :content_type, :size, :url, :proxy_url, :height, :width

    def initialize(io, filename: nil, content_type: nil)
      if io.is_a? Hash
        data = io
        @id = Snowflake.new(data[:id])
        @filename = data[:filename]
        @content_type = data[:content_type]
        @size = data[:size]
        @url = data[:url]
        @proxy_url = data[:proxy_url]
        @height = data[:height]
        @width = data[:width]
      else
        class << self
          attr_writer :io
        end

        class << self
          attr_writer :filename
        end

        class << self
          attr_writer :content_type
        end
        @io = io
        @filename = filename || (io.respond_to?(:path) ? io.path : object_id)
        @content_type = content_type || MIME::Types.type_for(@filename)[0].to_s
        @content_type = 'application/octet-stream' if @content_type == ''
      end
    end

    def image?
      @content_type.start_with? 'image/'
    end
  end
end
