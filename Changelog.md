# Changelog

## v0.0.1

- Initial release

## v0.0.2

- Fix: Fix rubygems description

## v0.0.3

- Fix: Fix no dependencies

## v0.0.4

- Fix: Fix NoMethodError by webhook message
- Add: Add `#author` to webhook message
- Fix: Add `#bot?` to webhook author

## v0.0.5

- Fix: Fix GitHub link
- Change: Internet to HTTP

## v0.0.6

- Fix: Fix error in client without members intent
- Add: Add ThreadChannel::News
- Add: Add official discord link

## v0.0.7

- Fix: Fix `member_xxx` event

## 0.0.8

- Delete: Delete task parameter

## 0.1.0

- Add: Add `User#created_at`
- Add: Add `Member#to_s_user`
- Add: Add `DefaultAvatar`
- Add: Support application commands
- Add: Add `Client#ping`
- Add: Allow `String` for `Embed#initialize`
- Change: Change log format

## 0.2.0

- Fix: Fix unused dependency
- Add: Add `Client#close!`
- Add: Add discord-irb

## 0.2.1

- Fix: Fix NoMethodError in reaction event
- Add: Add Changelog.md to document

## 0.2.2 (yanked)

- Add: Add `Snowflake#to_str`

## 0.2.3

- Fix: Fix critical error

## 0.2.4

- Fix: Fix error in `Embed#image=`, `Embed#thumbnail=`

## 0.2.5

- Add: Add way to add event listener
- Change: Move document to https://discorb-lib.github.io/

## 0.3.0

- Add: Improve CLI tools
- Add: Add `discorb init`
- Change: Change `discord-irb` to `discorb irb`
  
## 0.3.1

- Add: Add `discorb show`
- Fix: Fix documenting

## 0.4.0

- Add: Add `discorb setup`
- Add: Add `discorb run`
- Add: Add realtime documentation

## 0.4.1

- Add: Add `-s` option to `discorb run`
  
## 0.4.2

- Fix: Fix error in `discorb run`
  
## 0.5.0

- Change: Use zlib stream instead
- Add: Add tutorials
- Add: Add ratelimit handler
- Change: Make `--git` option in `discorb init` false
  
## 0.5.1

- Add: Can use block for defining group commands
- Fix: Fix bug in subcommands
- Fix: Fix bug in receiving commands

## 0.5.2

- Fix: Fix bug of registering commands
- Add: Add way to register commands in Extension

## 0.5.3

- Add: Add way to handle raw events with `event_xxx`
- Add: Add `Client#session_id`
- Add: Add `Connectable`
- Fix: Fix error by sending DM

## 0.5.4

- Fix: Fix issue of receiving component events

## 0.5.5

- Fix: Fix some bugs

## 0.5.6

- Add: Raise error when intents are invalid
- Fix: Fix Emoji#==

## 0.6.0

- Fix: Fix issue with client with no guilds
- Add: Add rbs (experimental)
- Add: Add `-t`, `--token` option to `discorb run`
- Add: Add `-g`, `--guild` option to `discorb setup`
- Change: Use `Async::Task<R>` instead of `R` in return value

## 0.6.1

- Change: Rename `Event#discriminator` to `Event#metadata`
- Add: Add `:override` to `Client#on`

## 0.7.0

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