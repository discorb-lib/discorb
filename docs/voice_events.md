<!--
# @title Voice Events
-->

# Voice Events

### Voice Channel Events

#### `voice_channel_connect(state)`

Fires when someone joins a voice channel.

| Parameter | Type                  | Description                              |
| --------- | --------------------- | ---------------------------------------- |
| state     | {Discorb::VoiceState} | The voice state of the user that joined. |

#### `voice_channel_disconnect(state)`

Fires when someone leaves a voice channel.

| Parameter | Type                  | Description                            |
| --------- | --------------------- | -------------------------------------- |
| state     | {Discorb::VoiceState} | The voice state of the user that left. |

#### `voice_channel_move(before, after)`

Fires when someone moves to a different voice channel.

| Parameter | Type                  | Description                                  |
| --------- | --------------------- | -------------------------------------------- |
| before    | {Discorb::VoiceState} | The voice state of the user before the move. |
| after     | {Discorb::VoiceState} | The voice state of the user after the move.  |

#### `voice_channel_update(before, after)`

Fires when a voice channel is connected, disconnected, or updated.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| before    | {Discorb::VoiceState} | The voice state before the update. |
| after     | {Discorb::VoiceState} | The voice state after the update.  |

### Mute Events

#### `voice_mute_disable(state)`

Fires when a user's voice mute is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_mute_enable(state)`

Fires when a user's voice mute is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_mute_update(before, after)`

Fires when a user's voice mute is enabled or disabled.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

#### `voice_server_mute_enable(state)`

Fires when a user's server voice mute is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_server_mute_disable(state)`

Fires when a user's server voice mute is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_server_mute_update(before, after)`

Fires when a user's server voice mute is enabled or disabled.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

#### `voice_self_mute_enable(state)`

Fires when a user's self voice mute is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_self_mute_disable(state)`

Fires when a user's self voice mute is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_self_mute_update(before, after)`

Fires when a user's self voice mute is enabled or disabled.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

### Deaf Events

#### `voice_deaf_enable(state)`

Fires when a user's voice deaf is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_deaf_disable(state)`

Fires when a user's voice deaf is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_deaf_update(before, after)`

Fires when a user's voice deaf is enabled or disabled.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

#### `voice_server_deaf_enable(state)`

Fires when a user's server voice deaf is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_server_deaf_disable(state)`

Fires when a user's server voice deaf is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_server_deaf_update(before, after)`

Fires when a user's server voice deaf is enabled or disabled.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

#### `voice_self_deaf_enable(state)`

Fires when a user's self voice deaf is enabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_self_deaf_disable(state)`

Fires when a user's self voice deaf is disabled.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_self_deaf_update(before, after)`

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

### Stream Events

#### `voice_stream_start(state)`

Fires when a stream is started.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_stream_end(state)`

Fires when a stream is ended.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_stream_update(before, after)`

Fires when a stream is started or ended.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

### Video Events

#### `voice_video_start(state)`

Fires when a video is started.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_video_end(state)`

Fires when a video is ended.

| Parameter | Type                  | Description      |
| --------- | --------------------- | ---------------- |
| `state`   | {Discorb::VoiceState} | The voice state. |

#### `voice_video_update(before, after)`

Fires when a video is started or ended.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| `before`  | {Discorb::VoiceState} | The voice state before the update. |
| `after`   | {Discorb::VoiceState} | The voice state after the update.  |

### Stage Instances Events

#### `stage_instance_create(instance)`

Fires when a new stage instance is created.

| Parameter  | Type                     | Description           |
| ---------- | ------------------------ | --------------------- |
| `instance` | {Discorb::StageInstance} | The created instance. |

#### `stage_instance_delete(instance)`

Fires when a stage instance is deleted.

| Parameter  | Type                     | Description           |
| ---------- | ------------------------ | --------------------- |
| `instance` | {Discorb::StageInstance} | The deleted instance. |

#### `stage_instance_update(before, after)`

Fires when a stage instance is updated.

| Parameter | Type                     | Description                     |
| --------- | ------------------------ | ------------------------------- |
| `before`  | {Discorb::StageInstance} | The instance before the update. |
| `after`   | {Discorb::StageInstance} | The instance after the update.  |

### Misc Events

#### `voice_state_update(before, after)`

Fired when a user changes voice state.

| Parameter | Type                  | Description                        |
| --------- | --------------------- | ---------------------------------- |
| before    | {Discorb::VoiceState} | The voice state before the update. |
| after     | {Discorb::VoiceState} | The voice state after the update.  |
