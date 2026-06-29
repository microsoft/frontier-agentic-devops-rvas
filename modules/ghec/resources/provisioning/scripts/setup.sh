#!/usr/bin/env bash
#
# setup.sh — wth provisioning CLI (Bash entrypoint, macOS/Linux).
#
#   wth <doctor|provision|status|teardown> <ch##> --org <org> \
#        [--enterprise <slug>] [--ref <juiceShopRef>] [--dry-run] [--yes]
#
# One challenge per invocation. Everything created is namespaced wth-<chid>-*.
# Runs against a CUSTOMER-OWNED org: idempotent, prefix-guarded, dry-run aware.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHALLENGES_DIR="$REPO_ROOT/challenges"

# shellcheck source=lib/log.sh
source "$SCRIPT_DIR/lib/log.sh"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/auth.sh
source "$SCRIPT_DIR/lib/auth.sh"
# shellcheck source=lib/guards.sh
source "$SCRIPT_DIR/lib/guards.sh"
# shellcheck source=lib/gh.sh
source "$SCRIPT_DIR/lib/gh.sh"
# shellcheck source=lib/juice-shop-import.sh
source "$SCRIPT_DIR/lib/juice-shop-import.sh"

# ---- defaults --------------------------------------------------------------
COMMAND=""
CHID=""
ORG=""
ENTERPRISE=""
JUICE_SHOP_REF=""        # may be set by --ref; else meta.yml; else versions.lock
DRY_RUN="false"          # mutate by default for create-only provisioning;
ASSUME_YES="false"       # --dry-run previews, teardown still needs confirmation
FORCE="false"            # allow provisioners to reconcile overwrite-safe resources
VL_JUICE_SHOP_REF="v20.0.0"
VL_GH_MIN_VERSION="2.0.0"

usage() {
  cat >&2 <<EOF
wth provisioning CLI (v${WTH_VERSION})

USAGE:
  ./setup.sh <command> <ch##> --org <org> [options]

COMMANDS:
  doctor      Preflight: tooling, auth, required scopes/capabilities (no changes)
  provision   Create all wth-<chid>-* starting state for the challenge (idempotent)
              (alias: setup)
  status      Report what wth-<chid>-* artifacts currently exist
  teardown    Delete ONLY wth-<chid>-* artifacts (confirmation required)

OPTIONS:
  --org <org>          Target org (required for provision/status/teardown)
  --enterprise <slug>  Enterprise slug (only used by enterprise-tier challenges)
  --ref <ref>          Override Juice Shop ref (default: pinned ${VL_JUICE_SHOP_REF})
  --dry-run            Print the mutation plan; change nothing
  --force              Reconcile overwrite-safe seeded resources where supported
  --yes                Skip the teardown confirmation prompt
  -h, --help           This help

EXAMPLES:
  ./setup.sh doctor ch01 --org acme-co
  ./setup.sh provision ch01 --org acme-co --dry-run
  ./setup.sh provision ch01 --org acme-co
  ./setup.sh status ch01 --org acme-co
  ./setup.sh teardown ch01 --org acme-co
EOF
}

# ---- arg parsing -----------------------------------------------------------
[[ $# -lt 1 ]] && { usage; exit 1; }
COMMAND="$1"; shift || true
# `setup` is a friendly alias for `provision` (the verb used throughout the docs).
[[ "$COMMAND" == "setup" ]] && COMMAND="provision"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)         ORG="${2:-}"; shift 2 ;;
    --enterprise)  ENTERPRISE="${2:-}"; shift 2 ;;
    --ref)         JUICE_SHOP_REF="${2:-}"; shift 2 ;;
    --dry-run)     DRY_RUN="true"; shift ;;
    --force)       FORCE="true"; shift ;;
    --yes)         ASSUME_YES="true"; shift ;;
    -h|--help)     usage; exit 0 ;;
    ch[0-9][0-9])  CHID="$1"; shift ;;
    *)             die "unknown argument: '$1' (see --help)" ;;
  esac
done

case "$COMMAND" in
  doctor|provision|status|teardown) ;;
  -h|--help) usage; exit 0 ;;
  *) die "unknown command '$COMMAND' (expected doctor|provision|setup|status|teardown)" ;;
esac

[[ -n "$CHID" ]] || die "missing challenge id (e.g. ch01)"

# ---- resolve challenge + meta ---------------------------------------------
CH_DIR="$(resolve_challenge_dir "$CHID" "$CHALLENGES_DIR")" \
  || die "no challenge folder found for '$CHID' under $CHALLENGES_DIR"
META="$CH_DIR/meta.yml"
if [[ ! -f "$META" ]]; then
  CH_FOLDER="$(basename "$CH_DIR")"
  CANONICAL_META="$(cd "$REPO_ROOT/../.." && pwd)/challenges/$CH_FOLDER/meta.yml"
  [[ -f "$CANONICAL_META" ]] \
    || die "missing meta.yml at $META (also checked $CANONICAL_META)"
  META="$CANONICAL_META"
fi

SLUG="$(meta_scalar "$META" slug)"
[[ -n "$SLUG" ]] || SLUG="${CH_FOLDER:-$(basename "$CH_DIR")}"
SLUG="${SLUG#${CHID}-}"
APP="$(meta_scalar "$META" app)"
[[ -n "$APP" ]] || APP="$(meta_scalar "$META" app_dependency)"
EMU_COMPAT="$(meta_scalar "$META" emu_compatible)"

# Juice Shop ref precedence: --ref > meta.yml > versions.lock
load_versions_lock "$SCRIPT_DIR/versions.lock"
if [[ -z "$JUICE_SHOP_REF" ]]; then
  JUICE_SHOP_REF="$(meta_scalar "$META" juice_shop_ref)"
  [[ -z "$JUICE_SHOP_REF" ]] && JUICE_SHOP_REF="$VL_JUICE_SHOP_REF"
fi

# Canonical names exported to per-challenge provisioners.
NAMESPACE="wth-${CHID}-"
REPO="wth-${CHID}-${SLUG}"
export ORG ENTERPRISE CHID SLUG APP JUICE_SHOP_REF DRY_RUN ASSUME_YES FORCE NAMESPACE REPO META

require_org() {
  [[ -n "$ORG" ]] || die "--org <org> is required for '$COMMAND'"
}

challenge_requires() {
  local explicit caps tags title
  explicit="$(meta_list "$META" requires)"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "$explicit"
    return 0
  fi

  caps="$(meta_list "$META" prerequisite_capabilities)"
  tags="$(meta_list "$META" tags)"
  title="$(meta_scalar "$META" title)"
  {
    echo "org"
    if printf '%s\n%s\n' "$caps" "$tags" | grep -qiE 'advanced security|ghas|code scanning|secret scanning|dependabot'; then
      echo "ghas"
    fi
    if printf '%s\n%s\n%s\n' "$caps" "$tags" "$title" | grep -qi 'copilot'; then
      echo "copilot"
    fi
  } | awk 'NF && !seen[$0]++'
}

# load_challenge — source the per-challenge provisioner and verify its contract.
load_challenge() {
  local pf="$CH_DIR/provision.sh"
  [[ -f "$pf" ]] || die "no provision.sh for $CHID — author must add $pf"
  # shellcheck source=/dev/null
  source "$pf"
  local fn
  for fn in wth_provision wth_teardown wth_status; do
    declare -F "$fn" >/dev/null \
      || die "$pf does not define required function $fn()"
  done
}

# ---- doctor ----------------------------------------------------------------
print_min_scopes() {
  log_step "minimum token scopes for $CHID"
  local scopes=("repo" "read:org")
  meta_list "$META" provision_creates | grep -qiE 'project' && scopes+=("project")
  [[ "$APP" == "juice-shop" ]] && scopes+=("workflow")
  local joined; joined="$(printf '%s, ' "${scopes[@]}")"; joined="${joined%, }"
  log_info "classic PAT scopes:   $joined"
  log_info "fine-grained PAT:     Administration:RW, Contents:RW, Issues:RW, Metadata:R (org '$ORG')"
  if challenge_requires | grep -qx copilot; then
    log_warn "Copilot cannot be enabled via a PAT — an org owner must enable it in org settings."
  fi
  if challenge_requires | grep -qx ghas; then
    log_info "GHAS: no extra PAT scope on PUBLIC repos; ensure Actions + code scanning are enabled."
  fi
}

cmd_doctor() {
  local fail=0
  log_step "doctor — preflight for $CHID ($SLUG)"

  local tool
  for tool in gh git jq; do
    if command -v "$tool" >/dev/null 2>&1; then
      log_ok "$tool present"
    else
      log_error "$tool NOT found — install it before provisioning"; fail=1
    fi
  done

  if command -v gh >/dev/null 2>&1; then
    local v; v="$(gh_version)"
    if [[ -n "$v" ]] && version_ge "$v" "$VL_GH_MIN_VERSION"; then
      log_ok "gh $v (>= $VL_GH_MIN_VERSION)"
    else
      log_warn "gh $v is older than $VL_GH_MIN_VERSION — some commands may differ"
    fi
  fi

  if auth_check; then
    log_ok "gh authenticated as '$(auth_login)'"
  else
    log_error "gh not authenticated"; auth_login_hint; fail=1
  fi

  log_step "required capabilities"
  local cap
  while read -r cap; do
    [[ -z "$cap" ]] && continue
    case "$cap" in
      org)     log_info "org-owner access on '${ORG:-<your org>}'" ;;
      ghas)    log_warn "GHAS — FREE on PUBLIC repos; private/internal needs Code Security/Secret Protection" ;;
      copilot) log_warn "Copilot must be enabled at org level by an org owner" ;;
      *)       log_info "capability: $cap" ;;
    esac
  done < <(challenge_requires)

  print_min_scopes

  if [[ "$CHID" == "ch19" || "$EMU_COMPAT" == "false" ]]; then
    log_warn "EMU: Copilot cloud agent is NOT available on EMU repos — ch19 needs a non-EMU org."
  fi
  case "$APP" in
    juice-shop) log_warn "metered: scanning workflows consume Actions minutes (free tier on public repos)." ;;
  esac
  [[ "$CHID" =~ ^ch(03|04|05|18)$ ]] && \
    log_warn "metered: this challenge may consume Actions/Codespaces minutes on the participant account."

  echo >&2
  if [[ "$fail" -eq 0 ]]; then
    log_ok "DOCTOR PASS — ready to provision $CHID"
  else
    log_error "DOCTOR FAIL — resolve the items above first"
    return 1
  fi
}

# ---- teardown flow ---------------------------------------------------------
teardown_flow() {
  log_warn "About to DELETE all ${NAMESPACE}* artifacts in org '$ORG'."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "dry-run: nothing will be deleted."
  elif ! confirm_destructive "Confirm teardown of $CHID in '$ORG'"; then
    die "teardown aborted by user."
  fi
  wth_teardown
  log_ok "teardown of $CHID complete."
}

# ---- dispatch --------------------------------------------------------------
case "$COMMAND" in
  doctor)
    cmd_doctor
    ;;
  provision)
    require_org
    auth_check || { auth_login_hint; die "authenticate first (run: ./setup.sh doctor $CHID --org $ORG)"; }
    load_challenge
    log_step "provision $CHID -> org '$ORG' (dry-run=$DRY_RUN)"
    wth_provision
    log_ok "provision of $CHID complete."
    ;;
  status)
    require_org
    load_challenge
    wth_status
    ;;
  teardown)
    require_org
    auth_check || { auth_login_hint; die "authenticate first"; }
    load_challenge
    teardown_flow
    ;;
esac
