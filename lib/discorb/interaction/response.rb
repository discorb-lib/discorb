module Discorb
  class Interaction
    #
    # A module for response with source.
    #
    module SourceResponse
      #
      # Response with `DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE`(`5`).
      #
      # @async
      #
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      # @return [Async::Task<void>] The task.
      #
      def defer_source(ephemeral: false)
        Async do
          @client.http.post("/interactions/#{@id}/#{@token}/callback", {
            type: 5,
            data: {
              flags: (ephemeral ? 1 << 6 : 0),
            },
          }).wait
          @defered = true
        end
      end

      #
      # Response with `CHANNEL_MESSAGE_WITH_SOURCE`(`4`).
      #
      # @async
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      # @return [Discorb::Interaction::SourceResponse::CallbackMessage, Discorb::Webhook::Message] The callback message.
      #
      def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, ephemeral: false)
        Async do
          payload = {}
          payload[:content] = content if content
          payload[:tts] = tts
          payload[:embeds] = (embeds || [embed])&.map { |e| e&.to_hash }.filter { _1 }
          payload[:allowed_mentions] = allowed_mentions&.to_hash(@client.allowed_mentions) || @client.allowed_mentions.to_hash
          payload[:components] = Component.to_payload(components) if components
          payload[:flags] = (ephemeral ? 1 << 6 : 0)

          ret = if @responded
              _resp, data = @client.http.post("/webhooks/#{@application_id}/#{@token}", payload).wait
              webhook = Webhook::URLWebhook.new("/webhooks/#{@application_id}/#{@token}")
              Webhook::Message.new(webhook, data, @client)
            elsif @defered
              @client.http.patch("/webhooks/#{@application_id}/#{@token}/messages/@original", payload).wait
              CallbackMessage.new(@client, payload, @application_id, @token)
            else
              @client.http.post("/interactions/#{@id}/#{@token}/callback", { type: 4, data: payload }).wait
              CallbackMessage.new(@client, payload, @application_id, @token)
            end
          @responded = true
          ret
        end
      end

      class CallbackMessage
        # @private
        def initialize(client, data, application_id, token)
          @client = client
          @data = data
          @application_id = application_id
          @token = token
        end

        #
        # Edits the callback message.
        # @async
        # @macro edit
        #
        # @param [String] content The new content of the message.
        # @param [Discorb::Embed] embed The new embed of the message.
        # @param [Array<Discorb::Embed>] embeds The new embeds of the message.
        # @param [Array<Discorb::Attachment>] attachments The attachments to remain.
        # @param [Discorb::File] file The file to send.
        # @param [Array<Discorb::File>] files The files to send.
        #
        # @return [Async::Task<void>] The task.
        #
        def edit(
          content = :unset,
          embed: :unset, embeds: :unset,
          file: :unset, files: :unset,
          attachments: :unset
        )
          Async do
            payload = {}
            payload[:content] = content if content != :unset
            payload[:embeds] = embed ? [embed.to_hash] : [] if embed != :unset
            payload[:embeds] = embeds.map(&:to_hash) if embeds != :unset
            payload[:attachments] = attachments.map(&:to_hash) if attachments != :unset
            files = [file] if file != :unset
            files = [] if files == :unset
            @client.http.multipart_patch("/webhooks/#{@application_id}/#{@token}/messages/@original", payload, files, headers: headers).wait
          end
        end

        alias modify edit

        #
        # Deletes the callback message.
        # @async
        # @note This will fail if the message is ephemeral.
        #
        # @return [Async::Task<void>] The task.
        #
        def delete!
          Async do
            @client.http.delete("/webhooks/#{@application_id}/#{@token}/messages/@original").wait
          end
        end
      end
    end

    #
    # A module for response with update.
    #
    module UpdateResponse
      #
      # Response with `DEFERRED_UPDATE_MESSAGE`(`6`).
      # @async
      #
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      # @return [Async::Task<void>] The task.
      #
      def defer_update(ephemeral: false)
        Async do
          @client.http.post("/interactions/#{@id}/#{@token}/callback", {
            type: 6,
            data: {
              flags: (ephemeral ? 1 << 6 : 0),
            },
          }).wait
        end
      end

      #
      # Response with `UPDATE_MESSAGE`(`7`).
      #
      # @async
      #
      # @param [String] content The content of the response.
      # @param [Boolean] tts Whether to send the message as text-to-speech.
      # @param [Discorb::Embed] embed The embed to send.
      # @param [Array<Discorb::Embed>] embeds The embeds to send. (max: 10)
      # @param [Discorb::AllowedMentions] allowed_mentions The allowed mentions to send.
      # @param [Array<Discorb::Component>, Array<Array<Discorb::Component>>] components The components to send.
      # @param [Boolean] ephemeral Whether to make the response ephemeral.
      #
      # @return [Async::Task<void>] The task.
      #
      def edit(content, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, components: nil, ephemeral: false)
        Async do
          payload = {}
          payload[:content] = content if content
          payload[:tts] = tts
          tmp_embed = if embed
              [embed]
            elsif embeds
              embeds
            end
          payload[:embeds] = tmp_embed.map(&:to_hash) if tmp_embed
          payload[:allowed_mentions] = allowed_mentions ? allowed_mentions.to_hash(@client.allowed_mentions) : @client.allowed_mentions.to_hash
          payload[:components] = Component.to_payload(components) if components
          payload[:flags] = (ephemeral ? 1 << 6 : 0)
          @client.http.post("/interactions/#{@id}/#{@token}/callback", { type: 7, data: payload }).wait
        end
      end
    end

    private

    def _set_data(*)
      nil
    end
  end
end
