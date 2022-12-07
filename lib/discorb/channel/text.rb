# frozen_string_literal: true

module Discorb
  #
  # Represents a text channel.
  #
  class TextChannel < GuildChannel
    # @return [String] The topic of the channel.
    attr_reader :topic
    # @return [Boolean] Whether the channel is nsfw.
    attr_reader :nsfw
    # @return [Discorb::Snowflake] The id of the last message.
    attr_reader :last_message_id
    # @return [Integer] The rate limit per user (Slowmode) in the channel.
    attr_reader :rate_limit_per_user
    alias slowmode rate_limit_per_user
    # @return [Time] The time when the last pinned message was pinned.
    attr_reader :last_pin_timestamp
    alias last_pinned_at last_pin_timestamp
    # @return [Integer] The default value of duration of auto archive.
    attr_reader :default_auto_archive_duration

    include Messageable

    @channel_type = 0

    # @!attribute [r] threads
    #   @return [Array<Discorb::ThreadChannel>] The threads in the channel.
    def threads
      guild.threads.select { |thread| thread.parent == self }
    end

    #
    # Edits the channel.
    # @async
    # @macro edit
    #
    # @param [String] name The name of the channel.
    # @param [Integer] position The position of the channel.
    # @param [Discorb::CategoryChannel, nil] category The parent of channel. Specify `nil` to remove the parent.
    # @param [Discorb::CategoryChannel, nil] parent Alias of `category`.
    # @param [String] topic The topic of the channel.
    # @param [Boolean] nsfw Whether the channel is nsfw.
    # @param [Boolean] announce Whether the channel is announce channel.
    # @param [Integer] rate_limit_per_user The rate limit per user (Slowmode) in the channel.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [Integer] default_auto_archive_duration The default auto archive duration of the channel.
    # @param [Integer] archive_in Alias of `default_auto_archive_duration`.
    # @param [String] reason The reason of editing the channel.
    #
    # @return [Async::Task<self>] The edited channel.
    #
    def edit(
      name: Discorb::Unset,
      position: Discorb::Unset,
      category: Discorb::Unset,
      parent: Discorb::Unset,
      topic: Discorb::Unset,
      nsfw: Discorb::Unset,
      announce: Discorb::Unset,
      rate_limit_per_user: Discorb::Unset,
      slowmode: Discorb::Unset,
      default_auto_archive_duration: Discorb::Unset,
      archive_in: Discorb::Unset,
      reason: nil
    )
      Async do
        payload = {}
        payload[:name] = name if name != Discorb::Unset
        payload[:announce] = announce ? 5 : 0 if announce != Discorb::Unset
        payload[:position] = position if position != Discorb::Unset
        payload[:topic] = topic || "" if topic != Discorb::Unset
        payload[:nsfw] = nsfw if nsfw != Discorb::Unset

        slowmode = rate_limit_per_user if slowmode == Discorb::Unset
        payload[:rate_limit_per_user] = slowmode || 0 if slowmode !=
          Discorb::Unset
        parent = category if parent == Discorb::Unset
        payload[:parent_id] = parent&.id if parent != Discorb::Unset

        default_auto_archive_duration ||= archive_in
        if default_auto_archive_duration != Discorb::Unset
          payload[
            :default_auto_archive_duration
          ] = default_auto_archive_duration
        end

        @client
          .http
          .request(
            Route.new("/channels/#{@id}", "//channels/:channel_id", :patch),
            payload,
            audit_log_reason: reason
          )
          .wait
        self
      end
    end

    alias modify edit

    #
    # Create webhook in the channel.
    # @async
    #
    # @param [String] name The name of the webhook.
    # @param [Discorb::Image] avatar The avatar of the webhook.
    #
    # @return [Async::Task<Discorb::Webhook::IncomingWebhook>] The created webhook.
    #
    def create_webhook(name, avatar: nil)
      Async do
        payload = {}
        payload[:name] = name
        payload[:avatar] = avatar.to_s if avatar
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/webhooks",
                "//channels/:channel_id/webhooks",
                :post
              ),
              payload
            )
            .wait
        Webhook.from_data(@client, data)
      end
    end

    #
    # Fetch webhooks in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::Webhook>>] The webhooks in the channel.
    #
    def fetch_webhooks
      Async do
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/webhooks",
                "//channels/:channel_id/webhooks",
                :get
              )
            )
            .wait
        data.map { |webhook| Webhook.from_data(@client, webhook) }
      end
    end

    #
    # Bulk delete messages in the channel.
    # @async
    #
    # @param [Discorb::Message] messages The messages to delete.
    # @param [Boolean] force Whether to ignore the validation for message (14 days limit).
    #
    # @return [Async::Task<void>] The task.
    #
    def delete_messages(*messages, force: false)
      Async do
        messages = messages.flatten
        unless force
          time = Time.now
          messages.delete_if do |message|
            next false unless message.is_a?(Message)

            time - message.created_at > 60 * 60 * 24 * 14
          end
        end

        message_ids = messages.map { |m| Discorb::Utils.try(m, :id).to_s }

        @client
          .http
          .request(
            Route.new(
              "/channels/#{@id}/messages/bulk-delete",
              "//channels/:channel_id/messages/bulk-delete",
              :post
            ),
            { messages: message_ids }
          )
          .wait
      end
    end

    alias bulk_delete delete_messages
    alias destroy_messages delete_messages

    #
    # Follow the existing announcement channel.
    # @async
    #
    # @param [Discorb::NewsChannel] target The channel to follow.
    # @param [String] reason The reason of following the channel.
    #
    # @return [Async::Task<void>] The task.
    #
    def follow_from(target, reason: nil)
      Async do
        @client
          .http
          .request(
            Route.new(
              "/channels/#{target.id}/followers",
              "//channels/:channel_id/followers",
              :post
            ),
            { webhook_channel_id: @id },
            audit_log_reason: reason
          )
          .wait
      end
    end

    #
    # Start thread in the channel.
    # @async
    #
    # @param [String] name The name of the thread.
    # @param [Discorb::Message] message The message to start the thread.
    # @param [:hour, :day, :three_days, :week] auto_archive_duration The duration of auto-archiving.
    # @param [Boolean] public Whether the thread is public.
    # @param [Integer] rate_limit_per_user The rate limit per user.
    # @param [Integer] slowmode Alias of `rate_limit_per_user`.
    # @param [String] reason The reason of starting the thread.
    #
    # @return [Async::Task<Discorb::ThreadChannel>] The started thread.
    #
    def start_thread(
      name,
      message: nil,
      auto_archive_duration: nil,
      public: true,
      rate_limit_per_user: nil,
      slowmode: nil,
      reason: nil
    )
      auto_archive_duration ||= @default_auto_archive_duration
      Async do
        _resp, data =
          if message.nil?
            @client
              .http
              .request(
                Route.new(
                  "/channels/#{@id}/threads",
                  "//channels/:channel_id/threads",
                  :post
                ),
                {
                  name: name,
                  auto_archive_duration: auto_archive_duration,
                  type: public ? 11 : 10,
                  rate_limit_per_user: rate_limit_per_user || slowmode
                },
                audit_log_reason: reason
              )
              .wait
          else
            @client
              .http
              .request(
                Route.new(
                  "/channels/#{@id}/messages/#{Utils.try(message, :id)}/threads",
                  "//channels/:channel_id/messages/:message_id/threads",
                  :post
                ),
                { name: name, auto_archive_duration: auto_archive_duration },
                audit_log_reason: reason
              )
              .wait
          end
        Channel.make_channel(@client, data)
      end
    end

    alias create_thread start_thread

    #
    # Fetch archived threads in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The archived threads in the channel.
    #
    def fetch_archived_public_threads
      Async do
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/threads/archived/public",
                "//channels/:channel_id/threads/archived/public",
                :get
              )
            )
            .wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch archived private threads in the channel.
    # @async
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The archived private threads in the channel.
    #
    def fetch_archived_private_threads
      Async do
        _resp, data =
          @client
            .http
            .request(
              Route.new(
                "/channels/#{@id}/threads/archived/private",
                "//channels/:channel_id/threads/archived/private",
                :get
              )
            )
            .wait
        data.map { |thread| Channel.make_channel(@client, thread) }
      end
    end

    #
    # Fetch joined archived private threads in the channel.
    # @async
    #
    # @param [Integer] limit The limit of threads to fetch.
    # @param [Time] before The time before which the threads are created.
    #
    # @return [Async::Task<Array<Discorb::ThreadChannel>>] The joined archived private threads in the channel.
    #
    def fetch_joined_archived_private_threads(limit: nil, before: nil)
      Async do
        if limit.nil?
          before = Time.now
          threads = []
          loop do
            _resp, data =
              @client
                .http
                .request(
                  Route.new(
                    "/channels/#{@id}/users/@me/threads/archived/private?before=#{before.iso8601}",
                    "//channels/:channel_id/users/@me/threads/archived/private",
                    :get
                  )
                )
                .wait
            threads +=
              data[:threads].map do |thread|
                Channel.make_channel(@client, thread)
              end

            break unless data[:has_more]

            before = Snowflake.new(data[:threads][-1][:id]).timestamp
          end
          threads
        else
          _resp, data =
            @client
              .http
              .request(
                Route.new(
                  "/channels/#{@id}/users/@me/threads/archived/private?limit=#{limit}&before=#{before.iso8601}",
                  "//channels/:channel_id/users/@me/threads/archived/private",
                  :get
                )
              )
              .wait
          data.map { |thread| Channel.make_channel(@client, thread) }
        end
      end
    end

    private

    def _set_data(data)
      @topic = data[:topic]
      @nsfw = data[:nsfw]
      @last_message_id = data[:last_message_id]
      @rate_limit_per_user = data[:rate_limit_per_user]
      @last_pin_timestamp =
        data[:last_pin_timestamp] && Time.iso8601(data[:last_pin_timestamp])
      @default_auto_archive_duration = data[:default_auto_archive_duration]
      super
    end
  end

  #
  # Represents a news channel (announcement channel).
  #
  class NewsChannel < TextChannel
    @channel_type = 5

    #
    # Follow the existing announcement channel from self.
    # @async
    #
    # @param [Discorb::TextChannel] target The channel to follow to.
    # @param [String] reason The reason of following the channel.
    #
    # @return [Async::Task<void>] The task.
    #
    def follow_to(target, reason: nil)
      Async do
        @client
          .http
          .request(
            Route.new(
              "/channels/#{@id}/followers",
              "//channels/:channel_id/followers",
              :post
            ),
            { webhook_channel_id: target.id },
            audit_log_reason: reason
          )
          .wait
      end
    end
  end
end
