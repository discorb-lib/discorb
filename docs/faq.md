<!--
# @title FAQ
-->

# Fequently asked questions

## What is ...?

### What is `Async::Task`?

Async::Task is an object for asynchronous tasks.

https://socketry.github.io/async/ for more information.

### What is `Guild`?

It means a `server` of Discord.

### What is difference between `User` and `Member`?

`User` is an object for account, `Member` is an object for user in guild.

## How can I ...?

### How can I do something with sent messages?

Use `Async::Task#wait` method.

```ruby
# NG
message = channel.post("Hello world!")       # => Async::Task
message.pin                                  # => NoMethodError

# OK
message = channel.post("Hello world!").wait  # => Message
message.pin
```


### How can I send DM to a user?

Use {Discorb::User#post} method, {Discorb::User} includes {Discorb::Messageable}.

### How can I edit status?

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

### How can I send attachments?

Use {Discorb::Attachment} class.

```ruby
# Send an attachment
message.channel.post attachment: Discorb::Attachment.new(File.open("./README.md"))

# Send some attachment with text
message.channel.post "File!", attachments: [Discorb::Attachment.new("./README.md"), Discorb::Attachment.new(File.open("./License.txt"))]

# Send a string as an attachment
message.channel.post attachments: Discorb::Attachment.from_string("Hello world!", "hello.txt")
```

### How can I add reactions?

Use {Discorb::Message#add_reaction} method.

```ruby
message.add_reaction Discorb::UnicodeEmoji["🤔"]
message.add_reaction Discorb::UnicodeEmoji["thinking"]
```

# Not fequently asked questions

## How can I pronounce `discorb`?

Discorb is pronounced `disco-R-B`.

## Why did you make `discorb`?

There are many reasons -- One is I didn't like `discordrb`'s `bot.message` -- but the main reason is, "Just for Fun".

## How was `discorb` named?

`discord` and `.rb`.
