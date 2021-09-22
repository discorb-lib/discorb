# @title Events

# Events

## How to use events

discorb uses event driven programming.
You can register event handlers with {Discorb::Client#on}.
Alternatively, you can use {Discorb::Client#once} to register a one-time event handler.

```ruby
client.on :message do |event|
  puts event.message.content
end
```

This example will print the content of every message received.

Since v0.2.5, you can also register event handlers by adding a method to the client, with the prefix `on_` and the event name as the method name.

```ruby
client = Discorb::Client.new

class << client
  def on_standby
    puts "Ready!"
  end
end
```

If you want to seperate event handlers from the client, consider using {Discorb::Extension}. {file:docs/extension.md Learn more about extensions}.

Since v0.6.1, you can set `:override` to `true` to register overridable event handlers.

```ruby
client.on :message, override: true do |event|
  puts "This event handler is overrideable!"
end

client.on :message do |event|
  puts "Override!"
end
```

This example will print `Override!`, but not `This event handler is overrideable!`.
This is useful for registering event handlers as default behaviour, such as error handlers.

```ruby
# In the library...

client.on :command_error, override: true do |event, error|
  $stderr.puts "Command error:\n#{error.full_message}"
end

# In your code...

client.on :command_error do |event, error|
  event.message.reply "An error occurred while executing the command!\n#{error.full_message}"
end
```

## Event reference

### Client events

#### `event_receive(event_name, data)`
Fires when a event is received.  

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event_name`| Symbol | The name of the event. |
|`data`      | Hash   | The data of the event. |

#### `ready()`

Fires when the client receives the `READY` event.

#### `standby()`

Fires when the client is standby. (When the client connects to Discord, and has cached guilds and members.)

#### `resumed()`

Fires when the client is resumed connection.

#### `error(event_name, args, error)`

Fires when an error occurs during an event.
Defaults to printing the error to stderr, override to handle it yourself.

### Guild events

#### `guild_join(guild)`

Fires when client joins a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was joined. |

#### `guild_available(guild)`

Fires when a guild becomes available.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that became available. |

#### `guild_update(before, after)`

Fires when client updates a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Guild} | The guild before the update. |
|`after`     | {Discorb::Guild} | The guild after the update. |

#### `guild_leave(guild)`

Fires when client leaves a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was left. |

#### `guild_destroy(guild)`

Fires when guild is destroyed.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was destroyed. |

#### `guild_integrations_update(guild)`

Fires when guild integrations are updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that integrations were updated for. |

#### `guild_ban_add(guild, user)`

Fires when a user is banned from a guild.


| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that the user was banned from. |
|`user`      | {Discorb::User}  | The user that was banned. |

#### `guild_ban_remove(guild, user)`

Fires when a user is unbanned from a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that the user was unbanned from. |
|`user`      | {Discorb::User}  | The user that was unbanned. |

### Channel events

#### `channel_create(channel)`

Fires when a channel is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`channel`   | {Discorb::Channel} | The channel that was created. |

#### `channel_update(before, after)`

Fires when a channel is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Channel} | The channel before the update. |
|`after`     | {Discorb::Channel} | The channel after the update. |

#### `channel_delete(channel)`

Fires when a channel is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`channel`   | {Discorb::Channel} | The channel that was deleted. |

#### `webhooks_update(event)`

Fires when a webhook is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::WebhooksUpdateEvent} | The webhook update event. |

#### `thread_new(thread)`

Fires when a thread is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was created. |

#### `thread_join(thread)`

Fires when client joins a thread.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was joined. |


#### `thread_delete(thread)`

Fires when a thread is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was deleted. |

#### `thread_update(before, after)`

Fires when a thread is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::ThreadChannel} | The thread before the update. |
|`after`     | {Discorb::ThreadChannel} | The thread after the update. |

#### `thread_members_update(thread, added, removed)`

Fires when a thread's members are updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that the members were updated for. |
|`added`     | Array<{Discorb::ThreadChannel::Member}> | An array of {Discorb::ThreadChannel::Member} objects that were added to the thread. |
|`removed`   | Array<{Discorb::ThreadChannel::Member}> | An array of {Discorb::ThreadChannel::Member} objects that were removed from the thread. |

#### `thread_member_update(before, after)`

Fires when a thread member is updated.

| Parameter | Type  | Description |
| --------- | ----- | ----------- |
|`thread`   | {Discorb::ThreadChannel} | The thread that the member was updated for. |
|`before`   | {Discorb::ThreadChannel::Member} | The thread member before the update. |
|`after`    | {Discorb::ThreadChannel::Member} | The thread member after the update. |

### Integration events

#### `integration_create(integration)`

Fires when a guild integration is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`integration`| {Discorb::Integration}| The created integration. |

#### `integration_update(after)`

Fires when a guild integration is updated.


| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`after`     | {Discorb::Integration}| The integration after the update. |

#### `integration_delete(integration)`

Fires when a guild integration is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`integration`| {Discorb::Integration}| The deleted integration. |

### Message events

#### `message(message)`

Fires when a message is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message`   | {Discorb::Message}| The created message. |

#### `message_update(event)`

Fires when a message is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::MessageUpdateEvent}| The message after the update. |

#### `message_delete(message, channel, guild)`

Fires when a message is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message`   | {Discorb::Message}| The deleted message. |
|`channel`   | {Discorb::Channel}| The channel the message was deleted from. |
|`guild`     | ?{Discorb::Guild} | The guild the message was deleted from. |

##### Note

This will fire when cached messages are deleted.

#### `message_delete_id(message_id, channel, guild)`

Fires when a message is deleted.
Not like {file:#message_delete} this will fire even message is not cached.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message_id`| {Discorb::Snowflake} | The deleted message ID. |
|`channel`   | {Discorb::Channel}| The channel the message was deleted from. |
|`guild`     | ?{Discorb::Guild} | The guild the message was deleted from. |

#### `message_delete_bulk(messages)`

Fires when a bulk of messages are deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`messages`  | Array<{Discorb::Message}, {Discorb::Gateway::UnknownDeleteBulkMessage}> | The deleted messages. |

#### `message_pin_update(event)`

Fires when a message is pinned or unpinned.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::MessagePinEvent}| The event object. |

#### `typing_start(event)`

Fires when a user starts typing.

| Parameter | Type  | Description |
| --------- | ----- | ----------- |
|`event`    | {Discorb::Gateway::TypingStartEvent}| The event object. |

### Reaction events

#### `reaction_add(event)`

Fires when a reaction is added to a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::ReactionEvent}| The event object. |

#### `reaction_remove(event)`

Fires when someone removes a reaction from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::ReactionEvent}| The event object. |

#### `reaction_remove_all(event)`

Fires when all reactions are removed from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::ReactionRemoveAllEvent}| The event object. |

#### `reaction_remove_emoji(event)`

Fires when a reaction is removed from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::Gateway::ReactionRemoveEmojiEvent}| The event object. |

### Role events

#### `role_create(role)`

Fires when a role is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The created role. |

#### `role_update(before, after)`

Fires when a role is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Role}| The role before the update. |
|`after`     | {Discorb::Role}| The role after the update. |

#### `role_remove(role)`

Fires when a role is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The deleted role. |

### Member events

#### Note

These events requires the `guild_members` intent.

#### `member_add(member)`

Fires when a member joins a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`member`    | {Discorb::Member}| The member that joined. |

#### `member_update(before, after)`

Fires when a member is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Member}| The member before the update. |
|`after`     | {Discorb::Member}| The member after the update. |

#### `member_remove(member)`

Fires when a member is removed from a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`member`    | {Discorb::Member}| The member that left. |

### Role events

#### `role_create(role)`

Fires when a role is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The created role. |

#### `role_update(before, after)`

Fires when a role is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Role}| The role before the update. |
|`after`     | {Discorb::Role}| The role after the update. |

#### `role_remove(role)`

Fires when a role is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The deleted role. |

### Invite events

#### `invite_create(invite)`

Fires when a invite is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`invite`    | {Discorb::Invite}| The created invite. |

#### `invite_delete(invite)`

Fires when a invite is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`invite`    | {Discorb::Invite}| The deleted invite. |

### Interaction events

#### `button_click(interaction)`

Fires when a button is clicked.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`interaction`| {Discorb::MessageComponentInteraction::Button}| The interaction object. |

#### `select_menu_select(interaction)`

Fires when a select menu is selected.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`interaction`| {Discorb::MessageComponentInteraction::SelectMenu}| The interaction object. |

### Voice events

It's too big, so they're documented in {file:docs/voice_events.md}

### Low-level events

#### `guild_create(guild)`

Fires when `GUILD_CREATE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild}| The guild of the event. |

#### `guild_delete(guild)`

Fires when `GUILD_DELETE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild}| The guild of the event. |

#### `thread_create(thread)`

Fires when `THREAD_CREATE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel}| The thread of the event. |
