# Discorb
[![Gem](https://img.shields.io/gem/dt/discorb)](https://rubygems.org/gems/discorb)
[![Gem](https://img.shields.io/gem/v/discorb)](https://rubygems.org/gems/discorb)  

discorb is a Discord API wrapper for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discorb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install discorb

## Usage

### Simple ping-pong

```ruby
require "discorb"

client = Discorb::Client.new

client.once :ready do
  puts "Logged in as #{client.user}"
end

client.on :message do |_task, message|
  next if message.author.bot?
  next unless message.content == "ping"

  message.channel.post("Pong!")
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sevenc-nanashi/discorb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
