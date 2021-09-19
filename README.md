![discorb](./assets/banner.svg)

<center>[![Document](https://img.shields.io/badge/Document-discorb--lib.github.io-blue.svg)](https://discorb-lib.github.io/)
[![Gem](https://img.shields.io/gem/dt/discorb?logo=rubygems&logoColor=fff)](https://rubygems.org/gems/discorb)
[![Gem](https://img.shields.io/gem/v/discorb?logo=rubygems&logoColor=fff)](https://rubygems.org/gems/discorb)
[![Discord](https://img.shields.io/discord/863581274916913193?logo=discord&logoColor=fff&color=5865f2&label=Discord)](https://discord.gg/hCP6zq8Vpj)
[![GitHub](https://img.shields.io/github/stars/discorb-lib/discorb?color=24292e&label=Stars&logo=GitHub&logoColor=fff)](https://github.com/discorb-lib/discorb)</center>
----

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

client.on :message do |message|
  next if message.author.bot?
  next unless message.content == "ping"

  message.channel.post("Pong!")
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/discorb-lib/discorb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
