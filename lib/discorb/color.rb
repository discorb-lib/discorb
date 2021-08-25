# frozen_string_literal: true

module Discorb
  #
  # Represents RGB color.
  #
  class Color
    attr_accessor :value

    @discord_colors = {
      teal: 0x1abc9c,
      dark_teal: 0x11806a,
      green: 0x2ecc71,
      dark_green: 0x1f8b4c,
      blue: 0x3498db,
      dark_blue: 0x206694,
      purple: 0x9b59b6,
      dark_purple: 0x71368a,
      magenta: 0xe91e63,
      dark_magenta: 0xad1457,
      gold: 0xf1c40f,
      dark_gold: 0xc27c0e,
      orange: 0xe67e22,
      dark_orange: 0xa84300,
      red: 0xe74c3c,
      dark_red: 0x992d22,
      lighter_grey: 0x95a5a6,
      lighter_gray: 0x95a5a6,
      dark_grey: 0x607d8b,
      dark_gray: 0x607d8b,
      light_grey: 0x979c9f,
      light_gray: 0x979c9f,
      darker_grey: 0x546e7a,
      darker_gray: 0x546e7a,
      og_blurple: 0x7289da,
      blurple: 0x5865f2,
      greyple: 0x99aab5,
      dark_theme: 0x36393f,
      fuchsia: 0xeb459e,
      yellow: 0xfee75c,
    }.freeze

    #
    # Create a color from a Integer.
    #
    # @param [Integer] value A color value.
    #
    def initialize(value)
      @value = value
    end

    #
    # Integerize a color.
    #
    # @return [Integer] A color value.
    #
    def to_i
      @value
    end

    #
    # Convert a color to a hexadecimal value.
    #
    # @return [String] A hexadecimal value.
    #
    def to_hex
      @value.to_s(16).rjust(6, "0")
    end

    #
    # Convert a color to RGB array.
    #
    # @return [Array(Integer, Integer, Integer)] A RGB array.
    #
    def to_rgb
      [@value / (256 * 256), @value / 256 % 256, @value % 256]
    end

    alias to_a to_rgb
    alias deconstruct to_rgb

    #
    # Convert a color to RGB hash.
    #
    # @return [Hash{:r, :g, :b => Integer}] A RGB hash.
    #
    def to_rgb_hash
      [@value / (256 * 256), @value / 256 % 256, @value % 256]
    end

    alias deconstruct_keys to_rgb_hash

    #
    # Converts a color to a `#000000` string.
    #
    # @return [String] Converted string.
    #
    def to_s
      "##{to_hex}"
    end

    def inspect
      "#<#{self.class} #{@value}/#{self}>"
    end

    #
    # Create a color from a hexadecimal string.
    #
    # @param [String] hex A hexadecimal string.
    #
    # @return [Discorb::Color] A color object.
    #
    def self.from_hex(hex)
      new(hex.to_i(16))
    end

    #
    # Create a color from a RGB array.
    #
    # @param [Integer] red A red value.
    # @param [Integer] green A green value.
    # @param [Integer] blue A blue value.
    #
    # @return [Discorb::Color] A color object.
    #
    def self.from_rgb(red, green, blue)
      new(red * 256 * 256 + green * 256 + blue)
    end

    #
    # Create a color from a Discord's color.
    # Currently these colors are supported:
    #   - teal (0x1abc9c)
    #   - dark_teal (0x11806a)
    #   - green (0x2ecc71)
    #   - dark_green (0x1f8b4c)
    #   - blue (0x3498db)
    #   - dark_blue (0x206694)
    #   - purple (0x9b59b6)
    #   - dark_purple (0x71368a)
    #   - magenta (0xe91e63)
    #   - dark_magenta (0xad1457)
    #   - gold (0xf1c40f)
    #   - dark_gold (0xc27c0e)
    #   - orange (0xe67e22)
    #   - dark_orange (0xa84300)
    #   - red (0xe74c3c)
    #   - dark_red (0x992d22)
    #   - lighter_grey (0x95a5a6)
    #   - lighter_gray (0x95a5a6)
    #   - dark_grey (0x607d8b)
    #   - dark_gray (0x607d8b)
    #   - light_grey (0x979c9f)
    #   - light_gray (0x979c9f)
    #   - darker_grey (0x546e7a)
    #   - darker_gray (0x546e7a)
    #   - og_blurple (0x7289da)
    #   - blurple (0x5865f2)
    #   - greyple (0x99aab5)
    #   - dark_theme (0x36393f)
    #   - fuchsia (0xeb459e)
    #
    # @param [Symbol] color A Discord color name.
    #
    # @return [Discorb::Color] A color object.
    #
    def self.[](color)
      new(@discord_colors[color])
    end
  end

  Colour = Color
end
