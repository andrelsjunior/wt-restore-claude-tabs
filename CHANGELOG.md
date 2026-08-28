# Changelog

All notable changes are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-28

First release.

### Added

- Rebuild Windows Terminal tabs from the Claude Code session history, with no
  setup needed before the crash.
- Tab names taken from the session: your `/rename` name first, then the generated
  one, then the first prompt.
- Windows Terminal default profile detection, so restored tabs look like the rest.
- `--grep` to filter sessions by what was said in the conversation, skipping tool
  output.
- `--only` to reopen a chosen subset of the listing.
- Skips sessions that already have a `claude --resume` process running.
- Short time formats for `--since`: `30m`, `6h`, `7d`, `2w`.
- `--enable-persistence` to turn on Windows Terminal tab persistence, keeping a
  timestamped backup of `settings.json`.
- Dry run by default. Nothing opens without `--go`.
- 37 tests covering option parsing, session discovery, naming and the generated
  Windows Terminal command line.

### Notes

- The default window is 7 days. Measured against a real crash, shorter windows
  missed tabs that had been open but idle for days.
- Restored tabs drop into your login shell when the session ends, so the tab
  stays open.
- `direnv` output is silenced inside restored tabs, which keeps Powerlevel10k's
  instant prompt from warning on every tab.

[1.0.0]: https://github.com/andrelsjunior/wt-restore-claude-tabs/releases/tag/v1.0.0
