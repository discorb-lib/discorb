# frozen_string_literal: true

require "mime/types"
require "stringio"

module Discorb
  #
  # Represents a attachment file.
  #
  class Attachment
    # @return [#read] The file content.
    attr_reader :io
    # @return [String] The attachment filename.
    attr_reader :filename
    # @return [String] The attachment content type.
    attr_reader :content_type
    # @return [String] The attachment description.
    attr_reader :description
    # @return [Discorb::Snowflake] The attachment id.
    attr_reader :id
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
    # @return [:client, :discord] The attachment was created by.
    attr_reader :created_by
    # @private
    # @return [Boolean] Whether the attachment will be closed after it is sent.
    attr_reader :will_close

    # @!attribute [r] image?
    #   @return [Boolean] whether the file is an image.

    #
    # Creates a new attachment.
    #
    # @param [#read, String] source The Source of the attachment.
    # @param [String] filename The filename of the attachment. If not set, path or object_id of the IO is used.
    # @param [String] description The description of the attachment.
    # @param [String] content_type The content type of the attachment. If not set, it is guessed from the filename.
    #   If failed to guess, it is set to `application/octet-stream`.
    # @param [Boolean] will_close Whether the IO will be closed after the attachment is sent.
    #
    def initialize(
      source,
      filename = nil,
      description: nil,
      content_type: nil,
      will_close: true
    )
      @io = (source.respond_to?(:read) ? source : File.open(source, "rb"))
      @filename =
        filename || (@io.respond_to?(:path) ? @io.path : @io.object_id)
      @description = description
      @content_type =
        content_type || MIME::Types.type_for(@filename.to_s)[0].to_s
      @content_type = "application/octet-stream" if @content_type == ""
      @will_close = will_close
      @created_by = :client
    end

    #
    # Initializes the object from a hash.
    # @private
    #
    def initialize_hash(data)
      @id = Snowflake.new(data[:id])
      @filename = data[:filename]
      @content_type = data[:content_type] || "application/octet-stream"
      @size = data[:size]
      @url = data[:url]
      @proxy_url = data[:proxy_url]
      @height = data[:height]
      @width = data[:width]
      @created_by = :discord
    end

    def image?
      @content_type.start_with? "image/"
    end

    def inspect
      if @created_by == :discord
        "<#{self.class} #{@id}: #{@filename}>"
      else
        "<#{self.class} #{io.fileno}: #{@filename}>"
      end
    end

    #
    # Creates a new file from a hash.
    # @private
    #
    def self.from_hash(data)
      inst = allocate
      inst.initialize_hash(data)
      inst
    end

    #
    # Creates a new file from a string.
    #
    # @param [String] string The string to create the file from.
    # @param [String] filename The filename of the file. object_id of the string is used if not set.
    # @param [String] content_type The content type of the file. If not set, it is guessed from the filename.
    #
    # @return [Discorb::Attachment] The new file.
    #
    def self.from_string(
      string,
      filename = nil,
      content_type: nil,
      description: nil
    )
      io = StringIO.new(string)
      filename ||= "#{string.object_id}.txt"
      new(
        io,
        filename,
        content_type: content_type,
        description: description,
        will_close: true
      )
    end
  end
end
