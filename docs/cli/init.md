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

### `--[no-]desc`

Whether to create a description file.
If true, the command will create a `.env.sample` and `README.md` file.
Default to false.

### `-n` `--name`

The name of the project.
It will be used in the `README.md` file.
Default to the directory name.

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
| `main.rb` | Main script. |
| `.gitignore` | Git ignore file. Won't be created if `--git` is false. |
| `Gemfile` | Gemfile. Won't be created if `--bundle` is false. |
| `Gemfile.lock` | Gemfile lock file. Won't be created if `--bundle` is false. |
| `README.md` | Readme file. Won't be created if `--desc` is false. |
| `.env.sample` | Sample environment variables. Won't be created if `--desc` is false. |
