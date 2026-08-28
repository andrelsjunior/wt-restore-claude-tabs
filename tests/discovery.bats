#!/usr/bin/env bats
# Finding sessions, naming tabs and filtering.

load helpers

setup() { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "a session shows up in the listing" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Fix the login bug"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Fix the login bug"* ]]
  [[ "$output" == *"DRY RUN"* ]]
}

@test "the name you gave the session wins over the generated one" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Generated name" "MY-42"
  run "$SCRIPT"
  [[ "$output" == *"* MY-42"* ]]
  [[ "$output" != *"Generated name"* ]]
}

@test "the generated name is used when there is no custom one" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Generated name"
  run "$SCRIPT"
  [[ "$output" == *"~ Generated name"* ]]
}

@test "the first prompt is the fallback name" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3
  run "$SCRIPT"
  [[ "$output" == *"first prompt of aaaaaaaa"* ]]
}

@test "sessions below --min-turns are ignored" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 1 "Too short"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No session found"* ]]
}

@test "a session whose directory is gone is ignored" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Gone"
  rmdir "${SANDBOX}/work"
  run "$SCRIPT"
  [[ "$output" == *"No session found"* ]]
}

@test "--grep keeps only sessions that mention the text" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "About payments" "" "the invoice total is wrong"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "About cats"
  run "$SCRIPT" --grep invoice
  [ "$status" -eq 0 ]
  [[ "$output" == *"About payments"* ]]
  [[ "$output" != *"About cats"* ]]
  [[ "$output" == *"conversations mentioning"* ]]
}

@test "--grep is case insensitive" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Upper" "" "The INVOICE is wrong"
  run "$SCRIPT" --grep invoice
  [[ "$output" == *"Upper"* ]]
}

@test "--grep with no match explains itself" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Something"
  run "$SCRIPT" --grep nothinghere
  [ "$status" -eq 0 ]
  [[ "$output" == *"No session mentioning"* ]]
}

@test "--exclude drops matching paths" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Keep me"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/skipme" 3 "Drop me"
  run "$SCRIPT" --exclude skipme
  [[ "$output" == *"Keep me"* ]]
  [[ "$output" != *"Drop me"* ]]
}

@test "--mode dir keeps one session per directory" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Older"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/work" 3 "Newer"
  touch -d '2026-08-27 10:00' "${CLAUDE_PROJECTS_DIR}"/*/aaaaaaaa-*.jsonl
  run "$SCRIPT" --mode dir --since 20w
  [[ "$output" == *"Newer"* ]]
  [[ "$output" != *"Older"* ]]
}

@test "--limit caps how many are listed" {
  make_session "aaaaaaaa-1111-2222-3333-444444444444" "${SANDBOX}/w1" 3 "One"
  make_session "bbbbbbbb-1111-2222-3333-444444444444" "${SANDBOX}/w2" 3 "Two"
  make_session "cccccccc-1111-2222-3333-444444444444" "${SANDBOX}/w3" 3 "Three"
  run "$SCRIPT" --limit 2
  [ "$(grep -c '^[ =-][0-9]' <<< "$output")" -eq 2 ]
}
