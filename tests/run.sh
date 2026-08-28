#!/usr/bin/env bash
# Run the full check: shellcheck then bats.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if command -v shellcheck >/dev/null 2>&1; then
  echo "==> shellcheck"
  shellcheck bin/wt-restore-claude-tabs install.sh tests/run.sh
else
  echo "==> shellcheck not installed, skipping"
fi

echo "==> bats"
if command -v bats >/dev/null 2>&1; then
  bats tests/
else
  echo "bats is not installed. See https://bats-core.readthedocs.io" >&2
  exit 1
fi
