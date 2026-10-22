#!/bin/bash
# SessionStart(compact): re-announce clickup-card only if this session loaded the skill.
t=$(python3 -c 'import sys,json;print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null)
[ -n "$t" ] && [ -f "$t" ] || exit 0
# Anchor on the real load line (": /..."), so reading this file does not count as loading the skill.
grep -qE 'Base directory for this skill: /[^ "\\]*skills/clickup-card' "$t" || exit 0
echo "clickup-card workflow ACTIVE for this session (was active before compaction). Re-read the clickup-card SKILL.md (ai-main/skills/clickup-card), find the stage from .scratch/<CARD>/ and clickup_get_task, resume from there. Keep all Hard rules (preview+confirm every ClickUp write, no commit/push without approval, the coordinator never edits code)."
