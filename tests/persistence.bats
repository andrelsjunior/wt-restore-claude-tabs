#!/usr/bin/env bats
# --enable-persistence is the only thing that writes to a file of yours.

load helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "sets firstWindowPreference" {
  run "$SCRIPT" --enable-persistence
  [ "$status" -eq 0 ]
  run python3 -c "import json;print(json.load(open('${WT_SETTINGS}'))['firstWindowPreference'])"
  [ "$output" = "persistedWindowLayout" ]
}

@test "keeps a backup of the original settings" {
  cp "${WT_SETTINGS}" "${SANDBOX}/before.json"
  run "$SCRIPT" --enable-persistence
  [[ "$output" == *"backup:"* ]]
  local backup
  backup=$(find "${SANDBOX}" -name 'settings.json.bak.*' | head -1)
  [ -n "$backup" ]
  run diff "${SANDBOX}/before.json" "$backup"
  [ "$status" -eq 0 ]
}

@test "leaves every other setting untouched" {
  run "$SCRIPT" --enable-persistence
  run python3 -c "
import json
data = json.load(open('${WT_SETTINGS}'))
print(data['defaultProfile'])
print(len(data['profiles']['list']))
"
  [[ "$output" == *"{11111111-2222-3333-4444-555555555555}"* ]]
  [[ "$output" == *"2"* ]]
}

@test "running it twice is harmless" {
  run "$SCRIPT" --enable-persistence
  [ "$status" -eq 0 ]
  run "$SCRIPT" --enable-persistence
  [ "$status" -eq 0 ]
  run python3 -c "import json;print(json.load(open('${WT_SETTINGS}'))['firstWindowPreference'])"
  [ "$output" = "persistedWindowLayout" ]
}

@test "a settings file with a BOM is still readable" {
  python3 -c "
import json
data = json.load(open('${WT_SETTINGS}'))
open('${WT_SETTINGS}', 'w', encoding='utf-8-sig').write(json.dumps(data))
"
  run "$SCRIPT" --enable-persistence
  [ "$status" -eq 0 ]
}

@test "fails clearly when settings.json is missing" {
  WT_SETTINGS="${SANDBOX}/nope.json" run "$SCRIPT" --enable-persistence
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}

@test "does not touch settings.json on a normal run" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "No writes"
  local before
  before=$(md5sum < "${WT_SETTINGS}")
  run "$SCRIPT" --go
  [ "$(md5sum < "${WT_SETTINGS}")" = "$before" ]
}
