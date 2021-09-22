![discorb](./assets/banner.svg)

<div align="center"><a href="https://discorb-lib.github.io/"><img src="https://img.shields.io/badge/Document-discorb--lib.github.io-blue.svg" alt="Document"></a>
<a href="https://rubygems.org/gems/discorb"><img src="https://img.shields.io/gem/dt/discorb?logo=rubygems&logoColor=fff&label=Downloads" alt="Gem"></a>
<a href="https://rubygems.org/gems/discorb"><img src="https://img.shields.io/gem/v/discorb?logo=rubygems&logoColor=fff&label=Version" alt="Gem"></a>
<a href="https://discord.gg/hCP6zq8Vpj"><img src="https://img.shields.io/discord/863581274916913193?logo=discord&logoColor=fff&color=5865f2&label=Discord" alt="Discord"></a>
<a href="https://github.com/discorb-lib/discorb"><img src="https://img.shields.io/github/stars/discorb-lib/discorb?color=24292e&label=Stars&logo=GitHub&logoColor=fff" alt="GitHub"></a></div>

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

### Ping & Pong

```ruby
require "discorb"

client = Discorb::Client.new

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

### Quiz Game

```ruby
require "discorb"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content == "!quiz"

  operator = [:+, :-, :*].sample
  num1 = rand(1..10)
  num2 = rand(1..10)

  val = num1.send(operator, num2)
  message.channel.post("Quiz: `#{num1} #{operator} #{num2}`")
  begin
    msg = client.event_lock(:message, 30) { |m|
      m.content == val.to_s && m.channel == message.channel
    }.wait
  rescue Discorb::TimeoutError
    message.channel.post("No one answered...")
  else
    msg.reply("Correct!")
  end
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

### Slash Commands

```ruby
require "discorb"

client = Discorb::Client.new

client.slash("hello", "Greet for you") do |interaction|
  interaction.post("Hello!", ephemeral: true)
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

Note: You must run `discorb setup` before using slash commands.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/discorb-lib/discorb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
