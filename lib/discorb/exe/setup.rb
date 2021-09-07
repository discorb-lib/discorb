# description: Setup application commands.
require "optparse"
require "discorb/utils/colored_puts"

ARGV.delete_at 0

opt = OptionParser.new <<~BANNER
                         This command will setup application commands.

                         Usage: discorb setup [script]

                                   script                     The script to setup.
                       BANNER
opt.parse!(ARGV)

script = ARGV[0]
ENV["DISCORB_CLI_FLAG"] = "setup"

begin
  load script
rescue LoadError
  eputs "Could not load script: \e[31m#{script}\e[m"
else
  sputs "Successfully set up commands for \e[32m#{script}\e[m."
end
