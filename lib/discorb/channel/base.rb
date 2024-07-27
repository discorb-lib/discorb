# frozen_string_literal: true

module Discorb
  #
  # Represents a channel of Discord.
  # @abstract
  #
  class Channel < DiscordModel
    # @return [Discorb::Snowflake] The ID of the channel.
    attr_reader :id
    # @return [String] The name of the channel.
    attr_reader :name

    # @!attribute [r] type
    #   @return [Integer] The type of the channel as integer.

    @channel_type = nil
    @subclasses = []

    #
    # Initializes a new instance of the Channel class.
    # @private
    #
    def initialize(client, data, no_cache: false)
      # @type [Discorb::Client]
      @client = client
      @data = {}
      @no_cache = no_cache
      _set_data(data)
    end

    #
    # Checks if the channel is other channel.
    #
    # @param [Discorb::Channel] other The channel to check.
    #
    # @return [Boolean] True if the channel is other channel.
    #
    def ==(other)
      return false unless other.respond_to?(:id)

      @id == other.id
    end

    def inspect
      "#<#{self.class} \"##{@name}\" id=#{@id}>"
    end

    #
    # Returns the descendants of the Channel class.
    # @private
    #
    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    #
    # Creates a new instance of the Channel class or instance of its descendants.
    # @private
    #
    # @param [Discorb::Client] client The client that instantiated the object.
    # @param [Hash] data The data of the object.
    # @param [Boolean] no_cache Whether to disable cache the object.
    #
    def self.make_channel(client, data, no_cache: false)
      descendants.each do |klass|
        if !klass.channel_type.nil? && klass.channel_type == data[:type] &&
             klass != ForumChannel::Post
          return klass.new(client, data, no_cache:)
        end
      end
      client.logger.warn(
        "Unknown channel type #{data[:type]}, initialized GuildChannel"
      )
      GuildChannel.new(client, data)
    end

    class << self
      #
      # @private
      # @return [Integer] The type of the channel.
      #
      attr_reader :channel_type
    end

    def type
      self.class.channel_type
    end

    #
    # Returns the channel id to request.
    # @private
    #
    # @return [Async::Task<Discorb::Snowflake>] A task that resolves to the channel id.
    #
    def channel_id
      Async { @id }
    end

    private

    def _set_data(data)
      @id = Snowflake.new(data[:id])
      @name = data[:name]
      @client.channels[@id] = self if !@no_cache && !(data[:no_cache])
      @data.update(data)
    end
  end
end
