# frozen_string_literal: true

require_relative 'common'
require_relative 'user'

module Discorb
  class Invite < DiscordModel
    attr_reader :code, :target_type, :target_user, :target_application,
                :approximate_presence_count, :approximate_member_count,
                :expires_at, :stage_instance, :uses, :max_uses, :max_age, :temporary, :created_at

    @target_types = {
      nil => :voice,
      1 => :stream,
      2 => :guild
    }.freeze
    def initialize(client, data, gateway)
      @client = client
      @data = data[:data]
      _set_data(data, gateway)
    end

    def channel
      @client.channels[@channel_data[:id]]
    end

    def guild
      @client.guilds[@guild_data[:id]]
    end

    def url
      "https://discord.gg/#{@code}"
    end

    def delete!(reason: nil)
      Async do
        @client.internet.delete("/invites/#{@code}", audit_log_reason: reason)
      end
    end

    private

    def _set_data(data, gateway)
      @code = data[:code]
      if gateway
        @channel_data = { id: data[:channel_id] }
        @guild_data = { id: data[:guild_id] }
      else
        @guild_data = data[:guild]
        @channel_data = data[:channel]
        @approximate_presence_count = data[:approximate_presence_count]
        @approximate_member_count = data[:approximate_member_count]
        @expires_at = data[:expires_at] && Time.iso8601(data[:expires_at])
      end
      @inviter_data = data[:inviter]
      @target_type = self.class.target_types[data[:target_type]]
      @target_user = @client.users[data[:target_user][:id]] || User.new(@client, data[:target_user]) if data[:target_user]
      @target_application = nil # TODO: Application

      # @stage_instance = data[:stage_instance] && Invite::StageInstance.new(self, data[:stage_instance])
      return unless data.key?(:uses)

      @uses = data[:uses]
      @max_uses = data[:max_uses]
      @max_age = data[:max_age]
      @temporary = data[:temporary]
      @created_at = Time.iso8601(data[:created_at])
    end

    # class StageInstance
    #   def initialize(invite, data)
    #     @invite = invite
    #     @topic = data[:topic]
    #     @participant_count = data[:participant_count]
    #     @speaker_count = data[:speaker_count]
    #     @members = data[:members].map do |member_data|
    #       next member if (member = invite.guild&.members&.[](member_data[:id]))

    #       Invite::StageInstance::Member.new(member)
    #     end
    #   end

    #   class Member
    #     attr_reader :roles, :nick, :avatar, :premium_since, :joined_at

    #     def initialize(data)

    #       @roles = data[:roles].map { |role| Snowflake.new(role) }
    #       @nick = data[:nick]
    #       @avatar = Asset.new(self, data[:avatar])
    #       @premium_since = data[:premium_since] && Time.iso8601(data[:premium_since])
    #       @joined_at = Time.iso8601(data[:joined_at])
    #       @pending = data[:pending]
    #     end
    #   end
    # end

    class << self
      attr_reader :target_types
    end
  end
end
