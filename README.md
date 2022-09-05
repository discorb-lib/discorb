<div align="center"><img src="./assets/banner.svg" alt="discorb"></div>

<div align="center"><a href="https://discorb-lib.github.io/"><img src="https://img.shields.io/badge/Document-discorb--lib.github.io-blue.svg?style=flat-square&labelColor=2f3136&logo=github&logoColor=fff" alt="Document"></a>
<a href="https://rubygems.org/gems/discorb"><img src="https://img.shields.io/gem/dt/discorb?logo=rubygems&logoColor=fff&label=Downloads&style=flat-square&labelColor=2f3136" alt="Gem"></a>
<a href="https://rubygems.org/gems/discorb"><img src="https://img.shields.io/gem/v/discorb?logo=rubygems&logoColor=fff&label=Version&style=flat-square&labelColor=2f3136" alt="Gem"></a>
<a href="https://discord.gg/hCP6zq8Vpj"><img src="https://img.shields.io/discord/863581274916913193?logo=discord&logoColor=fff&color=5865f2&label=Discord&style=flat-square&labelColor=2f3136" alt="Discord"></a>
<a href="https://github.com/discorb-lib/discorb"><img src="https://img.shields.io/github/stars/discorb-lib/discorb?color=24292e&label=Stars&logo=GitHub&logoColor=fff&style=flat-square&labelColor=2f3136" alt="GitHub"></a>
<a href="https://codeclimate.com/github/discorb-lib/discorb"><img alt="Code Climate maintainability" src="https://img.shields.io/codeclimate/maintainability/discorb-lib/discorb?logo=Code%20Climate&logoColor=ffffff&style=flat-square&labelColor=2f3136&label=Maintainability"></a></div>

----

discorb is a Discord API wrapper for Ruby, Using [socketry/async](https://github.com/socketry/async).

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

> **Note**
> You must run `discorb setup` before using slash commands.

More examples are available in [/examples](/examples) directory.

### Simple Slash Command

```ruby
require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.slash("ping", "Ping!") do |interaction|
  interaction.post("Pong!", ephemeral: true)
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

### Legacy Message Command

```ruby
require "discorb"

intents = Discorb::Intents.new
intents.message_content = true

client = Discorb::Client.new(intents: intents)

client.once :standby do
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
