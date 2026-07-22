thread_id: 019f8442-2665-7082-a710-f24709dca055
updated_at: 2026-07-21T10:51:30+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/oho-1171-add-metadata-of-message-send-to-streamchat

# Third-pass read-only review of `migrate-unread` ended in a decided plan: backfill `unread_by` only, do not backfill `is_unresponded`, and use existing contact index plus one minimal group index with explain-based preflight.

Rollout context: The user asked for a third and final review pass on the MongoDB migration, explicitly read-only, with all factual claims verified against source and every open risk converted into a single decided mitigation. They required the working source of truth to be `oho-api@master` via `git show`/`git grep`, not the checked-out stale tree, and the deliverable had to answer five specific questions with citations.

## Task 1: Decide whether `is_unresponded` should be backfilled

Outcome: success

Preference signals:
- The user said “do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns” -> future similar reviews should converge to one choice and not leave the user with a concern list.
- The user repeatedly required “Verify every factual claim in the brief against source before relying on it” and “cite file:line for each load-bearing claim” -> future similar work should default to source-first line-cited proof, and should explicitly say “cannot verify from repo” when the proof is missing.
- The user asked for “If you must assume, name the assumption” -> future plan docs should separate evidence from assumptions rather than folding assumptions into conclusions.

Key steps:
- Verified the live API behavior on `oho-api@master` for customer messages, member replies, bot replies, spam, comments, partner sends, and group-session writes.
- Confirmed that customer-message hooks derive both timestamps from the same stream timestamp but use separate guarded writes, so equality is not a durable invariant.
- Confirmed that multiple non-answer actions also advance `last_active_at`, and that reply provenance is not preserved in a reconstructible way.
- Confirmed that `is_unresponded` is an absence-typed field, created only by live customer-message behavior when the feature is enabled, not something that can be recovered from Mongo state alone.

Failures and how to do differently:
- The brief’s proposed classifier depended on `assigned_at`/`last_status_at` style reasoning; the repo showed that this does not have enough event provenance and that at least one proposed field name does not match the schema. Future runs should reject timestamp heuristics unless the repo shows a true reply ledger.
- The brief’s claim that the migration is the only thing materializing user-visible state was too strong; clear paths remain unconditional when the field exists. Future runs should check both SET and CLEAR paths, not just the migration.

Reusable knowledge:
- Contact customer-message handling writes `last_active_at` and `last_contact_date` via separate guarded updates; the common timestamp does not prove durable equality.
- `chat_status` is not a reliable historical reply classifier because it conflates customer-message fallback and bot fallback cases.
- The inbox send path is a known asymmetry: it advances `last_active_at` but does not clear `is_unresponded`.
- The safest migration policy from the audited source is to leave historical `is_unresponded` absent rather than infer it.

References:
- `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:164-167, 230-237` — customer-message timestamping and guarded writes.
- `oho-api/src/services/chat-session/group/contact-user/send-message/send-message.class.js:19-36` — group customer-message timestamping and guarded writes.
- `oho-api/src/utils/update-contact-last-active-at.js:12-19` — `$lt`-guarded last-active write.
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:634-686` — member reply clears `is_unresponded` but writes no reply timestamp.
- `oho-api/src/services/bot-send-message/bot-send-message.hooks.js:540-576` — bot reply/fallback behavior.
- `oho-api/src/utils/build-customer-message-unread-payload.ts:24-38` — live customer-message path creates `is_unresponded:true` when enabled.
- `oho-api/src/models/contact.model.js:211-219` and `oho-api/src/models/chat-session.model.js:78-86` — absence contract for `is_unresponded`.

## Task 2: Decide classifier / Mongo filter shape if `is_unresponded` is not backfilled

Outcome: success

Preference signals:
- The user asked for “the final classifier rule, as a pure function and as a Mongo filter” but the audit concluded the honest answer was that the classifier should not exist -> future similar reviews should be willing to answer “not applicable” when the evidence says the feature should be omitted entirely.
- The user asked to “Attack the draft above” -> future similar work should actively reject unsafe heuristics, not just weaken them.

Key steps:
- Rejected the draft classifier as unsalvageable from source evidence.
- Converted the answer into a deletion/absence plan: remove the `is_unresponded` passes, related residual checks, report rows, and the opt-out switch rather than keep a hidden or no-op classifier.
- Noted that the current migration CLI still enables the unresponded passes unless the operator explicitly skips them, so merely relying on flags is weaker than deleting the path.

Failures and how to do differently:
- A timestamp-based heuristic can misclassify assignment/status/comment/spam actions as replies; future reviews should treat these as fundamentally different event classes unless the repo exposes an authoritative reply ledger.
- A tolerance around near-equal timestamps worsens ambiguity rather than fixing it.

Reusable knowledge:
- `first_chat_at` is useful for excluding “never messaged” contacts, but it does not prove whether later activity was a reply.
- `assigned_at` was called out as unsafe because the contact schema uses `assign_at`, not a top-level `assigned_at`; this field mismatch should be treated as a “cannot verify from repo” boundary, not as evidence.

References:
- `script-oho/unread-unresponded/helpers/migration-cli.ts:479-485` — `resolvePasses()` still includes unresponded passes unless skipped.
- `oho-api/src/models/contact.model.js:154-164, 185-188` — assignment fields/schema mismatch and missing timestamp provenance.

## Task 3: Decide index and paging strategy

Outcome: success

Preference signals:
- The user asked for “Adjudicate the index/paging disagreement” and “Give one answer” -> future similar decisions should pick a side and tie it to a concrete preflight rule, not leave both options on the table.
- The user explicitly constrained the rollout to read `oho-api` on `master` and warned the checked-out tree was stale -> future similar repo decisions should trust branch `master` evidence, not the working tree.

Key steps:
- Verified that `pagedFind()` currently does keyset pagination on `_id` but does not use `hint()` or `explain()`.
- Confirmed that contacts already have a `business_id + _id` index on `master`, while group sessions do not have the needed `_id`-ordered index for this migration path.
- Chose the smaller, more surgical plan: keep the existing contact index and add only one minimal group-session index, then enforce an explain-based preflight that rejects execution if the plan is a collection scan or blocking sort.
- Rejected the idea of building broad new contact compound indexes for this one-shot migration.

Failures and how to do differently:
- It is not enough to know a query is “probably fine”; this rollout only accepted the plan after tying it to a concrete index declaration and a fail-closed explain check.
- The current code’s residual-count logic can numerically cancel unrelated documents, so the migration’s “done” condition must be exact-ID based rather than aggregate-count based.

Reusable knowledge:
- Contact side: rely on the existing `idx_business_id_v1` pattern for tenant-scoped `_id` scans, then add `hint()`/`explain()` enforcement.
- Group side: add exactly one minimal index on the real `chat-sessions` collection with `_id` included for migration pagination.
- The migration should not be allowed to execute if explain reveals `COLLSCAN` or a blocking sort.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:177-190, 238-250` — keyset paging funnel.
- `oho-api/src/models/contact.model.js:621-624` — `idx_business_id_v1`.
- `oho-api/src/models/chat-session.model.js:109-137` — existing group indexes lack an `_id`-ordered migration-friendly index.

## Task 4: Produce an ordered production plan

Outcome: success

Preference signals:
- The user required “one ordered plan” including dependencies, parallelism, and explicit human decisions -> future similar plans should be sequenced, not freeform.
- The user’s rollout shape already agreed on per-tenant migration then immediate tenant flag-on -> future plans should preserve that operational sequencing unless the user changes it.

Key steps:
- Built the plan around an absence-only `is_unresponded` migration, not around classifier tuning.
- Grouped the work into: remove unresponded writes, harden unread guards, add exact checkpoint/retry handling, add explain/index preflight, prep ops artifacts, then do a tenant-by-tenant rollout.
- Kept the `read_by` cleanup as a later separate gated mode, not part of the core migration run.

Failures and how to do differently:
- The current migration’s checkpoint and residual logic is count-based in places where exact identity is safer; future plans should treat exact ID tracking as a prerequisite, not as an optional nice-to-have.
- The old status file showed cumulative totals that cannot be mapped cleanly back to individual tenants; future ops plans should treat old counters as advisory until exact IDs are reconciled.

Reusable knowledge:
- The current code already has a separate `cleanup-read-by` mode that is gated by checkpoint membership and dedicated confirmation.
- The CLI is fail-closed: `.env.<env>` selection, a matching `--confirm`, and explicit `--execute` are required.
- Production rollout should only proceed after explicit database authorization and explain/index verification.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:2084-2112, 2126-2134` — dedicated cleanup mode and checkpoint gating.
- `script-oho/unread-unresponded/helpers/migration-cli.ts:321-334, 401-412` — env-file and fail-closed CLI behavior.
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69` — old status file that could not cleanly attribute cumulative writes to the listed tenants.

## Task 5: Identify remaining incorrect or missing claims

Outcome: success

Preference signals:
- The user asked for “Anything in the above you believe is still wrong or missing” -> future similar reports should explicitly enumerate corrections and not just provide the main answer.
- The user demanded evidence-dense language and “cannot verify from repo” rather than guessing -> future similar reports should keep uncertainty visible.

Key steps:
- Flagged that some brief claims overreached the repo evidence, especially around exact historical reconstruction, assignment timestamps, and what the old status file proves.
- Captured the fact that the inbox send path is a known behavior hole for `is_unresponded` if that feature is enabled.
- Distinguished between verified repo facts, operational assumptions, and claims that could not be proven from the codebase alone.

Failures and how to do differently:
- Do not encode external operational facts, production state, or data retention assumptions as if they were repo facts.
- Do not treat cumulative counts as proof of per-tenant effect unless the artifact explicitly preserves per-tenant attribution.

Reusable knowledge:
- The inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that turns on the unresponded flag must either accept that known false-positive path or defer the feature until API behavior changes.
- The old status file proves a prior run happened, but not that the named three tenants each received the cumulative `s0a` total.

References:
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:143-159` — unresolved unresponded-clearing asymmetry.
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69` — cumulative totals vs per-business rows.

## Bottom line

The rollout concluded that `unread_by` is reconstructible from Stream, but historical `is_unresponded` is not. The correct production path is to leave `is_unresponded` absent, keep the migration fail-closed, enforce explain-based preflight, and roll out tenant by tenant with exact checkpoint/retry handling.

