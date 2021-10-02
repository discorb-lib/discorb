# @title Extension

# Extension

Extension allows you to seperate your code from the main application.

# @since 

## Make a new extension

Make a new class that extends Extension.

```ruby
class MyExtension < Discorb::Extension
  # ...
end
```

## Register Event

Use {Discorb::Extension.event} to register event, or {Discorb::Extension.once_event} to register event only once.

```ruby
class MyExtension < Discorb::Extension
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
class MyExtension < Discorb::Extension
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
class MyExtension < Discorb::Extension
  event :message do |message|
    # ...
  end
end

client.load_extension(MyExtension)
```

## Access Client from extension

You can access {Discorb::Client} from extension with `@client`.

```ruby
class MyExtension < Discorb::Extension
  event :standby do |message|
    puts "Logged in as #{@client.user}"
  end
end
```
