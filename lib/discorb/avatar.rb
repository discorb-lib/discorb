require_relative 'common'

module Discorb
  class Avatar < DiscordModel
    attr_reader :hash

    def initialize(user, hash)
      @hash = hash
      @user = user
    end

    def animated?
      @hash.start_with? 'a_'
    end

    def url(image_format: nil, size: 1024)
      "https://cdn.discordapp.com/avatars/#{@user.id}/#{@hash}.#{image_format or (animated? ? 'gif' : 'webp')}?size=#{size}"
    end
  end
end
