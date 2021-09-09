# @title CLI: discorb init

# discorb init

This command will create a new project in the directory.

## Usage

```bash
discorb init [options] [dir]
```

## Options

### `dir`

The directory to create the project in.
Defaults to the current directory.
If the directory exists and is not empty, an error is returned.
You can use `--force` to overwrite an existing directory.

### `--[no-]bundle`

Whether to use bundle.
If true, the command will create Gemfile and execute `bundle install`.
Default to true.

### `--[no-]git`

Whether to initialize git.
If true, the command will initialize git and commit the initial files with commit message `Initial commit`.
Use `git commit --amend -m "..."` to change the commit message.
Default to false.

### `-t`, `--token`

The name of token environment variable.
Default to TOKEN.

### `-f`, `--force`

Whether to overwrite an existing directory.
Default to false.

## File structure

The following files will be created:

| File | Description |
| ---- | ----------- |
| `.env` | Environment variables. |
| `.gitignore` | Git ignore file. Won't be created if `--git` is false. |
| `Gemfile` | Gemfile. Won't be created if `--bundle` is false. |
| `Gemfile.lock` | Gemfile lock file. Won't be created if `--bundle` is false. |
| `main.rb` | Main script. |
