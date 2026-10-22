# Rules earned from mistakes

Format: `- [*] When <trigger>, <do/don't> — <why> (src; hits:N)`. Cap ~2 KB. New lessons arrive via `.scratch/<CARD>/lessons-proposed.md` after user approval (`self-learning`); hits ≥ 3 and mechanically checkable → a `core/checks/` script plus a `COVERAGE.md` row, then the line leaves this file. Repo-only rules live in `knowledge/<repo>.md` under `## Rules earned`.

- [*] When reviewing or editing, **Confirm the target branch and worktree** first and pin a named remote branch as the review subject — discovery does not authorize switching branches; local changes are reported separately (src: ai-main 2026-08-01, Meta Business AI review 2026-09; hits:2)
- [*] When the user reports an unintended change, pause it, audit the session diff and restore only your own deviation within the approved scope; ask if ownership is unclear — other sessions share the worktree (src: ai-main 2026-08-24; hits:1)
- [*] When asked "did release X cause it?", diff the deployed tags, not `git log --since` — authored dates do not establish release contents (src: ai-main 2026-09-01; hits:1)
- [*] When the user asks a question ("แก้ X ได้ไหม", "can we"), answer and wait for an explicit go ("แก้เลย", "do it") before touching files — a question is not authorization (src: oho-web-app FB reply-permission fix, reverted; hits:1)
- [*] When a cause, environment or rollout mechanism is named, stay inside it: don't fix other causes, touch other envs (UAT vs prod) or add unrequested feature flags; report them instead — out-of-scope work was discarded (src: webhook incident 2026-07, staging-1 debug 2026-09, Meta Business AI RC gate 2026-09, UAT endpoints 2026-09; hits:4)

- [*] When reporting session work time, count the wall-clock union of active intervals (parallel subagents/waits once) and make the itemised breakdown sum to the booked number (src: OHO-8778 2026-10-21; hits:1)
- [*] When estimating a card in the clickup-card flow, estimate **AI-executor** effort (agent time + mock/fix loops + one review round), not human writing time — human-scoped estimates blow the 8h/day budget and the card dates (src: OHO-8672 2026-10-22; hits:1)

General preservation, authorization, migration, and validation rules are maintained in `config/workflow.md`, not repeated here.
