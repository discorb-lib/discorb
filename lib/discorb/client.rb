# frozen_string_literal: true

require 'pp'
require 'json'
require 'logger'
require_relative 'intents'
require_relative 'internet'
require_relative 'common'
require_relative 'channel'
require_relative 'message'
require_relative 'user'
require_relative 'dictionary'
require_relative 'guild'
require_relative 'error'
require_relative 'log'
require_relative 'event'
require_relative 'gateway'
require_relative 'extension'
require_relative 'role'

require 'async'
require 'async/websocket/client'

module Discorb
  class Client
    attr_accessor :intents
    attr_reader :application, :internet, :heartbeat_interval, :api_version, :token, :allowed_mentions, :user, :guilds, :users,
                :channels, :emojis, :messages, :log

    def initialize(allowed_mentions: nil, intents: nil, message_caches: 1000, log: nil, colorize_log: false, log_level: :info, wait_until_ready: true)
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
    end

    def on(event_name, id: nil, **discriminator, &block)
      ne = Event.new(block, id, discriminator)
      @events[event_name] ||= []
      @events[event_name] << ne
      ne
    end

    def remove_event(event_name, id)
      @events[event_name].delete_if { |e| e.id == id }
    end

    def dispatch(event_name, *args)
      Async do |_task|
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
        if @events[event_name].nil?
          @log.debug "Event #{event_name} doesn't have any proc, skipping"
          next
        end
        @log.debug "Dispatching event #{event_name}"
        @events[event_name].each do |block|
          lambda { |event_args|
            Async(annotation: "Discorb event: #{event_name}") do |task|
              block.call(task, *event_args)
              @log.debug "Dispatched proc with ID #{block.id.inspect}"
            rescue StandardError, ScriptError => e
              if block.rescue.nil?
                message = "An error occurred while dispatching proc with ID #{block.id.inspect}\n#{e.full_message}"
                if @log.out
                  @log.error message
                else
                  warn message
                end
              else
                begin
                  block.rescue.call(task, e, *args)
                rescue StandardError, ScriptError => e2
                  message = "An error occurred while dispatching rescue proc with ID #{block.id.inspect}\n#{e2.full_message}\nBy an error:\n#{e.full_message}"
                  if @log.out
                    @log.error message
                  else
                    warn message
                  end
                end
              end
            end
          }.call(args)
        end
      end
    end

    def run(token)
      @token = token.to_s
      connect_gateway(true)
    end

    def fetch_user(id)
      Async do
        _resp, data = internet.get("/users/#{id}").wait
        User.new(self, data)
      end
    end

    def fetch_channel(id)
      Async do
        _resp, data = internet.get("/channels/#{id}").wait
        Channel.make_channel(self, data)
      end
    end

    def fetch_guild(id)
      Async do
        _resp, data = internet.get("/guilds/#{id}").wait
        Guild.new(self, data, false)
      end
    end

    def fetch_invite(code, with_count: false, with_expiration: false)
      Async do
        _resp, data = internet.get("/invites/#{code}?with_count=#{with_count}&with_expiration=#{with_expiration}").wait
        Invite.new(self, data, false)
      end
    end

    def fetch_application(force: false)
      Async do
        next @application if @application && !force

        _resp, data = internet.get('/oauth2/applications/@me').wait
        @application = Application.new(self, data)
        @application
      end
    end

    def fetch_nitro_sticker_packs
      Async do
        _resp, data = internet.get('/stickers-packs').wait
        data.map { |pack| Sticker::Pack.new(self, pack) }
      end
    end

    def update_presence(activity = nil, activities: nil, idle: nil, status: nil, afk: nil)
      payload = {}
      if !activity.nil?
        payload[:activities] = [activity.to_hash]
      elsif !activities.nil?
        payload[:activities] = activities.map(&:to_hash)
      end
      payload[:idle] = (Time.now.to_f * 1000).floor unless idle.nil?
      payload[:status] = status unless status.nil?
      payload[:afk] = afk unless afk.nil?
      if @connection
        Async do |_task|
          send_gateway(3, **payload)
        end
      else
        @identify_presence = payload
      end
    end

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
            raise Discorb::TimeoutError, "Timeout waiting for event #{event}"
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

    def extend(mod)
      if mod.respond_to?(:events)
        mod.events.each do |name, events|
          @events[name] = [] if @events[name].nil?
          events.each do |event|
            @events[name] << event
          end
        end
        mod.client = self
      end
      super(mod)
    end

    include GatewayHandler

    alias add_event on
    alias event on
  end
end
