#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
MANIFEST="$REPO_ROOT/external-repos.json"
APP_KEY="grubify-starter-lab"

if command -v jq >/dev/null 2>&1; then
  SUBMODULE_PATH="$(jq -r ".dependencies[] | select(.key == \"$APP_KEY\") | .provisioning.submodule_path // empty" "$MANIFEST")"
  CONTENT_PATH="$(jq -r ".dependencies[] | select(.key == \"$APP_KEY\") | .provisioning.content_path // empty" "$MANIFEST")"
else
  mapfile -t FIELDS < <(node -e "
const manifest = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
const entry = manifest.dependencies.find(dep => dep.key === process.argv[2]);
const provisioning = (entry && entry.provisioning) || {};
console.log(provisioning.submodule_path || '');
console.log(provisioning.content_path || '');
" "$MANIFEST" "$APP_KEY")
  SUBMODULE_PATH="${FIELDS[0]:-}"
  CONTENT_PATH="${FIELDS[1]:-}"
fi

if [[ -z "$SUBMODULE_PATH" || -z "$CONTENT_PATH" ]]; then
  printf 'Could not read the lab location and content path for %s from %s\n' "$APP_KEY" "$MANIFEST" >&2
  exit 1
fi

bash "$REPO_ROOT/scripts/provision-app.sh" "$APP_KEY" >/dev/null

LAB_DIR="$REPO_ROOT/$SUBMODULE_PATH/$CONTENT_PATH"
if [[ ! -d "$LAB_DIR" ]]; then
  printf 'Azure SRE Agent starter lab was not found at %s\n' "$LAB_DIR" >&2
  exit 1
fi

printf '%s\n' "$LAB_DIR"
