# frozen_string_literal: true

module Discorb
  #
  # Represents a shard.
  #
  class Shard
    attr_reader :number, :thread, :shard_count, :index
    attr_accessor :status, :connection, :session_id, :next_shard
    #
    # Initializes a new shard.
    #
    # @param [Discorb::Client] client The client.
    # @param [Integer] number The number of the shard.
    # @param [Integer] shard_count The number of shards.
    # @param [Integer] index The index of the shard.
    #
    def initialize(client, number, shard_count, index)
      @client = client
      @number = number
      @shard_count = shard_count
      @status = :idle
      @index = index
      @session_id = nil
      @next_shard = nil
      @thread = Thread.new do
        Thread.current.thread_variable_set("shard_id", number)
        Thread.current.thread_variable_set("shard", self)
        Thread.stop if @index.positive?
        sleep 5
        client.send(:main_loop, number)
      end
    end

    def start
      @thread.wakeup
    end

    def inspect
      "#<#{self.class} #{@number}/#{@shard_count} #{@status}>"
    end
  end
end
