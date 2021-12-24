<!--
# @title CLI: discorb run
-->

# discorb run

This command will run a client.


## Usage

```
discorb run [options] [script]
```

### Arguments

#### `script`

The script to run. Defaults to `main.rb`.
If the script wasn't specified, it will also look for a file named `main.rb` in the parent directories, like rake.

### Options

#### `-t`, `--title`

The title of the process.

#### `-l`, `--log-level`

Specify the log level.
Should be one of the following:

* `none`
* `debug`
* `info`
* `warn`
* `error`
* `fatal`

#### `-f`, `--log-file`

Specify the file to write logs to.
You can use `stdout` to write to the standard output, and `stderr` to write to the standard error.

#### `-c`, `--[no-]log-color`

Whether to colorize the log output.
If not specified, the default will be:
- `true` if the file to write logs to is `stdout` or `stderr`.
- `false` otherwise.

#### `-s`, `--setup`

Whether to setup application commands.

#### `-e`, `--env`

The name of the environment variable to use for token, or just `-t` or `--token` for intractive prompt.

#### `-b`, `--bundler`

Whether to use bundler to load the script.
