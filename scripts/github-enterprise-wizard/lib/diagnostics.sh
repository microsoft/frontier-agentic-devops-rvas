#!/usr/bin/env bash

wizard_diagnostic_text() {
  if command -v jq >/dev/null 2>&1; then
    if printf '%s' "$1" | jq -Rrs '
      gsub("github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9_]+|AKIA[A-Z0-9]{16}|-----BEGIN [^-]*PRIVATE KEY-----[\\s\\S]*"; "[REDACTED]")
      | gsub("(?i)bearer[ \\t]+[^\\s\"<>]+|(?:token|password|secret|authorization|api[_-]?key)[ \\t]*[=:][ \\t]*[^\\s,;]+|https?://[^/@\\s]+:[^/@\\s]+@"; "[REDACTED]")
      | gsub("[\u0000-\u0008\u000b-\u001f\u007f]"; "?")
      | if length > 4000 then .[0:4000] + "\n[details truncated]" else . end
    '; then return 0; fi
  fi
  printf '%s\n' 'Details withheld because jq could not sanitize the error. Install or repair jq, then retry.'
}

wizard_diagnostic() {
  local stage="$1" status="$2" detail="$3" revision='unavailable' fingerprint='unavailable' jq_version='unavailable'
  local diagnostics_root
  diagnostics_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
  if command -v git >/dev/null 2>&1; then
    revision="$(git -C "$diagnostics_root" rev-parse --short=12 HEAD 2>/dev/null)" || revision='unavailable'
  fi
  if [[ -n "${WIZARD_HOME:-}" ]] && declare -F wizard_code_hash >/dev/null && { command -v shasum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1; }; then
    fingerprint="$(wizard_code_hash)" || fingerprint='unavailable'
  fi
  if command -v jq >/dev/null 2>&1; then jq_version="$(jq --version 2>&1)" || jq_version='unavailable'; fi
  printf '\n--- Wizard diagnostic: copy this block ---\n' >&2
  wizard_diagnostic_text "Command: ${command_name:-library}
Stage: $stage
Exit status: $status
Revision: $revision
Implementation SHA-256: $fingerprint
Bash: $BASH_VERSION
jq: $jq_version
Details:
$detail" >&2
  printf '%s\n\n' '--- End wizard diagnostic ---' >&2
}
