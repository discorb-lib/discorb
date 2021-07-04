# frozen_string_literal: true

require_relative 'components'
module Discorb
  module Messageable
    def post(content = nil, tts: false, embed: nil, embeds: nil, allowed_mentions: nil, message_reference: nil, components: nil, attachments: nil)
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
        payload[:message_reference] = message_reference.to_reference if message_reference
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
        if attachments
          boundary = "DiscorbChannels#{@channel_id}MessagesPost#{Time.now.to_f}"
          headers = {
            'content-type'=> "multipart/form-data; boundary=#{boundary}"
          }
          str_payloads = [<<~HTTP
                        Content-Disposition: form-data; name="payload_json"
                        Content-Type: application/json

                        #{payload.to_json}
          HTTP
          ]
          attachments.each do |file|
            str_payloads << <<~HTTP
                            Content-Disposition: form-data; name="file"; filename="#{file.filename}"
                            Content-Type: #{file.content_type}

                            #{file.io.read}
            HTTP
          end
          payload = "--#{boundary}\n#{str_payloads.join("\n--#{boundary}\n")}\n--#{boundary}--"
        else
          headers = {}
        end
        Message.new(@client, @client.internet.post(post_url, payload, headers: headers).wait[1])
      end
    end
  end
end
