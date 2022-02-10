# description: Setup application commands.
require "optparse"
require "discorb/utils/colored_puts"

ARGV.delete_at 0

options = {
  guilds: nil,
  script: true,
}

opt = OptionParser.new <<~BANNER
                         This command will setup application commands.

                         Usage: discorb setup [options] [script]

                                   script                     The script to setup.
                       BANNER
opt.on("-g", "--guild ID", Array, "The guild ID to setup, use comma for setup commands in multiple guilds, or `global` for setup global commands.") { |v| options[:guilds] = v }
opt.on("-s", "--[no-]script", "Whether to run `:setup` event. This may be useful if setup script includes operation that shouldn't run twice. Default to true.") { |v| options[:script] = v }
opt.parse!(ARGV)

script = ARGV[0]
script ||= "main.rb"
ENV["DISCORB_CLI_FLAG"] = "setup"

if options[:guilds] == ["global"]
  ENV["DISCORB_SETUP_GUILDS"] = "global"
elsif options[:guilds]
  ENV["DISCORB_SETUP_GUILDS"] = options[:guilds].join(",")
else
  ENV["DISCORB_SETUP_GUILDS"] = nil
end

ENV["DISCORB_SETUP_SCRIPT"] = options[:script].to_s if options[:script]

begin
  load script
rescue LoadError
  eputs "Could not load script: \e[31m#{script}\e[m"
else
  sputs "Successfully set up commands for \e[32m#{script}\e[m."
end
