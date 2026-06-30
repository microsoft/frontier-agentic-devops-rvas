#!/usr/bin/env bash
# provision-app.sh — lazy/on-demand provisioner for locally-run apps.
# Usage: bash scripts/provision-app.sh <app-key>
# Example: bash scripts/provision-app.sh juice-shop
#
# Reads the matching entry from external-repos.json (provisioning.method == "submodule"),
# inits the submodule at the pinned SHA, verifies the SHA matches the manifest, ensures
# symlinks exist, and prints next steps. Safe to re-run.

set -euo pipefail

BOLD="\033[1m"; CYAN="\033[36m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/external-repos.json"

# ── arg check ────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $0 <app-key>${RESET}" >&2
  echo -e "  Example: $0 juice-shop" >&2
  exit 1
fi

APP_KEY="$1"

echo -e "${BOLD}${CYAN}Provisioning local app: ${APP_KEY}${RESET}"

# ── read manifest (prefer jq; fall back to node) ─────────────────────────────
read_manifest_field() {
  local query="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r "${query}" "${MANIFEST}"
  else
    node -e "
      const m = JSON.parse(require('fs').readFileSync('${MANIFEST}','utf8'));
      const e = m.dependencies.find(d => d.key === '${APP_KEY}');
      if (!e) { console.error('key not found'); process.exit(1); }
      // minimal path evaluator for the queries we use
      const query = '${query}';
      const match = query.match(/\\.dependencies\\[\\]\\s*\\|\\s*select\\(.+\\)\\s*\\|\\s*(.+)\$/);
      if (match) {
        const path = match[1].replace(/^\\./, '').split('.');
        let val = e;
        for (const k of path) { val = val && val[k]; }
        console.log(val == null ? 'null' : val);
      } else {
        console.log('');
      }
    "
  fi
}

# ── look up the entry ─────────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  ENTRY_JSON=$(jq -r ".dependencies[] | select(.key == \"${APP_KEY}\")" "${MANIFEST}")
  if [[ -z "${ENTRY_JSON}" ]]; then
    echo -e "${RED}✗ No entry with key '${APP_KEY}' found in external-repos.json${RESET}" >&2
    exit 1
  fi
  PROV_METHOD=$(echo "${ENTRY_JSON}" | jq -r '.provisioning.method // empty')
  SUBMODULE_PATH=$(echo "${ENTRY_JSON}" | jq -r '.provisioning.submodule_path // empty')
  CONTENT_PATH=$(echo "${ENTRY_JSON}" | jq -r '.provisioning.content_path // empty')
  MANIFEST_SHA=$(echo "${ENTRY_JSON}" | jq -r '.source.sha // empty')
  MANIFEST_TAG=$(echo "${ENTRY_JSON}" | jq -r '.source.tag // empty')
  SYMLINKS_JSON=$(echo "${ENTRY_JSON}" | jq -r '.provisioning.symlinks // [] | .[]')
else
  # node fallback
  node -e "
const m = JSON.parse(require('fs').readFileSync('${MANIFEST}','utf8'));
const e = m.dependencies.find(d => d.key === '${APP_KEY}');
if (!e) { process.stderr.write('no entry\\n'); process.exit(1); }
const p = e.provisioning || {};
console.log([
  p.method||'',
  p.submodule_path||'',
  (e.source||{}).sha||'',
  (e.source||{}).tag||'',
  p.content_path||'',
  (p.symlinks||[]).join('\n')
].join('\n'));
" > "${REPO_ROOT}/.provision-tmp-out" 2>&1 || {
    echo -e "${RED}✗ Failed to read manifest entry '${APP_KEY}'${RESET}" >&2
    cat "${REPO_ROOT}/.provision-tmp-out" >&2
    rm -f "${REPO_ROOT}/.provision-tmp-out"
    exit 1
  }
  mapfile -t _FIELDS < "${REPO_ROOT}/.provision-tmp-out"
  rm -f "${REPO_ROOT}/.provision-tmp-out"
  PROV_METHOD="${_FIELDS[0]:-}"
  SUBMODULE_PATH="${_FIELDS[1]:-}"
  MANIFEST_SHA="${_FIELDS[2]:-}"
  MANIFEST_TAG="${_FIELDS[3]:-}"
  CONTENT_PATH="${_FIELDS[4]:-}"
  if ((${#_FIELDS[@]} > 5)); then
    SYMLINKS_JSON="$(printf '%s\n' "${_FIELDS[@]:5}")"
  else
    SYMLINKS_JSON=""
  fi
fi

# ── validate provisioning method ─────────────────────────────────────────────
if [[ "${PROV_METHOD}" != "submodule" ]]; then
  echo -e "${RED}✗ '${APP_KEY}' provisioning.method is '${PROV_METHOD}', not 'submodule'. Only submodule-backed apps are supported by this script.${RESET}" >&2
  exit 1
fi
if [[ -z "${SUBMODULE_PATH}" || -z "${MANIFEST_SHA}" ]]; then
  echo -e "${RED}✗ Manifest entry for '${APP_KEY}' is missing provisioning.submodule_path or source.sha${RESET}" >&2
  exit 1
fi

echo -e "  Submodule path : ${SUBMODULE_PATH}"
echo -e "  Pinned SHA     : ${MANIFEST_SHA}"
[[ -n "${MANIFEST_TAG}" ]] && echo -e "  Tag (human ref): ${MANIFEST_TAG}"
[[ -n "${CONTENT_PATH}" ]] && echo -e "  Content path   : ${SUBMODULE_PATH}/${CONTENT_PATH}"

# ── step 1: init submodule ────────────────────────────────────────────────────
echo
echo -e "${BOLD}[1/3] Initialising submodule…${RESET}"
ABS_SUB="${REPO_ROOT}/${SUBMODULE_PATH}"

if [[ -f "${ABS_SUB}/.git" || -d "${ABS_SUB}/.git" ]]; then
  echo -e "  ${GREEN}✓ Submodule already initialised — skipping fetch${RESET}"
else
  git -C "${REPO_ROOT}" submodule update --init --depth 1 -- "${SUBMODULE_PATH}"
  echo -e "  ${GREEN}✓ Submodule fetched${RESET}"
fi

# ── step 2: verify pinned SHA ─────────────────────────────────────────────────
echo -e "${BOLD}[2/3] Verifying pinned SHA…${RESET}"
ACTUAL_SHA=$(git -C "${ABS_SUB}" rev-parse HEAD 2>/dev/null || echo "")
if [[ -z "${ACTUAL_SHA}" ]]; then
  echo -e "${RED}✗ Could not read HEAD SHA from ${SUBMODULE_PATH}${RESET}" >&2
  exit 1
fi
if [[ "${ACTUAL_SHA}" != "${MANIFEST_SHA}" ]]; then
  echo -e "${RED}╔══════════════════════════════════════════════════════════╗${RESET}" >&2
  echo -e "${RED}║  SHA DRIFT DETECTED — submodule and manifest disagree!  ║${RESET}" >&2
  echo -e "${RED}╚══════════════════════════════════════════════════════════╝${RESET}" >&2
  echo -e "${RED}  Checked-out SHA : ${ACTUAL_SHA}${RESET}" >&2
  echo -e "${RED}  Manifest SHA    : ${MANIFEST_SHA}${RESET}" >&2
  echo -e "${RED}  Fix: update the gitlink pointer OR update external-repos.json,${RESET}" >&2
  echo -e "${RED}  then run: npm run verify:repos${RESET}" >&2
  exit 1
fi
echo -e "  ${GREEN}✓ SHA verified: ${ACTUAL_SHA}${RESET}"

# ── step 3: prepare stable paths ─────────────────────────────────────────────
echo -e "${BOLD}[3/3] Preparing stable paths…${RESET}"
# SYMLINKS_JSON is newline-separated (both jq and node fallback emit one entry per line)
SYMLINK_BLOCKED=0
while IFS= read -r SYMLINK_TARGET || [[ -n "${SYMLINK_TARGET}" ]]; do
  [[ -z "${SYMLINK_TARGET}" ]] && continue
  LINK_PATH="${REPO_ROOT}/${SYMLINK_TARGET}"
  if [[ -L "${LINK_PATH}" ]]; then
    echo -e "  ${GREEN}✓ ${SYMLINK_TARGET} → ${SUBMODULE_PATH} (already present)${RESET}"
  elif [[ -e "${LINK_PATH}" ]]; then
    echo -e "  ${YELLOW}! ${SYMLINK_TARGET} exists as a real path (not a symlink) — cannot create symlink${RESET}" >&2
    SYMLINK_BLOCKED=1
  else
    ln -s "${SUBMODULE_PATH}" "${LINK_PATH}"
    echo -e "  ${GREEN}✓ Created symlink: ${SYMLINK_TARGET} → ${SUBMODULE_PATH}${RESET}"
  fi
done <<< "${SYMLINKS_JSON}"

if [[ -n "${CONTENT_PATH}" ]]; then
  CONTENT_DIR="${ABS_SUB}/${CONTENT_PATH}"
  if [[ ! -d "${CONTENT_DIR}" ]]; then
    echo -e "${RED}✗ Expected content path not found: ${SUBMODULE_PATH}/${CONTENT_PATH}${RESET}" >&2
    exit 1
  fi
  echo -e "  ${GREEN}✓ Content path available: ${SUBMODULE_PATH}/${CONTENT_PATH}${RESET}"
elif [[ -z "${SYMLINKS_JSON}" ]]; then
  echo -e "  ${GREEN}✓ No additional paths required${RESET}"
fi

if [[ "${SYMLINK_BLOCKED}" -eq 1 ]]; then
  echo >&2
  echo -e "${RED}✗ Provisioning incomplete: one or more symlink paths are blocked by real directories/files.${RESET}" >&2
  echo -e "${RED}  Remove or rename the conflicting paths listed above, then re-run:${RESET}" >&2
  echo -e "${RED}    npm run setup:${APP_KEY}${RESET}" >&2
  exit 1
fi

# ── done ─────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${GREEN}✓ ${APP_KEY} is ready.${RESET}"
echo
echo -e "${BOLD}Next steps:${RESET}"
if [[ -n "${CONTENT_PATH}" ]]; then
  echo -e "  cd ${SUBMODULE_PATH}/${CONTENT_PATH}"
else
  echo -e "  cd app && npm install && npm start"
  echo -e "  Open ${CYAN}http://localhost:3000${RESET} in your browser (or the Codespaces Ports tab)."
fi
echo
