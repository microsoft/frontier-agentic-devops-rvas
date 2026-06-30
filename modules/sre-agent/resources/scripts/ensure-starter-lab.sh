#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
MANIFEST="$REPO_ROOT/external-repos.json"
APP_KEY="grubify-starter-lab"
SUBMODULE_PATH="external/sre-agent"
LAB_REPO_DIR="$REPO_ROOT/$SUBMODULE_PATH"
LAB_DIR="$LAB_REPO_DIR/labs/starter-lab"

if command -v jq >/dev/null 2>&1; then
  MANIFEST_SHA="$(jq -r ".dependencies[] | select(.key == \"$APP_KEY\") | .source.sha // empty" "$MANIFEST")"
else
  MANIFEST_SHA="$(node -e "
const manifest = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
const entry = manifest.dependencies.find(dep => dep.key === process.argv[2]);
process.stdout.write((entry && entry.source && entry.source.sha) || '');
" "$MANIFEST" "$APP_KEY")"
fi

if [[ -z "$MANIFEST_SHA" ]]; then
  printf 'Could not read pinned SHA for %s from %s\n' "$APP_KEY" "$MANIFEST" >&2
  exit 1
fi

git -C "$REPO_ROOT" submodule update --init --depth 1 -- "$SUBMODULE_PATH" >&2

ACTUAL_SHA="$(git -C "$LAB_REPO_DIR" rev-parse HEAD 2>/dev/null || true)"
if [[ "$ACTUAL_SHA" != "$MANIFEST_SHA" ]]; then
  printf 'Azure SRE Agent submodule SHA drift detected.\n' >&2
  printf '  Checked-out SHA: %s\n' "${ACTUAL_SHA:-<unreadable>}" >&2
  printf '  Manifest SHA:    %s\n' "$MANIFEST_SHA" >&2
  printf 'Run npm run verify:repos for details.\n' >&2
  exit 1
fi

if [[ ! -d "$LAB_DIR" ]]; then
  printf 'Azure SRE Agent starter lab was not found at %s\n' "$LAB_DIR" >&2
  printf 'Check the pinned microsoft/sre-agent commit and update external-repos.json if the lab moved.\n' >&2
  exit 1
fi

printf '%s\n' "$LAB_DIR"
