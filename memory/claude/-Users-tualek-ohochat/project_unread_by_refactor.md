---
name: project-unread-by-refactor
description: "oho-api unread feature incident (2026-07-08) and the read_by → unread_by refactor state, flag off pending canary relaunch"
metadata: 
  node_type: memory
  type: project
  originSessionId: 01acfddb-9c1c-4ad1-973b-02998bc0e1e8
---

Unread feature incident 2026-07-08: enabling `rt_unread_feature_enabled` melted prod Mongo —
badge count used `read_by: {$nin: [null, id]}` (negation on array = no index, fetch all contacts
per business per poll, no maxTimeMS; requests up to 173s). Flag turned off same night.

Refactor (2026-07-09, code complete, not yet committed/deployed): field inverted to `unread_by`
(members who have NOT read; equality query, index-friendly). Full plan in `oho-api/plan.md`,
incident analysis in `oho-api/incident-unread-count-slowdown-2026-07-08.md`.

Key decisions:
- unread definition: per-member — someone else reading does not mark it read for you
- `unread_by` set to channel-eligible members (channel_permission only, NOT sale visibility —
  read path `addVisibilityFilter` covers that) on customer message; `$pull` self on read/reply
- missing/empty `unread_by` = not unread → no migration needed; `read_by` had no real data
- indexes on Atlas named `idx_contact_unread_filter_v3` / `idx_chat_session_unread_filter_v3`
  (v3 suffix, `_filter_` not `_by_` — model names must match or autoIndex conflicts)
- UAT explain verified: docsExamined 0, count from index keys only
- T4 done in code (2026-07-09): firebase-remote-config.js caches the template and evaluates
  per call with { APP_ENV, BUSINESS_ID }; isUnreadFeatureEnabled(businessId) threaded into all
  6 call sites (stream.js resolves business via findById on contact/chat-session first).
- Flags SPLIT (2026-07-09, user requirement): `rt_unread_feature_enabled` and
  `rt_unresponded_feature_enabled` are two independent flags — every write path checks only
  the flag(s) relevant to the field(s) it touches (unread_by vs is_unresponded), gated
  independently. Badge counts, query converter, and all 6 message/case-close write sites
  updated. Off = zero writes/reads for that field, matching pre-feature behavior exactly.
  stream.js caches channel_id→business_id (no TTL, immutable) to avoid a lookup per
  message.read event.
  Remaining before flag relaunch: BUSINESS_ID custom-signal condition for BOTH flags in
  Firebase console, Atlas Search storedSource update to `unread_by`, prod indexes, canary
  per business, `rm` the 4 dead migration/backfill service dirs (see plan.md footer)

**Why:** multi-session refactor spanning code + Atlas + Firebase; next session needs the state
without re-deriving.
**How to apply:** when oho-api unread/badge/chat-search perf comes up, read plan.md and the
incident file first; never reintroduce $nin on read_by/unread_by.

**Bug found 2026-07-09 (post-deploy on test):** the "no migration needed, read_by had no real
data" assumption was wrong — prod `read_by` had real accumulated data (same day's null-crash
incident proved it). Deleted the old backfill scripts (`migrate-contact-read-by`,
`backfill-contact-unread-30d`, group variants) on that wrong assumption. Consequence: every
pre-existing chat's `unread_by` is absent → `addIsReadByMeToContactResults` and the badge
`countDocuments({unread_by: memberId})` both treat it as "read" → red-dot badge went to zero
across the whole install base on deploy, not just new messages. Not a double-fetch/pagination
bug.

**Real migration tool lives in `script-oho/unread-unresponded/migrate-unread.ts`** (not
oho-api's `src/services/scripts/` — those were only ever thin, heuristic versions). This is a
mature, checkpointed, gate-rollout production tool (dashboard HTML, per-business resume, budget
throttling) that had ALREADY been run on prod (gate=small, 3 businesses, 2026-07-08 14:33 UTC —
just 27 min before the flag flip at 15:00 UTC, and its Step 1 `read_by: null` marker write is
the actual source of the `read_by` null-type data that caused the `$addToSet` crash investigated
same day; several businesses' Stream backfill hadn't finished, leaving many contacts stuck at
`read_by: null` when the old ungated `$addToSet` code hit them).

Adapted this script to the new design (2026-07-09, confirmed with user):
- Dropped the old steps 1/2 (`read_by: null` marker) — `unread_by` has no untracked-marker
  state, absent already means "not unread".
- Steps 1/2 (renumbered from old 3/4) now write `unread_by` = channel-eligible members (via a
  new `getEligibleMembers`, same channel_permission logic as oho-api's `getEligibleMemberIds`)
  minus whoever Stream's real read-receipts (`channel.state.read`) say has read since
  `last_contact_date` — accurate ground truth, not a heuristic.
  Steps 3/4/5 (is_unresponded, renumbered from old 5/6/7) unchanged.
- Checkpoint/status/dashboard file prefix changed to `migrate-unread-by-*` (was
  `migrate-unread-*`) so this run's checkpoint can't collide with / be skipped by the old
  read_by-era gate=small run already on disk — those 3 businesses were NOT actually migrated
  under the new unread_by design and must be reprocessed.
  `.gitignore` updated to match the new prefix too.
- `isDryRun` reset to `true` (script had been left `false`/live from the last run) — recommend a
  dry run before going live again given the semantic rewrite.
- `TARGET_BUSINESS_IDS` cleared back to `[]` so the confirmed gate rollout (small→medium→large
  via `BUSINESS_IDS_FILE` + `GATE_FILTER`) is what actually runs next, not the leftover explicit
  3-business test list.
- `npx tsc --noEmit` passes clean on both `migrate-unread.ts` and `monitor-migrate-unread.ts`.

Not yet done: actually running the dry run / live run (user executes, not me — script-oho has no
explicit no-bash rule but this writes prod data, same caution applies). `reports/`,
`analyze-business-size-*.json`, `export-sales-order/`, `loadtest/`,
`migrate-line-webhook-endpoint/` were already dirty/untracked in script-oho before this session
touched anything — not mine, left alone.
