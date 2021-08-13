# frozen_string_literal: true

require_relative 'common'
require_relative 'user'
require_relative 'member'
require_relative 'guild'

module Discorb
  class Asset < DiscordModel
    attr_reader :hash

    def initialize(target, hash)
      @hash = hash
      @target = target
    end

    def animated?
      @hash.start_with? 'a_'
    end

    def url(image_format: nil, size: 1024)
      "https://cdn.discordapp.com/#{endpoint}/#{@target.id}/#{@hash}.#{image_format or (animated? ? 'gif' : 'webp')}?size=#{size}"
    end

    def inspect
      "#<#{self.class} #{@target.class} #{@hash}>"
    end

    private

    def endpoint
      case @target
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
