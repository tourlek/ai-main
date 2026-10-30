#!/bin/bash
# SessionStart(compact): re-announce clickup-card only if this session loaded the skill.
t=$(python3 -c 'import sys,json;print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null)
[ -n "$t" ] && [ -f "$t" ] || exit 0
# Anchor on the real load line (": /..."), so reading this file does not count as loading the skill.
grep -qE 'Base directory for this skill: /[^ "\\]*skills/clickup-card' "$t" || exit 0
echo "clickup-card workflow ACTIVE for this session (was active before compaction). Re-read ~/.claude/skills/clickup-card/SKILL.md, find the stage from .scratch/<CARD>/ and clickup_get_task, resume from there. Keep all Hard rules (preview + T3 Allow control for every ClickUp write, no commit/push without approval, the orchestrator never edits code; implement = one Sonnet claude-team thread in T3, review = the plan thread's reviewer subagent: Sonnet each round, one Opus pass before the MR)."
