# frozen_string_literal: true

module Discorb
  class Asset < DiscordModel
    # @return [String] The hash of asset.
    attr_reader :hash

    # @!visibility private
    def initialize(target, hash, path: nil)
      @hash = hash
      @target = target
      @path = path
    end

    #
    # Whether the asset is animated.
    #
    # @return [Boolean] Whether the asset is animated.
    #
    def animated?
      @hash.start_with? 'a_'
    end

    #
    # URL of the asset.
    #
    # @param [String] image_format The image format.
    # @param [Integer] size The size of the image.
    #
    # @return [String] URL of the asset.
    #
    def url(image_format: nil, size: 1024)
      "https://cdn.discordapp.com/#{endpoint}/#{@target.id}/#{@hash}.#{image_format or (animated? ? 'gif' : 'webp')}?size=#{size}"
    end

    def inspect
      "#<#{self.class} #{@target.class} #{@hash}>"
    end

    private

    def endpoint
      @path || case @target
               when User, Member, Webhook
                 'avatars'
               when Guild, IncomingWebhook::Guild
                 'icons'
               when Application
                 'app-icons'
               when Application::Team
                 'team-icons'
               end
    end
  end
end
