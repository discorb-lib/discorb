module Discorb
  class Color
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def to_i
      @value
    end

    def to_hex
      @value.to_s(16)
    end

    def to_rgb
      [@value / (256 * 256), @value / 256 % 256, @value % 256]
    end

    def to_s
      "#" + @value.to_s(16)
    end

    def inspect
      "#<#{self.class} #{@value}/##{to_hex}>"
    end

    alias_method :to_a, :to_rgb

    def self.from_hex(hex)
      self.new(hex.to_i(16))
    end
    def self.from_rgb(r, g, b)
      self.new(r * 256 * 256 + g * 256 + b)
    end
  end
end
