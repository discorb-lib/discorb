# @title CLI: discorb run

# discorb run

This command will run a client.


## Usage

```
discorb run [options] [script]
```

### Arguments

#### `script`

The script to run. Defaults to `main.rb`.

#### `-d`, `--deamon`

Run the client in deamon mode.

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