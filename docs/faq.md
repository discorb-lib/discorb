# @title FAQ

# Fequently asked questions

## What is `Async::Task`?

Async::Task is a object for asynchronous tasks.

https://socketry.github.io/async/ for more information.

## How do I do something with sent messages?

Use `Async::Task#wait` method.

```ruby
# NG
message = channel.post("Hello world!")       # => Async::Task
message.pin                                  # => NoMethodError

# OK
message = channel.post("Hello world!").wait  # => Message
message.pin
```

## How can I send DM to a user?

Use {Discorb::User#post} method, {Discorb::User} includes {Discorb::Messageable}.

## How can I edit status?

Use {Discorb::Client#update_presence} method.

```ruby
%i[standby guild_join guild_leave].each do |event|
  client.on event do
    client.update_presence(
      Discorb::Activity.new(
        "#{client.guilds.length} Servers"
      ),
      status: :online
    )
  end
end

client.on :ready do
  client.update_presence(status: :dnd)
end
```

## How can I send files?

Use {Discorb::File} class.

```ruby
# Send a file
message.channel.post file: Discorb::File.new(File.open("./README.md"))

# Send some files with text
message.channel.post "File!", files: [Discorb::File.new(File.open("./README.md")), Discorb::File.new(File.open("./License.txt"))]

# Send a string as a file
message.channel.post file: Discorb::File.from_string("Hello world!", "hello.txt")
```

# Not fequently asked questions

## How can I pronounce `discorb`?

Discorb is pronounced `disco-R-B`.

## Why did you make `discorb`?

There are many reasons -- One is I didn't like `discordrb`'s `bot.message` -- but the main reason is, "Just for Fun".

## How was `discorb` named?

`discord` and `.rb`.
