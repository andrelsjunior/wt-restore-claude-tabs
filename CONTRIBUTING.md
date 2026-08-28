# Contributing

Thanks for taking a look. Issues and pull requests are welcome.

## Running the checks

```bash
tests/run.sh
```

That runs `shellcheck` on the shell files and the `bats` suite. Both need to be
installed:

```bash
# Debian or Ubuntu
sudo apt-get install shellcheck bats
```

The suite builds a throwaway session history in a temporary directory and puts a
fake `wt.exe` on the `PATH` that only records its arguments. No real tab is ever
opened, and the tests run on plain Linux without WSL.

## What a good pull request looks like

- One change per pull request.
- A test for anything that changes behaviour. Look at `tests/command.bats` for
  assertions about the Windows Terminal command line, and `tests/discovery.bats`
  for anything about finding or naming sessions.
- `shellcheck` clean. No new suppressions unless you explain why in the PR.

## Style

- POSIX-ish bash, `set -euo pipefail`, 2 space indent.
- Comments explain why, not what. If a line looks odd, say what breaks without
  it. The `;` handling and the direnv line are there for real reasons.
- Messages the user sees are lowercase and say what to do next.
- Nothing new on the dependency list. bash, python3 and coreutils is the whole
  runtime, and it should stay that way.

## Things to be careful with

**The `;` character.** Windows Terminal splits its command line on `;` even
inside quotes. Anything that ends up in the `wt.exe` arguments has to be free of
it. `tests/command.bats` guards this, please do not weaken those tests.

**Anything destructive.** The tool opens tabs and, with an explicit flag, edits
`settings.json` after making a backup. It should never delete or overwrite
anything else, and a run without `--go` must stay a pure dry run.

## Reporting a bug

Include the dry run output, without `--go`. It shows which sessions were found
and how they were named, which is usually enough to see what went wrong.
