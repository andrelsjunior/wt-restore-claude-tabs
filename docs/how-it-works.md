# How it works

## Where the state comes from

Claude Code writes one JSON Lines file per session:

```
~/.claude/projects/<slug-of-cwd>/<session-uuid>.jsonl
```

Everything this tool needs is in there:

| Field | Record type | Used for |
| ----- | ----------- | -------- |
| `cwd` | any message | the directory to open the tab in |
| file name | - | the session id passed to `claude --resume` |
| `customTitle` | `custom-title` | the tab name you set with `/rename` |
| `aiTitle` | `ai-title` | the generated tab name |
| first user message | `user` | fallback tab name |
| file mtime | - | how recently the session was touched |

The glob is one level deep on purpose:

```python
glob.glob(os.path.join(root, '*', '*.jsonl'))
```

Going deeper picks up `subagents/agent-*.jsonl`, the transcripts of subagent runs.
Those are not tabs. On a real history, 101 of 121 files in a 7 day window were
subagent transcripts, so a recursive search inflates the count by 5x.

Reading is line by line, and only lines that can matter are parsed as JSON. A
session with a thousand messages costs a few milliseconds.

## The semicolon problem

Windows Terminal separates tabs with `;`:

```
wt.exe new-tab ... ; new-tab ...
```

It splits on `;` **even inside quotes**. This looks reasonable and is broken:

```bash
wt.exe new-tab wsl.exe -d Ubuntu -- bash -lc "cd ~ && claude --resume $ID; exec bash -l"
```

Windows Terminal reads it as two tabs. The second one tries to run a Windows
program called `exec bash -l` and fails with:

```
[error 2147942402 (0x80070002) when launching `exec bash -l`]
The system cannot find the file specified.
```

The fix is to keep `;` out of the command line completely. The script calls
itself in an internal mode:

```
wsl.exe -d Ubuntu -- bash -lc '<script>' --tab-runner '<dir>' 'resume' '<id>'
```

The `cd`, the `claude` call and the final `exec` all happen inside that mode,
where Windows Terminal cannot see them. The only `;` left is the tab separator,
passed as its own argument.

Session names are also stripped of `;` before becoming tab titles, for the same
reason.

## The profile problem

Passing a command line to `new-tab` without `-p` creates a tab with no profile.
It does not inherit your font, colors or icon, and it looks like a `cmd` window.
You can see it in the tab's environment: `WT_PROFILE_ID` comes back empty.

So the script reads `defaultProfile` from your Windows Terminal `settings.json`,
matches it against the profile list, and passes `-p <name>`.

## Why the tab drops into a login shell

The runner ends with `exec "$SHELL" -l`. Two reasons:

1. Without it the tab closes as soon as the Claude session ends.
2. Using `$SHELL` rather than `bash` keeps you in the shell you actually use.

## Why direnv is silenced in the tab

The tab starts already inside the project directory, so `direnv` loads `.envrc`
during shell startup. Powerlevel10k's instant prompt warns about any console
output at that moment, so every restored tab would open with a wall of warning
text.

The runner exports `DIRENV_LOG_FORMAT=""`. That silences the `direnv: loading`
lines while still exporting every variable from `.envrc`. It applies only to tabs
opened by this tool, your normal shells are untouched.

## Detecting sessions that are already open

Before opening anything, the script scans `/proc/*/cmdline` for a running
`claude --resume <uuid>` and skips those ids.

This is partial by design. A session you resumed from inside the TUI runs as a
plain `claude` process with no id in its arguments, so it cannot be matched. The
listing marks what it does find with `=`, and `--no-skip-open` turns the check
off.

## Testing

The suite builds a throwaway history in a temporary directory and puts a fake
`wt.exe` on the `PATH` that appends its arguments to a file. Every assertion
about the command line reads that file, so no real tab ever opens during a test
run and the suite works on plain Linux CI, without WSL or Windows Terminal.
