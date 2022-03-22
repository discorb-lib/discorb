message = File.read(ARGV[0])
raise "Commit message is empty" if message.empty?
raise "Commit message must be ASCII" unless message.ascii_only?
