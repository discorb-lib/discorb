# frozen_string_literal: true

begin
  require "colorize"
  LOADED_COLORIZE = true
rescue LoadError
  LOADED_COLORIZE = false
end

module Discorb
  # @!visibility private
  class Logger
    attr_reader :out, :colorize_log

    @levels = %i[debug info warn error fatal].freeze

    def initialize(out, colorize_log, level)
      @out = out
      @level = self.class.levels.index(level)
      @colorize_log = colorize_log
      raise "colorize is required to use colorized log" if !LOADED_COLORIZE && @colorize_log
    end

    def level
      @levels[@level]
    end

    def level=(level)
      @level = @levels.index(level)
    end

    def debug(message)
      return unless @level <= 0

      write_output("DEBUG", :light_black, message)
    end

    def info(message)
      return unless @level <= 1

      write_output("INFO", :light_blue, message)
    end

    def warn(message)
      return unless @level <= 2

      write_output("WARN", :yellow, message)
    end

    def error(message)
      return unless @level <= 3

      write_output("ERROR", :red, message)
    end

    def fatal(message)
      return unless @level <= 4

      write_output("FATAL", :light_red, message)
    end

    class << self
      attr_reader :levels
    end

    private

    def write_output(name, color, message)
      return unless @out

      if @colorize_log
        @out.puts(format(
          "%<info>s %<message>s",
          info: [
            name[0].colorize(color),
            Time.now.strftime("[%D %T]").colorize(:gray),
            name.rjust(5).colorize(color),
            ":",
          ].join(" ").underline, message: message,
        ))
      else
        @out.puts([
          name[0],
          Time.now.strftime("[%D %T]"),
          name.rjust(5),
          ":",
          message,
        ].join(" "))
      end
    end
  end
end
