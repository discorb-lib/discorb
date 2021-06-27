begin
  require "colorize"
rescue LoadError
end

module Discorb
  class Logger
    @@levels = [:debug, :info, :warn, :error, :fatal]

    def initialize(out, colorize_log, level)
      @out = out
      @level = @@levels.index(level)
      @colorize_log = colorize_log
      if colorize_log and not defined? String.color_samples
        raise "colorize is required to use colorized log"
      end
    end

    def debug(message)
      return unless @level >= 0
      write_output("DEBUG", :light_black, message)
    end

    def info(message)
      return unless @level >= 1
      write_output("INFO", :light_blue, message)
    end

    def warning(message)
      return unless @level >= 2
      write_output("WARN", :yellow, message)
    end

    def error(message)
      return unless @level >= 3
      write_output("ERROR", :red, message)
    end

    def fatal(message)
      return unless @level >= 4
      write_output("FATAL", :light_red, message)
    end

    private

    def write_output(name, color, message)
      return if not @out
      if @colorize_log
        @out.puts([
          name[0].colorize(color),
          Time.now.strftime("[%D %T]").colorize(:gray),
          name.rjust(5).colorize(color),
          ":",
        ].join(" ").underline + " " + message)
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
