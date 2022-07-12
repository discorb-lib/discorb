# frozen_string_literal: true

module Discorb
  #
  # Represents a shard.
  #
  class Shard
    # @return [Integer] The ID of the shard.
    attr_reader :id
    # @return [Thread] The thread of the shard.
    attr_reader :thread
    # @return [Logger] The logger of the shard.
    attr_reader :logger
    # @private
    # @return [Integer] The internal index of the shard.
    attr_reader :index
    # @private
    attr_accessor :status, :connection, :session_id, :next_shard, :main_task

    #
    # Initializes a new shard.
    # @private
    #
    # @param [Discorb::Client] client The client.
    # @param [Integer] id The ID of the shard.
    # @param [Integer] count The number of shards.
    # @param [Integer] index The index of the shard.
    #
    def initialize(client, id, count, index)
      @client = client
      @id = id
      @shard_count = count
      @status = :idle
      @index = index
      @session_id = nil
      @next_shard = nil
      @main_task = nil
      @logger = client.logger.dup.tap { |l| l.progname = "discorb: shard #{id}" }
      @thread = Thread.new do
        Thread.current.thread_variable_set("shard_id", id)
        Thread.current.thread_variable_set("shard", self)
        if @index.positive?
          Thread.stop
          sleep 5 # Somehow discord disconnects the shard without a little sleep.
        end
        client.send(:main_loop, id)
      end
    end

    #
    # Starts the shard.
    #
    # @return [void]
    #
    def start
      @thread.wakeup
    end

    #
    # Stops the shard.
    #
    # @return [void]
    #
    def close
      @status = :closed
      @main_task&.stop
      @thread.kill
    end

    def inspect
      "#<#{self.class} #{id}/#{@shard_count} #{@status}>"
    end
  end
end
