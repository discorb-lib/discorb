# frozen_string_literal: true

module Discorb
  #
  # Represents a flag.
  # @abstract
  #
  class Flag
    # @return [Hash{Symbol => Boolean}] the values of the flag.
    attr_reader :values
    alias to_h values
    # @return [Integer] the value of the flag.
    attr_reader :value

    @bits = {}

    # Initialize the flag.
    # @note This is usually called by the subclass.
    #
    # @param [Integer] value The value of the flag.
    def initialize(value)
      @value = value
      @values = {}
      self.class.bits.each_with_index do |(bn, bv), _i|
        @values[bn] = value & (1 << bv) != 0
      end
    end

    #
    # Returns the value of the flag.
    #
    def method_missing(name, args = nil)
      if @values.key?(name.to_s.delete_suffix("?").to_sym)
        @values[name.to_s.delete_suffix("?").to_sym]
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private)
      @values.key?(name.to_s.delete_suffix("?").to_sym) ? true : super
    end

    #
    # Union of two flags.
    #
    # @param [Discorb::Flag] other The other flag.
    #
    # @return [Discorb::Flag] The union of the two flags.
    #
    def |(other)
      self.class.new(@value | other.value)
    end

    alias + |

    #
    # Subtraction of two flags.
    #
    # @param [Discorb::Flag] other The other flag.
    #
    # @return [Discorb::Flag] The subtraction of the two flags.
    #
    def -(other)
      self.class.new(@value & (@value ^ other.value))
    end

    #
    # Intersection of two flags.
    #
    # @param [Discorb::Flag] other The other flag.
    #
    # @return [Discorb::Flag] The intersection of the two flags.
    #
    def &(other)
      self.class.new(@value & other.value)
    end

    #
    # XOR of two flags.
    #
    # @param [Discorb::Flag] other The other flag.
    #
    # @return [Discorb::Flag] The XOR of the two flags.
    #
    def ^(other)
      self.class.new(@value ^ other.value)
    end

    #
    # Negation of the flag.
    #
    # @return [Discorb::Flag] The negation of the flag.
    #
    def ~@
      self.class.new(~@value)
    end

    class << self
      # @return [Hash{Integer => Symbol}] the bits of the flag.
      attr_reader :bits

      #
      # Max value of the flag.
      #
      # @return [Integer] the max value of the flag.
      #
      def max_value
        2 ** @bits.values.max - 1
      end
    end
  end
end
