<!--
# @title CLI: discorb irb
-->

# discorb irb

This command will start an interactive Ruby shell with connected client.


## Usage

```
discorb irb [options]
```

### Load a token

discorb irb will load a token from...
1. the `DISCORD_BOT_TOKEN` environment variable
2. the `DISCORD_TOKEN` environment variable
3. `token` file in the current directory(customizable with `-t` option)
4. your input

### Arguments

#### `-i`, `--intents`

Intents to use.
Specify intents with integers.

#### `-t`, `--token-file`

Token file to load.

### Variables

#### `message`

Last message received.