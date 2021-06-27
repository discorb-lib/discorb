require "overloader"
require_relative "common"
require_relative "flag"
require_relative "error"
require_relative "avatar"

module Discorb
  class Embed
    attr_accessor :title, :description, :url, :timestamp, :color, :author, :fields, :footer, :image, :thumbnail

    def initialize(title = nil, description = nil, color = nil, url: nil, timestamp: nil, author: nil, fields: nil, footer: nil, image: nil, thumbnail: nil)
      @title = title
      @description = description
      @url = url
      @timestamp = timestamp
      @color = color
      @author = author
      @fields = fields || []
      @footer = footer
      @image = image
      @thumbnail = thumbnail
    end

    def to_hash
      {
        title: @title,
        description: @description,
        url: @url,
        timestamp: @timestamp&.iso8601,
        color: @color&.to_i,
        footer: @footer&.to_hash,
        image: @image ? { url: @image } : nil,
        thumbnail: @thumbnail ? { url: @thumbnail } : nil,
        author: @author&.to_hash,
        fields: @fields&.map { |f| f.to_hash },
      }
    end

    class Author
      attr_accessor :name, :url, :icon

      def initialize(name, url: nil, icon: nil)
        @name = name
        @url = url
        @icon = icon
      end

      def to_hash
        {
          name: @name,
          url: @url,
          icon_url: @icon,
        }
      end

      def self.[](...)
        self.initialize(...)
      end
    end

    class Footer
      attr_accessor :name, :icon

      def initialize(name, icon: nil)
        @name = name
        @url = url
        @icon = icon
      end

      def to_hash
        {
          name: @name,
          url: @url,
          icon_url: @icon,
        }
      end

      def self.[](...)
        self.initialize(...)
      end
    end

    class Field
      attr_accessor :name, :value, :inline

      def initialize(name, value, inline = false)
        @name = name
        @value = value
        @inline = inline
      end

      def to_hash
        {
          name: @name,
          value: @value,
          inline: @inline,
        }
      end

      def self.[](...)
        self.new(...)
      end
    end
  end
end
