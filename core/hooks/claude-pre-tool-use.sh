#!/usr/bin/env bash
# Claude Code PreToolUse hook — routes Bash commands through core/checks/git-guard.sh.
#
# This is the only tool in the current fleet with a real interception point, so it gets the
# strongest enforcement. Every other tool is covered by the git hooks and the PATH shim,
# which catch the same mistakes slightly later (at commit/push time instead of before).
#
# Claude Code feeds the hook a JSON object on stdin and reads a JSON decision on stdout.

set -uo pipefail

AI_MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GUARD="${AI_MAIN}/core/checks/git-guard.sh"

payload="$(cat || true)"
command -v jq >/dev/null 2>&1 || exit 0
[ -x "$GUARD" ] || exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

if reason="$("$GUARD" "$cmd" 2>&1)"; then
    exit 0
fi

# Default to audit: a false positive here stops real work mid-task, so the hook reports and
# gets out of the way until the rules have been lived with. Flip to enforcement with
# AIMAIN_ENFORCE=block (export it in ~/.zshrc).
if [ "${AIMAIN_ENFORCE:-audit}" != "block" ]; then
    printf 'ai-main guard (audit, not blocking): %s\n' "$reason" >&2
    exit 0
fi

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
