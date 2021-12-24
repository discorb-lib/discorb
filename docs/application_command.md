<!--
# @title Application Commands
-->

# Application Commands

## What is an application command?

> Application commands are commands that an application can register to Discord. They provide users a first-class way of interacting directly with your application that feels deeply integrated into Discord.

From: [Discord API docs](https://discord.com/developers/docs/interactions/application-commands#application-commands)

## How do I register an application command?

Write to your script:
- {Discorb::ApplicationCommand::Handler.slash}, {Discorb::ApplicationCommand::Handler.slash_group} for slash commands,
- {Discorb::ApplicationCommand::Handler.user_command} for user menu commands,
- {Discorb::ApplicationCommand::Handler.message_command} for message menu commands.

And then run `discorb setup` to register your application commands.
{file:docs/cli/setup.md Learn more about `discorb setup`}. 

### Note

To register a global command, it will take 1 hour to be registered.
Guild commands will be registered immediately.

### Register Slash Commands

This example registers a slash command that says "Hello, world!" when the user types `/hello`.

```ruby
require "discorb"

client = Discorb::Client.new

client.slash("hello", "Greet for you") do |interaction|
  interaction.post("Hello World!", ephemeral: true)
end

client.run(ENV["DISCORD_BOT_TOKEN"])
```

{Discorb::ApplicationCommand::Handler#slash} takes 5 arguments:

| Argument | Description |
|---------|-------------|
| `command_name` | The name of the command. |
| `description` | The description of the command. |
| `options` | A hash of options. |
| `guild_ids` | The ID of the guild to register the command in. |
| `block` | A block that will be called when the command is invoked. |

Block will be called with a {Discorb::ApplicationCommand::Interaction} object and specified options.

In `options`, hash should be like this:

```ruby
{
  "Name" => {
    type: :string,
    required: true,
    description: "The description of the command."
  }
}
```
| Key | Type | Description |
| --- | --- | --- |
| `:description` | `String` | Description of the option. |
| `:required` | Whether the argument is required. `optional` will be used if not specified. |
| `:optional` | Whether the argument is optional. `required` will be used if not specified. |
| `:type` | `Object` | Type of the option. |
| `:choice` | `Hash{String => String, Integer, Float}` | Choice of the option. |
| `:default` | `Object` | Default value of the option. |
| `:channel_types` | `Array<Class<Discorb::Channel>>` | Type of the channel option. |
| `:autocomplete` | `Proc` | Autocomplete function. |
| `:range` | `Range` | Range of the option. Only valid for numeric options. (`:int`, `:float`) |

`choices` should be unspecified if you don't want to use it.
`choices` is hash like this:

```ruby
{
  "vocaloid" => {
    required: true,
    description: "The vocaloid which you like.",
    type: :string,
    choices: {
      "Hatsune Miku" => "miku",
      "Kagamine Rin" => "rin",
      "Kagamine Len" => "len",
      "Megurine Luka" => "luka",
      "MEIKO" => "meiko",
      "KAITO" => "kaito",
    }
  }
}

# Note: This aritcle is written in 8/31.
```

The key will be displayed in the user menu, and the value will be used as the argument.

In `type`, You must use one of the following:

| Name | Description | Aliases|
| --- | --- | --- |
| `:string` | String argument. | `:str` |
| `:integer` | Integer argument. | `:int` |
| `:float` | Float argument. | None |
| `:boolean` | Boolean argument. | `:bool` |
| `:user` | User argument. | `:member` |
| `:channel` | Channel argument. | None |
| `:role` | Role argument. | None |

#### Group Slash Commands

To register a group of slash commands, use {Discorb::ApplicationCommand::Handler#slash_group}.

```ruby
group = client.slash_group("settings", "Set settings of bot.")

group.slash("message_expand", "Whether bot should expand message.", {
  "enabled" => {
    type: :boolean,
    description: "Whether bot should expand message."
  }
}) do |interaction, enabled|
  # ...
end

group.slash("level", "Whether level system is enabled.", {
  "enabled" => {
    type: :boolean,
    description: "Whether level system is enabled."
  }
}) do |interaction, enabled|
  # ...
end

```

Since v0.5.1, You can use block for register commands.

```ruby

client.slash_group("settings", "Set settings of bot.") do |group|
  group.slash("message_expand", "Whether bot should expand message.", {
    "enabled" => {
      type: :boolean,
      description: "Whether bot should expand message."
    }
  }) do |interaction, enabled|
    # ...
  end
  group.slash("bump_alert", "Whether level system is enabled.", {
    "enabled" => {
      type: :boolean,
      description: "Whether level system is enabled."
    }
  }) do |interaction, enabled|
    # ...
  end
end
```

You can make subcommand group by using {Discorb::ApplicationCommand::Command::GroupCommand#group}.

```ruby
group = client.slash_group("permission", "Set/Get command permissions.")

group_user = group.group("user", "Set/Get user's command permissions.")

group_user.slash("set", "Set user's command permissions.", {
  "user_id" => {
      type: :user,
      description: "The user."
  },
  "value" => {
      type: :boolean,
      description: "Whether the user can use the command."
  }
}) do |interaction, user|
  # ...
end

group_user.slash("get", "Set user's command permissions.", {
    "user_id" => {
        type: :user,
        description: "The user."
    },
}) do |interaction, user|
  # ...
end

group_user = group.group("user", "Set/Get user's command permissions.")

group_user.slash("set", "Set user's command permissions.", {
    "user_id" => {
        type: :user,
        description: "The user."
    },
    "value" => {
        type: :boolean,
        description: "Whether the user can use the command."
    }
}) do |interaction, user|
  # ...
end

group_user.slash("get", "Set user's command permissions.", {
    "user_id" => {
        type: :user,
        description: "The user."
    },
}) do |interaction, user|
  # ...
end

group_role = group.group("role", "Set/Get role's command permissions.")

group_role.slash("set", "Set role's command permissions.", {
    "role_id" => {
        type: :role,
        description: "The role."
    },
    "value" => {
        type: :boolean,
        description: "Whether the role can use the command."
    }
}) do |interaction, role|
  # ...
end

group_role.slash("get", "Set role's command permissions.", {
    "role_id" => {
        type: :role,
        description: "The role."
    },
}) do |interaction, role|
  # ...
end

```

Same as above, you can use block for register commands since v0.5.1.

#### Use Auto Completing

Since v0.11.0, you can use auto-completion by setting Proc to `:autocomplete` in options.
The proc will be called with interaction object and the argument.
The proc should return a hash of the autocomplete result.

```ruby
client.slash("hello2", "Greet for you", {
  "target" => {
    type: :string,
    description: "Person to greet",
    autocomplete: ->(interaction, target) {
      {
        "You" => interaction.target.to_s
      }
    },
  },
}) do |interaction, target|
  interaction.post("Hello, #{target}!")
end
```

In the above example, `You` will be displayed in the user menu.
Due to the limitation of Discord API, the proc must return the result in less than 3 second.

### Register User Context Menu Command

```ruby
client.user_command("hello") do |interaction, user|
  interaction.post("Hello, #{user.name}!")
end
```
{Discorb::ApplicationCommand::Handler.user_command} takes 3 arguments:

| Parameter | Description |
| --- | --- |
| `command_name` | The name of the command. |
| `guild_ids` | The ID of the guild to register the command in. |
| `block` | A block that will be called when the command is invoked. |

`block` will be called with two arguments:

| Parameter | Description |
| --- | --- |
| `interaction` | The interaction object. |
| `user` | The user object. |


### Register Message Context Menu Command

```ruby
client.message_command("Bookmark") do |interaction, message|
  # ...
end
```

{Discorb::ApplicationCommand::Handler.message_command} takes 3 arguments:

| Parameter | Description |
| --- | --- |
| `command_name` | The name of the command. |
| `guild_ids` | The ID of the guild to register the command in. |
| `block` | A block that will be called when the command is invoked. |

`block` will be called with two arguments:

| Parameter | Description |
| --- | --- |
| `interaction` | The interaction object. |
| `message` | The message object. |
