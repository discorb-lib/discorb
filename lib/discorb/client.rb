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
    # @return [Discorb::Logger] The logger.
    attr_reader :log
    # @return [Array<Discorb::ApplicationCommand::Command>] The commands that the client is using.
    attr_reader :commands
    # @return [Float] The ping of the client.
    #   @note This will be calculated from heartbeat and heartbeat_ack.
    # @return [nil] If not connected to the gateway.
    attr_reader :ping
    # @return [:initialized, :running, :closed] The status of the client.
    attr_reader :status
    # @return [Integer] The session ID of connection.
    attr_reader :session_id
    # @private
    attr_reader :bottom_commands

    #
    # Initializes a new client.
    #
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions that the client is using.
    # @param [Discorb::Intents] intents The intents that the client is currently using.
    # @param [Integer] message_caches The number of messages to cache.
    # @param [#puts] log The IO object to use for logging.
    # @param [Boolean] colorize_log Whether to colorize the log.
    # @param [:debug, :info, :warn, :error, :critical] log_level The log level.
    # @param [Boolean] wait_until_ready Whether to delay event dispatch until ready.
    # @param [Boolean] fetch_member Whether to fetch member on ready. This may slow down the client. Default to `false`.
    # @param [String] title The title of the process. `false` to default, `nil` to `discorb: User#0000`. Default to `nil`.
    #
    def initialize(
      allowed_mentions: nil, intents: nil, message_caches: 1000,
      log: nil, colorize_log: false, log_level: :info,
      wait_until_ready: true, fetch_member: false,
      title: nil
    )
      @allowed_mentions = allowed_mentions || AllowedMentions.new(everyone: true, roles: true, users: true)
      @intents = (intents or Intents.default)
      @events = {}
      @api_version = nil
      @log = Logger.new(log, colorize_log, log_level)
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
      @bottom_commands = []
      @status = :initialized
      @fetch_member = fetch_member
      @title = title
      set_default_events
    end

    #
    # Registers an event handler.
    # @see file:docs/Events.md
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Symbol] id Custom ID of the event.
    # @param [Hash] metadata The metadata of the event.
    # @param [Proc] block The block to execute when the event is triggered.
    #
    # @return [Discorb::Event] The event.
    #
    def on(event_name, id: nil, **metadata, &block)
      ne = Event.new(block, id, metadata)
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
    # @return [Discorb::Event] The event.
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
    #
    # @param [Symbol] event_name The name of the event.
    # @param [Object] args The arguments to pass to the event.
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
          @log.debug "Event #{event_name} doesn't have any proc, skipping"
          next
        end
        @log.debug "Dispatching event #{event_name}"
        events.each do |block|
          Async do
            Async(annotation: "Discorb event: #{event_name}") do |task|
              if block.is_a?(Discorb::Event)
                @events[event_name].delete(block) if block.metadata[:once]
              end
              block.call(*args)
              @log.debug "Dispatched proc with ID #{block.id.inspect}"
            rescue StandardError, ScriptError => e
              dispatch(:error, event_name, args, e)
            end
          end
        end
      end
    end

    #
    # Fetch user from ID.
    # @macro async
    # @macro http
    #
    # @param [#to_s] id <description>
    #
    # @return [Async::Task<Discorb::User>] The user.
    #
    # @raise [Discorb::NotFoundError] If the user doesn't exist.
    #
    def fetch_user(id)
      Async do
        _resp, data = http.get("/users/#{id}").wait
        User.new(self, data)
      end
    end

    #
    # Fetch channel from ID.
    # @macro async
    # @macro http
    #
    # @param [#to_s] id The ID of the channel.
    #
    # @return [Async::Task<Discorb::Channel>] The channel.
    #
    # @raise [Discorb::NotFoundError] If the channel doesn't exist.
    #
    def fetch_channel(id)
      Async do
        _resp, data = http.get("/channels/#{id}").wait
        Channel.make_channel(self, data)
      end
    end

    #
    # Fetch guild from ID.
    # @macro async
    # @macro http
    #
    # @param [#to_s] id <description>
    #
    # @return [Async::Task<Discorb::Guild>] The guild.
    #
    # @raise [Discorb::NotFoundError] If the guild doesn't exist.
    #
    def fetch_guild(id)
      Async do
        _resp, data = http.get("/guilds/#{id}").wait
        Guild.new(self, data, false)
      end
    end

    #
    # Fetch invite from code.
    # @macro async
    # @macro http
    #
    # @param [String] code The code of the invite.
    # @param [Boolean] with_count Whether to include the count of the invite.
    # @param [Boolean] with_expiration Whether to include the expiration of the invite.
    #
    # @return [Async::Task<Discorb::Invite>] The invite.
    #
    def fetch_invite(code, with_count: false, with_expiration: false)
      Async do
        _resp, data = http.get("/invites/#{code}?with_count=#{with_count}&with_expiration=#{with_expiration}").wait
        Invite.new(self, data, false)
      end
    end

    #
    # Fetch webhook from ID.
    # If application was cached, it will be used.
    # @macro async
    # @macro http
    #
    # @param [Boolean] force Whether to force the fetch.
    #
    # @return [Async::Task<Discorb::Application>] The application.
    #
    def fetch_application(force: false)
      Async do
        next @application if @application && !force

        _resp, data = http.get("/oauth2/applications/@me").wait
        @application = Application.new(self, data)
        @application
      end
    end

    #
    # Fetch nitro sticker pack from ID.
    # @macro async
    # @macro http
    #
    # @return [Async::Task<Array<Discorb::Sticker::Pack>>] The packs.
    #
    def fetch_nitro_sticker_packs
      Async do
        _resp, data = http.get("/stickers-packs").wait
        data.map { |pack| Sticker::Pack.new(self, pack) }
      end
    end

    #
    # Update presence of the client.
    #
    # @param [Discorb::Activity] activity The activity to update.
    # @param [:online, :idle, :dnd, :invisible] status The status to update.
    # @param [String] afk Whether to set the client as AFK.
    #
    def update_presence(activity = nil, status: nil, afk: false)
      payload = {
        activities: [],
        status: status,
        afk: nil,
        since: nil,
      }
      if !activity.nil?
        payload[:activities] = [activity.to_hash]
      end
      payload[:status] = status unless status.nil?
      if @connection
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
    #
    # @param [Symbol] event The name of the event.
    # @param [Integer] timeout The timeout in seconds.
    # @param [Proc] check The check to use.
    #
    # @return [Object] The result of the event.
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
    # @param [Module] mod The extension to load.
    #
    def extend(mod)
      if mod.respond_to?(:events)
        @events.each_value do |event|
          event.delete_if { |c| c.metadata[:extension] == mod.name }
        end
        mod.events.each do |name, events|
          @events[name] ||= []
          @events[name].delete_if { |c| c.metadata[:override] }
          events.each do |event|
            @events[name] << event
          end
        end
        @commands.delete_if do |cmd|
          cmd.respond_to? :extension and cmd.extension == mod.name
        end
        mod.commands.each do |cmd|
          cmd.define_singleton_method(:extension) { mod.name }
          @commands << cmd
        end
        @bottom_commands += mod.bottom_commands
        mod.client = self
      end
      super(mod)
    end

    include Discorb::Gateway::Handler
    include Discorb::ApplicationCommand::Handler

    #
    # Starts the client.
    # @note This method behavior will change by CLI.
    # @see file:docs/cli.md
    #
    # @param [String, nil] token The token to use.
    #
    # @note If the token is nil, you should use `discorb run` with the `-t` or `--token` option.
    #
    def run(token = nil)
      token ||= ENV["DISCORB_CLI_TOKEN"]
      raise ArgumentError, "Token is not specified, and -t/--token is not specified" if token.nil?
      case ENV["DISCORB_CLI_FLAG"]
      when nil
        start_client(token)
      when "run"
        require "json"
        options = JSON.parse(ENV["DISCORB_CLI_OPTIONS"], symbolize_names: true)
        @daemon = options[:daemon]

        setup_commands(token) if options[:setup]
        if options[:log_level]
          if options[:log_level] == "none"
            @log.out = nil
          else
            @log.out = case options[:log_file]
              when nil, "stderr"
                $stderr
              when "stdout"
                $stdout
              else
                ::File.open(options[:log_file], "a")
              end
            @log.level = options[:log_level].to_sym
            @log.colorize_log = case options[:log_color]
              when nil
                if @log.out == $stdout || @log.out == $stderr
                  true
                else
                  false
                end
              when true, false
                options[:log_color]
              end
          end
        end
        start_client(token)
      when "setup"
        guild_ids = "global"
        if guilds = ENV["DISCORB_SETUP_GUILDS"]
          guild_ids = guilds.split(",")
        end
        if guild_ids == ["global"]
          guild_ids = false
        end
        setup_commands(token, guild_ids: guild_ids).wait
      end
    end

    #
    # Stops the client.
    #
    def close!
      @connection.send_close
      @tasks.each(&:stop)
      @status = :closed
      @close_condition.signal
    end

    private

    def start_client(token)
      Async do |task|
        trap(:SIGINT) {
          @log.info "SIGINT received, closing..."
          close!
        }
        @token = token.to_s
        @close_condition = Async::Condition.new
        @main_task = Async do
          @status = :running
          connect_gateway(true).wait
        rescue
          @status = :stopped
          @close_condition.signal
          raise
        end
        @close_condition.wait
        @main_task.stop
      end
    end

    def set_default_events
      on :error, override: true do |event_name, _args, e|
        message = "An error occurred while dispatching #{event_name}:\n#{e.full_message}"
        @log.error message, fallback: $stderr
      end

      once :standby do
        next if @title == false

        title = @title || ENV["DISCORB_CLI_TITLE"] || "discorb: #{@user}"
        Process.setproctitle title
      end
    end
  end
end
