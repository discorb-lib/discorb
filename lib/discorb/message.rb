require "time"
require_relative "common"
require_relative "member"
require_relative "channel"
require_relative "flag"
require_relative "error"

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
      loading: 7,
    }
  end

  class MessageReference
    attr_accessor :guild_id, :channel_id, :message_id, :fail_if_not_exists
    alias_method :fail_if_not_exists?, :fail_if_not_exists

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
        fail_if_not_exists: @fail_if_not_exists,
      }
    end

    alias_method :to_reference, :to_hash

    def self.from_hash(data)
      self.new(data[:guild_id], data[:channel_id], data[:message_id], fail_if_not_exists: data[:fail_if_not_exists])
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
        parse: ["everyone", "roles", "users", "replied_user"],
      }
      replied_user = nil_merge(@replied_user, other&.replied_user)
      everyone = nil_merge(@everyone, other&.everyone)
      roles = nil_merge(@roles, other&.roles)
      users = nil_merge(@users, other&.users)
      if replied_user == false
        payload[:parse].delete("replied_user")
      end
      if everyone == false
        payload[:parse].delete("everyone")
      end
      if roles == false or roles.is_a? Array
        if roles.is_a? Array
          payload[:roles] = roles.map { |u| u.id.to_s }
        end
        payload[:parse].delete("roles")
      end
      if users == false or users.is_a? Array
        if users.is_a? Array
          payload[:users] = users.map { |u| u.id.to_s }
        end
        payload[:parse].delete("users")
      end
      payload
    end

    def nil_merge(*args)
      args.each do |a|
        if a != nil
          return a
        end
      end
      return nil
    end
  end

  class Message < DiscordModel
    attr_reader :client, :id, :author, :content, :created_at, :updated_at, :mentions, :mention_roles, :mention_channels, :attachments, :embeds, :reactions,
                :webhook_id, :type, :activity, :application, :application_id, :message_reference, :flag, :stickers, :referenced_message, :interaction, :thread, :components
    @@message_type = {
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
      guild_invite_reminder: 22,
    }

    def initialize(client, data)
      @client = client
      set_data(data)
    end

    def update!()
      Async do
        _, data = @client.get("/users/#{@id}").wait
        set_data(data)
      end
    end

    def channel
      @client.channels[@channel_id]
    end

    def guild
      @client.guilds[@guild_id]
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

    def to_reference(fail_if_not_exists: true)
      {
        message_id: @id,
        channel_id: @channel_id,
        guild_id: @guild_id,
        fail_if_not_exists: fail_if_not_exists,
      }
    end

    def reply(*args, **kwargs)
      self.channel.post(*args, message_reference: self, **kwargs)
    end

    def add_reaction(emoji)
      Async do |task|
        @client.internet.put("/channels/#{@channel_id}/messages/#{@id}/reactions/#{emoji.to_uri}/@me", nil)
      end
    end

    def inspect
      "#<#{self.class} #{@content.inspect} id=#{@id}>"
    end

    private

    def set_data(data)
      @id = data[:id].to_i
      @author = Member.new(@client, data[:author], data[:member])
      @channel_id = data[:channel_id]
      @guild_id = data[:guild_id]
      @content = data[:content]
      @created_at = data[:timestamp]
      @updated_at = data[:edited_timestamp]

      @tts = data[:tts]
      @mention_everyone = data[:mention_everyone]
      @mention_roles = nil # TODO: Array<Discorb::Role>
      @attachments = nil # TODO: Array<Discorb::Attachment>
      @embeds = nil # TODO: Array<Discorb::Embed>
      @reactions = nil # TODO: Array<Discorb::Reaction>
      @pinned = data[:pinned]
      @type = @@message_type[data[:type]]
      @activity = nil # TODO: Discorb::MessageActivity
      @application = nil # TODO: Discorb::Application
      @application_id = data[:application_id]
      @message_reference = data[:message_reference] ? MessageReference.from_hash(data[:message_reference]) : nil # TODO: Discorb::MessageReference
      @flag = MessageFlag.new(0b111 - data[:flags])
      @sticker = nil # TODO: Discorb::Sticker
      @referenced_message = data[:referenced_message] ? Message.new(@client, data[:referenced_message]) : nil
      @interaction = nil # TODO: Discorb::InterctionFeedback
      @thread = nil # TODO: Discorb::Thread
      @components = nil # TODO: Array<Discorb::Components>
    end

    # :activity, :application, :application_id, :message_reference, :flag, :stickers, :referenced_message, :interaction, :thread, :components
  end
end
