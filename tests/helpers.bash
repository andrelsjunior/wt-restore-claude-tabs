#!/usr/bin/env bash
# Shared helpers: build a throwaway Claude Code history and a fake wt.exe.

SCRIPT="${BATS_TEST_DIRNAME}/../bin/wt-restore-claude-tabs"

setup_sandbox() {
  SANDBOX="$(mktemp -d)"
  export CLAUDE_PROJECTS_DIR="${SANDBOX}/projects"
  export WT_SETTINGS="${SANDBOX}/settings.json"
  export WT_BIN="wt.exe"
  export WT_CALLS="${SANDBOX}/wt-calls.txt"
  mkdir -p "${CLAUDE_PROJECTS_DIR}" "${SANDBOX}/bin"

  # fake Windows Terminal: records every argument, one per line
  cat > "${SANDBOX}/bin/wt.exe" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "${WT_CALLS}"
STUB
  chmod +x "${SANDBOX}/bin/wt.exe"
  PATH="${SANDBOX}/bin:${PATH}"
  export PATH

  cat > "${WT_SETTINGS}" <<'JSON'
{
  "defaultProfile": "{11111111-2222-3333-4444-555555555555}",
  "profiles": {
    "list": [
      { "guid": "{00000000-0000-0000-0000-000000000000}", "name": "Command Prompt" },
      { "guid": "{11111111-2222-3333-4444-555555555555}", "name": "Ubuntu" }
    ]
  }
}
JSON
}

teardown_sandbox() {
  if [ -n "${SANDBOX:-}" ] && [ -d "${SANDBOX}" ]; then
    rm -r "${SANDBOX}"
  fi
}

# make_session <session-id> <workdir> <turns> [ai-title] [custom-title] [extra-text]
make_session() {
  local sid="$1" workdir="$2" turns="$3" ai="${4:-}" custom="${5:-}" extra="${6:-}"
  local slug project
  slug=$(printf '%s' "$workdir" | tr -c 'a-zA-Z0-9' '-')
  project="${CLAUDE_PROJECTS_DIR}/proj${slug}"
  mkdir -p "$project" "$workdir"
  SESSION_FILE="${project}/${sid}.jsonl"
  python3 - "$SESSION_FILE" "$sid" "$workdir" "$turns" "$ai" "$custom" "$extra" <<'PY'
import json
import sys

path, sid, workdir, turns, ai, custom, extra = sys.argv[1:8]


def dump(obj):
    return json.dumps(obj, separators=(',', ':'), ensure_ascii=False)


lines = []
for i in range(int(turns)):
    body = 'first prompt of %s' % sid if i == 0 else 'message %d' % i
    if extra and i == 1:
        body = extra
    lines.append(dump({
        'type': 'user', 'cwd': workdir, 'isSidechain': False,
        'timestamp': '2026-08-27T12:00:%02dZ' % (i % 60),
        'message': {'role': 'user', 'content': body},
    }))
    lines.append(dump({
        'type': 'assistant', 'isSidechain': False,
        'timestamp': '2026-08-27T12:00:%02dZ' % (i % 60),
        'message': {'role': 'assistant', 'content': [{'type': 'text', 'text': 'reply %d' % i}]},
    }))

if ai:
    lines.append(dump({'type': 'ai-title', 'aiTitle': ai, 'sessionId': sid}))
if custom:
    lines.append(dump({'type': 'custom-title', 'customTitle': custom, 'sessionId': sid}))

with open(path, 'w', encoding='utf-8') as fh:
    fh.write('\n'.join(lines) + '\n')
PY
}

# number of tabs in the recorded wt.exe call
tab_count() {
  if [ ! -f "${WT_CALLS}" ]; then
    echo 0
    return
  fi
  grep -c '^new-tab$' "${WT_CALLS}"
}
