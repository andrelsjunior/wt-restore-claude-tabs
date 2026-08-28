#!/usr/bin/env bats
# Option parsing and input validation.

load helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "--help exits 0 and describes the usage" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"reopen Claude Code tabs"* ]]
  [[ "$output" == *"--go"* ]]
}

@test "--version prints the version" {
  run "$SCRIPT" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^wt-restore-claude-tabs\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "unknown option fails with exit 2" {
  run "$SCRIPT" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option"* ]]
}

@test "option without a value fails instead of crashing" {
  run "$SCRIPT" --limit
  [ "$status" -eq 2 ]
  [[ "$output" == *"needs a value"* ]]
  [[ "$output" != *"unbound variable"* ]]
}

@test "invalid --mode is rejected" {
  run "$SCRIPT" --mode sideways
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid --mode"* ]]
}

@test "invalid --action is rejected" {
  run "$SCRIPT" --action explode
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid --action"* ]]
}

@test "non numeric --limit is rejected" {
  run "$SCRIPT" --limit abc
  [ "$status" -eq 2 ]
  [[ "$output" == *"must be a number"* ]]
}

@test "--only rejects anything that is not numbers and commas" {
  run "$SCRIPT" --only "1;rm"
  [ "$status" -eq 2 ]
  [[ "$output" == *"numbers separated by commas"* ]]
}

@test "short time formats are accepted" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Short window"
  for spec in 30m 6h 7d 2w; do
    run "$SCRIPT" --since "$spec"
    [ "$status" -eq 0 ]
    [[ "$output" == *"window: ${spec}"* ]]
  done
}

@test "invalid --since is rejected" {
  run "$SCRIPT" --since "not a date"
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid --since"* ]]
}

@test "missing history directory fails clearly" {
  CLAUDE_PROJECTS_DIR="${SANDBOX}/does-not-exist" run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no session history"* ]]
}
