# frozen_string_literal: true

module Discorb
  #
  # Represents a shard.
  #
  class Shard
    attr_reader :number, :thread, :shard_count
    attr_accessor :status, :connection
    #
    # Initializes a new shard.
    #
    # @param [Discorb::Client] client The client.
    # @param [Integer] number The number of the shard.
    # @param [Integer] shard_count The number of shards.
    #
    def initialize(client, number, shard_count)
      @client = client
      @number = number
      @thread = Thread.start do
        Thread.current.thread_variable_set("shard_id", number)
        client.send(:main_loop, number)
      end
      @shard_count = shard_count
      @status = :idle
    end

    def inspect
      "#<#{self.class} #{@number}/#{@shard_count} #{@status}>"
    end
  end
end
