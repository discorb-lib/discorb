# frozen_string_literal: true

module Discorb
  class AuditLog < DiscordModel
    attr_reader :webhooks, :users, :threads, :entries

    def initialize(client, data, guild)
      @client = client
      @guild = guild
      @webhooks = data[:webhooks].map { |webhook| Webhook.new([@client, webhook]) }
      @users = data[:users].map { |user| client.users[user[:id]] || User.new(@client, user) }
      @threads = data[:threads].map { |thread| client.channels[thread[:id]] || Channel.make_channel(@client, thread, no_cache: true) }
      @entries = data[:audit_log_entries].map { |entry| AuditLog::Entry.new(@client, entry, guild.id) }
    end

    def [](index)
      @entries[index]
    end

    class Entry < DiscordModel
      attr_reader :id, :user_id, :target_id, :type, :changes, :target

      @events = {
        1 => :guild_update,
        10 => :channel_create,
        11 => :channel_update,
        12 => :channel_delete,
        13 => :channel_overwrite_create,
        14 => :channel_overwrite_update,
        15 => :channel_overwrite_delete,
        20 => :member_kick,
        21 => :member_prune,
        22 => :member_ban_add,
        23 => :member_ban_remove,
        24 => :member_update,
        25 => :member_role_update,
        26 => :member_move,
        27 => :member_disconnect,
        28 => :bot_add,
        30 => :role_create,
        31 => :role_update,
        32 => :role_delete,
        40 => :invite_create,
        41 => :invite_update,
        42 => :invite_delete,
        50 => :webhook_create,
        51 => :webhook_update,
        52 => :webhook_delete,
        60 => :emoji_create,
        61 => :emoji_update,
        62 => :emoji_delete,
        72 => :message_delete,
        73 => :message_bulk_delete,
        74 => :message_pin,
        75 => :message_unpin,
        80 => :integration_create,
        81 => :integration_update,
        82 => :integration_delete,
        83 => :stage_instance_create,
        84 => :stage_instance_update,
        85 => :stage_instance_delete,
        90 => :sticker_create,
        91 => :sticker_update,
        92 => :sticker_delete,
        110 => :thread_create,
        111 => :thread_update,
        112 => :thread_delete
      }.freeze
      @converts = {
        channel: ->(client, id, _guild_id) { client.channels[id] },
        thread: ->(client, id, _guild_id) { client.channels[id] },
        role: ->(client, id, guild_id) { client.guilds[guild_id]&.roles&.[](id) },
        member: ->(client, id, guild_id) { client.guilds[guild_id]&.members&.[](id) },
        guild: ->(client, id, _guild_id) { client.guilds[id] },
        message: ->(client, id, _guild_id) { client.messages[id] }
      }
      def initialize(client, data, guild_id)
        @client = client
        @guild_id = Snowflake.new(guild_id)
        @id = Snowflake.new(data[:id])
        @user_id = Snowflake.new(data[:user_id])
        @target_id = Snowflake.new(data[:target_id])
        @type = self.class.events[data[:action_type]]
        @target = self.class.converts[@type.to_s.split('_')[0].to_sym]&.call(client, @target_id, @gui)
        @target ||= Snowflake.new(data[:target_id])
        @changes = data[:changes] && Changes.new(data[:changes])
        @reason = data[:reason]
      end

      def user
        @client.users[@user_id]
      end

      def [](key)
        @changes[key]
      end

      def inspect
        "#<#{self.class} #{@changes&.data&.length || 'No'} changes>"
      end

      class << self
        attr_reader :events, :converts
      end

      class Changes < DiscordModel
        attr_reader :data

        def initialize(data)
          @data = data.map { |d| [d[:key].to_sym, d] }.to_h
          @data.each do |k, v|
            define_singleton_method(k) { Change.new(v) }
          end
        end

        def inspect
          "#<#{self.class} #{@data.length} changes>"
        end

        def keys
          @data.keys
        end

        def [](key)
          @data[key.to_sym]
        end
      end

      class Change < DiscordModel
        attr_reader :key, :old_value, :new_value

        def initialize(data)
          @key = data[:key].to_sym
          method = case @key.to_s
                   when /.*_id$/, 'id'
                     ->(v) { Snowflake.new(v) }
                   when 'permissions'
                     ->(v) { Discorb::Permission.new(v.to_i) }
                   else
                     ->(v) { v }
                   end
          @old_value = data[:old_value].then(&method)
          @new_value = data[:new_value].then(&method)
        end

        def method_missing(method, ...)
          @new_value.__send__(method, ...)
        end

        def inspect
          "#<#{self.class} #{@key.inspect}>"
        end

        def respond_to_missing?(method, include_private = false)
          @new_value.respond_to?(method, include_private)
        end
      end
    end

    class Integration < DiscordModel
      attr_reader :id, :type, :name, :account

      def initialize(data)
        @id = Snowflake.new(data[:id])
        @type = data[:type].to_sym
        @name = data[:name]
        @data = data
        @account = Discorb::Integration::Account.new(@data[:account]) if @data[:account]
      end
    end
  end
end
