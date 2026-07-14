# Lessons — mistakes every AI tool must not repeat

Loaded into every session of every tool. Append via the `self-learning` skill.
Format: one `##` entry per lesson — newest last. When this file exceeds ~50 lessons,
consolidate: merge duplicates, drop obsolete ones, keep the rule one line each.

## 2026-05 — Reverted user code to "clean up"
- **Mistake**: undid prior user work during a refactor; user: `Why you revert code ???`
- **Rule**: never revert or reset work you didn't create; only revert when asked.

## 2026-05 — Altered passing-QA behavior during Nuxt 3 migration
- **Mistake**: "improved" UI/logic while migrating; QA-passed behavior changed.
- **Rule**: migrations preserve behavior exactly; improvements need a separate ask.

## 2026-06 — Added Co-Authored-By to commits
- **Mistake**: appended AI attribution lines; user removed them repeatedly.
- **Rule**: no Co-Authored-By or AI-attribution lines in commit messages.

## 2026-06 — Used `--json` with glab
- **Mistake**: `glab ... --json` fails on this machine.
- **Rule**: use `glab ... -F json`.

## 2026-06 — Committed without being asked
- **Mistake**: auto-committed after finishing a change.
- **Rule**: commit only after explicit `commit it` / `create commit ให้เลย`. (Exception: `ai-main` auto-sync of `memory/` + `logs/` via sync.sh is authorized.)

## 2026-07 — Shipped negation query on array field (unread incident, prod slowdown)
- **Mistake**: unread feature counted with `read_by: {$nin: [null, id]}` — negation on a multikey field can't use any index, forcing a fetch of every contact in the business per poll; flag-on melted the prod Mongo cluster (8 Jul 2026).
- **Rule**: for hot-path queries on array fields, design for equality membership (store the inverse set, e.g. `unread_by`) — never `$ne`/`$nin`; verify with `explain()` that `docsExamined` scales with the answer, not the collection.

## 2026-07 — Unbounded countDocuments on a polled endpoint
- **Mistake**: badge-count `countDocuments` had no `maxTimeMS` and ran on every chat-list poll; slow counts (up to 173s) piled up and starved the cluster, and a count failure 500'd the whole list response.
- **Rule**: every query added to a polled/high-QPS path gets `maxTimeMS` + fail-soft (auxiliary data returns null, never fails the main response), sized against the biggest tenant, not the average.

## 2026-07 — Feature flag flipped for all tenants at once
- **Mistake**: `rt_unread_feature_enabled` was enabled globally at night with no per-business targeting; the flag check also cached one evaluated config for the whole process, so per-tenant conditions couldn't work anyway.
- **Rule**: DB-heavy features roll out behind per-tenant (business_id) targeting — canary a small tenant first and watch p95 + slow-query logs before widening.

## 2026-07 — One flag silently gated two independent features
- **Mistake**: `rt_unread_feature_enabled` gated both "unread" (read_by/unread_by) and "unresponded" (is_unresponded) writes/reads bundled together, and several write sites (customer message, member/bot reply, case close) weren't gated by the flag at all — they wrote unconditionally even when the feature was "off". User: `ปิด flag ก็ต้องไม่ทำงานเลย ... ต้องทำงานได้ปกติเหมือนเวอร์ชันก่อนหน้าที่ไม่มี feature นี้อยู่`.
- **Rule**: when a task names two sub-features together ("unread/unresponded"), give each its own independent flag/gate from the start, and grep every write path (not just the ones already touched) before declaring a flag-gating task done — "off must behave exactly like the feature never existed" includes writes, not just reads.

## 2026-07 — Deleted backfill scripts, blanking every existing unread badge
- **Mistake**: renamed `read_by`→`unread_by` (absent field = "not unread") and deleted the old `migrate-contact-read-by`/`backfill-contact-unread-30d`-style scripts, reasoning "no real data existed so no backfill needed" — but that assumption was already disproven the same day by a live incident showing `read_by` had real accumulated data in prod. Result: every pre-existing chat lost its unread state on deploy (badge silently went to zero for the whole install base) because nothing populated `unread_by` for history, only for messages arriving after deploy.
- **Rule**: renaming/inverting a field that gates user-visible state (badges, counters) always needs a backfill for existing documents, even when told "no real data" — verify that claim against production directly (e.g. `countDocuments` on the old field) before deleting the migration tooling that would have covered it; a field being absent is not the same as it being safe to leave unpopulated.

## 2026-07 — Reviewed the wrong branch worktree
- **Mistake**: reviewed `hotfix/v2.24.1/oho-unread-unresponded-flag-gate` when the intended scope was `feature/tk-sprint-2613/oho-1018-unrespone`; user: `focus review ที่ brach feature/tk-sprint-2613/oho-1018-unrespone รึป่าว`.
- **Rule**: before reviewing a multi-worktree repo, identify and confirm the target branch from the request and inspect only that branch's worktree.
