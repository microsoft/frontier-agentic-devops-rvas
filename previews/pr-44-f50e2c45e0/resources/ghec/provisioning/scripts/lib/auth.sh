# shellcheck shell=bash
# auth.sh — authentication checks. NEVER handles raw tokens.
# Tokens enter only via `gh auth login` (device flow) or the GH_TOKEN env var,
# never as a CLI argument that would leak into shell history.

auth_check() {
  gh auth status >/dev/null 2>&1
}

auth_login_hint() {
  cat >&2 <<'EOF'
  Not authenticated. Authenticate WITHOUT leaking a token to shell history:
      gh auth login                 # interactive device flow (recommended)
      # or:  export GH_TOKEN=...     # set in your environment, never as a flag
EOF
}

# auth_login -> prints the current login, or empty.
auth_login() {
  gh api user --jq '.login' 2>/dev/null || true
}
