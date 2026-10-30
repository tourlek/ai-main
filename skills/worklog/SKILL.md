---
name: worklog
description: Use to record work on explicit request or enabled auto-log, or to read recent work.
---

# Worklog

## Overview

Central work log shared by every AI tool, at `~/ai-main/logs/<YYYY-MM>.md` (one file per month). Synced across machines via the ai-main repo. Entries let any tool — and the user — see what happened recently without re-reading transcripts.

## Writing an entry

1. Write only for an explicit log request or enabled auto-log; read-only/chat-only restrictions override auto-log. A request to create a task is not a worklog request. Determine the current month file: `~/ai-main/logs/$(date +%Y-%m).md`. Create it with a `# Worklog YYYY-MM` heading if missing.
2. Append ONE line per completed piece of work:

```markdown
- YYYY-MM-DD HH:MM [repo] tool: what was done (MR/issue link if any)
```

Examples:

```markdown
- 2026-07-04 14:30 [oho-web-app] claude: fixed Smartchat unread badge race in filtered list refetch (MR !482)
- 2026-07-04 16:10 [oho-api] claude-code: added contact_links index migration, not deployed yet
```

3. Keep it one line — outcome, not narration. Unfinished work states what remains (`not deployed yet`, `blocked on review`).
4. Logging does not authorize a commit or push. Scheduled `scripts/sync.sh` automation is separate from agent authorization; do not invoke it to bypass approval.

## Reading back

When the user asks "ทำอะไรไปบ้าง" / "what did I work on", read the current (and previous, if early in the month) log file and answer from it before digging into git history or transcripts.
