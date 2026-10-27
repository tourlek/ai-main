# Rules earned from mistakes

Format: `- [*] When <trigger>, <do/don't> — <why> (src; hits:N)`. Cap ~2 KB. New lessons arrive via `.scratch/<CARD>/lessons-proposed.md` after user approval (`self-learning`); hits ≥ 3 and mechanically checkable → a `core/checks/` script plus a `COVERAGE.md` row, then the line leaves this file. Repo-only rules live in `knowledge/<repo>.md` under `## Rules earned`.

- [*] When reviewing or editing, **Confirm the target branch and worktree** first and pin a named remote branch as the review subject — discovery does not authorize switching branches; local changes are reported separately (src: ai-main 2026-08-01, Meta Business AI review 2026-09; hits:2)
- [*] When the user reports an unintended change, pause it, audit the session diff and restore only your own deviation within the approved scope; ask if ownership is unclear — other sessions share the worktree (src: ai-main 2026-08-24; hits:1)
- [*] When asked "did release X cause it?", diff the deployed tags, not `git log --since` — authored dates do not establish release contents (src: ai-main 2026-09-01; hits:1)
- [*] When the user asks a question ("แก้ X ได้ไหม", "can we"), answer and wait for an explicit go ("แก้เลย", "do it") before touching files — a question is not authorization (src: oho-web-app FB reply-permission fix, reverted; hits:1)
- [*] When a cause, environment or rollout mechanism is named, stay inside it: don't fix other causes, touch other envs (UAT vs prod) or add unrequested feature flags; report them instead — out-of-scope work was discarded (src: webhook incident 2026-07, staging-1 debug 2026-09, Meta Business AI RC gate 2026-09, UAT endpoints 2026-09; hits:4)

- [*] When reporting session work time, count the wall-clock union of active intervals (parallel subagents/waits once) and make the itemised breakdown sum to the booked number; compute it with core/checks/session-hours.py, never from memory (src: OHO-8778 2026-10-21, OHO-8672 2026-10-22; hits:2)
- [*] When a reply mentions tracker cards or tasks, call them the user's ("card ของคุณ"); the assignee account is the user's even when you write through it — never "card ของผม" (src: ClickUp Sprint 21 scoping 2026-10-22; hits:1)
- [*] When estimating a card in the clickup-card flow, estimate **AI-executor** effort (agent time + mock/fix loops + one review round), not human writing time — human-scoped estimates blow the 8h/day budget and the card dates (src: OHO-8672 2026-10-22; hits:1)

- [*] When running `gcloud logging read`, always pass `--limit` and `--freshness` or a `timestamp>=…` window; never unbounded — use Cloud Monitoring for multi-day trends (src: pi retro 2026-10-26, ~2h lost, 4 timeouts, longest 43 min; hits:3)
- [*] When editing an MR description, read the current one first and change only the requested part; never overwrite it whole (src: pi retro 2026-10-26 01a17737; hits:1)
- [*] When unsure of CLI syntax or metric names (`atlas`, `gcloud monitoring`, …), run `--help` first instead of guessing (src: pi retro 2026-10-26, ~20 wasted calls; hits:2)
- [*] When a command may hang or run long on macOS (no GNU `timeout` by default), wrap it with `gtimeout <sec>` (coreutils, installed); prefer the tool's own limit flag when it has one (mongosh `maxTimeMS`/`socketTimeoutMS`, `curl --max-time`, gcloud `--limit`/`--freshness`); never drop the limit when a wrapper fails (src: pi retro 2026-10-26; hits:4)
- [*] When deploying to UAT, check that repo's `deploy.sh`/`.gitlab-ci.yml` for traffic routing first — it differs per repo (oho-web-app deploys `--no-traffic`; oho-webhook and oho-api switch 100% on deploy) (src: pi retro 2026-10-26; hits:3)
- [*] When work needs many tool calls, don't use `gemini-3.8-flash` — it stalls in tool loops (src: pi retro 2026-10-26 01a1766e, 01a17678; hits:2)
- [*] When waiting for CI, don't block the chat with `sleep` loops; run the wait in the background and check back (src: pi retro 2026-10-26, ~30 min blocked; hits:4)
- [*] When a brief allows deleting a doc section "if all about X", check each paragraph first and keep non-X operational notes — deleting the heading whole lost unrelated runbook notes (src: OHO-8915 r3 review 2026-10-27; hits:1)
- [*] When computing session tokens/cost/hours from `.jsonl` transcripts, filter each event by its own `timestamp` (never file `mtime`, which changes on `cost-state`/`pr-link` writes) and dedupe entry ids across forked pi sessions (src: gemini retro 2026-10-27, 169M cache-read miscounted; hits:1)
- [*] When moving a checkout from a background script to an interactive T3 thread, kill the script PID first and verify with `ps aux` — both alive collided at quota reset (src: react-p0 P02d 2026-10-27 23:06; hits:1)

General preservation, authorization, migration, and validation rules are maintained in `config/workflow.md`, not repeated here.
