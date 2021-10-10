# frozen_string_literal: true

module Discorb
  #
  # Class to handle rate limiting.
  # @private
  #
  class RatelimitHandler
    # @private
    def initialize(client)
      @client = client
      @ratelimit_hash = {}
      @path_ratelimit_hash = {}
      @global = false
    end

    #
    # Wait for the rate limit to reset.
    #
    # @param [String] method The HTTP method.
    # @param [String] path The path.
    #
    def wait(method, path)
      return if path.start_with?("https://")

      if @global
        time = b[:reset_at] - Time.now.to_i
        @client.log.info("Global ratelimit reached, waiting #{time} seconds")
        sleep(time)
        @global = false
        
      end

      return unless hash = @path_ratelimit_hash[method + path]

      return unless b = @ratelimit_hash[hash]

      if b[:reset_at] < Time.now.to_i
        @ratelimit_hash.delete(hash)
        return
      end
      return if b[:remaining] > 0

      time = b[:reset_at] - Time.now.to_i
      @client.log.info("Ratelimit reached, waiting #{time} seconds")
      sleep(time)
    end

    #
    # Save the rate limit.
    #
    # @param [String] method The HTTP method.
    # @param [String] path The path.
    # @param [Net::HTTPResponse] resp The response.
    #
    def save(method, path, resp)
      if resp["X-Ratelimit-Global"] == "true"
        @global = Time.now.to_i + JSON.parse(resp.body, symbolize_names: true)[:retry_after]
      end
      return unless resp["X-RateLimit-Remaining"]

      @path_ratelimit_hash[method + path] = resp["X-RateLimit-Bucket"]
      @ratelimit_hash[resp["X-RateLimit-Bucket"]] = {
        remaining: resp["X-RateLimit-Remaining"].to_i,
        reset_at: resp["X-RateLimit-Reset"].to_i,
      }
    end
  end
end
