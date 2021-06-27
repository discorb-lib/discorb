require "time"
require_relative "common"
require_relative "member"
require_relative "channel"
require_relative "flag"
require_relative "error"

module Discorb
  class MessageFlag < Flag
    @bits = {
      discord_employee: 0,
      partnered_server_owner: 1,
      hypesquad_events: 2,
      bug_hunter_level_1: 3,
      house_bravery: 6,
      house_brilliance: 7,
      house_balance: 8,
      early_supporter: 9,
      team_user: 10,
      bug_hunter_level_2: 14,
      verified_bot: 16,
      early_verified_bot_developer: 17,
      discord_certified_moderator: 18,
    }
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
      @mention_channels = nil # TODO: Array<Discorb::Channel>
      @attachments = nil # TODO: Array<Discorb::Attachment>
      @embeds = nil # TODO: Array<Discorb::Embed>
      @reactions = nil # TODO: Array<Discorb::Reaction>
      @pinned = data[:pinned]
      @type = @@message_type[data[:type]]
      @activity = nil # TODO: Discorb::MessageActivity
      @application = nil # TODO: Discorb::Application
      @application_id = data[:application_id]
      @message_reference = nil # TODO: Discorb::MessageReference
      @flag = MessageFlag.new(0b100 - data[:flags])
      @sticker = nil # TODO: Discorb::Sticker
      @referenced_message = data[:referenced_message] ? Message.new(@client, data[:referenced_message]) : nil
      @interaction = nil # TODO: Discorb::InterctionFeedback
      @thread = nil # TODO: Discorb::Thread
      @components = nil # TODO: Array<Discorb::Components>
    end

    # :activity, :application, :application_id, :message_reference, :flag, :stickers, :referenced_message, :interaction, :thread, :components
  end
end
