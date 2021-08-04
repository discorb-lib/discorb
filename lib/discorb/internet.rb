# frozen_string_literal: true

require 'async/http/internet'
require_relative 'common'
require_relative 'error'

module Discorb
  class Internet < Async::HTTP::Internet
    @nil_body = nil

    def initialize(client)
      @client = client
      super()
    end

    def get(path, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(get_path(path), get_headers(headers, '', audit_log_reason), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == 429
                     @client.log.warn "Ratelimit exceeded for #{path}, trying again in #{data[:retry_after]} seconds."
                     task.sleep(data[:retry_after])
                     get(path, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
                   else
                     [resp, data]
                   end)
      end
    end

    def post(path, body = '', headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(get_path(path), get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == 429
                     task.sleep(data[:retry_after])
                     post(path, body, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
                   else
                     [resp, data]
                   end)
      end
    end

    def patch(path, body = '', headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(get_path(path), get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == 429
                     task.sleep(data[:retry_after])
                     patch(path, body, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
                   else
                     [resp, data]
                   end)
      end
    end

    def put(path, body = '', headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(get_path(path), get_headers(headers, body, audit_log_reason), get_body(body), **kwargs)
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == 429
                     task.sleep(data[:retry_after])
                     put(path, body, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
                   else
                     [resp, data]
                   end)
      end
    end

    def delete(path, headers: nil, audit_log_reason: nil, **kwargs)
      Async do |task|
        resp = super(get_path(path), get_headers(headers, '', audit_log_reason), '')
        rd = resp.read
        data = if rd.nil?
                 nil
               else
                 JSON.parse(rd, symbolize_names: true)
               end
        test_error(if resp.status == 429
                     task.sleep(data[:retry_after])
                     delete(path, headers: headers, audit_log_reason: audit_log_reason, **kwargs).wait
                   else
                     [resp, data]
                   end)
      end
    end

    def inspect
      "#<#{self.class} client=#{@client}>"
    end

    def self.multipart(payload, files)
      boundary = "DiscorbBySevenC7CMultipartFormData#{Time.now.to_f}"
      str_payloads = [<<~HTTP
        Content-Disposition: form-data; name="payload_json"
        Content-Type: application/json

        #{payload.to_json}
      HTTP
      ]
      files.each do |single_file|
        str_payloads << <<~HTTP
          Content-Disposition: form-data; name="file"; filename="#{single_file.filename}"
          Content-Type: #{single_file.content_type}

          #{single_file.io.read}
        HTTP
      end
      [boundary, "--#{boundary}\n#{str_payloads.join("\n--#{boundary}\n")}\n--#{boundary}--"]
    end

    private

    def test_error(ary)
      resp, data = *ary
      case resp.status
      when 400
        raise BadRequestError.new(resp, data)
      when 403
        raise ForbiddenError.new(resp, data)
      when 404
        raise NotFoundError.new(resp, data)
      else
        [resp, data]
      end
    end

    def get_headers(headers, body = '', audit_log_reason = nil)
      ret = if body.nil?
              { 'User-Agent' => USER_AGENT, 'authorization' => "Bot #{@client.token}" }
            else
              { 'User-Agent' => USER_AGENT, 'authorization' => "Bot #{@client.token}",
                'content-type' => 'application/json' }
            end
      ret.merge(headers) if !headers.nil? && headers.length.positive?
      ret['X-Audit-Log-Reason'] = audit_log_reason unless audit_log_reason.nil?
      ret
    end

    def get_body(body)
      if body.nil?
        []
      elsif body.is_a?(String)
        [body]
      else
        [recr_utf8(body).to_json]
      end
    end

    def get_path(path)
      if path.start_with?('https://')
        path
      else
        API_BASE_URL + path
      end
    end

    def recr_utf8(data)
      case data
      when Hash
        data.each do |k, v|
          data[k] = recr_utf8(v)
        end
        data
      when Array
        data.each_index do |i|
          data[i] = recr_utf8(data[i])
        end
        data
      when String
        data.dup.force_encoding(Encoding::UTF_8)
      else
        data
      end
    end
  end
end
