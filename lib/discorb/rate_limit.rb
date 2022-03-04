# frozen_string_literal: true

module Discorb
  #
  # Class to handle rate limiting.
  # @private
  #
  class RatelimitHandler
    #
    # Initialize a rate limit handler.
    # @private
    #
    # @param [Discorb::Client] client The client.
    #
    def initialize(client)
      @client = client
      @path_ratelimit_bucket = {}
      @path_ratelimit_hash = {}
      @global = false
    end

    def inspect
      "#<#{self.class}>"
    end

    #
    # Wait for the rate limit to reset.
    #
    # @param [Discorb::Route] path The path.
    #
    def wait(path)
      # return if path.url.start_with?("https://")
      if @global && @global > Time.now.to_f
        time = @global - Time.now.to_f
        @client.log.info("global rate limit reached, waiting #{time} seconds")
        sleep(time)
        @global = false
      end

      return unless hash = @path_ratelimit_hash[path.identifier]

      return unless bucket = @path_ratelimit_bucket[hash + path.major_param]

      if bucket[:reset_at] < Time.now.to_f
        @path_ratelimit_bucket.delete(path.identifier + path.major_param)
        return
      end
      return if (bucket[:remaining]).positive?

      time = bucket[:reset_at] - Time.now.to_f
      @client.log.info("rate limit for #{path.identifier} with #{path.major_param} reached, waiting #{time.round(4)} seconds")
      sleep(time)
    end

    #
    # Save the rate limit.
    #
    # @param [String] path The path.
    # @param [Net::HTTPResponse] resp The response.
    #
    def save(path, resp)
      @global = Time.now.to_f + JSON.parse(resp.body, symbolize_names: true)[:retry_after] if resp["X-Ratelimit-Global"] == "true"
      return unless resp["X-RateLimit-Remaining"]
      @path_ratelimit_hash[path.identifier] = resp["X-Ratelimit-Bucket"]
      @path_ratelimit_bucket[resp["X-Ratelimit-Bucket"] + path.major_param] = {
        remaining: resp["X-RateLimit-Remaining"].to_i,
        reset_at: Time.now.to_f + resp["X-RateLimit-Reset-After"].to_f,
      }
    end
  end
end
