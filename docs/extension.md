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

## Load extension

Use {Discorb::Client#extend} to load extension.

## Access Client from extension

You can access {Discorb::Client} from extension with `@client`.

```ruby
module MyExtension
  extend Discorb::Extension

  event :ready do |message|
    puts "Logged in as #{client.user}"
  end
end
```
