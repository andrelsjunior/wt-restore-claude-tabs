#!/usr/bin/env bats
# --tab-runner is what actually runs inside each new tab.

load helpers

setup() {
  setup_sandbox
  setup_fake_tab_binaries
  mkdir -p "${SANDBOX}/work"
}
teardown() { teardown_sandbox; }

@test "runner changes into the session directory before starting claude" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude-cwd: ${SANDBOX}/work"* ]]
}

@test "runner resumes the session it was given" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [[ "$output" == *"claude-called: --resume aaaaaaaa-1111-2222-3333-444444444444"* ]]
}

@test "runner supports the continue action" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" continue ""
  [[ "$output" == *"claude-called: --continue"* ]]
}

@test "runner with the shell action does not start claude" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" shell ""
  [ "$status" -eq 0 ]
  [[ "$output" != *"claude-called"* ]]
  [[ "$output" == *"login-shell"* ]]
}

@test "runner ends in the login shell so the tab stays open" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [[ "$output" == *"login-shell: -l"* ]]
}

@test "runner silences direnv, which would break the instant prompt" {
  cat > "${SANDBOX}/bin/claude" <<'PROBE'
#!/usr/bin/env bash
echo "direnv-log-format: [${DIRENV_LOG_FORMAT-unset}]"
PROBE
  chmod +x "${SANDBOX}/bin/claude"
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [[ "$output" == *"direnv-log-format: []"* ]]
}

@test "runner survives a directory that no longer exists" {
  run "$SCRIPT" --tab-runner "${SANDBOX}/gone" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [ "$status" -eq 0 ]
  [[ "$output" == *"directory not found"* ]]
  [[ "$output" == *"login-shell"* ]]
}

@test "runner says so when claude is missing instead of failing silently" {
  rm "${SANDBOX}/bin/claude"
  PATH="${SANDBOX}/bin:/usr/bin:/bin" HOME="${SANDBOX}" run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [[ "$output" == *"was not found"* ]]
  [[ "$output" == *"login-shell"* ]]
}

@test "a claude failure still leaves you with a usable shell" {
  cat > "${SANDBOX}/bin/claude" <<'FAILING'
#!/usr/bin/env bash
echo "boom" >&2
exit 3
FAILING
  chmod +x "${SANDBOX}/bin/claude"
  run "$SCRIPT" --tab-runner "${SANDBOX}/work" resume "aaaaaaaa-1111-2222-3333-444444444444"
  [ "$status" -eq 0 ]
  [[ "$output" == *"login-shell"* ]]
}
