# frozen_string_literal: true

# description: Setup application commands.
require "optparse"
require "discorb/utils/colored_puts"

options = { guilds: nil, script: true }

opt = OptionParser.new <<~BANNER
                         This command will setup application commands.

                         Usage: discorb setup [options] [script]

                                   script                     The script to setup.
                       BANNER
opt.on(
  "-g",
  "--guild ID",
  Array,
  "The guild ID to setup, use comma for setup commands in multiple guilds, " \
    "or `global` for setup global commands."
) { |v| options[:guilds] = v }
opt.on(
  "-c",
  "--clear-guild ID",
  Array,
  "The guild ID to clear command, use comma for clear commands in multiple guilds, " \
    "or `global` for clear global commands."
) { |v| options[:clear_guilds] = v }
opt.on(
  "-s",
  "--[no-]script",
  "Whether to run `:setup` event. " \
    "This may be useful if setup script includes operation that shouldn't run twice. Default to true."
) { |v| options[:script] = v }
opt.parse!(ARGV)

script = ARGV[0]
script ||= "main.rb"
ENV["DISCORB_CLI_FLAG"] = "setup"

ENV["DISCORB_SETUP_GUILDS"] = if options[:guilds] == ["global"]
  "global"
elsif options[:guilds]
  options[:guilds].join(",")
end

ENV["DISCORB_SETUP_CLEAR_GUILDS"] = options[:clear_guilds]&.join(",")

ENV["DISCORB_SETUP_SCRIPT"] = options[:script].to_s if options[:script]

if File.exist? script
  load script
  sputs "Successfully set up commands for \e[32m#{script}\e[m."
else
  eputs "Could not load script: \e[31m#{script}\e[m"
end
