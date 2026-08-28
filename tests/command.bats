#!/usr/bin/env bats
# What actually gets handed to Windows Terminal.

load helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "a dry run never calls Windows Terminal" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Dry"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -f "${WT_CALLS}" ]
}

@test "--go opens one tab per session" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/w1" 3 "One"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/w2" 3 "Two"
  run "$SCRIPT" --go
  [ "$status" -eq 0 ]
  [ "$(tab_count)" -eq 2 ]
}

@test "the tabs use the default profile from settings.json" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Profile"
  run "$SCRIPT" --go
  grep -qx -- "-p" "${WT_CALLS}"
  grep -qx "Ubuntu" "${WT_CALLS}"
}

@test "--profile overrides the detected profile" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Profile"
  run "$SCRIPT" --profile "Command Prompt" --go
  grep -qx "Command Prompt" "${WT_CALLS}"
}

@test "the tab title is the session name" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Generated" "MY-42"
  run "$SCRIPT" --go
  grep -qx -- "--title" "${WT_CALLS}"
  grep -qx "MY-42" "${WT_CALLS}"
}

@test "no argument carries a semicolon, which would split into extra tabs" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/w1" 3 "One"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/w2" 3 "Two"
  run "$SCRIPT" --go
  # the only ';' allowed is the standalone tab separator
  run grep -c ';' "${WT_CALLS}"
  [ "$output" -eq 1 ]
  grep -qx ';' "${WT_CALLS}"
}

@test "a semicolon in the session name does not leak into the command line" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "" "bad;name"
  run "$SCRIPT" --go
  [ "$(tab_count)" -eq 1 ]
  run grep -c ';' "${WT_CALLS}"
  [ "$output" -eq 0 ]
}

@test "the command runs the script in tab-runner mode with the session id" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Runner"
  run "$SCRIPT" --go
  grep -q -- "--tab-runner" "${WT_CALLS}"
  grep -q "aaaaaaaa-1111-2222-3333-444444444444" "${WT_CALLS}"
  grep -q "'resume'" "${WT_CALLS}"
}

@test "--action shell does not ask for a resume" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Shell"
  run "$SCRIPT" --action shell --go
  grep -q "'shell'" "${WT_CALLS}"
}

@test "--only opens just the chosen numbers" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/w1" 3 "One"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/w2" 3 "Two"
  make_session "cccccccc-1111-2222-3333-444444444444" "${SANDBOX}/w3" 3 "Three"
  run "$SCRIPT" --only 2 --go
  [ "$(tab_count)" -eq 1 ]
  [[ "$output" == *"outside --only"* ]]
}

@test "--only with nothing selected opens nothing" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "One"
  run "$SCRIPT" --only 99 --go
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to open"* ]]
  [ ! -f "${WT_CALLS}" ]
}

@test "--window is passed through" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Window"
  run "$SCRIPT" --window 0 --go
  head -2 "${WT_CALLS}" | grep -qx -- "-w"
  head -2 "${WT_CALLS}" | grep -qx "0"
}

@test "--verbose shows the command line" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Verbose"
  run "$SCRIPT" --verbose
  [[ "$output" == *"Command:"* ]]
  [[ "$output" == *"new-tab"* ]]
}

@test "a missing Windows Terminal binary fails clearly" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "No wt"
  WT_BIN="not-a-real-terminal" run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found in PATH"* ]]
}
