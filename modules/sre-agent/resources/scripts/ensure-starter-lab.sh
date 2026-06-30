#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
LAB_REPO_DIR="$REPO_ROOT/external/sre-agent"
LAB_DIR="$LAB_REPO_DIR/labs/starter-lab"

if [[ ! -d "$LAB_REPO_DIR/.git" ]]; then
  mkdir -p "$REPO_ROOT/external"
  git clone https://github.com/microsoft/sre-agent.git "$LAB_REPO_DIR"
fi

if [[ ! -d "$LAB_DIR" ]]; then
  printf 'Azure SRE Agent starter lab was not found at %s\n' "$LAB_DIR" >&2
  printf 'Check https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab for current lab location.\n' >&2
  exit 1
fi

printf '%s\n' "$LAB_DIR"
