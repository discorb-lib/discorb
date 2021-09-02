# @title discord-irb

# discord-irb

discord-irb is a command line tool for interacting with the Discord API.


## Usage

```
$ bundle exec discord-irb
```

To start.

### Load a token

discord-irb will load a token from...
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