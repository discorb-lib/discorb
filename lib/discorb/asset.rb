# frozen_string_literal: true

module Discorb
  #
  # Represents a single asset.
  #
  class Asset < DiscordModel
    # @return [String] The hash of asset.
    attr_reader :hash

    # @!attribute [r] animated?
    #   @return [Boolean] Whether the asset is animated.

    #
    # Initialize a new instance of the Asset class.
    # @private
    #
    # @param [Discorb::Client] client The client that instantiated the object.
    # @param [Hash] data The data of the object.
    #
    def initialize(target, hash, path: nil)
      @hash = hash
      @target = target
      @path = path
    end

    def animated?
      @hash.start_with? "a_"
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
      path = @path || "#{endpoint}/#{@target.id}"
      "https://cdn.discordapp.com/#{path}/#{@hash}.#{image_format or (animated? ? "gif" : "webp")}?size=#{size}"
    end

    def inspect
      "#<#{self.class} #{@target.class} #{@hash}>"
    end

    private

    def endpoint
      case @target
      when User, Member, Webhook
        "avatars"
      when Guild, Webhook::FollowerWebhook::Guild
        "icons"
      when Application, Integration::Application
        "app-icons"
      when Application::Team
        "team-icons"
      end
    end
  end

  #
  # Represents a default avatar.
  #
  class DefaultAvatar < DiscordModel
    # @!attribute [r] animated?
    #   @return [false] For compatibility with {Asset}, always `false`.

    #
    # Initialize a new instance of the DefaultAvatar class.
    # @private
    #
    def initialize(discriminator)
      @discriminator = discriminator.to_s.rjust(4, "0")
    end

    def animated?
      false
    end

    #
    # Returns the URL of the avatar.
    #
    # @param [String] image_format The image format. This is compatible with {Asset#url}, will be ignored.
    # @param [Integer] size The size of the image. This is compatible with {Asset#url}, will be ignored.
    #
    # @return [String] URL of the avatar.
    #
    # rubocop: disable Lint/UnusedMethodArgument
    def url(image_format: nil, size: 1024)
      # rubocop: enable Lint/UnusedMethodArgument
      "https://cdn.discordapp.com/embed/avatars/#{@discriminator.to_i % 5}.png"
    end

    def inspect
      "#<#{self.class} #{@discriminator}>"
    end
  end
end
