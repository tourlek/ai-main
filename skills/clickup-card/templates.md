# breakdown.md

```
# <CARD> <title>
Source: <clickup url>   Type: feature | issue
## Subtasks (assignee: me only)
### 1. <title>
What: <2-4 lines, readable without opening the code>
Start: YYYY-MM-DD  Due: YYYY-MM-DD  Estimate: Nh
Evidence: <runbook / doc / past card | ยังไม่ verify>
## Investigation (issues only)
- <finding> [VERIFIED | hypothesis] — <evidence>
Time spent: Nh
## Solutions (issues only)
- <option> — <trade-off>
```

# brief.md

```
# <CARD> brief
Repo: <name> (one brief per repo)   Base: origin/master   MR target: develop
Allowed files: <paths>
Out of scope: <list>
Acceptance: <items, A1..An>
Test: <cmd with full node/jest paths, Node 20; run once and passing/known baseline>
Lint: <cmd>
Rules: stay inside allowed files; no commit/push/revert/amend; do not proceed past the plan without approval.
Ponytail: smallest complete change. Reuse code already in the repo (helpers, DS components) before writing new; no unrequested abstractions or new dependencies; never cut validation, error handling, security or accessibility; list what you skipped under Not done.
Final step (always, even if blocked): write .scratch/<CARD>/done.md in the done.md format (acceptance -> file:line, grep proof), with `STATUS:` as its last line. Write it once, at the very end; nothing after it.
Plan: <numbered items for user approval>
```

# done.md

```
Changed: <files + one line each>
Acceptance map: A1 -> path:line, A2 -> path:line ...
Grep proof: <pattern> -> 0 hits of the old behavior
Tests: <cmd + result>
Lint: <cmd + result>
Not done: <list>
STATUS: complete | blocked: <reason> | plan-ready
```

# review.md

```
MR: <repo> !<iid>   Verdict: ready | not ready   Blocks commit: yes | no
Head SHA: <glab sha> == <git rev-parse HEAD of worktree>   (re-check after every push; note if worktree is on another branch)
CI: <status | unknown>   (unknown = not ready)
Reviewer: <model>   (rules: ~/ai-main/config/review.md)
Findings:
- [Important|Nit|Pre-existing] path:line — <problem> — <fix>   (lesson: repeat <rule> | new)
Contract (multi-repo): <field> producer path:line -> validator path:line -> consumer path:line (name, nesting, types)
Deploy order (multi-repo): <order> — source: <code | MR Rollout section>; unknown = say unknown
Checklist: scope / description vs code / SHA match / Node 20 tests / lint / secrets
```

# lessons-proposed.md

```
# <CARD> lessons proposed (approve at eod; never auto-written)
- repeat: <RULES.md / Rules earned line> — <finding path:line> -> hits:N+1
- new: - [*] When <trigger>, <do/don't> — <why> (src: <CARD> / !MR, YYYY-MM-DD; hits:1)   target: RULES.md | knowledge/<repo>.md
```
