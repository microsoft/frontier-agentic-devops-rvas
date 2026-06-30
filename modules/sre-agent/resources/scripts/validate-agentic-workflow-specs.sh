#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_DIR="$MODULE_DIR/resources/agentic-workflows"

required_specs=(
  "issue-triage-agent.md"
  "ci-doctor.md"
  "plan-command.md"
)

required_frontmatter_keys=(
  "name:"
  "description:"
  "triggers:"
  "permissions:"
  "tools:"
  "safe_outputs:"
  "post_stage:"
)

required_sections=(
  "## Purpose"
  "## Peli's Factory Pattern"
  "## Trigger"
  "## Minimal Permissions"
  "## Inputs"
  "## Tools"
  "## Agent Instructions"
  "## Safe Outputs"
  "## Post-Stage Write Job"
  "## Threat Checks"
  "## Human Review Gate"
  "## Fallback Without gh-aw"
  "## Validation Checklist"
)

failures=0

check_contains() {
  local file="$1"
  local needle="$2"

  if ! grep -Fq -- "$needle" "$file"; then
    printf 'ERROR: %s missing required text: %s\n' "${file#$MODULE_DIR/}" "$needle" >&2
    failures=$((failures + 1))
  fi
}

check_frontmatter() {
  local file="$1"
  local delimiter_count

  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    printf 'ERROR: %s must start with YAML frontmatter delimiter.\n' "${file#$MODULE_DIR/}" >&2
    failures=$((failures + 1))
    return
  fi

  delimiter_count="$(grep -n '^---$' "$file" | wc -l | tr -d ' ')"
  if [[ "$delimiter_count" -lt 2 ]]; then
    printf 'ERROR: %s must contain closing YAML frontmatter delimiter.\n' "${file#$MODULE_DIR/}" >&2
    failures=$((failures + 1))
  fi

  for key in "${required_frontmatter_keys[@]}"; do
    check_contains "$file" "$key"
  done
}

for spec in "${required_specs[@]}"; do
  path="$SPEC_DIR/$spec"

  if [[ ! -f "$path" ]]; then
    printf 'ERROR: Missing required spec: %s\n' "${path#$MODULE_DIR/}" >&2
    failures=$((failures + 1))
    continue
  fi

  check_frontmatter "$path"

  for section in "${required_sections[@]}"; do
    check_contains "$path" "$section"
  done

  check_contains "$path" "gh aw compile"
  check_contains "$path" 'Do not hand-edit generated `.lock.yml` files.'
done

check_contains "$SPEC_DIR/README.md" "Peli's Agent Factory"
check_contains "$SPEC_DIR/README.md" "gh extension install github/gh-aw"
check_contains "$SPEC_DIR/agentic-workflow-review-rubric.md" "PROSE"

if [[ "$failures" -gt 0 ]]; then
  printf 'Agentic workflow spec validation failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Agentic workflow spec validation passed for %s specs.\n' "${#required_specs[@]}"
