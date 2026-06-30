# shellcheck shell=bash
# guards.sh — namespace + destructive-action guard rails.
# This runs against a CUSTOMER-OWNED org. Nothing destructive happens without
# (a) a name that starts with this challenge's exact prefix, and
# (b) explicit confirmation (interactive or --yes).

# guard_prefix <name> <chid> -> 0 only if <name> is inside wth-<chid>-*.
# Teardown MUST call this before deleting anything.
guard_prefix() {
  local name="$1" chid="$2" expect
  expect="wth-${chid}-"
  case "$name" in
    "${expect}"*) return 0 ;;
    *)
      log_error "refusing to touch '$name' — outside namespace '${expect}*'"
      return 1
      ;;
  esac
}

# confirm_destructive <prompt> -> 0 if confirmed.
# --yes bypasses the prompt; otherwise the user must type the challenge id back.
confirm_destructive() {
  local prompt="$1" reply
  if [[ "${ASSUME_YES:-false}" == "true" ]]; then
    return 0
  fi
  printf '%s\n  type "%s" to confirm: ' "$prompt" "${CHID:-?}" >&2
  read -r reply
  [[ "$reply" == "${CHID:-}" ]]
}
