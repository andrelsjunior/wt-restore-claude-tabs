# wt-restore-claude-tabs

Reopen your Claude Code tabs in Windows Terminal after a reboot, a crash, or an
accidental close.

[![CI](https://github.com/andrelsjunior/wt-restore-claude-tabs/actions/workflows/ci.yml/badge.svg)](https://github.com/andrelsjunior/wt-restore-claude-tabs/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell: bash](https://img.shields.io/badge/shell-bash-4EAA25.svg)](bin/wt-restore-claude-tabs)

```
$ wt-restore-claude-tabs
window: 7d (since 21/08 00:43)
#    LAST USED     MSG   DIRECTORY                       TAB NAME  (* yours / ~ generated)
 1   27/08 23:56   112   ~/work/backend                  * AUTH-42 token refresh
 2   27/08 23:56   472   ~/work/api                      * checkout retries
=3   27/08 23:23   58    ~                               ~ Chess engine in Docker
 4   27/08 22:58   101   ~/work/frontend                 ~ Dark mode for the settings page

= already open (1 skipped; use --no-skip-open to open anyway)
DRY RUN - nothing was opened. Run it again with --go to open 3 tab(s).
```

## The problem

Windows Terminal can restore your tabs, but only if `firstWindowPreference` was
set to `persistedWindowLayout` **before** the window closed. If it was not, there
is nothing to undo, and every Claude Code conversation you had open is now
something you have to find by hand, one `claude --resume` at a time.

Worse, even with persistence turned on, a tab you opened by hand is saved as a
plain `wsl.exe --cd ~`. Windows Terminal gives you back an empty shell in your
home directory, not the session you were working in.

## What this does

It rebuilds the tabs from the session history that Claude Code already writes to
`~/.claude/projects/*/<uuid>.jsonl`. That file holds the working directory, the
session id and the session name, so no setup, daemon or hook is needed before the
crash. It works after the fact.

For each session it opens one Windows Terminal tab that:

- uses your default Windows Terminal profile, so it looks like your other tabs
- is named after the session, not after a truncated first prompt
- changes into the original working directory
- runs `claude --resume <id>`
- drops into your login shell when the session ends, so the tab stays open

## Install

```bash
git clone https://github.com/andrelsjunior/wt-restore-claude-tabs.git
cd wt-restore-claude-tabs
./install.sh
```

`install.sh` symlinks `bin/wt-restore-claude-tabs` into `~/.local/bin`. To install
somewhere else, run `PREFIX=/usr/local ./install.sh`.

To remove it, run `./install.sh --uninstall`.

You can also just copy the single file, it has no dependencies beyond bash,
python3 and coreutils.

## Usage

Nothing opens without `--go`. Running it with no flags is always a dry run.

```bash
wt-restore-claude-tabs                 # list what it would reopen
wt-restore-claude-tabs --go            # reopen it
wt-restore-claude-tabs --only 2,5 --go # reopen only items 2 and 5
wt-restore-claude-tabs -g "auth bug"   # only sessions that discussed it
```

A short alias helps, since you reach for this right after losing your tabs:

```bash
echo 'alias rt="wt-restore-claude-tabs"' >> ~/.zshrc
```

### Picking the time window

There is no flag in the transcript that says "this tab was open". The proxy is
when the session was last touched, which is what `--since` controls.

Pick it wider than feels right. An open tab is not the same as a recently used
tab: people leave a conversation sitting for days and come back to it. On the run
that led to this tool, of the 11 tabs that were open at the moment of the crash,
one had been idle for 154 hours.

| `--since` | tabs recovered | extra tabs |
| --------- | -------------- | ---------- |
| 6h        | 2 of 11        | 0          |
| 1d        | 6 of 11        | 0          |
| 2d        | 9 of 11        | 0          |
| **7d**    | **11 of 11**   | **1**      |
| 14d       | 11 of 11       | 8          |

The default is 7d. The two mistakes are not symmetric: an extra tab is one click
to close, a missing tab is one you find out about days later.

### Tab names

The name comes from the session itself, in this order:

1. the name you gave it with `/rename`, shown as `*`
2. the name Claude generated, shown as `~`
3. the first prompt of the conversation

Naming the session, rather than the tab, means the name survives a crash. A tab
name lives only inside Windows Terminal and has no link back to the conversation.

### Searching inside conversations

`--grep` filters by what was actually said, not by the tab name:

```bash
wt-restore-claude-tabs -g "rate limit"
```

It reads what you and Claude wrote and skips tool output, which keeps out matches
from search results and loaded files. Around 0.3s for 133 MB of history.

## Options

| Option | What it does |
| ------ | ------------ |
| `-n, --limit N` | maximum number of tabs (default 30) |
| `-s, --since SPEC` | time window: `30m`, `6h`, `7d`, `2w`, or `"2 days ago"` (default 7d) |
| `-m, --mode MODE` | `session` (one tab per conversation, default) or `dir` (one per directory) |
| `-a, --action ACTION` | `resume` (default), `continue`, or `shell` for the directory only |
| `-o, --only LIST` | open only these numbers, for example `1,3,5` |
| `-g, --grep TEXT` | only sessions that mention this text |
| `-x, --exclude REGEX` | drop matching paths |
| `--min-turns N` | ignore sessions shorter than N messages (default 2) |
| `-w, --window W` | `new` for a new window (default), `0` for the current one |
| `-p, --profile NAME` | Windows Terminal profile (default: the one in your settings) |
| `--no-skip-open` | do not skip sessions that are already running |
| `-v, --verbose` | print the full `wt.exe` command line |
| `--enable-persistence` | turn on Windows Terminal tab persistence, with a backup |
| `--go` | actually open the tabs |

## Turning on Windows Terminal persistence too

```bash
wt-restore-claude-tabs --enable-persistence
```

This sets `firstWindowPreference` to `persistedWindowLayout` in your Windows
Terminal `settings.json`, keeping a timestamped backup. Close and reopen Windows
Terminal for it to take effect.

Worth doing, but it does not replace this tool:

- it only helps on a clean close, a hard power loss can beat it
- a tab you opened by hand comes back as an empty shell in your home directory

Tabs opened by this tool are saved with the full resume command, so Windows
Terminal brings the actual session back. The two work better together.

## Requirements

- WSL, with Windows Terminal on the Windows side
- bash 4+, python3, coreutils (`date -d`)
- Claude Code, with history in `~/.claude/projects`

## Limits worth knowing

- **Detecting open sessions is partial.** It catches sessions started with
  `claude --resume <id>`. A session resumed from inside the TUI does not expose
  the id, so it can be listed as closed when it is not.
- **It does not restore panes or splits**, only tabs.
- **It does not restore a tab you renamed in Windows Terminal.** That name lives
  in Windows Terminal and has no link to a session. Rename the session instead.
- **Only the Claude Code part comes back.** A tab that was running vim or a dev
  server is not something this tool knows about.

## How it works

See [docs/how-it-works.md](docs/how-it-works.md) for the transcript format, the
`;` problem in the Windows Terminal command line, and why the tab command routes
through the script itself.

## Development

```bash
tests/run.sh          # shellcheck + bats
```

61 tests, green on Ubuntu 22.04 and 24.04. The suite builds a throwaway session
history, a fake `wt.exe` that records its arguments, a fake `claude` and a fake
login shell, so nothing real is opened while testing and it runs on plain Linux
without WSL.

These environment variables exist so the tests can drive the script, and they are
useful for debugging too:

| Variable | Default | What it does |
| -------- | ------- | ------------ |
| `CLAUDE_PROJECTS_DIR` | `~/.claude/projects` | where to read session history from |
| `WT_SETTINGS` | detected | path to the Windows Terminal `settings.json` |
| `WT_BIN` | `wt.exe` | the Windows Terminal binary to call |
| `WT_PROC_DIR` | `/proc` | where to look for running sessions |
| `WSL_DISTRO_NAME` | `Ubuntu` | distro passed to `wsl.exe` |

## License

MIT. See [LICENSE](LICENSE).
