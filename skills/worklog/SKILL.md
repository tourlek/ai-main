---
name: worklog
description: Append a one-line work log entry to the central log in ai-main. Use when the user says /worklog, "log งาน", "จดงาน", asks what was done recently, or when a substantial work session ends and the work is worth recording.
---

# Worklog

## Overview

Central work log shared by every AI tool, at `~/ai-main/logs/<YYYY-MM>.md` (one file per month). Synced across machines via the ai-main repo. Entries let any tool — and the user — see what happened recently without re-reading transcripts.

## Writing an entry

1. Determine the current month file: `~/ai-main/logs/$(date +%Y-%m).md`. Create it with a `# Worklog YYYY-MM` heading if missing.
2. Append ONE line per completed piece of work:

```markdown
- YYYY-MM-DD HH:MM [repo] tool: what was done (MR/issue link if any)
```

Examples:

```markdown
- 2026-07-04 14:30 [oho-web-app] claude: fixed Smartchat unread badge race in filtered list refetch (MR !482)
- 2026-07-04 16:10 [oho-api] codex: added contact_links index migration, not deployed yet
```

3. Keep it one line — outcome, not narration. Unfinished work states what remains (`not deployed yet`, `blocked on review`).
4. Do not commit — `scripts/sync.sh` auto-commits `logs/` on its schedule.

## Reading back

When the user asks "ทำอะไรไปบ้าง" / "what did I work on", read the current (and previous, if early in the month) log file and answer from it before digging into git history or transcripts.
