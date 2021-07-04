# frozen_string_literal: true

require 'overloader'
require_relative 'common'
require_relative 'flag'
require_relative 'error'
require_relative 'color'

module Discorb
  class Embed
    attr_accessor :title, :description, :url, :timestamp, :color, :author, :fields, :footer
    attr_reader :image, :thumbnail, :type

    def initialize(title = nil, description = nil, color: nil, url: nil, timestamp: nil, author: nil, fields: nil, footer: nil, image: nil, thumbnail: nil, data: nil)
      if data.nil?
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
        @type = 'rich'
      else
        @title = data[:title]
        @description = data[:description]
        @url = data[:url]
        @timestamp = data[:timestamp] ? Time.iso8601(data[:timestamp]) : nil
        @type = data[:type]
        @color = data[:color] ? Color.new(data[:color]) : nil
        @footer = data[:footer] ? Footer.new(**data[:footer]) : nil
        @author = data[:author] ? Author.new(**data[:author]) : nil
        @thumbnail = data[:thumbnail] ? Thumbnail.new(data[:thumbnail]) : nil
        @image = data[:image] ? Image.new(data[:image]) : nil
        @video = data[:video] ? Video.new(data[:video]) : nil
        @provider = data[:provider] ? Provider.new(data[:provider]) : nil
        @fields = data[:fields] ? data[:fields].map { |f| Field.new(**f) } : []
      end
    end

    def image=(value)
      @image = Image.new(value) if value.is_a? String
    end

    def thumbnail=(value)
      @thumbnail = Thumbnail.new(value) if value.is_a? String
    end

    def to_hash
      {
        title: @title,
        description: @description,
        url: @url,
        timestamp: @timestamp&.iso8601,
        color: @color&.to_i,
        footer: @footer&.to_hash,
        image: @image&.to_hash,
        thumbnail: @thumbnail&.to_hash,
        author: @author&.to_hash,
        fields: @fields&.map { |f| f.to_hash }
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
          icon_url: @icon
        }
      end

      def self.[](...)
        initialize(...)
      end
    end

    class Footer
      attr_accessor :name, :icon

      def initialize(name, icon: nil)
        @name = name
        @icon = icon
      end

      def to_hash
        {
          name: @name,
          icon_url: @icon
        }
      end

      def self.[](...)
        initialize(...)
      end
    end

    class Field
      attr_accessor :name, :value, :inline

      def initialize(name, value, inline: true)
        @name = name
        @value = value
        @inline = inline
      end

      def to_hash
        {
          name: @name,
          value: @value,
          inline: @inline
        }
      end

      def self.[](...)
        new(...)
      end
    end

    class Image
      attr_accessor :url
      attr_reader :proxy_url, :height, :width

      def initialize(data)
        if data.is_a? String
          @url = data
        else
          @url = data[:url]
          @proxy_url = data[:proxy_url]
          @height = data[:height]
          @width = data[:width]
        end
      end

      def to_hash
        { url: @url }
      end
    end

    class Thumbnail
      attr_accessor :url
      attr_reader :proxy_url, :height, :width

      def initialize(data)
        if data.is_a? String
          @url = data
        else
          @url = data[:url]
          @proxy_url = data[:proxy_url]
          @height = data[:height]
          @width = data[:width]
        end
      end

      def to_hash
        { url: @url }
      end
    end

    class Video
      attr_reader :url, :proxy_url, :height, :width

      def initialize(data)
        @url = data[:url]
        @proxy_url = data[:proxy_url]
        @height = data[:height]
        @width = data[:width]
      end
    end

    class Provider
      attr_reader :name, :url

      def initialize(name, url)
        @name = name
        @url = url
      end
    end
  end
end
