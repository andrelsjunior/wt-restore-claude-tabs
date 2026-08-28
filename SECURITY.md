# Security

## Reporting

Please open a [private security advisory](https://github.com/andrelsjunior/wt-restore-claude-tabs/security/advisories/new)
rather than a public issue. I will reply as soon as I can.

## What this tool touches

Worth knowing when you review it:

- **It reads your Claude Code history** in `~/.claude/projects`. Those files hold
  everything from your conversations. The tool only extracts the working
  directory, session id, session name and message count, but `--grep` does search
  the full text of what was written.
- **Session names become tab titles.** If you paste a secret into a conversation
  and it ends up as the first prompt, it can end up as a tab title. Naming your
  sessions with `/rename` avoids that.
- **`--enable-persistence` writes to your Windows Terminal `settings.json`,**
  after copying it to a timestamped backup next to the original. It is the only
  file the tool ever writes to.
- **It runs `claude --resume` in a new tab.** Nothing else is executed on your
  behalf, and nothing runs without `--go`.
- **Nothing leaves your machine.** There is no network access anywhere in the
  script.
