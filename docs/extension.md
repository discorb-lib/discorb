# @title Extension

# Extension

Extension allows you to split your code into multiple files.

## Make a new extension

Make a new module, and extend {Discorb::Extension}.

```ruby
module MyExtension
  extend Discorb::Extension
  
  # ...
end
```

## Register Event

Use {Discorb::Extension.event} to register event, or {Discorb::Extension.once_event} to register event only once.

```ruby
module MyExtension
  extend Discorb::Extension

  event :message do |message|
    # ...
  end

  once_event :ready do |message|
    # ...
  end
end
```

## Register Command

Since v0.5.2, {Discorb::Extension} includes {Discorb::ApplicationCommand::Handler} module, so you can register command with {Discorb::ApplicationCommand::Handler#slash} and {Discorb::ApplicationCommand::Handler#slash_group}.

```ruby
module MyExtension
  extend Discorb::Extension

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

Use {Discorb::Client#extend} to load extension.

```ruby
module MyExtension
  extend Discorb::Extension

  event :message do |message|
    # ...
  end
end

client.extend MyExtension
```

## Access Client from extension

You can access {Discorb::Client} from extension with `@client`.

```ruby
module MyExtension
  extend Discorb::Extension

  event :ready do |message|
    puts "Logged in as #{@client.user}"
  end
end
```
