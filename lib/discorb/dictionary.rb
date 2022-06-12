# frozen_string_literal: true

module Discorb
  #
  # Extended hash class. This is used for storing pair of ID and object.
  #
  class Dictionary
    # @return [Numeric] The maximum number of items in the dictionary.
    attr_accessor :limit

    #
    # Initialize a new Dictionary.
    #
    # @param [Hash] hash A hash of items to add to the dictionary.
    # @param [Numeric] limit The maximum number of items in the dictionary.
    # @param [false, Proc] sort Whether to sort the items in the dictionary.
    #
    def initialize(hash = {}, limit: nil, sort: false)
      @cache = hash.transform_keys(&:to_s)
      @limit = limit
      @sort = sort
      @cache = @cache.sort_by(&@sort).to_h if @sort
    end

    #
    # Registers a new item in the dictionary.
    #
    # @param [#to_s] id The ID of the item.
    # @param [Object] body The item to register.
    #
    # @return [self] The dictionary.
    #
    def register(id, body)
      @cache[id.to_s] = body
      @cache = @cache.sort_by(&@sort).to_h if @sort
      @cache.delete(@cache.keys[0]) if !@limit.nil? && @cache.size > @limit
      self
    end

    #
    # Merges another dictionary into this one.
    #
    # @param [Discorb::Dictionary] other The dictionary to merge.
    #
    def merge(other)
      @cache.merge!(other.to_h)
    end

    #
    # Removes an item from the dictionary.
    #
    # @param [#to_s] id The ID of the item to remove.
    #
    def remove(id)
      @cache.delete(id.to_s)
    end

    alias delete remove

    #
    # Get an item from the dictionary.
    #
    # @param [#to_s] id The ID of the item.
    # @return [Object] The item.
    # @return [nil] if the item was not found.
    #
    # @overload get(index)
    #   @param [Numeric] index The index of the item.
    #
    #   @return [Object] The item.
    #   @return [nil] if the item is not found.
    #
    def get(id)
      res = @cache[id.to_s]
      if res.nil? && id.is_a?(Numeric) && id < @cache.length
        @cache.values[id]
      else
        res
      end
    end

    #
    # Convert the dictionary to a hash.
    #
    def to_h
      @cache
    end

    #
    # Returns the values of the dictionary.
    #
    # @return [Array] The values of the dictionary.
    #
    def values
      @cache.values
    end

    #
    # Checks if the dictionary has an ID.
    #
    # @param [#to_s] id The ID to check.
    #
    # @return [Boolean] `true` if the dictionary has the ID, `false` otherwise.
    #
    def has?(id)
      !self[id].nil?
    end

    #
    # Send a message to the array of values.
    #
    def method_missing(name, ...)
      if values.respond_to?(name)
        values.send(name, ...)
      else
        super
      end
    end

    def respond_to_missing?(name, ...)
      if values.respond_to?(name)
        true
      else
        super
      end
    end

    alias [] get
    alias []= register

    def inspect
      "#<#{self.class} #{values.length} items>"
    end
  end
end
