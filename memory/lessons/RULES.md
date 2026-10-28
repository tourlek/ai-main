Full text: archive/rules/RULES-full-20261028.md
# Rules earned from mistakes
Format: hits≥3 + checkable → core/checks/ + COVERAGE.md, then drop. Repo: knowledge/<repo>.md
- [*] **Confirm the target branch and worktree**: Review: pin a named remote first; report local changes separately (hits:2)
- [*] **unintended change**: pause it and restore only your own deviation; ask if ownership is unclear (hits:1)
- [*] **did release X cause it?**: diff deployed tags, not git log --since (hits:1)
- [*] **question is not authorization**: wait for an explicit go ("แก้เลย", "do it") before touching files (hits:1)
- [*] **named cause**: stay inside the named cause, env, or rollout; report the rest (hits:4)
- [*] **session work time**: wall-clock union via core/checks/session-hours.py; breakdown sums to booked (hits:2)
- [*] **card ของคุณ**: call tracker cards the user's, never "card ของผม" (hits:1)
- [*] **AI-executor**: estimate agent time + mock/fix + one review, not human writing time (hits:1)
- [*] **gcloud logging read**: always pass --limit and --freshness or a timestamp window (hits:3)
- [*] **MR description**: read the current text first; change only the requested part (hits:1)
- [*] **CLI --help**: run --help before guessing syntax or metric names (hits:2)
- [*] **gtimeout**: wrap long macOS commands; never drop the tool's own limit (hits:4)
- [*] **UAT deploy**: check that repo's deploy.sh/.gitlab-ci.yml traffic routing first (hits:3)
- [*] **gemini-3.8-flash**: don't use it for many tool calls (hits:2)
- [*] **CI wait**: wait in the background; don't block chat with sleep loops (hits:4)
- [*] **doc section delete**: if told to delete a section only when all about X, keep non-X paragraphs (hits:1)
- [*] **jsonl timestamp**: filter events by timestamp, not file mtime; dedupe forked session ids (hits:1)
- [*] **background script handoff**: kill the script PID and check ps aux before interactive T3 use (hits:1)
preservation/authorization/migration/validation: config/workflow.md.

## React port — Smart Chat float (2026-10-28)
Smart Chat UI keeps legacy content, layout, and placement (handler indicator, จบแชท/รับแชท, etc.); only the visual style becomes float. No AI-slop: float tokens/CSS vars for spacing/padding/margin/radius; no invented chrome. UI batches need before/after vs legacy placement. Source: GOAL.md §4.0 + user.
