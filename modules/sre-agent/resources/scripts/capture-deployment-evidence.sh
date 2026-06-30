#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="$MODULE_DIR/resources/runbooks/generated"
APP_URL="${1:-${APP_URL:-}}"
ENVIRONMENT_NAME="${AZURE_ENVIRONMENT_NAME:-prod-sim}"
RUN_URL="${GITHUB_RUN_URL:-}"
COMMIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || true)}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_FILE="$OUTPUT_DIR/${TIMESTAMP}-deployment-evidence.md"

mkdir -p "$OUTPUT_DIR"

health_status="not_checked"
checkout_status="not_checked"

if [[ -n "$APP_URL" ]]; then
  health_status="$(curl -sS -o /tmp/sre-health.json -w '%{http_code}' "$APP_URL/healthz" || true)"
  checkout_status="$(curl -sS -o /tmp/sre-checkout.json -w '%{http_code}' "$APP_URL/api/checkout" || true)"
fi

cat > "$OUTPUT_FILE" <<EOF
# Deployment Evidence

- Generated: $TIMESTAMP
- Environment: $ENVIRONMENT_NAME
- Commit SHA: ${COMMIT_SHA:-unknown}
- GitHub Actions run: ${RUN_URL:-not provided}
- Endpoint: ${APP_URL:-not provided}
- Health check status: $health_status
- Checkout status: $checkout_status

## Gate Outcomes

- Sample app tests: <pass/fail/link>
- Workflow approval or environment protection: <not used/approved/link>
- Azure deployment status: <success/failure/link>
- Known warnings: <none or list>

## Notes For Challenge 06

Record anything an incident responder would need later: deployment time, changed files, run logs, environment variables that are safe to disclose, and whether the app was deployed healthy or with a controlled incident mode.
EOF

printf 'Deployment evidence written to %s\n' "$OUTPUT_FILE"
