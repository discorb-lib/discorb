# frozen_string_literal: true

module Discorb
  #
  # Represents a Discord audit log.
  #
  class AuditLog < DiscordModel
    # @return [Array<Discorb::Webhook>] The webhooks in this audit log.
    attr_reader :webhooks
    # @return [Array<Discorb::User>] The users in this audit log.
    attr_reader :users
    # @return [Array<Discorb::ThreadChannel>] The threads in this audit log.
    attr_reader :threads
    # @return [Array<Discorb::AuditLog::Entry>] The entries in this audit log.
    attr_reader :entries

    # @private
    def initialize(client, data, guild)
      @client = client
      @guild = guild
      @webhooks = data[:webhooks].map { |webhook| Webhook.new([@client, webhook]) }
      @users = data[:users].map { |user| client.users[user[:id]] || User.new(@client, user) }
      @threads = data[:threads].map { |thread| client.channels[thread[:id]] || Channel.make_channel(@client, thread, no_cache: true) }
      @entries = data[:audit_log_entries].map { |entry| AuditLog::Entry.new(@client, entry, guild.id) }
    end

    #
    # Gets an entry from entries.
    #
    # @param [Integer] index The index of the entry.
    #
    # @return [Discorb::AuditLog::Entry] The entry.
    # @return [nil] If the index is out of range.
    #
    def [](index)
      @entries[index]
    end

    #
    # Represents an entry in an audit log.
    #
    class Entry < DiscordModel
      # @return [Discorb::Snowflake] The ID of the entry.
      attr_reader :id
      # @return [Discorb::Snowflake] The ID of the user who performed the action.
      attr_reader :user_id
      # @return [Discorb::Snowflake] The ID of the target of the action.
      attr_reader :target_id
      # @return [Symbol] The type of the entry.
      # These symbols will be used:
      #
      # * `:guild_update`
      # * `:channel_create`
      # * `:channel_update`
      # * `:channel_delete`
      # * `:channel_overwrite_create`
      # * `:channel_overwrite_update`
      # * `:channel_overwrite_delete`
      # * `:member_kick`
      # * `:member_prune`
      # * `:member_ban_add`
      # * `:member_ban_remove`
      # * `:member_update`
      # * `:member_role_update`
      # * `:member_move`
      # * `:member_disconnect`
      # * `:bot_add`
      # * `:role_create`
      # * `:role_update`
      # * `:role_delete`
      # * `:invite_create`
      # * `:invite_update`
      # * `:invite_delete`
      # * `:webhook_create`
      # * `:webhook_update`
      # * `:webhook_delete`
      # * `:emoji_create`
      # * `:emoji_update`
      # * `:emoji_delete`
      # * `:message_delete`
      # * `:message_bulk_delete`
      # * `:message_pin`
      # * `:message_unpin`
      # * `:integration_create`
      # * `:integration_update`
      # * `:integration_delete`
      # * `:stage_instance_create`
      # * `:stage_instance_update`
      # * `:stage_instance_delete`
      # * `:sticker_create`
      # * `:sticker_update`
      # * `:sticker_delete`
      # * `:guild_scheduled_event_create`
      # * `:guild_scheduled_event_update`
      # * `:guild_scheduled_event_delete`
      # * `:thread_create`
      # * `:thread_update`
      # * `:thread_delete`
      attr_reader :type
      # @return [Discorb::AuditLog::Entry::Changes] The changes in this entry.
      attr_reader :changes
      # @return [Discorb::Channel, Discorb::Role, Discorb::Member, Discorb::Guild, Discorb::Message] The target of the entry.
      attr_reader :target
      # @return [Hash{Symbol => Object}] The optional data for this entry.
      # @note You can use dot notation to access the data.
      attr_reader :options

      # @!attribute [r] user
      #   @return [Discorb::User] The user who performed the action.

      # @private
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
        100 => :guild_scheduled_event_create,
        101 => :guild_scheduled_event_update,
        102 => :guild_scheduled_event_delete,
        110 => :thread_create,
        111 => :thread_update,
        112 => :thread_delete,
      }.freeze

      # @private
      @converts = {
        channel: ->(client, id, _guild_id) { client.channels[id] },
        thread: ->(client, id, _guild_id) { client.channels[id] },
        role: ->(client, id, guild_id) { client.guilds[guild_id]&.roles&.[](id) },
        member: ->(client, id, guild_id) { client.guilds[guild_id]&.members&.[](id) },
        guild: ->(client, id, _guild_id) { client.guilds[id] },
        message: ->(client, id, _guild_id) { client.messages[id] },
      }

      # @private
      def initialize(client, data, guild_id)
        @client = client
        @guild_id = Snowflake.new(guild_id)
        @id = Snowflake.new(data[:id])
        @user_id = Snowflake.new(data[:user_id])
        @target_id = Snowflake.new(data[:target_id])
        @type = self.class.events[data[:action_type]]
        @target = self.class.converts[@type.to_s.split("_")[0].to_sym]&.call(client, @target_id, @gui)
        @target ||= Snowflake.new(data[:target_id])
        @changes = data[:changes] && Changes.new(data[:changes])
        @reason = data[:reason]
        data[:options]&.each do |option, value|
          define_singleton_method(option) { value }
          if option.end_with?("_id")
            define_singleton_method(option.to_s.sub("_id", "")) do
              self.class.converts[option.to_s.split("_")[0].to_sym]&.call(client, value, @guild_id)
            end
          end
        end
        @options = data[:options] || {}
      end

      def user
        @client.users[@user_id]
      end

      #
      # Get a change with the given key.
      #
      # @param [Symbol] key The key to get.
      #
      # @return [Discorb::AuditLog::Entry::Change] The change with the given key.
      # @return [nil] The change with the given key does not exist.
      #
      def [](key)
        @changes[key]
      end

      def inspect
        "#<#{self.class} #{@changes&.data&.length || "No"} changes>"
      end

      class << self
        attr_reader :events, :converts
      end

      #
      # Represents the changes in an audit log entry.
      #
      class Changes < DiscordModel
        attr_reader :data

        #
        # @private
        #
        def initialize(data)
          @data = data.map { |d| [d[:key].to_sym, d] }.to_h
          @data.each do |k, v|
            define_singleton_method(k) { Change.new(v) }
          end
        end

        def inspect
          "#<#{self.class} #{@data.length} changes>"
        end

        #
        # Get keys of changes.
        #
        # @return [Array<Symbol>] The keys of the changes.
        #
        def keys
          @data.keys
        end

        #
        # Get a change with the given key.
        #
        # @param [Symbol] key The key to get.
        #
        # @return [Discorb::AuditLog::Entry::Change] The change with the given key.
        # @return [nil] The change with the given key does not exist.
        #
        def [](key)
          @data[key.to_sym]
        end
      end

      #
      # Represents a change in an audit log entry.
      # @note This instance will try to call a method of {#new_value} if the method wasn't defined.
      #
      class Change < DiscordModel
        # @return [Symbol] The key of the change.
        attr_reader :key
        # @return [Object] The old value of the change.
        attr_reader :old_value
        # @return [Object] The new value of the change.
        attr_reader :new_value

        # @private
        def initialize(data)
          @key = data[:key].to_sym
          method = case @key.to_s
            when /.*_id$/, "id"
              ->(v) { Snowflake.new(v) }
            when "permissions"
              ->(v) { Discorb::Permission.new(v.to_i) }
            when "status"
              ->(v) { Discorb::ScheduledEvent.status[v] }
            when "entity_type"
              ->(v) { Discorb::ScheduledEvent.entity_type[v] }
            when "privacy_level"
              ->(v) { Discorb::StageInstance.privacy_level[v] || Discorb::ScheduledEvent.privacy_level[v] }
            else
              ->(v) { v }
            end
          @old_value = method.(data[:old_value])
          @new_value = method.(data[:new_value])
        end

        #
        # Send a message to the new value.
        #
        def method_missing(method, ...)
          @new_value.__send__(method, ...)
        end

        def inspect
          "#<#{self.class} #{@key.inspect} #{@old_value.inspect} -> #{@new_value.inspect}>"
        end

        def respond_to_missing?(method, include_private = false)
          @new_value.respond_to?(method, include_private)
        end
      end
    end

    #
    # Represents an integration in an audit log entry.
    #
    class Integration < DiscordModel
      # @return [Discorb::Snowflake] The ID of the integration.
      attr_reader :id
      # @return [Symbol] The type of the integration.
      attr_reader :type
      # @return [String] The name of the integration.
      attr_reader :name
      # @return [Discorb::Integration::Account] The account of the integration.
      attr_reader :account

      # @private
      def initialize(data)
        @id = Snowflake.new(data[:id])
        @type = data[:type].to_sym
        @name = data[:name]
        @data = data
        @account = Discorb::Integration::Account.new(@data[:account]) if @data[:account]
      end

      def inspect
        "#<#{self.class} #{@id}>"
      end
    end
  end
end
