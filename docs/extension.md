<!--
# @title Extension
-->

# Extension

Extension allows you to seperate events.

## Make a new extension

Make a new class that includes Extension.

```ruby
class MyExtension
  include Discorb::Extension

  # ...
end
```

## Register Event

Use {Discorb::Extension.event} to register event, or {Discorb::Extension.once_event} to register event only once.

```ruby
class MyExtension
  include Discorb::Extension

  event :message do |message|
    # ...
  end

  once_event :standby do |message|
    # ...
  end
end
```

Note block will be binded to the extension instance.

## Register Command

Use `Discorb::Extension.command` to register command, see {Discorb::ApplicationCommand::Handler} for more information.

```ruby
class MyExtension
  include Discorb::Extension

  slash("command", "Command") do |interaction|
    # ...
  end

  slash_group("group", "Group") do |group|
    group.slash("subcommand", "Subcommand") do |interaction|
      # ...
    end

    group.group("subgroup", "Subcommand group") do |group|
      group.slash("group_subcommand", "Command in Subcommand group") do |interaction|
        # ...
      end
    end
  end
end
```


## Load extension

Use {Discorb::Client#load_extension} to load extension.

```ruby
class MyExtension
  include Discorb::Extension

  event :message do |message|
    # ...
  end
end

client.load_extension(MyExtension)
```

## Access Client from extension

You can access {Discorb::Client} from extension with `@client`.

```ruby
class MyExtension
  include Discorb::Extension

  event :standby do |message|
    puts "Logged in as #{@client.user}"
  end
end
```

## Receiving Arguments on load

You can receive arguments by adding some arguments to `#initialize`.

```ruby
class MyExtension
  include Discorb::Extension

  def initialize(client, arg1, arg2)
    super(client)
    # @client = client will also work, but it's not recommended.
    @arg1 = arg1
    @arg2 = arg2
  end
end

client.load_extension(MyExtension, "arg1", "arg2")

```

## Do something on load

You can do something on load by overriding `.loaded`. Client and arguments will be passed to it.

```ruby
class MyExtension
  include Discorb::Extension

  def self.loaded(client)
    puts "This extension is loaded to #{client}"
  end
end
```