#!/usr/bin/env bash
# Deterministic check of the plain-pi (~/.pi/agent) ai-main wiring without an LLM key: guard (block push, pass ls) + MCP call.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; PORT=${MOCK_PORT:-18765}; export MOCK_PORT=$PORT
export MOCK_LOG="${MOCK_LOG:-/tmp/pi-mock-llm.jsonl}"; : > "$MOCK_LOG"
python3 "$D/mock-llm.py" "$PORT" & MP=$!; trap 'kill $MP 2>/dev/null' EXIT; sleep 1
cd /tmp && env -u PI_CODING_AGENT_DIR "${PI_BIN:-$(command -v pi)}" -e "$D/selftest-provider.ts" --model guard-selftest/mock --no-session --mode json -p "selftest" > "${OUT:-/tmp/pi-selftest.jsonl}"
echo "pi exit=$?"; jq -c '{req:.request, tool:(.last_tool_result.content|tostring|.[0:240])}' "$MOCK_LOG"
