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
          @client.http.request(Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post), {
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
              _resp, data = @client.http.request(Route.new("/webhooks/#{@application_id}/#{@token}", "//webhooks/:webhook_id/:token", :post), payload).wait
              webhook = Webhook::URLWebhook.new("/webhooks/#{@application_id}/#{@token}")
              Webhook::Message.new(webhook, data, @client)
            elsif @defered
              @client.http.request(Route.new("/webhooks/#{@application_id}/#{@token}/messages/@original", "//webhooks/:webhook_id/:token/messages/@original", :patch), payload).wait
              CallbackMessage.new(@client, payload, @application_id, @token)
            else
              @client.http.request(Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post), { type: 4, data: payload }).wait
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
          content = Discorb::Unset,
          embed: Discorb::Unset, embeds: Discorb::Unset,
          file: Discorb::Unset, files: Discorb::Unset,
          attachments: Discorb::Unset
        )
          Async do
            payload = {}
            payload[:content] = content if content != Discorb::Unset
            payload[:embeds] = embed ? [embed.to_hash] : [] if embed != Discorb::Unset
            payload[:embeds] = embeds.map(&:to_hash) if embeds != Discorb::Unset
            payload[:attachments] = attachments.map(&:to_hash) if attachments != Discorb::Unset
            files = [file] if file != Discorb::Unset
            files = [] if files == Discorb::Unset
            @client.http.multipart_request(Route.new("/webhooks/#{@application_id}/#{@token}/messages/@original", "//webhooks/:webhook_id/:token/messages/@original", :patch), payload, files, headers: headers).wait
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
            @client.http.request(Route.new("/webhooks/#{@application_id}/#{@token}/messages/@original", "//webhooks/:webhook_id/:token/messages/@original", :delete)).wait
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
          @client.http.request(Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post), {
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
          @client.http.request(Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post), { type: 7, data: payload }).wait
        end
      end
    end

    module ModalResponse
      #
      # Response with `MODAL`(`9`).
      #
      # @param [String] title The title of the modal.
      # @param [String] custom_id The custom id of the modal.
      # @param [Array<Discorb::TextInput>] components The text inputs to send.
      #
      # @return [Async::Task<void>] The task.
      #
      def show_modal(title, custom_id, components)
        payload = { title: title, custom_id: custom_id, components: Component.to_payload(components) }
        @client.http.request(
          Route.new("/interactions/#{@id}/#{@token}/callback", "//interactions/:interaction_id/:token/callback", :post),
          { type: 9, data: payload }
        ).wait
      end
    end

    private

    def _set_data(*)
      nil
    end
  end
end
