# frozen_string_literal: true

require "net/http"

module Discorb
  #
  # A class to handle http requests.
  # @private
  #
  class HTTP
    @nil_body = nil

    #
    # Initializes the http client.
    # @private
    #
    # @param [Discorb::Client] client The client.
    #
    def initialize(client)
      @client = client
      @ratelimit_handler = RatelimitHandler.new(client)
    end

    #
    # Execute a request.
    # @async
    #
    # @param [Discorb::Route] path The path to the resource.
    # @param [String, Hash] body The body of the request. Defaults to an empty string.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Async::Task<Array(Net::HTTPResponse, Hash)>] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def request(path, body = "", audit_log_reason: nil, **kwargs)
      Async do |_task|
        @ratelimit_handler.wait(path)
        resp = if %i[post patch put].include? path.method
            http.send(
              path.method,
              get_path(path),
              get_body(body),
              get_headers(body, audit_log_reason),
              **kwargs,
            )
          else
            http.send(
              path.method,
              get_path(path),
              get_headers(body, audit_log_reason),
              **kwargs,
            )
          end
        data = get_response_data(resp)
        @ratelimit_handler.save(path, resp)
        handle_response(resp, data, path, body, nil, audit_log_reason, kwargs)
      end
    end

    #
    # Execute a multipart request.
    # @async
    #
    # @param [Discorb::Route] path The path to the resource.
    # @param [String, Hash] body The body of the request.
    # @param [Array<Discorb::Attachment>] files The files to upload.
    # @param [String] audit_log_reason The audit log reason to send with the request.
    # @param [Hash] kwargs The keyword arguments.
    #
    # @return [Async::Task<Array(Net::HTTPResponse, Hash)>] The response and as JSON.
    # @return [Async::Task<Array(Net::HTTPResponse, nil)>] The response was 204.
    #
    # @raise [Discorb::HTTPError] The request was failed.
    #
    def multipart_request(path, body, files, audit_log_reason: nil, **kwargs)
      Async do |_task|
        @ratelimit_handler.wait(path)
        req = Net::HTTP.const_get(path.method.to_s.capitalize).new(
          get_path(path),
          get_headers(body, audit_log_reason),
          **kwargs,
        )
        data = [
          ["payload_json", get_body(body)],
        ]
        files&.each_with_index do |file, i|
          next if file.nil?

          if file.created_by == :discord
            request_io = StringIO.new(
              cdn_http.get(
                URI.parse(file.url).path,
                {
                  "Content-Type" => nil,
                  "User-Agent" => Discorb::USER_AGENT,
                }
              ).body
            )
            data << ["files[#{i}]", request_io, { filename: file.filename, content_type: file.content_type }]
          else
            data << ["files[#{i}]", file.io, { filename: file.filename, content_type: file.content_type }]
          end
        end
        req.set_form(data, "multipart/form-data")
        session = Net::HTTP.new("discord.com", 443)
        session.use_ssl = true
        resp = session.request(req)
        data = get_response_data(resp)
        @ratelimit_handler.save(path, resp)
        response = handle_response(resp, data, path, body, files, audit_log_reason, kwargs)
        files&.then { _1.filter(&:will_close).each { |f| f.io.close } }
        response
      end
    end

    def inspect
      "#<#{self.class} client=#{@client}>"
    end

    private

    def handle_response(resp, data, path, body, files, audit_log_reason, kwargs)
      case resp.code
      when "429"
        @client.logger.info("Rate limit exceeded for #{path.method} #{path.url}, waiting #{data[:retry_after]} seconds")
        sleep(data[:retry_after])
        if files
          multipart_request(path, body, files, audit_log_reason: audit_log_reason, **kwargs).wait
        else
          request(path, body, audit_log_reason: audit_log_reason, **kwargs).wait
        end
      when "400"
        raise BadRequestError.new(resp, data)
      when "401"
        raise UnauthorizedError.new(resp, data)
      when "403"
        raise ForbiddenError.new(resp, data)
      when "404"
        raise NotFoundError.new(resp, data)
      else
        [resp, data]
      end
    end

    def get_headers(body = "", audit_log_reason = nil)
      ret = if body.nil? || body == ""
          {
            "User-Agent" => USER_AGENT,
            "Authorization" => "Bot #{@client.token}",
            "Connection" => "Keep-Alive",
          }
        else
          {
            "User-Agent" => USER_AGENT,
            "Authorization" => "Bot #{@client.token}",
            "Content-Type" => "application/json",
            "Connection" => "Keep-Alive",
          }
        end
      ret["X-Audit-Log-Reason"] = audit_log_reason unless audit_log_reason.nil?
      ret
    end

    def get_body(body)
      if body.nil?
        ""
      elsif body.is_a?(String)
        body
      else
        recr_utf8(body).to_json
      end
    end

    def get_path(path)
      full_path = if path.url.start_with?("https://")
          path.url
        else
          API_BASE_URL + path.url
        end
      uri = URI(full_path)
      full_path.sub(uri.scheme + "://" + uri.host, "")
    end

    def get_response_data(resp)
      begin
        data = JSON.parse(resp.body, symbolize_names: true)
      rescue JSON::ParserError, TypeError
        data = if resp.body.nil? || resp.body.empty?
            nil
          else
            resp.body
          end
      end
      raise CloudFlareBanError.new(resp, @client) if resp["Via"].nil? && resp.code == "429" && data.is_a?(String)

      data
    end

    def http
      if @http.nil?
        http = Net::HTTP.new("discord.com", 443)
        http.use_ssl = true
        http.start
        @http = http
      end
      @http
    end

    def cdn_http
      if @cdn_http.nil?
        http = Net::HTTP.new("cdn.discordapp.com", 443)
        http.use_ssl = true
        http.start
        @cdn_http = http
      end
      @cdn_http
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
