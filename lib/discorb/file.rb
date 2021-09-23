# frozen_string_literal: true

require "mime/types"
require "stringio"

module Discorb
  #
  # Represents a attachment file.
  #
  class Attachment < DiscordModel
    # @return [#read] The file content.
    attr_reader :io
    # @return [Discorb::Snowflake] The attachment id.
    attr_reader :id
    # @return [String] The attachment filename.
    attr_reader :filename
    # @return [String] The attachment content type.
    attr_reader :content_type
    # @return [Integer] The attachment size in bytes.
    attr_reader :size
    # @return [String] The attachment url.
    attr_reader :url
    # @return [String] The attachment proxy url.
    attr_reader :proxy_url
    # @return [Integer] The image height.
    # @return [nil] If the attachment is not an image.
    attr_reader :height
    # @return [Integer] The image width.
    # @return [nil] If the attachment is not an image.
    attr_reader :width

    # @!attribute [r] image?
    #   @return [Boolean] whether the file is an image.

    # @!visibility private
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

  #
  # Represents a file to send as an attachment.
  #
  class File
    # @return [#read] The IO of the file.
    attr_accessor :io
    # @return [String] The filename of the file. If not set, path or object_id of the IO is used.
    attr_accessor :filename
    # @return [String] The content type of the file. If not set, it is guessed from the filename.
    attr_accessor :content_type

    def initialize(io, filename = nil, content_type: nil)
      @io = io
      @filename = filename || (io.respond_to?(:path) ? io.path : io.object_id)
      @content_type = content_type || MIME::Types.type_for(@filename.to_s)[0].to_s
      @content_type = "application/octet-stream" if @content_type == ""
    end

    def self.from_string(string, filename: nil, content_type: nil)
      io = StringIO.new(string)
      new(io, filename, content_type: content_type)
    end
  end
end
