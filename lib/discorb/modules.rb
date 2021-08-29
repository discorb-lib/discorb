# frozen_string_literal: true

module Discorb
  #
  # Module for sending and reading messages.
  #
  module Messageable
    #
    # Post a message to the channel.
    #
    # @param [String] content The message content.
    # @param [Boolean] tts Whether the message is tts.
    # @param [Discorb::Embed] embed The embed to send.
    # @param [Array<Discorb::Embed>] embeds The embeds to send.
    # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions.
    # @param [Discorb::Message, Discorb::Message::Reference] reference The message to reply to.
    # @param [Array<Discorb::Components>, Array<Array<Discorb::Components>>] components The components to send.
    # @param [Discorb::File] file The file to send.
    # @param [Array<Discorb::File>] files The files to send.
    #
    # @return [Discorb::Message] The message sent.
    #
    def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil,
                            reference: nil, components: nil, file: nil, files: nil)
      Async do |_task|
        payload = {}
        payload[:content] = content if content
        payload[:tts] = tts
        tmp_embed = if embed
            [embed]
          elsif embeds
            embeds
          end
        payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
        payload[:allowed_mentions] =
          allowed_mentions ? allowed_mentions.to_hash(@client.allowed_mentions) : @client.allowed_mentions.to_hash
        payload[:message_reference] = reference.to_reference if reference
        if components
          tmp_components = []
          tmp_row = []
          components.each do |c|
            case c
            when Array
              tmp_components << tmp_row
              tmp_row = []
              tmp_components << c
            when SelectMenu
              tmp_components << tmp_row
              tmp_row = []
              tmp_components << [c]
            else
              tmp_row << c
            end
          end
          tmp_components << tmp_row
          payload[:components] = tmp_components.filter { |c| c.length.positive? }.map { |c| { type: 1, components: c.map(&:to_hash) } }
        end
        files = [file] if file
        if files
          headers, payload = HTTP.multipart(payload, files)
        else
          headers = {}
        end
        _resp, data = @client.http.post("#{base_url.wait}/messages", payload, headers: headers).wait
        Message.new(@client, data.merge({ guild_id: @guild_id.to_s }))
      end
    end

    #
    # Fetch a message from ID.
    #
    # @param [Discorb::Snowflake] id The ID of the message.
    #
    # @return [Discorb::Message] The message.
    # @raise [Discorb::NotFoundError] If the message is not found.
    #
    def fetch_message(id)
      Async do
        _resp, data = @client.http.get("#{base_url.wait}/messages/#{id}").wait
        Message.new(@client, data.merge({ guild_id: @guild_id.to_s }))
      end
    end

    #
    # Fetch a message history.
    #
    # @param [Integer] limit The number of messages to fetch.
    # @param [Discorb::Snowflake] before The ID of the message to fetch before.
    # @param [Discorb::Snowflake] after The ID of the message to fetch after.
    # @param [Discorb::Snowflake] around The ID of the message to fetch around.
    #
    # @return [Array<Discorb::Message>] The messages.
    #
    def fetch_messages(limit = 50, before: nil, after: nil, around: nil)
      Async do
        params = {
          limit: limit,
          before: Discorb::Utils.try(after, :id),
          after: Discorb::Utils.try(around, :id),
          around: Discorb::Utils.try(before, :id),
        }.filter { |_k, v| !v.nil? }.to_h
        _resp, messages = @client.http.get("#{base_url.wait}/messages?#{URI.encode_www_form(params)}").wait
        messages.map { |m| Message.new(@client, m.merge({ guild_id: @guild_id.to_s })) }
      end
    end

    #
    # Trigger the typing indicator in the channel.
    # @macro async
    # @macro http
    #
    # If block is given, trigger typing indicator during executing block.
    # @example
    #   channel.typing do
    #     channel.post("Waiting for 60 seconds...")
    #     sleep 60
    #     channel.post("Done!")
    #   end
    #
    def typing
      Async do |task|
        if block_given?
          begin
            post_task = task.async do
              @client.http.post("/channels/#{@id}/typing", {})
              sleep(5)
            end
            yield
          ensure
            post_task.stop
          end
        else
          @client.http.post("/channels/#{@id}/typing", {})
        end
      end
    end
  end
end
