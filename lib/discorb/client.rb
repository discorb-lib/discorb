# frozen_string_literal: true

require "json"
require "logger"

require "async"
require "async/websocket/client"
require_relative "./utils/colored_puts"

module Discorb
  #
  # Class for connecting to the Discord server.
  #
  class Client
    # @return [Discorb::Intents] The intents that the client is currently using.
    attr_accessor :intents
    # @return [Discorb::Application] The application that the client is using.
    # @return [nil] If never fetched application by {#fetch_application}.
    attr_reader :application
    # @return [Discorb::HTTP] The http client.
    attr_reader :http
    # @return [Integer] The heartbeat interval.
    attr_reader :heartbeat_interval
    # @return [Integer] The API version of the Discord gateway.
    # @return [nil] If not connected to the gateway.
    attr_reader :api_version
    # @return [String] The token of the client.
    attr_reader :token
    # @return [Discorb::AllowedMentions] The allowed mentions that the client is using.
    attr_reader :allowed_mentions
    # @return [Discorb::ClientUser] The client user.
    attr_reader :user
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Guild}] A dictionary of guilds.
    attr_reader :guilds
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::User}] A dictionary of users.
    attr_reader :users
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Channel}] A dictionary of channels.
    attr_reader :channels
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Emoji}] A dictionary of emojis.
    attr_reader :emojis
    # @return [Discorb::Dictionary{Discorb::Snowflake => Discorb::Message}] A dictionary of messages.
    attr_reader :messages
    # @return [Array<Discorb::ApplicationCommand::Command>] The commands that the client is using.
    attr_reader :commands
    # @return [Float] The ping of the client.
    #   @note This will be calculated from heartbeat and heartbeat_ack.
    # @return [nil] If not connected to the gateway.
    attr_reader :ping
    # @return [:initialized, :running, :closed] The status of the client.
    attr_reader :status
    # @return [Hash{String => Discorb::Extension}] The loaded extensions.
    attr_reader :extensions
    # @return [Hash{Integer => Discorb::Shard}] The shards of the client.
    attr_reader :shards
    # @private
    # @return [Hash{Discorb::Snowflake => Discorb::ApplicationCommand::Command}] The commands on the top level.
    attr_reader :callable_commands
    # @private
    # @return [{String => Thread::Mutex}] A hash of mutexes.
    attr_reader :mutex

    # @!attribute [r] session_id
    #   @return [String] The session ID of the client or current shard.
    #   @return [nil] If not connected to the gateway.
    # @!attribute [r] shard
    #   @return [Discorb::Shard] The current shard. This is implemented with Thread variables.
    #   @return [nil] If client has no shard.
    # @!attribute [r] shard_id
    #   @return [Integer] The current shard ID. This is implemented with Thread variables.
    #   @return [nil] If client has no shard.
    # @!attribute [r] logger
    #   @return [Logger] The logger.

    #
    # Initializes a new client.
    #
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions that the client is using.
    # @param [Discorb::Intents] intents The intents that the client is currently using.
    # @param [Integer] message_caches The number of messages to cache.
    # @param [Logger] logger The IO object to use for logging.
    # @param [:debug, :info, :warn, :error, :critical] log_level The log level.
    # @param [Boolean] wait_until_ready Whether to delay event dispatch until ready.
    # @param [Boolean] fetch_member Whether to fetch member on ready. This may slow down the client. Default to `false`.
    # @param [String] title
    #  The title of the process. `false` to default of ruby, `nil` to `discorb: User#0000`. Default to `nil`.
    #
    def initialize(
      allowed_mentions: nil, intents: nil, message_caches: 1000,
      logger: nil,
      wait_until_ready: true, fetch_member: false,
      title: nil
    )
      @allowed_mentions = allowed_mentions || AllowedMentions.new(everyone: true, roles: true, users: true)
      @intents = (intents or Intents.default)
      @events = {}
      @api_version = nil
      @logger = logger || Logger.new(
        $stdout,
        progname: "discorb",
        level: Logger::ERROR,
      )
      @user = nil
      @users = Discorb::Dictionary.new
      @channels = Discorb::Dictionary.new
      @guilds = Discorb::Dictionary.new(sort: ->(k) { k[0].to_i })
      @emojis = Discorb::Dictionary.new
      @messages = Discorb::Dictionary.new(limit: message_caches)
      @application = nil
      @last_s = nil
      @identify_presence = nil
      @wait_until_ready = wait_until_ready
      @ready = false
      @tasks = []
      @conditions = {}
      @commands = []
      @callable_commands = []
      @status = :initialized
      @fetch_member = fetch_member
      @title = title
      @extensions = {}
      @mutex = {}
      @shards = {}
      set_default_events
    end

    #
    # Registers an event handler.
    # @see file:docs/Events.md Events Documentation
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] id Custom ID of the event.
    # @param [Hash] metadata The metadata of the event.
    # @param [Proc] block The block to execute when the event is triggered.
    #
    # @return [Discorb::EventHandler] The event.
    #
    def on(event_name, id: nil, **metadata, &block)
      ne = EventHandler.new(block, id, metadata)
      @events[event_name] ||= []
      @events[event_name].delete_if { |e| e.metadata[:override] }
      @events[event_name] << ne
      ne
    end

    #
    # Almost same as {#on}, but only triggers the event once.
    #
    # @param (see #on)
    #
    # @return [Discorb::EventHandler] The event.
    #
    def once(event_name, id: nil, **metadata, &block)
      metadata[:once] = true
      on(event_name, id: id, **metadata, &block)
    end

    #
    # Remove event by ID.
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] id The ID of the event.
    #
    def remove_event(event_name, id)
      @events[event_name].delete_if { |e| e.id == id }
    end

    #
    # Dispatch an event.
    # @async
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Object] args The arguments to pass to the event.
    #
    # @return [Async::Task<void>] The task.
    #
    def dispatch(event_name, *args)
      Async do
        if (conditions = @conditions[event_name])
          ids = Set[*conditions.map(&:first).map(&:object_id)]
          conditions.delete_if do |condition|
            next unless ids.include?(condition.first.object_id)

            check_result = condition[1].nil? || condition[1].call(*args)
            if check_result
              condition.first.signal(args)
              true
            else
              false
            end
          end
        end
        events = @events[event_name].dup || []
        if respond_to?("on_" + event_name.to_s)
          event_method = method("on_" + event_name.to_s)
          class << event_method
            def id
              "method"
            end
          end
          events << event_method
        end
        if events.nil?
          logger.debug "Event #{event_name} doesn't have any proc, skipping"
          next
        end
        logger.debug "Dispatching event #{event_name}"
        events.each do |block|
          Async do
            Async(annotation: "Discorb event: #{event_name}") do |_task|
              @events[event_name].delete(block) if block.is_a?(Discorb::EventHandler) && block.metadata[:once]
              block.call(*args)
              logger.debug "Dispatched proc with ID #{block.id.inspect}"
            rescue StandardError, ScriptError => e
              if event_name == :error
                raise e
              else
                dispatch(:error, event_name, args, e)
              end
            end
          end
        end
      end
    end

    #
    # Fetch user from ID.
    # @async
    #
    # @param [#to_s] id <description>
    #
    # @return [Async::Task<Discorb::User>] The user.
    #
    # @raise [Discorb::NotFoundError] If the user doesn't exist.
    #
    def fetch_user(id)
      Async do
        _resp, data = @http.request(Route.new("/users/#{id}", "//users/:user_id", :get)).wait
        User.new(self, data)
      end
    end

    #
    # Fetch channel from ID.
    # @async
    #
    # @param [#to_s] id The ID of the channel.
    #
    # @return [Async::Task<Discorb::Channel>] The channel.
    #
    # @raise [Discorb::NotFoundError] If the channel doesn't exist.
    #
    def fetch_channel(id)
      Async do
        _resp, data = @http.request(Route.new("/channels/#{id}", "//channels/:channel_id", :get)).wait
        Channel.make_channel(self, data)
      end
    end

    #
    # Fetch guild from ID.
    # @async
    #
    # @param [#to_s] id <description>
    #
    # @return [Async::Task<Discorb::Guild>] The guild.
    #
    # @raise [Discorb::NotFoundError] If the guild doesn't exist.
    #
    def fetch_guild(id)
      Async do
        _resp, data = @http.request(Route.new("/guilds/#{id}", "//guilds/:guild_id", :get)).wait
        Guild.new(self, data, false)
      end
    end

    #
    # Fetch invite from code.
    # @async
    #
    # @param [String] code The code of the invite.
    # @param [Boolean] with_count Whether to include the count of the invite.
    # @param [Boolean] with_expiration Whether to include the expiration of the invite.
    #
    # @return [Async::Task<Discorb::Invite>] The invite.
    #
    def fetch_invite(code, with_count: true, with_expiration: true)
      Async do
        _resp, data = @http.request(
          Route.new(
            "/invites/#{code}?with_count=#{with_count}&with_expiration=#{with_expiration}",
            "//invites/:code",
            :get
          )
        ).wait
        Invite.new(self, data, false)
      end
    end

    #
    # Fetch webhook from ID.
    # If application was cached, it will be used.
    # @async
    #
    # @param [Boolean] force Whether to force the fetch.
    #
    # @return [Async::Task<Discorb::Application>] The application.
    #
    def fetch_application(force: false)
      Async do
        next @application if @application && !force

        _resp, data = @http.request(Route.new("/oauth2/applications/@me", "//oauth2/applications/@me", :get)).wait
        @application = Application.new(self, data)
        @application
      end
    end

    #
    # Fetch nitro sticker pack from ID.
    # @async
    #
    # @return [Async::Task<Array<Discorb::Sticker::Pack>>] The packs.
    #
    def fetch_nitro_sticker_packs
      Async do
        _resp, data = @http.request(Route.new("/sticker-packs", "//sticker-packs", :get)).wait
        data[:sticker_packs].map { |pack| Sticker::Pack.new(self, pack) }
      end
    end

    #
    # Update presence of the client.
    #
    # @param [Discorb::Activity] activity The activity to update.
    # @param [:online, :idle, :dnd, :invisible] status The status to update.
    #
    def update_presence(activity = nil, status: nil)
      payload = {
        activities: [],
        status: status,
        since: nil,
        afk: nil,
      }
      payload[:activities] = [activity.to_hash] unless activity.nil?
      payload[:status] = status unless status.nil?
      if connection
        Async do
          send_gateway(3, **payload)
        end
      else
        @identify_presence = payload
      end
    end

    alias change_presence update_presence

    #
    # Method to wait for a event.
    # @async
    #
    # @param [Symbol] event The name of the event.
    # @param [Integer] timeout The timeout in seconds.
    # @param [Proc] check The check to use.
    #
    # @return [Async::Task<Object>] The result of the event.
    #
    # @raise [Discorb::TimeoutError] If the event didn't occur in time.
    #
    def event_lock(event, timeout = nil, &check)
      Async do |task|
        condition = Async::Condition.new
        @conditions[event] ||= []
        @conditions[event] << [condition, check]
        if timeout.nil?
          value = condition.wait
        else
          timeout_task = task.with_timeout(timeout) do
            condition.wait
          rescue Async::TimeoutError
            @conditions[event].delete_if { |c| c.first == condition }
            raise Discorb::TimeoutError, "Timeout waiting for event #{event}", cause: nil
          end
          value = timeout_task
        end
        value.length <= 1 ? value.first : value
      end
    end

    alias await event_lock

    def inspect
      "#<#{self.class} user=\"#{user}\">"
    end

    #
    # Load the extension.
    #
    # @param [Class, Discorb::Extension] ext The extension to load.
    # @param [Object] ... The arguments to pass to the `ext#initialize`.
    #
    def load_extension(ext, ...)
      case ext
      when Class
        raise ArgumentError, "#{ext} is not a extension" unless ext < Discorb::Extension

        ins = ext.new(self, ...)
      when Discorb::Extension
        ins = ext
      else
        raise ArgumentError, "#{ext} is not a extension"
      end

      @events.each_value do |event|
        event.delete_if { |c| c.metadata[:extension] == ins.class.name }
      end
      ins.events.each do |name, events|
        @events[name] ||= []
        events.each do |event|
          @events[name] << event
        end
      end
      @commands.delete_if do |cmd|
        cmd.respond_to? :extension and cmd.extension == ins.class.name
      end
      ins.class.commands.each do |cmd|
        cmd.define_singleton_method(:extension) { ins.class.name }
        cmd.replace_block(ins)
        cmd.block.define_singleton_method(:self_replaced) { true }
        @commands << cmd
      end

      cls = ins.class
      cls.loaded(self, ...) if cls.respond_to? :loaded
      ins.class.callable_commands.each do |cmd|
        unless cmd.respond_to? :self_replaced
          cmd.define_singleton_method(:extension) { ins.class.name }
          cmd.replace_block(ins)
          cmd.block.define_singleton_method(:self_replaced) { true }
        end
        @callable_commands << cmd
      end
      @extensions[ins.class.name] = ins
      ins
    end

    include Discorb::Gateway::Handler
    include Discorb::ApplicationCommand::Handler

    #
    # Starts the client.
    # @note This method behavior will change by CLI.
    # @see file:docs/cli.md CLI documentation
    #
    # @param [String, nil] token The token to use.
    #
    # @note If the token is nil, you should use `discorb run` with the `-e` or `--env` option.
    #
    def run(token = nil, shards: nil, shard_count: nil)
      token ||= ENV.fetch("DISCORB_CLI_TOKEN", nil)
      raise ArgumentError, "Token is not specified, and -e/--env is not specified" if token.nil?

      case ENV.fetch("DISCORB_CLI_FLAG", nil)
      when nil
        start_client(token, shards: shards, shard_count: shard_count)
      when "run"
        before_run(token)
        start_client(token, shards: shards, shard_count: shard_count)
      when "setup"
        run_setup(token)
      end
    end

    #
    # Stops the client.
    #
    def close!
      if @shards.any?
        @shards.each_value(&:close!)
      else
        @connection.send_close
      end
      @tasks.each(&:stop)
      @status = :closed
    end

    def session_id
      if shard
        shard.session_id
      else
        @session_id
      end
    end

    def logger
      shard&.logger || @logger
    end

    def shard
      Thread.current.thread_variable_get("shard")
    end

    def shard_id
      Thread.current.thread_variable_get("shard_id")
    end

    private

    def before_run(token)
      require "json"
      options = JSON.parse(ENV.fetch("DISCORB_CLI_OPTIONS", nil), symbolize_names: true)
      setup_commands(token) if options[:setup]
    end

    def run_setup(token)
      # @type var guild_ids: Array[String] | false
      guild_ids = false
      if guilds = ENV.fetch("DISCORB_SETUP_GUILDS", nil)
        guild_ids = guilds.split(",")
      end
      guild_ids = false if guild_ids == ["global"]
      setup_commands(token, guild_ids: guild_ids).wait
      clear_commands(token, ENV.fetch("DISCORB_SETUP_CLEAR_GUILDS", "").split(","))
      if ENV.fetch("DISCORB_SETUP_SCRIPT", nil) == "true"
        @events[:setup]&.each do |event|
          event.call
        end
        self.on_setup if respond_to? :on_setup
      end
    end

    def set_status(status, shard)
      if shard.nil?
        @status = status
      else
        @shards[shard].status = status
      end
    end

    def connection
      if shard_id
        @shards[shard_id].connection
      else
        @connection
      end
    end

    def connection=(value)
      if shard_id
        @shards[shard_id].connection = value
      else
        @connection = value
      end
    end

    def session_id=(value)
      sid = shard_id
      if sid
        @shards[sid].session_id = value
      else
        @session_id = value
      end
    end

    def start_client(token, shards: nil, shard_count: nil)
      @token = token.to_s
      @shard_count = shard_count
      Signal.trap(:SIGINT) do
        logger.info "SIGINT received, closing..."
        Signal.trap(:SIGINT, "DEFAULT")
        close!
      end
      if shards.nil?
        main_loop(nil)
      else
        @shards = shards.to_h.with_index do |shard, i|
          [shard, Shard.new(self, shard, shard_count, i)]
        end
        @shards.values[..-1].each_with_index do |shard, i|
          shard.next_shard = @shards.values[i + 1]
        end
        @shards.each_value { |s| s.thread.join }
      end
    end

    def main_loop(shard)
      set_status(:running, shard)
      connect_gateway(false).wait
    rescue StandardError
      set_status(:closed, shard)
      raise
    end

    def main_task
      if shard_id
        shard.main_task
      else
        @main_task
      end
    end

    def main_task=(value)
      if shard_id
        shard.main_task = value
      else
        @main_task = value
      end
    end

    def set_default_events
      on :error, override: true do |event_name, _args, e|
        message = "An error occurred while dispatching #{event_name}:\n#{e.full_message}"
        logger.error message
      end

      once :standby do
        next if @title == false

        title = @title || ENV.fetch("DISCORB_CLI_TITLE", nil) || "discorb: #{@user}"
        Process.setproctitle title
      end
    end
  end
end
