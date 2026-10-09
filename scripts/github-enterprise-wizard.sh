#!/usr/bin/env bash
set -euo pipefail
umask 077

WIZARD_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/github-enterprise-wizard" && pwd)"
export WIZARD_HOME
source "$WIZARD_HOME/lib/api.sh"
source "$WIZARD_HOME/lib/config.sh"
source "$WIZARD_HOME/lib/readiness.sh"
source "$WIZARD_HOME/lib/execute.sh"
source "$WIZARD_HOME/lib/content.sh"
source "$WIZARD_HOME/packages/enterprise.sh"
source "$WIZARD_HOME/packages/workspace.sh"
source "$WIZARD_HOME/packages/actions.sh"
source "$WIZARD_HOME/packages/capabilities.sh"

wizard_usage() {
  cat <<'USAGE'
GitHub enterprise setup wizard

  init   --output config.json [--plain] [--no-discovery]
  doctor --config config.json [--json]
  plan   --config config.json --output plan.json
  apply  --plan plan.json --run run-directory [--approve PLAN_DIGEST]
  resume --run run-directory [--approve PLAN_DIGEST]
  verify --run run-directory
  status --run run-directory
  attest --run run-directory --action ID --evidence HTTPS_URL --approve PLAN_DIGEST
  catalog [--governance]

Apply asks you to approve the saved plan. In CI, pass its exact digest.
Init shows question pages with section progress. Enter/Right advances.
In menus, Left/B goes back. Use --plain for scrollable text prompts.
Init discovery only reads GitHub. Use --no-discovery to enter everything manually.
Exit codes: 0 ready/saved, 1 interview stopped, 2 invalid/failed, 3 incomplete.
USAGE
}

command_name="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
config='' output='' plan='' run='' approve='' action='' evidence='' doctor_format=text
catalog_kind=packages
WIZARD_PLAIN=false
WIZARD_NO_DISCOVERY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config|--output|--plan|--run|--approve|--action|--evidence)
      [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || wizard_die "Missing value for $1"
      case "$1" in
        --config) config="$2" ;; --output) output="$2" ;;
        --plan) plan="$2" ;; --run) run="$2" ;; --approve) approve="$2" ;;
        --action) action="$2" ;; --evidence) evidence="$2" ;;
      esac
      shift 2 ;;
    --help|-h) wizard_usage; exit 0 ;;
    --plain) [[ "$command_name" == init ]] || wizard_die "--plain is only supported for init"; WIZARD_PLAIN=true; shift ;;
    --no-discovery) [[ "$command_name" == init ]] || wizard_die "--no-discovery is only supported for init"; WIZARD_NO_DISCOVERY=true; shift ;;
    --json) [[ "$command_name" == doctor ]] || wizard_die "--json is only supported for doctor"; doctor_format=json; shift ;;
    --governance) [[ "$command_name" == catalog ]] || wizard_die "--governance is only supported for catalog"; catalog_kind=governance; shift ;;
    *) wizard_die "Unknown argument: $1" ;;
  esac
done
case "$command_name" in
  help|--help|-h) wizard_usage ;;
  catalog)
    command -v jq >/dev/null || wizard_die "Install jq first"
    if [[ "$catalog_kind" == governance ]]; then wizard_governance_catalog
    else jq . "$WIZARD_HOME/catalog.json"
    fi ;;
  init) [[ -n "$output" ]] || wizard_die "Use --output"; wizard_require_tools; wizard_init "$output" ;;
  doctor) [[ -n "$config" ]] || wizard_die "Use --config"; wizard_require_tools; wizard_doctor "$config" "$doctor_format" ;;
  plan) [[ -n "$config" && -n "$output" ]] || wizard_die "Use --config and --output"; wizard_require_tools; wizard_plan "$config" "$output" ;;
  apply) [[ -n "$plan" && -n "$run" ]] || wizard_die "Use --plan and --run"; wizard_require_tools; wizard_apply "$plan" "$run" "$approve" ;;
  resume) [[ -n "$run" ]] || wizard_die "Use --run"; wizard_require_tools; wizard_resume "$run" "$approve" ;;
  verify) [[ -n "$run" ]] || wizard_die "Use --run"; wizard_require_tools; wizard_verify_run "$run" ;;
  status) [[ -n "$run" ]] || wizard_die "Use --run"; wizard_require_tools; wizard_status "$run" ;;
  attest) [[ -n "$run" && -n "$action" && -n "$evidence" && -n "$approve" ]] || wizard_die "Use --run, --action, --evidence, and --approve"; wizard_require_tools; wizard_attest "$run" "$action" "$evidence" "$approve" ;;
  *) wizard_die "Unknown command: $command_name" ;;
esac
