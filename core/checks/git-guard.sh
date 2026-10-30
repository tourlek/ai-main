#!/usr/bin/env bash
# CLI front end for the one ai-main guard (core/hooks/guard.sh).
#
#   git-guard.sh "<the full shell command>"
#     exit 0  → allowed
#     exit 2  → denied, reason on stderr
#
# The rules live in core/hooks/guard.sh (Claude PreToolUse in T3 / claude-team). This wrapper
# feeds it a Bash payload with no transcript, so commit/push/glab mr always need
# authorization here. Escape hatches: AIMAIN_BYPASS=1 (skip everything),
# AIMAIN_ALLOW_COMMIT=1 (skip the commit-authorization rule only).

set -uo pipefail
cmd="${1:-}"
[ -n "$cmd" ] || exit 0
[ "${AIMAIN_BYPASS:-0}" = "1" ] && exit 0

GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/guard.sh"
payload="$(jq -nc --arg c "$cmd" --arg d "$PWD" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d,hook_event_name:"PreToolUse"}')"
out="$(GUARD_ALLOW_COMMIT="${AIMAIN_ALLOW_COMMIT:-0}" bash "$GUARD" <<<"$payload")"
reason="$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out" 2>/dev/null)"
[ -z "$reason" ] && exit 0
printf '✗ blocked: %s\n' "$reason" >&2
exit 2
