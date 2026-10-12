#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-checkout_error}"
PORT="${PORT:-3000}"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$MODULE_DIR/resources/sample-app"
OUTPUT_DIR="$MODULE_DIR/resources/runbooks/generated"

case "$MODE" in
  checkout_error|checkout_latency)
    ;;
  *)
    echo "Usage: modules/sre-agent/resources/scripts/simulate-checkout-incident.sh [checkout_error|checkout_latency]" >&2
    exit 2
    ;;
esac

mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$APP_DIR/package-lock.json" ]]; then
  echo "Installing sample app dependencies..."
  npm --prefix "$APP_DIR" install
fi

echo "Starting sample app with INCIDENT_MODE=$MODE on port $PORT"
INCIDENT_MODE="$MODE" PORT="$PORT" npm --prefix "$APP_DIR" start > "$OUTPUT_DIR/sample-app.log" 2>&1 &
APP_PID=$!

cleanup() {
  if kill -0 "$APP_PID" >/dev/null 2>&1; then
    kill "$APP_PID" >/dev/null 2>&1 || true
    wait "$APP_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for attempt in {1..20}; do
  if curl -sS "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 20 ]]; then
    echo "Sample app did not start. See $OUTPUT_DIR/sample-app.log" >&2
    exit 1
  fi
  sleep 0.25
done

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_ID="${TIMESTAMP}-${MODE}"
HEALTH_FILE="$OUTPUT_DIR/${EVIDENCE_ID}-health.json"
CHECKOUT_FILE="$OUTPUT_DIR/${EVIDENCE_ID}-checkout.json"
SUMMARY_FILE="$OUTPUT_DIR/${EVIDENCE_ID}-summary.md"

curl -sS -H "x-request-id: challenge-06-health" "http://127.0.0.1:$PORT/healthz" > "$HEALTH_FILE" || true
curl -sS -H "x-request-id: challenge-06-checkout" "http://127.0.0.1:$PORT/api/checkout" > "$CHECKOUT_FILE" || true

cat > "$SUMMARY_FILE" <<EOF
# Generated Incident Evidence

- Mode: $MODE
- Port: $PORT
- Generated: $TIMESTAMP
- Health response: $HEALTH_FILE
- Checkout response: $CHECKOUT_FILE
- Service log: $OUTPUT_DIR/sample-app.log

Use this evidence with modules/sre-agent/resources/runbooks/challenge-06-triage-template.md.
EOF

echo "Incident evidence written to $OUTPUT_DIR"
echo "$SUMMARY_FILE"
