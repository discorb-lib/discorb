# @title Events

# Events

## How to use events

discorb uses event driven programming.
You can register event handlers with {Client#on}.
Alternatively, you can use {Client#once} to register a one-time event handler.

```ruby
client.on :message do |_task, event|
  puts event.message.content
end
```

This example will print the content of every message received.

## Event reference

### Note

`Async::Task` object will be passed to the event handler in the first argument: `task`.

### Client events

#### `event_receive(task, event_name, data)`
Fires when a event is received.  

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event_name`| Symbol | The name of the event. |
|`data`      | Hash   | The data of the event. |

#### `ready(task)`

Fires when the client is ready.

#### `resumed(task)`

Fires when the client is resumed connection.

### Guild events

#### `guild_join(task, guild)`

Fires when client joins a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was joined. |

#### `guild_available(task, guild)`

Fires when a guild becomes available.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that became available. |

#### `guild_update(task, before, after)`

Fires when client updates a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Guild} | The guild before the update. |
|`after`     | {Discorb::Guild} | The guild after the update. |

#### `guild_leave(task, guild)`

Fires when client leaves a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was left. |

#### `guild_destroy(task, guild)`

Fires when guild is destroyed.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that was destroyed. |

#### `guild_integrations_update(task, guild)`

Fires when guild integrations are updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that integrations were updated for. |

#### `guild_ban_add(task, guild, user)`

Fires when a user is banned from a guild.


| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that the user was banned from. |
|`user`      | {Discorb::User}  | The user that was banned. |

#### `guild_ban_remove(task, guild, user)`

Fires when a user is unbanned from a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild} | The guild that the user was unbanned from. |
|`user`      | {Discorb::User}  | The user that was unbanned. |

### Channel events

#### `channel_create(task, channel)`

Fires when a channel is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`channel`   | {Discorb::Channel} | The channel that was created. |

#### `channel_update(task, before, after)`

Fires when a channel is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Channel} | The channel before the update. |
|`after`     | {Discorb::Channel} | The channel after the update. |

#### `channel_delete(task, channel)`

Fires when a channel is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`channel`   | {Discorb::Channel} | The channel that was deleted. |

#### `webhooks_update(task, event)`

Fires when a webhook is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::WebhooksUpdateEvent} | The webhook update event. |

#### `thread_new(task, thread)`

Fires when a thread is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was created. |

#### `thread_join(task, thread)`

Fires when client joins a thread.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was joined. |


#### `thread_delete(task, thread)`

Fires when a thread is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that was deleted. |

#### `thread_update(task, before, after)`

Fires when a thread is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::ThreadChannel} | The thread before the update. |
|`after`     | {Discorb::ThreadChannel} | The thread after the update. |

#### `thread_members_update(task, thread, added, removed)`

Fires when a thread's members are updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel} | The thread that the members were updated for. |
|`added`     | Array<{ThreadChannel::Member}> | An array of {Discorb::ThreadChannel::Member} objects that were added to the thread. |
|`removed`   | Array<{ThreadChannel::Member}> | An array of {Discorb::ThreadChannel::Member} objects that were removed from the thread. |

#### `thread_member_update(task, before, after)`

Fires when a thread member is updated.

| Parameter | Type  | Description |
| --------- | ----- | ----------- |
|`thread`   | {Discorb::ThreadChannel} | The thread that the member was updated for. |
|`before`   | {Discorb::ThreadChannel::Member} | The thread member before the update. |
|`after`    | {Discorb::ThreadChannel::Member} | The thread member after the update. |

### Integration events

#### `integration_create(task, integration)`

Fires when a guild integration is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`integration`| {Discorb::Integration}| The created integration. |

#### `integration_update(task, before, after)`

Fires when a guild integration is updated.


| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Integration}| The integration before the update. |
|`after`     | {Discorb::Integration}| The integration after the update. |

#### `integration_delete(task, integration)`

Fires when a guild integration is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`integration`| {Discorb::Integration}| The deleted integration. |

### Message events

#### `message(task, message)`

Fires when a message is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message`   | {Discorb::Message}| The created message. |

#### `message_update(task, event)`

Fires when a message is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::MessageUpdateEvent}| The message after the update. |

#### `message_delete(task, message, channel, guild)`

Fires when a message is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message`   | {Discorb::Message}| The deleted message. |
|`channel`   | {Discorb::Channel}| The channel the message was deleted from. |
|`guild`     | ?{Discorb::Guild} | The guild the message was deleted from. |

##### Note

This will fire when cached messages are deleted.

#### `message_delete_id(task, message_id, channel, guild)`

Fires when a message is deleted.
Not like {#message_delete} this will fire even message is not cached.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`message_id`| {Discorb::Snowflake} | The deleted message ID. |
|`channel`   | {Discorb::Channel}| The channel the message was deleted from. |
|`guild`     | ?{Discorb::Guild} | The guild the message was deleted from. |

#### `message_delete_bulk(task, messages)`

Fires when a bulk of messages are deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`messages`  | Array<{Discorb::Message}, {Discorb::GatewayHandler::UnknownDeleteBulkMessage}> | The deleted messages. |

#### `message_pin_update(task, event)`

Fires when a message is pinned or unpinned.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::MessagePinUpdateEvent}| The event object. |

#### `typing_start(task, event)`

Fires when a user starts typing.

| Parameter | Type  | Description |
| --------- | ----- | ----------- |
|`event`    | {Discorb::GatewayHandler::TypingStartEvent}| The event object. |

### Reaction events

#### `reaction_add(task, event)`

Fires when a reaction is added to a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::ReactionEvent}| The event object. |

#### `reaction_remove(task, event)`

Fires when someone removes a reaction from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::ReactionEvent}| The event object. |

#### `reaction_remove_all(task, event)`

Fires when all reactions are removed from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::ReactionRemoveAllEvent}| The event object. |

#### `reaction_remove_emoji(task, event)`

Fires when a reaction is removed from a message.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`event`     | {Discorb::GatewayHandler::ReactionRemoveEmojiEvent}| The event object. |

### Role events

#### `role_create(task, role)`

Fires when a role is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The created role. |

#### `role_update(task, before, after)`

Fires when a role is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Role}| The role before the update. |
|`after`     | {Discorb::Role}| The role after the update. |

#### `role_remove(task, role)`

Fires when a role is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The deleted role. |

### Member events

#### Note

These events requires the `guild_members` intent.

#### `member_add(task, member)`

Fires when a member joins a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`member`    | {Discorb::Member}| The member that joined. |

#### `member_update(task, before, after)`

Fires when a member is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Member}| The member before the update. |
|`after`     | {Discorb::Member}| The member after the update. |

#### `member_remove(task, member)`

Fires when a member is removed from a guild.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`member`    | {Discorb::Member}| The member that left. |

### Role events

#### `role_create(task, role)`

Fires when a role is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The created role. |

#### `role_update(task, before, after)`

Fires when a role is updated.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`before`    | {Discorb::Role}| The role before the update. |
|`after`     | {Discorb::Role}| The role after the update. |

#### `role_remove(task, role)`

Fires when a role is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`role`      | {Discorb::Role}| The deleted role. |

### Invite events

#### `invite_create(task, invite)`

Fires when a invite is created.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`invite`    | {Discorb::Invite}| The created invite. |

#### `invite_delete(task, invite)`

Fires when a invite is deleted.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`invite`    | {Discorb::Invite}| The deleted invite. |

### Interaction events

#### `button_click(task, interaction)`

Fires when a button is clicked.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`interaction`| {Discorb::MessageComponentInteraction::Button}| The interaction object. |

#### `select_menu_select(task, interaction)`

Fires when a select menu is selected.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`interaction`| {Discorb::MessageComponentInteraction::SelectMenu}| The interaction object. |

### Voice events

It's too big, so they're documented in {file:docs/voice_events.md}

### Low-level events

#### `guild_create(task, guild)`

Fires when `GUILD_CREATE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild}| The guild of the event. |

#### `guild_delete(task, guild)`

Fires when `GUILD_DELETE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`guild`     | {Discorb::Guild}| The guild of the event. |

#### `thread_create(task, thread)`

Fires when `THREAD_CREATE` is received.

| Parameter  | Type  | Description |
| ---------- | ----- | ----------- |
|`thread`    | {Discorb::ThreadChannel}| The thread of the event. |
