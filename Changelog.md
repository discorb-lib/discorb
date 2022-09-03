<!--
# @title Changelog
-->

# Changelog

## v0.20

### v0.20.0

- Update!: All flags are updated. `User::Flag` has many renames.
- Change!: Gateway version is always 10 now.
- Add: Add permissions field.
- Add: Support resume_gateway_url.
- Add: Add `AutoModRule#mention_total_limit`, `AutoModRule#allow_list`, and parameters to `Guild#create_automod_rule`.

## v0.19

### v0.19.0

- Change!: All bang methods don't have bang anymore. (ex: `Message#delete!`)
- Add: Add `%a{pure}` annotation to rbs.
- Add: Add low level APIs to Interaction.
- Update: Update IDENTIFY key.

## v0.18

### v0.18.1

- Add: Support `:length` option for `:string` type.
- Add: Add `Interaction#app_permissions`
- Fix: Fix typing of `:autocomplete` option.

### v0.18.0

- Change!: `XXX#fired_by` is now `XXX#user` or `XXX#member`.
- Change!: `Message#to_reference` returns `Message::Reference`.
- Change!: `TextChannel#default_auto_archive_duration` is now Integer.
- Add: Support AutoMod.
- Change: `discorb new` doesn't do initial commit.

## v0.17

### v0.17.1

- Add: Add valid rbs file.
- Change: Message content intent warning will show only once.
- Update: Update audit log events.

### v0.17.0

- Change!: Delete `Interaction#target` and `Interaction#fired_by`.
- Change: `Interaction#user` and `Interaction#member` are same.
- Add: Include Messageable in VoiceChannel
- Add: Add `--[no-]bundler` option to `discorb` command.
- Add: Add `--[no-]comment` option to `discorb new` command.
- Fix PermissionOverwrite was initialized with string.
- Fix emoji with different skin tones raises ArgumentError.
- Fix `Asset#endpoint` raises NameError.
- Fix `:error` event may call itself.

## v0.16

### v0.16.0

- Change!: Use built-in Logger instead of custom Logger.
- Delete!: `--log-level`, `--[no-]log-color` is deleted.
- Add: Support sharding
- Add: Use Mutex for preventing connection duplications.

## v0.15

### v0.15.1

- Add: Add `Member#can_manage?`
- Add: Add `Discorb::VERSION_ARRAY`
- Fix: `Snowflake#timestamp` includes milliseconds now
- Fix: `TextChannel#create_invite` will no longer return `ArgumentError`
- Fix: Connection will not closed with 4001 when `Client#update_presence`
  is called

### v0.15.0

- Add: Migrate to API v10
- Add: Add `TextChannel#threads`
- Add: Support editing attachments
- Delete!: Delete File class - Use Attachment class instead

## v0.14

### v0.14.0

- Add: Support Modal interaction
- Add: Support attachment option type in slash command
- Fix: Connections will no longer stacked
- Fix: Fix Client#fetch_nitro_sticker_packs returning 404
- Fix: Fix `self` reference in subcommand of extension
- Refactor: Refactored many things
- Refactor: Add Rubocop

## v0.13

### v0.13.4

- Add: Show command on `discorb setup`
- Fix: Fix issue when logging in to file(#6, thanks `deanpcmad`)
- Fix: Fix rate limit handing
- Fix: Fix `Client#users`, it was always empty
- Fix: Fix sorting dictionary

### v0.13.3

- Fix: Fix INTEGRATION_xxx event
- Change: Change description

### v0.13.2

- Fix: Fix MESSAGE_DELETE_BULK event
- Fix: Delete VoiceState from `Guild#voice_states` when member leaves
- Add: Add `VoiceChannel#members`, `VoiceChannel#voice_states`
- Add: Add `StageChannel#members`, `StageChannel#voice_states`, `StageChannel#audiences`, `StageChannel#speakers`
- Fix: Ignore errors on closing websocket

### v0.13.1

- Add: `Discorb::Integration#locale`, `Discorb::Integration#guild_locale`
- Fix: Fix grammers
- Change: Use `Discorb::Unset` instead of `:unset`
- Add: `Member#timeout`
- Improve: Improve sending attachments
- Fix: Handle `EPIPE` errors

### v0.13.0

- Change!: Event is now EventHandler.
- Add: Support for scheduled events.
- Fix: Fix bug in sticker initialization.
- Add: Support application flags
- Add: Add `#inspect` method to many classes.

## v0.12

### v0.12.4

- Update: Update emoji table
- Add: Support min_value and max_value for numeric options in slash command
- Fix: Fix sending images

### v0.12.3

- Fix: Fix NoMethodError in command interaction
- Fix: Fix NoMethodError in Integration#initialize

### v0.12.2

- Fix: Fix `Message#type`
- Change: `discorb run` will look up for `main.rb` in parent directories

### v0.12.1

- Fix: Fix some texts
- Add: Add `User#mention`

### v0.12.0

- Refactor: Refactor the code
- Fix: Fix resuming gateway, finally
- Fix: Fix `@client` in slash command handler in extension

## v0.11

### v0.11.4

- Fix: Fix unpinning messages

### v0.11.3

- Add: Add `Snowflake#id` as alias for `Snowflake#to_s`
- Fix: Fix `Message#unpin`

### v0.11.2

- Add: Add `setup` event
- Fix: Fix gateway resuming
- Add: Add GitHub Packages

### v0.11.1

- Improve: Improve rate limit handling
- Fix: Fix bug in Integration initalization
- Change: Change log style
- Add: Support OP code 7

### v0.11.0

- Add: Improve documents
- Add: Implement global rate limits
- Add: Add support autocomplete
- Add: Add role icon editting
- Change: Use `include Discorb::Extension` instead of `< Discorb::Extension`
- Fix: Fix role operation

## v0.10

### v0.10.3

- Add: Support role icons
- Fix: Fix version order
- Change: Use `exec` instead of `system` in `discorb run`
- Add: Add `Extension.loaded`

### v0.10.2

- Change: `discorb init` is now `discorb new`
- Add: Add `:channel_types` parameter to `ApplicationCommand::Handler#slash` and some

### v0.10.1

- Add: Add `Client#extensions`
- Change: `Client#load_extension` allows instance of `Extension`
- Add: Add `-b` option to `discorb run`

### v0.10.0

- Change: Sort versions
- Change: Snowflake is now String
- Change: Extension is now Class
- Add: Add `SelectMenu#disabled=`

## v0.9

### v0.9.6

- Add: Add `Messageable#send_message` as alias of `Messageable#post`
- Fix: Fix interaction responding with updating message
- Fix: Fix `MessageComponentInteraction#message`

### v0.9.5

- Fix: Fix editing message
- Add: Add `required` in slash command argument
- Add: Add `default` in slash command argument

### v0.9.4

- Change: `Messageable#typing` with block is now synchronous
- Fix: Fix some issues in document
- Add: Add some attributes to `Message`
- Fix: Fix guild parameter in message of message command

### v0.9.3

- Fix: Fix interaction responding

### v0.9.2 (yanked)

- Add: Make `Async::Task#inspect` shorter
- Add: `SourceResponse#post` will return message now
- Fix: Fix member caching

### v0.9.1

- Fix: Fix member fetching

### v0.9.0

- Delete: Delete `-d` parameter from `discorb run`; This is caused by segement fault error.
- Change: Rename `-t`, `--token` to `-e`, `--env` parameter
- Add: Add `-t`, `--title` parameter to `discorb run`
- Add: Add `title` parameter to `Client#initialize`

## v0.8

### v0.8.2

- Fix: Fix `Client#initialize`

### v0.8.1

- Add: Add FAQ
- Fix: Fix sending files
- Add: Add `File.from_string`
- Fix: Fix `Client#update_presence`
- Add: Add information in `discorb run -d`

### v0.8.0

- Add: Add `Guild#fetch_members`
- Add: Add `Guild#fetch_member_list` as alias of `Guild#fetch_members`
- Add: Add `Intents#to_h`
- Add: Add `fetch_member` parameter to `Client#initialize`; Note you should set `false` if your bot doesn't have `GUILD_MEMBERS` intent
- Change: Change `ready` to `standby` event
- Change: `ready` will be fired when client receives `READY` event

## v0.7

### v0.7.6

- Fix: Fix heartbeating error

### v0.7.5 (yanked)

- Fix: Fix critical error

### v0.7.4 (yanked)

- Fix: Fix disconnected client

### v0.7.3

- Add: Improve `discorb init`

### v0.7.2

- Add: Add `Member#owner?`
- Fix: Fix `Member#permissions`
- Add: Add `Member#guild_permissions` as alias of `Member#permissions`
- Add: Add default role to `Member#roles`
- Fix: Fix error in `Integration#_set_data`
- Change: Reverse `Member#roles`

### v0.7.1

- Fix: Fix error of responding to interaction

### v0.7.0

- Add: Add `error` event
- Fix: Fix some issues with client without guild intent
- Add: Add alias for `#fired_by`
- Change!: Change block usage of `ApplicationCommand::Handler#group`

```ruby
# before
client.slash_group do
  slash "help", "Help" do |interaction|
    # ...
  end
end

# after
client.slash_group do |group|
  group.slash "help", "Help" do |interaction|
    # ...
  end
end

```

## v0.6

### v0.6.1

- Change: Rename `Event#discriminator` to `Event#metadata`
- Add: Add `:override` to `Client#on`

### v0.6.0

- Fix: Fix issue with client with no guilds
- Add: Add rbs (experimental)
- Add: Add `-t`, `--token` option to `discorb run`
- Add: Add `-g`, `--guild` option to `discorb setup`
- Change: Use `Async::Task<R>` instead of `R` in return value

## v0.5

### v0.5.6

- Add: Raise error when intents are invalid
- Fix: Fix Emoji#==

### v0.5.5

- Fix: Fix some bugs

### v0.5.4

- Fix: Fix issue of receiving component events

### v0.5.3

- Add: Add way to handle raw events with `event_xxx`
- Add: Add `Client#session_id`
- Add: Add `Connectable`
- Fix: Fix error by sending DM

### v0.5.2

- Fix: Fix bug of registering commands
- Add: Add way to register commands in Extension

### v0.5.1

- Add: Can use block for defining group commands
- Fix: Fix bug in subcommands
- Fix: Fix bug in receiving commands

### v0.5.0

- Change: Use zlib stream instead
- Add: Add tutorials
- Add: Add ratelimit handler
- Change: Make `--git` option in `discorb init` false

## v0.4

### v0.4.2

- Fix: Fix error in `discorb run`

### v0.4.1

- Add: Add `-s` option to `discorb run`

### v0.4.0

- Add: Add `discorb setup`
- Add: Add `discorb run`
- Add: Add realtime documentation

## v0.3

### v0.3.1

- Add: Add `discorb show`
- Fix: Fix documenting

### v0.3.0

- Add: Improve CLI tools
- Add: Add `discorb init`
- Change: Change `discord-irb` to `discorb irb`

## v0.2

### v0.2.5

- Add: Add way to add event listener
- Change: Move document to https://discorb-lib.github.io/

### v0.2.4

- Fix: Fix error in `Embed#image=`, `Embed#thumbnail=`

### v0.2.3

- Fix: Fix critical error

### v0.2.2 (yanked)

- Add: Add `Snowflake#to_str`

### v0.2.1

- Fix: Fix NoMethodError in reaction event
- Add: Add Changelog.md to document

### v0.2.0

- Fix: Fix unused dependency
- Add: Add `Client#close!`
- Add: Add discord-irb

## v0.1

### v0.1.0

- Add: Add `User#created_at`
- Add: Add `Member#to_s_user`
- Add: Add `DefaultAvatar`
- Add: Support application commands
- Add: Add `Client#ping`
- Add: Allow `String` for `Embed#initialize`
- Change: Change log format

## v0.0

### v0.0.8

- Delete: Delete task parameter

### v0.0.7

- Fix: Fix `member_xxx` event

### v0.0.6

- Fix: Fix error in client without members intent
- Add: Add ThreadChannel::News
- Add: Add official discord link

### v0.0.5

- Fix: Fix GitHub link
- Change: Internet to HTTP

### v0.0.4

- Fix: Fix NoMethodError by webhook message
- Add: Add `#author` to webhook message
- Fix: Add `#bot?` to webhook author

### v0.0.3

- Fix: Fix no dependencies

### v0.0.2

- Fix: Fix rubygems description

### v0.0.1

- Initial release
