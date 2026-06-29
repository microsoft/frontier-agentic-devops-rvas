# shellcheck shell=bash
# common.sh — generic helpers shared by every command: dry-run gating,
# a minimal meta.yml reader (no yq dependency), and challenge-dir resolution.

WTH_VERSION="0.1.0"

# run_mutation <cmd...>
# Executes a state-changing command, or prints the plan under --dry-run and
# changes nothing. EVERY mutation in the codebase must go through this.
run_mutation() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_plan "would run: $*"
    return 0
  fi
  "$@"
}

# meta_scalar <file> <key> -> prints the scalar value (inline comments stripped).
meta_scalar() {
  local file="$1" key="$2"
  awk -v k="$key" '
    index($0, k":") == 1 {
      sub("^"k":[[:space:]]*", "")
      sub(/[[:space:]]*#.*$/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
      exit
    }' "$file"
}

# meta_list <file> <key> -> prints one list item per line.
meta_list() {
  local file="$1" key="$2"
  awk -v k="$key" '
    index($0, k":") == 1 { found=1; next }
    found {
      if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        sub(/[[:space:]]*#.*$/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (line != "") print line
      } else if ($0 ~ /^[^[:space:]#]/) {
        exit
      }
    }' "$file"
}

# resolve_challenge_dir <chid> <challenges-base> -> prints matching dir, or returns 1.
resolve_challenge_dir() {
  local chid="$1" base="$2" match
  match="$(find "$base" -maxdepth 1 -type d -name "${chid}-*" 2>/dev/null | sort | head -n1)"
  [[ -n "$match" ]] || return 1
  printf '%s\n' "$match"
}

# load_versions_lock <file> — sources KEY=VALUE pairs, ignoring comments.
load_versions_lock() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # Only accept simple, safe KEY=VALUE lines.
  while IFS='=' read -r key val; do
    key="${key%%#*}"; key="${key// /}"
    [[ -z "$key" ]] && continue
    val="${val%%#*}"; val="${val// /}"
    case "$key" in
      JUICE_SHOP_REF) VL_JUICE_SHOP_REF="$val" ;;
      GH_MIN_VERSION) VL_GH_MIN_VERSION="$val" ;;
    esac
  done < "$file"
}
