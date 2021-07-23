# frozen_string_literal: true

require 'time'
require_relative 'common'
require_relative 'member'
require_relative 'channel'
require_relative 'components'
require_relative 'flag'
require_relative 'error'
require_relative 'file'
require_relative 'embed'
require_relative 'reaction'

module Discorb
  class MessageFlag < Flag
    @bits = {
      crossposted: 0,
      crosspost: 1,
      supress_embeds: 2,
      source_message_deleted: 3,
      urgent: 4,
      has_thread: 5,
      ephemeral: 6,
      loading: 7
    }.freeze
  end

  class MessageReference
    attr_accessor :guild_id, :channel_id, :message_id, :fail_if_not_exists
    alias fail_if_not_exists? fail_if_not_exists

    def initialize(guild_id, channel_id, message_id, fail_if_not_exists: true)
      @guild_id = guild_id
      @channel_id = channel_id
      @message_id = message_id
      @fail_if_not_exists = fail_if_not_exists
    end

    def to_hash
      {
        message_id: @message_id,
        channel_id: @channel_id,
        guild_id: @guild_id,
        fail_if_not_exists: @fail_if_not_exists
      }
    end

    alias to_reference to_hash

    def self.from_hash(data)
      new(data[:guild_id], data[:channel_id], data[:message_id], fail_if_not_exists: data[:fail_if_not_exists])
    end
  end

  class AllowedMentions
    attr_accessor :everyone, :roles, :users, :replied_user

    def initialize(everyone: nil, roles: nil, users: nil, replied_user: nil)
      @everyone = everyone
      @roles = roles
      @users = users
      @replied_user = replied_user
    end

    def to_hash(other = nil)
      payload = {
        parse: %w[everyone roles users]
      }
      replied_user = nil_merge(@replied_user, other&.replied_user)
      everyone = nil_merge(@everyone, other&.everyone)
      roles = nil_merge(@roles, other&.roles)
      users = nil_merge(@users, other&.users)
      payload[:replied_user] = replied_user
      payload[:parse].delete('everyone') if everyone == false
      if (roles == false) || roles.is_a?(Array)
        payload[:roles] = roles.map { |u| u.id.to_s } if roles.is_a? Array
        payload[:parse].delete('roles')
      end
      if (users == false) || users.is_a?(Array)
        payload[:users] = users.map { |u| u.id.to_s } if users.is_a? Array
        payload[:parse].delete('users')
      end
      payload
    end

    def nil_merge(*args)
      args.each do |a|
        return a unless a.nil?
      end
      nil
    end
  end

  class Message < DiscordModel
    attr_reader :client, :id, :author, :content, :created_at, :updated_at, :mentions, :mention_roles,
                :mention_channels, :attachments, :embeds, :reactions,                :webhook_id, :type,
                :activity, :application, :application_id, :message_reference, :flag, :stickers, :referenced_message,
                :interaction, :thread, :components

    @message_type = {
      default: 0,
      recipient_add: 1,
      recipient_remove: 2,
      call: 3,
      channel_name_change: 4,
      channel_icon_change: 5,
      channel_pinned_message: 6,
      guild_member_join: 7,
      user_premium_guild_subscription: 8,
      user_premium_guild_subscription_tier_1: 9,
      user_premium_guild_subscription_tier_2: 10,
      user_premium_guild_subscription_tier_3: 11,
      channel_follow_add: 12,
      guild_discovery_disqualified: 14,
      guild_discovery_requalified: 15,
      guild_discovery_grace_period_initial_warning: 16,
      guild_discovery_grace_period_final_warning: 17,
      thread_created: 18,
      reply: 19,
      application_command: 20,
      thread_starter_message: 21,
      guild_invite_reminder: 22
    }.freeze

    def initialize(client, data)
      @client = client
      @_data = {}
      _set_data(data)
    end

    def update!
      Async do
        _, data = @client.get("/channels/#{@channel_id}/messages/#{@id}").wait
        _set_data(data)
      end
    end

    def channel
      @client.channels[@channel_id]
    end

    def guild
      @client.guilds[@guild_id]
    end

    def deleted?
      @deleted
    end

    def tts?
      @tts
    end

    def mention_everyone?
      @mention_everyone
    end

    def pinned?
      @pinned
    end

    def webhook?
      webhook_id != nil
    end

    def to_s
      @content
    end

    def jump_url
      "https://discord.com/channels/#{guild&.id || '@me'}/#{channel.id}/#{@id}"
    end

    def to_reference(fail_if_not_exists: true)
      {
        message_id: @id,
        channel_id: @channel_id,
        guild_id: @guild_id,
        fail_if_not_exists: fail_if_not_exists
      }
    end

    # HTTP

    def reply(*args, **kwargs)
      Async do |_task|
        channel.post(*args, message_reference: self, **kwargs)
      end
    end

    def publish
      Async do |_task|
        channel.post("/channels/#{@channel_id}/messages/#{@id}/crosspost", nil)
      end
    end

    def add_reaction(emoji)
      Async do |_task|
        @client.internet.put("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me", nil).wait
      end
    end

    def remove_reaction(emoji)
      Async do |_task|
        @client.internet.delete("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me", nil).wait
      end
    end

    def remove_reaction_of(emoji, member)
      Async do |_task|
        @client.internet.delete("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/#{member.is_a?(Member) ? member.id : member}", nil).wait
      end
    end
    # Meta

    def inspect
      "#<#{self.class} #{@content.inspect} id=#{@id}>"
    end

    def _set_data(data)
      @id = Snowflake.new(data[:id])

      @channel_id = data[:channel_id]
      @guild_id = data[:guild_id]
      @author = if data[:member].nil?
                  guild.members[data[:author][:id]]
                else
                  Member.new(@client,
                             @guild_id, data[:author], data[:member])
                end
      @content = data[:content]
      @created_at = Time.iso8601(data[:timestamp])
      @updated_at = data[:edited_timestamp].nil? ? nil : Time.iso8601(data[:edited_timestamp])

      @tts = data[:tts]
      @mention_everyone = data[:mention_everyone]
      @mention_roles = data[:mention_roles].map { |r| guild.roles[r] }
      @attachments = data[:attachments].map { |a| Attachment.new(a) }
      @embeds = data[:embeds] ? data[:embeds].map { |e| Embed.new(data: e) } : []
      @reactions = data[:reactions] ? data[:reactions].map { |r| Reaction.new(@client, r) } : []
      @pinned = data[:pinned]
      @type = self.class.message_type[data[:type]]
      @activity = nil # TODO: Discorb::MessageActivity
      @application = nil # TODO: Discorb::Application
      @application_id = data[:application_id]
      @message_reference = data[:message_reference] ? MessageReference.from_hash(data[:message_reference]) : nil
      @flag = MessageFlag.new(0b111 - data[:flags])
      @sticker = nil # TODO: Discorb::Sticker
      @referenced_message = data[:referenced_message] ? Message.new(@client, data[:referenced_message]) : nil
      @interaction = nil # TODO: Discorb::InterctionFeedback
      @thread = data[:thread]&.map { |t| Channel.make_channel(@client, t) }
      @components = data[:components].map { |c| c[:components].map { |co| Component.from_hash(co) } }
      @_data.update(data)
      @deleted = false
    end

    class << self
      attr_reader :message_type
    end
  end
end
