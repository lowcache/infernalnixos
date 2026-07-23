#!/usr/bin/env bash
# phone-mcp-call.sh TOOL [ARGS_JSON]
# Env: PHONE_IP (Tailscale IP), PHONE_PORT (default 8462), PHONE_TOKEN_FILE
set -euo pipefail
TOOL="$1"; ARGS="${2:-{}}"
PORT="${PHONE_PORT:-8462}"
TOKEN="$(cat "${PHONE_TOKEN_FILE:?set PHONE_TOKEN_FILE}")"

curl -sf --max-time "${PHONE_TIMEOUT:-10}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"${TOOL}\",\"arguments\":${ARGS}}}" \
  "http://${PHONE_IP}:${PORT}/mcp"
