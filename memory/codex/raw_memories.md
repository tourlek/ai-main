# Raw Memories

Merged stage-1 raw memories (stable ascending thread-id order):

## Thread `019f0366-4780-7b21-a9b4-c309436efcc5`
updated_at: 2026-06-26T10:19:09+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl
rollout_summary_file: 2026-06-26T10-07-42-z14x-oho_api_unread_unresponded_code_review.md

---
description: Thai code review of `oho-api` unread/unresponded + bulk-send changes; review found blocker-level query-composition regressions and a stale/failing spec, so the diff was not okay to merge yet.
task: review oho-api modified diff
task_group: /Users/tualek/ohochat/oho-api
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-api
keywords: oho-api, code review, unread, unresponded, search-query-converter, addVisibilityFilter, bulk send, Jest, type-check, Mongo query composition
---

### Task 1: Review `oho-api` unread/unresponded and bulk-send changes

task: review modified diff in `oho-api` for correctness/security/performance/testing
task_group: code review / backend API
task_outcome: fail

Preference signals:
- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged.
- when the user asked for review only, not implementation -> default to review-first and findings-first; do not jump into fixing code unless asked.

Reusable knowledge:
- `convertUnreadUnrespondedQuery.ts` now has a special both-flags path that returns `$or` / `$and` instead of the older top-level AND-style injection.
- `chat-search.hooks.js` and `chat-session/group/search/search.hooks.js` now omit `$or` from `countBaseQuery`, which is part of compensating for the new filter shape.
- `search-query-converter.ts` preserves only `read_by`, `is_unresponded`, and `read_by.0` as typed filters; any future query-shape change that introduces `$or` / `$and` needs matching converter updates.
- `bulk.class.js` now writes `is_unresponded: false` and optionally `$addToSet` on `read_by` directly via `contactModel.updateOne(...)` instead of the previous shared helper.

Failures and how to do differently:
- The both-flags OR branch failed the focused spec, so the implementation and the current test contract were not aligned.
- The new `$or` shape is vulnerable to later query composition: the search parser can corrupt typed values if `$or` leaks into its coercion path, and `addVisibilityFilter()` can overwrite the unread/unresponded filter by rebuilding `context.params.query` with its own `$or`.
- `npm run type-check` was not useful as a signal for this diff because the repo already had unrelated TypeScript errors elsewhere.

References:
- `rtk proxy npx jest src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts --runInBand --forceExit --detectOpenHandles` → failed at `convert-unread-unresponded-query.spec.ts:106` because `context.params.query.read_by` was `undefined` in the both-flags case.
- `src/services/contact/helper-hook/convert-unread-unresponded-query.ts:43-57` → new both-flags branch injects `$or`/`$and` and deletes the raw params.
- `src/services/contact/chat-search/chat-search.hooks.js:33-36, 84-107, 151-158, 181-188` → typed-filter split only preserves `read_by`, `is_unresponded`, and `read_by.0`, and countBaseQuery now omits `$or`.
- `src/services/chat-session/utils/search-query-converter.ts:9-10, 145-168` → same typed-filter list in the group-chat converter.
- `src/services/contact/chat-search/shared-hooks.js:124-150` → parser coercion still runs `+currentValue` first, so non-string typed structures need careful exclusion.
- `src/services/contact/chat-search/shared-hooks.js:314-413, 690-694` → `addVisibilityFilter()` rebuilds `context.params.query` with its own `$or`, which can drop unread/unresponded conditions.
- `src/services/member-send-message/bulk/bulk.class.js:169-176, 255, 393, 526` → bulk send now updates contact state directly via `contactModel.updateOne(...)`.

## Thread `019f516d-893b-7923-a4b3-96517d54a6c0`
updated_at: 2026-07-11T14:32:17+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl
rollout_summary_file: 2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md

---
description: Thai code review of `oho-api` unread/unresponded changes in worktree `mr-1285-fixes`; review-only task with blocker findings around query composition, stale-state rollout, and cache/broadcast behavior
task: oho-api unread/unresponded code review in mr-1285-fixes
task_group: /Users/tualek/ohochat/oho-api
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-api
keywords: oho-api, code review, unread, unresponded, convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, cacheService, Redis, Jest, Mongo query composition
---

### Task 1: Review `oho-api` unread/unresponded and bulk-send changes

task: code review of unread/unresponded and bulk-send changes in oho-api worktree `mr-1285-fixes`
task_group: /Users/tualek/ohochat/oho-api
track: review-only
_task_outcome: fail

Preference signals:
- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม`, the user wanted a direct Thai code review rather than implementation help -> future similar review responses should default to findings-first and judgmental wording.
- when the user only asked whether the changes were okay, not for implementation help -> future agents should not jump into fixes unless asked.

Reusable knowledge:
- `convertUnreadUnrespondedQuery.ts` now has a special both-flags path that injects `unread_by` + `is_unresponded` directly and deletes the raw params.
- Search/count logic for unread/unresponded now depends on `countBaseQuery`, `TYPED_FILTER_FIELDS`, and later visibility rewrites, so a review has to trace the full query lifecycle, not just the helper.
- `bulk.class.js` now updates `is_unresponded: false` via direct `contactModel.updateOne(...)` and also updates `read_by` / unread state directly in the bulk-send path.
- Focused Jest on `convert-unread-unresponded-query.spec.ts` is a useful early signal; if the both-flags case fails, it is a blocker before examining downstream hooks.
- `git diff --check` passed even though the review found logic issues; formatting sanity does not imply semantic correctness.

Failures and how to do differently:
- The new unread/unresponded filter shape can be corrupted when `search` is present because typed-filter handling only preserves specific fields, not the new query shape.
- `addVisibilityFilter()` rebuilds `context.params.query` with its own `$or`, which can overwrite unread/unresponded composition on sale-visibility paths.
- `npm run type-check` was not useful as a pass/fail gate in this repo because unrelated TypeScript errors already exist outside the touched diff.
- The review surfaced blocker-level query-composition regressions; future reviews in this area should explicitly walk the hook chain and not stop at the first helper.

References:
- `src/services/contact/helper-hook/convert-unread-unresponded-query.ts:41-49` — both-flags branch.
- `src/services/contact/chat-search/chat-search.hooks.js:89-118, 159-177` — typed filters and badge-count base query.
- `src/services/contact/chat-search/shared-hooks.js:314-413, 690-694` — visibility rewrite that can overwrite earlier query composition.
- `src/services/member-send-message/bulk/bulk.class.js:179-214` — bulk-send contact-state update and `is_unresponded` clear.
- `src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts:97-126` — both-flags test area.

### Task 2: Verification of rollout and remaining blockers

task: focused validation of the unread/unresponded rollout and its new shared helpers/cache paths
task_group: /Users/tualek/ohochat/oho-api
task_outcome: partial

Preference signals:
- the review remained review-only; user did not ask for code changes, so later work should stay on verification and findings.
- the rollout’s conversational flow was in Thai, so concise Thai findings were appropriate for direct reporting back to the user.

Reusable knowledge:
- `src/models/contact.model.spec.ts` and `src/models/chat-session.model.spec.ts` verify that `unread_by` and `is_unresponded` are absent on bare documents when flags are off.
- `src/utils/compute-badge-counts.ts` now uses `Promise.allSettled`, so unread and unresponded badge counts fail independently instead of both collapsing to null.
- `src/utils/channel-eligible-members.ts` returns `null` on lookup failure or >2000 eligible members so callers skip writing `unread_by` instead of wiping state with `[]`.
- `src/utils/cache/index.js` adds a 3s Redis command timeout wrapper; this changes all cacheService callers, not just unread-related paths.
- `src/webhook/stream.js` now caches channel-business resolution in Redis with a 7-day positive TTL and a 60s negative TTL.

Failures and how to do differently:
- Mongo-backed integration tests could not run because there was no `MONGODB_URI`; without a DB, there is still no `explain()` evidence for the index/query-shape question.
- `src/services/bot-send-message/bot-send-message.hooks.spec.js` still has 6 unrelated quick-reply failures, so it should not be used as a blanket success signal for the rollout.
- The customer-message and reply write paths still merit race analysis; targeted unit tests pass, but live interleaving behavior was not fully proven in this rollout.

References:
- Focused Jest result on the selected suites: `12 passed, 2 skipped, 128 passed`.
- Mongo-backed tests failed with `Could not find MongoDB URI. Set NODE_ENV to use config file or set MONGODB_URI env var.` plus follow-up `deleteMany` errors.
- `src/services/bot-send-message/bot-send-message.hooks.spec.js` output shows 6 failing quick-reply cases, while the new atomic `updateContactProfile` tests passed.
- `src/utils/cache/index.js:5-13, 21-38, 49-77, 104-121` — Redis command timeout wrapper implementation.
- `src/services/contact-send-message/contact-send-message.hooks.js:226-241` and `src/services/chat-session/group/contact-user/send-message/send-message.class.js:29-42` — shared customer-message unread payload path.

## Thread `019f51c4-bc6d-7223-a93d-e4ee27e97fe7`
updated_at: 2026-07-11T15:24:30+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T22-21-15-019f51c4-bc6d-7223-a93d-e4ee27e97fe7.jsonl
rollout_summary_file: 2026-07-11T15-21-15-jDcH-unread_unresponded_db_performance_root_cause.md

---
description: Diagnosed unread/unresponded performance in oho-api; root cause was unread count query shape and missing timeout, not write-side stamping.
task: performance investigation of unread/unresponded slowdown
task_group: oho-api performance debugging
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: unread, unresponded, unread_by, is_unresponded, countDocuments, $nin, maxTimeMS, MongoDB, chat-search, message.read, performance regression
---

### Task 1: Diagnose unread/unresponded slowdown

task: investigate whether unread/unresponded slowdown comes from count queries or write-side stamping
task_group: oho-api performance debugging
task_outcome: success

Preference signals:
- when the user asked "ลองดูให้หน่อยว่า Feature unread/unrespone มีจุดไหนหรอที่ทำให้ Performance ของ databse slow" -> they want a root-cause performance analysis, not a blind fix.
- when the user narrowed it to "ตอน count unread unresponded หรอ ตอนที่ ส่ง message แล้วต้อง stamp is_unresponded กับ เอา id ออกจาก unread_by หรอ" -> future similar investigations should explicitly compare read/query cost versus write/stamp cost.

Reusable knowledge:
- The incident note says the bad path was unread `countDocuments` using `read_by: { $nin: [null, memberId] }`; that shape on a multikey array forced fetch-heavy counts across essentially the whole business and could dominate cluster CPU/connection usage.
- Current code has already moved unread counting to equality on `unread_by`, added `maxTimeMS(timeout || 30000)` and fail-soft `null` handling, which is the mitigation pattern to preserve.
- `message.read` handling in `src/webhook/stream.js` resolves the channel’s business before checking the per-business feature flag, then `$pull`s the member id from `unread_by` on contact/chat-session.
- Write-side updates (`contact-send-message`, `member-send-message`) are point updates by `_id`; they can add write load, but they were not the primary cause of the incident described in the rollout.

Failures and how to do differently:
- The old unread query shape (`$nin` on an array field) is the failure mode to watch for; future performance investigations should treat that as a red flag immediately.
- If a similar incident recurs, verify `docsExamined`/`keysExamined` on the count path before spending time on write-path stamping.

References:
- `incident-unread-count-slowdown-2026-07-08.md:27-79` — incident writeup and root cause explanation.
- `src/services/contact/chat-search/chat-search.class.js:129-167` — unread/unresponded badge count implementation with timeout/fail-soft.
- `src/services/contact-send-message/contact-send-message.hooks.js:230-255` — customer message sets `unread_by`.
- `src/services/member-send-message/member-send-message.hooks.js:648-663` — member reply clears `unread_by` and `is_unresponded`.
- `src/webhook/stream.js:520-574` — Stream read event clears `unread_by` for contact/chat-session.
- `src/models/contact.model.js` — unread/unresponded index definitions aligned to the new equality-based shape.

## Thread `019f5ec7-6f0f-7e72-a7b6-720887ff0ac8`
updated_at: 2026-07-14T04:02:56+00:00
cwd: /Users/tualek/ohochat/script-oho
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl
rollout_summary_file: 2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md

---
description: Read-only correctness review of `unread-unresponded/migrate-unread.ts`; confirmed cleanup can trust checkpoint membership without Stream-verified legacy reconciliation, cleanup lacks the 90-day cutoff used by backfill/reconcile, and the new `buildTotals()` helper is wired into both status save paths.
task: review /Users/tualek/ohochat/script-oho/unread-unresponded/migrate-unread.ts for checkpoint/cleanup safety and totals refactor sanity
task_group: /Users/tualek/ohochat/script-oho / unread-unresponded correctness review
task_outcome: success
cwd: /Users/tualek/ohochat/script-oho
keywords: migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, STATUS_FILE, INCLUDE_PARTIAL, readByCutoffDate, runLegacyReadByReconcilePass, resolveBusinessIds, partial, MAX_DOCS_PER_BIZ, buildTotals, saveCheckpoint, saveStatus, checkpoint, resume, crash-safety
---

### Task 1: checkpoint semantics vs cleanup-read-by

task: read-only correctness review of checkpoint gating and cleanup-read-by eligibility in migrate-unread.ts
task_group: correctness review / checkpoint safety
task_outcome: success

Preference signals:
- When the user says "Trace the actual filter/gating logic, not the comments" and requires line citations, use code-grounded analysis only; comments are not sufficient as evidence.
- When the user asks for CONFIRMED / REFUTED / PARTIALLY-CONFIRMED per item, keep the report tightly structured and map each conclusion to exact lines.

Reusable knowledge:
- `INCLUDE_PARTIAL` is opt-in (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`) and legacy reconcile only runs inside that branch.
- `result.partial` is budget exhaustion only (`budget !== null && budget <= 0`); checkpointing uses `!isDryRun && !result.partial` and does not verify that legacy Stream reconciliation ran.
- Cleanup mode trusts checkpoint membership directly via `loadCheckpoint()` and `backfillCompleted.has(id.toString())`; there is no persisted proof that a business was Stream-verified end-to-end.
- `runLegacyReadByReconcilePass()` can skip unresolved channels (`skippedNoChannel`) and still return normally; that return value is not used to block checkpointing.

Failures and how to do differently:
- Do not infer safety from doc comments that say a business is "verified" or "safe to drop"; verify whether the code persists any proof and whether cleanup consumes that proof.
- If a future run needs to prove cleanup safety, inspect whether unresolved Stream channels and omitted opt-in passes are tracked anywhere durable; in this file they are not.

References:
- `migrate-unread.ts:132-135`
- `migrate-unread.ts:1335-1391`
- `migrate-unread.ts:1398`
- `migrate-unread.ts:2153-2159`
- `migrate-unread.ts:1454-1458`
- `migrate-unread.ts:1792-1798`
- `migrate-unread.ts:890-896`, `migrate-unread.ts:965`

### Task 2: cutoff mismatch in cleanup vs backfill/reconcile

task: read-only correctness review of last_active_at cutoff handling in migrate-unread.ts cleanup and backfill paths
task_group: correctness review / filter parity
task_outcome: success

Preference signals:
- When the user asks whether one pass uses the "same DAYS/readByCutoffDate bound" as another, compare the exact query objects across all relevant passes rather than assuming symmetry from comments or function names.
- The user explicitly asked to check for other invariants like business resolution, budget, and partial handling; future reviews should examine those surrounding guards, not just the obvious filter.

Reusable knowledge:
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when the cutoff exists.
- Cleanup does not apply any `last_active_at` cutoff; it only filters by business, complete channel IDs, and `HAS_LEGACY_READ_BY`.
- `resolveBusinessIds()` only narrows the business/channel universe; it does not enforce doc freshness or backfill coverage.
- `MAX_DOCS_PER_BIZ` is `null`, so partial/budget limiting is not a protective invariant here.

Failures and how to do differently:
- If cleanup is intended to remove only docs that were Stream-verified under the same window, the file currently does not enforce that. Checkpoint membership alone is too coarse.
- The comment saying legacy reconcile scans the full `HAS_LEGACY_READ_BY` population does not match the actual cutoff-bearing query; do not rely on that comment for behavior.

References:
- `migrate-unread.ts:127-128`
- `migrate-unread.ts:1920-1921`
- `migrate-unread.ts:1219-1225`
- `migrate-unread.ts:855-858`
- `migrate-unread.ts:1820-1830`
- `migrate-unread.ts:1853-1863`
- `migrate-unread.ts:1714-1729`
- `migrate-unread.ts:137`

### Task 3: checkpoint/status crash safety and totals refactor

task: read-only correctness review of checkpoint/status file interactions and totals consolidation in migrate-unread.ts
task_group: correctness review / crash safety and refactor sanity
task_outcome: success

Preference signals:
- When the user asks whether `CHECKPOINT_SUFFIX` can cause cross-contamination between explicit-target/gate runs, verify the actual suffix logic and whether the same file namespace is reused across modes/configs.
- When the user asks for a totals-builder sanity check, confirm there are no remaining manual object literals instead of assuming the refactor was applied everywhere.

Reusable knowledge:
- Cleanup mode reads checkpoint state only and does not write checkpoint/status files, so it cannot overwrite backfill state by itself.
- `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but does not encode all semantics such as cutoff or stream/partial choices.
- `saveCheckpoint()` writes directly to the checkpoint file, unlike `saveStatus()` which uses a temp-file rename; a crash during checkpoint write could corrupt the file and make `loadCheckpoint()` fall back to an empty set.
- The new `buildTotals()` helper is used by both `saveStatus()` call sites, and no third manual totals literal remained.

Failures and how to do differently:
- If future work depends on durable checkpoint correctness, consider the asymmetry between atomic status writes and non-atomic checkpoint writes.
- If config-specific resume safety matters, the checkpoint key may need to encode more than just gate/target identity.

References:
- `migrate-unread.ts:204-210`
- `migrate-unread.ts:1751-1760`
- `migrate-unread.ts:1792-1798`
- `migrate-unread.ts:1454-1458`
- `migrate-unread.ts:1665-1667`
- `migrate-unread.ts:1985-2009`
- `migrate-unread.ts:2028-2040`, `migrate-unread.ts:2162-2173`
- `migrate-unread.ts:2075-2081`
- `migrate-unread.ts:2153-2159`
- `migrate-unread.ts:2317-2326`

## Thread `019f5efc-691c-7000-8729-9eceb1cc207d`
updated_at: 2026-07-14T06:43:07+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T11-57-08-019f5efc-691c-7000-8729-9eceb1cc207d.jsonl
rollout_summary_file: 2026-07-14T04-57-08-S8ep-script_oho_unread_migration_read_by_cleanup_mode.md

---
description: User asked how to delete legacy `read_by` after running unread migration; script-oho already has a dedicated cleanup mode gated by checkpoint + two flags.
task: explain how to remove legacy read_by after migration
task_group: /Users/tualek/ohochat/script-oho
task_outcome: success
cwd: /Users/tualek/ohochat/script-oho
keywords: script-oho, migrate-unread.ts, cleanup-read-by, read_by, unread_by, checkpoint, MongoDB, $unset, migration
---

### Task 1: Remove legacy read_by after unread migration

task: explain how to remove legacy read_by after migration
task_group: script-oho unread-unresponded migration
task_outcome: success

Preference signals:
- when the user asked `ขอสรุปสั้นๆ` and then `ถ้างั้นถ้า run migration script ที่ script-oho แล้ว จะลบ read_byยังไง` -> they want short, direct operational instructions once the workflow is understood, not a long conceptual recap.
- when the user asked whether removing `read_by` would close the blockers -> they care about the exact safety boundary between backfill and cleanup, so future answers should explicitly separate `migrate unread_by` from `unset read_by`.

Reusable knowledge:
- `script-oho/unread-unresponded/migrate-unread.ts` already has a separate `--mode=cleanup-read-by` path; it is not auto-chained after backfill.
- Cleanup writes only when both `--execute` and `--confirm-cleanup-read-by` are present.
- Cleanup is gated by the current env/gate checkpoint: only businesses already marked complete in that checkpoint are eligible.
- The cleanup mode unsets `read_by` on both `contacts` and `chat-sessions`.
- The script comments say `read_by` is the rollback path until `unread_by` has been spot-checked.

Failures and how to do differently:
- Do not assume `read_by` can be dropped immediately after enabling `unread_by`; the script intentionally keeps a separate cleanup step for rollback safety.
- Treat the cleanup script as mutable/uncommitted until rechecked in the current tree.

References:
- `package.json: "migrate:unread:cleanup-read-by": "node -r @swc-node/register unread-unresponded/migrate-unread.ts --mode=cleanup-read-by"`
- `unread-unresponded/migrate-unread.ts` comments around `--mode=cleanup-read-by`
- Guard text: `--execute alone is not enough — pass --confirm-cleanup-read-by too.`
- Cleanup update: `{ $unset: { read_by: "" } }`
- Collections touched: `contacts`, `chat-sessions`

## Thread `019f5f90-99ef-79c1-9da8-c8468ab76236`
updated_at: 2026-07-14T07:43:25+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T14-38-59-019f5f90-99ef-79c1-9da8-c8468ab76236.jsonl
rollout_summary_file: 2026-07-14T07-38-59-v0i2-oho_backoffice_external_message_ui_review.md

---
description: Read-only UI/UX review of external-message whitelist and app-catalog screens; key durable takeaway is that Element UI remote filterable selects intentionally hide the dropdown arrow, and this repo had no CSS override suppressing it. Also captured data-safety issues in the mock two-table model (cascade delete, app_id rename orphan risk).
task: read-only ui/ux design review of external-message whitelist/admin screens with line-cited findings
task_group: oho-backoffice vue2/nuxt2 admin ui review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: vue2, nuxt2, element-ui, el-select, remote filterable, dropdown arrow, cascade delete, whitelist, app catalog, mock API, line-cited review
---

### Task 1: Read-only UI/UX review of external-message whitelist/app catalog screens

task: read-only ui/ux design review of external-message whitelist/admin screens with line-cited findings
task_group: oho-backoffice vue2/nuxt2 admin ui review
task_outcome: success

Preference signals:
- when the user said "Do NOT edit any files -- this is review only" -> future similar tasks should default to strictly read-only inspection and avoid edits.
- when the user said "Every finding must cite a concrete file path and line number" -> future similar reviews should gather exact line evidence first and avoid uncited judgments.
- when the user specified the output shape/order (root-cause first, then High/Medium/Low) -> preserve severity ordering and actionable fix language in future review output.
- when the user asked to grep the wider repo for other `filterable remote` usages -> check wider repo usage before claiming a pattern or divergence.

Reusable knowledge:
- Element UI `el-select` with `remote && filterable` intentionally omits the default arrow; the missing dropdown indicator is component behavior, not a repo CSS override, when no local CSS rule targets the suffix.
- In the checked worktree, no CSS override was found that suppresses the caret; the only related global rule was an unrelated dropdown-item hover tweak.
- The mock backend models two tables: `external_message_apps` and `business_external_app_whitelist`; deleting an app cascades into all whitelist rows.
- Changing `app_id` in the catalog does not propagate to existing whitelist entries, so whitelists can become orphaned if `app_id` is mutable.

Failures and how to do differently:
- Do not overclaim a repo-wide convention when grep finds only a single `remote filterable` select; explicitly note when no comparable instance exists.
- For framework-behavior questions, inspect the component source directly rather than inferring from screenshots or broad CSS searches.

References:
- `pages/external-message-whitelist.vue:14-34` — `el-select` with `filterable remote clearable` and no explicit icon.
- `pages/external-message-whitelist.vue:37-55` — main checklist/save layout.
- `pages/external-message-whitelist.vue:91-115` — remote business search and error handling.
- `pages/external-message-apps.vue:55-85` — create/edit dialog.
- `pages/external-message-apps.vue:162-183` — delete confirmation and cascade warning.
- `components/ExternalMessage/WhitelistAppChecklist.vue:12-14` — empty state.
- `api/mockExternalMessageApps.js:127-147` — delete cascade logic.
- `api/mockExternalMessageApps.js:97-125` — app_id edit logic that can orphan existing whitelist data.
- `node_modules/element-ui/packages/select/src/select.vue:196-198` — `iconClass()` returns `''` for `remote && filterable`.

## Thread `019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df`
updated_at: 2026-07-14T08:33:02+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T15-22-37-019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df.jsonl
rollout_summary_file: 2026-07-14T08-22-37-rN8j-oho_web_app_unread_unresponded_realtime_badge_review.md

---
description: Read-only review of frontend badge-counter increment diff against oho-websocket backend commit 9141805; main takeaway is that the patch is not merge-safe because sender-role/producer assumptions are unverified and the unread path still risks missing or double-adjusting counters.
task: review uncommitted realtime badge counter diff in oho-web-app against oho-websocket@9141805
task_group: code-review / oho-web-app + oho-websocket
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-web-app
keywords: code-review, smartchat, groupchat, unread_count, unresponded_count, is_read_by_me, is_unresponded, Vuex, realtime, websocket, oho-websocket@9141805, stale-event-guard, optimistic decrement, Vue 2 reactivity
---

### Task 1: Review frontend increment/decrement badge logic for realtime unread/unresponded updates

task: review uncommitted diff in `store/modules/smartchat.js` and `store/modules/groupchat.js` against backend commit `oho-websocket@9141805`
task_group: code-review / frontend-realtime-badge
task_outcome: fail

Preference signals:
- user explicitly required a **review-only** pass: "Do not fix anything, do not edit any files. Only report findings." -> future similar tasks should stay read-only unless the user asks for implementation.
- user required grounded evidence: "Ground every claim in the actual diff content and the actual oho-websocket commit 9141805 content that you read yourself. Quote or reference specific line/field names. Do not speculate ... If something can't be verified ... say so explicitly." -> future similar reviews should cite exact file/line/field evidence and avoid assumptions.
- user required a fixed response shape: findings grouped by severity and a one-line merge verdict -> preserve that structure on similar review asks.

Reusable knowledge:
- `oho-websocket@9141805` (`src/handlers/stream-webhook.handler.js`) emits `is_read_by_me:false` and `is_unresponded:true` on customer message events when the stale-event guard passes; `src/webhook/stream.js` handles `message.read` by `$pull`ing `unread_by` and does **not** emit `is_read_by_me:true`.
- `store/modules/groupchat.js` already declares `unread_count` and `unresponded_count` in initial state, so its direct assignment counter mutations have existing reactive slots.
- `store/modules/smartchat.js` `contact_list` initial/reset shapes do **not** include `unread_count` / `unresponded_count`; creating those properties during a reset/load window can be a Vue 2 reactivity gap.
- `components/Smartchat/Conversation.vue` optimistic unresponded handling already sets `room.is_unresponded = false` before decrementing, which prevents a duplicate decrement on the later realtime transition.
- `components/Smartchat/RoomList.vue` treats missing/legacy `is_read_by_me` as read in the list fallback, which is the rationale behind the asymmetry in the diff (`is_unresponded === true` vs `is_read_by_me !== false`) for known rows.

Failures and how to do differently:
- The reviewed diff is not merge-safe as-is. The review found a blocker that the backend commit does not show any sender-role guard in the `message.new` emission path, so the frontend cannot safely assume all such payloads are customer messages.
- The unread counter flow remains broken because the optimistic `markRoomRead()` path updates the counter but does not synchronize `room.is_read_by_me`, so the new realtime transition logic can still miss or double-handle unread state changes depending on which producer fires.
- The new increment path can still drift when the room is not already loaded in the list/current room, because it treats absent prior state as already-correct rather than proving whether the aggregate had previously been decremented.

References:
- [1] Frontend diff: `store/modules/smartchat.js` adds `incrementUnreadCount`, `incrementUnrespondedCount`, and a new `is_read_by_me` transition block; `store/modules/groupchat.js` adds `incrementGroupchatUnrespondedCount` and a symmetric `is_unresponded` transition branch.
- [2] Backend commit `9141805`: `src/handlers/stream-webhook.handler.js:289-299` stale-event guard compares `oho_created_at` to `last_contact_date`; `:337-365` emits `is_read_by_me:false` and `is_unresponded:true`; `:407-422` emits only `is_unresponded:true` for group.
- [3] `src/webhook/stream.js:142-160` on `message.read` only resolves the business and `$pull`s `unread_by`; it does not emit a `true` read flag.
- [4] `components/Smartchat/Conversation.vue:1649-1680` decrements unread on mark-read; `:1975-1979` sets `room.is_unresponded = false` before decrementing.
- [5] `components/Smartchat/RoomList.vue:170-176` fallback treats null/undefined `is_read_by_me` as read.

## Thread `019f603f-0763-7a32-9125-816c9dd5f2b5`
updated_at: 2026-07-14T11:40:37+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T17-49-31-019f603f-0763-7a32-9125-816c9dd5f2b5.jsonl
rollout_summary_file: 2026-07-14T10-49-31-cVgx-thai_unread_unresponded_flag_off_review_mr_1285_fixes.md

---
description: Thai review of unread/unresponded flag-off behavior in oho-api; found contract regressions, incomplete emitter wiring, and a zero-work/visibility mismatch across send paths
subtask: code_review, flag_contract, worktree_verification
outcome: fail
cwd: /Users/tualek/ohochat/oho-api
keywords: unread, unresponded, flag-off, code review, Thai, worktree, mr-1285-fixes, emitChatSessionStatusUpdatedEvent, emitContactUnrespondedStatusUpdatedEvent, buildClearUnreadUnrespondedPayload, convertUnreadUnrespondedQuery, chat-search, remote-config, jest, channel-eligible-members
---

### Task 1: Review unread/unresponded flag-gated changes in `mr-1285-fixes`

task: Thai code review of unread/unresponded flag-off behavior in `oho-api` worktree `mr-1285-fixes`
task_group: oho-api / code review
task_outcome: fail

Preference signals:
- when the user asked `review เกี่ยวกับ unread&unresponded ให้หน่อยว่าถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม` -> default to Thai, findings-first, contract-focused review that explicitly checks zero-behavior / zero-side-effect when the flag is off.
- when the user’s requirement was that the feature must not work with the flag off and other features must remain usable -> future reviews should verify both functional correctness and collateral impact on unrelated flows, not just presence/absence of the feature.
- when multiple worktrees exist, the assistant had to correct the review target to the actual diff in `.claude/worktrees/mr-1285-fixes` -> future similar reviews should verify branch/worktree before judging the diff.

Reusable knowledge:
- `buildClearUnreadUnrespondedPayload` is intentionally unconditional for the clear-write side and is used by many runtime paths; it exists to avoid stuck `is_unresponded` / unread state when flags toggle off and back on.
- `convertUnreadUnrespondedQuery` + its spec are the early gate for unread/unresponded query semantics; they are the right first place to validate query shape before tracing hooks.
- `emit-chat-session-event.spec.ts` now covers both group-session and contact-unresponded broadcasts, including flag-off behavior and eligibility-scoped fan-out.
- Focused Jest on the new helper/spec areas is the most useful validation signal for this change family; broad repo tests were less useful because unrelated quick-reply failures still existed elsewhere.

Failures and how to do differently:
- The new contact unresponded emitter was only wired into some send paths (`member-send-message`, `bot-send-message`) while `contact-send-message` still used the older emitter, so realtime `is_unresponded` updates were not handled uniformly across all transitions.
- Some flag-off paths still performed DB reads and Remote Config evaluation before deciding whether to emit, which adds latency/work even when the feature is off.
- The new emitter audience was based on channel eligibility only, while chat search visibility has stricter sale-owner/assignee/team rules; that can leak contact metadata to members who can open the channel but should not see the contact.
- The earlier wrong-worktree review should be ignored; always re-check worktree/branch before making assertions in a multi-worktree repo.

References:
- [1] Correct worktree: `/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes`.
- [2] User wording: `ถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม`.
- [3] Passing focused tests: `src/services/chat-session/hooks/emit-chat-session-event.spec.ts` passed 20/20; `src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts` and `src/utils/build-clear-unread-unresponded-payload.spec.ts` passed 24/24.
- [4] Emitter wiring handles: `src/services/contact-send-message/contact-send-message.hooks.js:582`, `src/services/member-send-message/member-send-message.hooks.js:1338`, `src/services/bot-send-message/bot-send-message.hooks.js:929`, `src/services/chat-session/hooks/emit-chat-session-event.js:362`.

## Thread `019f6135-9fb1-7b72-b968-52241fd501a2`
updated_at: 2026-07-14T15:35:19+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T22-18-52-019f6135-9fb1-7b72-b968-52241fd501a2.jsonl
rollout_summary_file: 2026-07-14T15-18-52-8PEC-mr1285_cross_repo_unread_unresponded_review.md

---
description: Cross-repo code review of MR !1285 unread/unresponded feature; backend write gating mostly correct, but websocket `message.read` clear is incorrectly flag-gated and missing ordering guard, while frontend/client Remote Config and optimistic badge tracking can drift.
task: review MR !1285 unread/unresponded feature across oho-api, oho-websocket, oho-web-app
task_group: code-review / unread-unresponded
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes
keywords: mr-1285, unread_by, is_unresponded, emitEligibilityScopedUnrespondedUpdate, message.read, Remote Config, optimistic-flag-count-tracker, groupchat, socket.io, code review
---

### Task 1: Backend review in oho-api

task: review MR !1285 unread/unresponded backend changes in oho-api
task_group: code-review / backend
task_outcome: partial

Preference signals:
- user said read `plan.md` and consolidated review docs first, and “do not re-flag findings already documented as fixed there” -> rebase on prior review history and avoid duplicate findings
- user asked for “structured findings report, ranked by severity” and exact `file:line` citations -> keep review output line-precise and severity-ranked
- user said “do not modify any files” -> keep the task read-only

Reusable knowledge:
- `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for `unread_by` and `is_unresponded:true`
- `buildClearUnreadUnrespondedPayload()` intentionally builds unconditional CLEAR payloads; that is the intended fix for flag-toggle stuck-state bugs
- `emitEligibilityScopedUnrespondedUpdate()` is the actual gate for the four newly fixed contact clear broadcasts; notify/inform/broadcast/bulk all reach it

Failures and how to do differently:
- sale-visibility audience for contact status broadcasts is broader/narrower than channel-eligible broadcasting; that mismatch is an audience bug, not a flag-gate bug
- bulk-send still needs success-aware handling because it can clear state even when platform delivery fails

References:
- `src/services/contact-send-message/contact-send-message.hooks.js:227-259`
- `src/services/chat-session/group/contact-user/send-message/send-message.class.js:40-50`
- `src/services/member-send-message/member-send-message.hooks.js:690-728`
- `src/services/member-send-message/bulk/bulk.class.js:218-285`
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-372`

### Task 2: websocket review in oho-websocket

task: review Stream websocket unread/unresponded behavior and flag gating in oho-websocket
task_group: code-review / websocket
task_outcome: fail

Preference signals:
- user wanted a review that covers all 3 repos and separates general findings from flag-gate audit findings -> keep repo boundaries and audit tables explicit
- user’s design rule said websocket broadcasts of these fields must be flag-gated, not the writes -> check websocket broadcasts separately from backend write behavior

Reusable knowledge:
- `src/webhook/stream.js` has a `message.read` branch that directly `$pull`s from `unread_by`; this is the websocket-side CLEAR site that should be scrutinized for unconditional behavior
- Stream webhook customer-message broadcasts are split into single-chat and group-chat paths; group broadcasts use the broader `businessChannel(businessId, 'member')` audience

Failures and how to do differently:
- `message.read` is incorrectly flag-gated and lacks the timestamp ordering guard used by backend, so delayed reads can clear newer unread state
- group customer-message broadcasts overreach within a business by sending to the whole business member room instead of a channel-eligibility-scoped audience

References:
- `src/webhook/stream.js:149-160`
- `src/handlers/stream-webhook.handler.js:361-449`
- `src/webhook/stream.spec.js:93-108`

### Task 3: frontend review in oho-web-app

task: review client-side unread/unresponded state handling, Remote Config, and socket badge updates in oho-web-app
task_group: code-review / frontend

task_outcome: partial

Preference signals:
- user wanted a careful senior review before rollout, not implementation suggestions -> remain judgmental and rollout-oriented
- user asked for a complete flag/write/broadcast inventory -> validate how UI state mutates from sockets and optimistic logic, not just API calls

Reusable knowledge:
- `store/index.js` bootstraps feature flags from backend auth response, but `plugins/firebase-remote-config.js` later fetches client config and commits to the same state again
- `store/modules/smartchat.js` and `store/modules/groupchat.js` both use the shared optimistic flag tracker; offscreen increment/decrement behavior must be validated, not just visible-room updates
- Groupchat UI relies heavily on local state and watcher-triggered refetches, so overlapping requests and stale socket events can cause visible drift

Failures and how to do differently:
- browser Remote Config can overwrite backend-authenticated flag state
- optimistic badge tracking can drift because it lacks a true per-contact baseline for unknown prior state
- groupchat badge/list behavior is not fully aligned with socket reality and can leave stale rooms visible or mutate the wrong counter bucket

References:
- `plugins/firebase-remote-config.js:8-52,81-85`
- `store/index.js:476-485`
- `store/modules/smartchat.js:692-749`
- `store/modules/groupchat.js:215-321`
- `pages/business/_biz_id/groupchat/index.vue:26-31,449-567`
- `utils/optimistic-flag-count-tracker.js:1-27`

## Thread `019f61e5-e958-75d1-ae40-e7dc4ffd3d5c`
updated_at: 2026-07-14T18:42:39+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T01-31-25-019f61e5-e958-75d1-ae40-e7dc4ffd3d5c.jsonl
rollout_summary_file: 2026-07-14T18-31-25-OSyU-oho_unread_unresponded_cross_repo_deploy_gate_review.md

---
description: Cross-repo read-only deploy-gate review of unread/unresponded realtime badge fixes; key takeaway is to distrust summaries, verify actual worktree diffs/status first, and trace emit/write guards end-to-end because several fixes were partially correct but still left security and rollback bugs.
task: read-only correctness review across oho-api, oho-websocket, and oho-web-app for unread/unresponded realtime badge fixes
task_group: cross-repo review / deploy-gate
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: read-only review, git diff, git status, deploy gate, unread, unresponded, realtime badge, websocket, optimistic counters, checked_channels, single-flight, backoff, TTL cache, modifiedCount, last_contact_date, rollback, groupchat, smartchat, channel-eligible-members, Firebase Remote Config
---

### Task 1: oho-api unread/unresponded fix round

task: read-only correctness review of oho-api unread/unresponded and bulk-send changes in mr-1285-fixes
task_group: oho-api review
task_outcome: partial

Preference signals:
- when the user said "Do NOT trust the summary below as fact — run git diff / git status yourself in each repo and verify every claim against the actual diff." -> future similar reviews should always pin the real worktree state first and treat summaries as suspect.
- when the user said "Do NOT edit, stage, commit, or run any command that mutates files or git state." -> keep similar reviews strictly read-only.
- when the user requested severity-ranked findings with file:line evidence and a one-line verdict -> stay compact, judgmental, and evidence-first instead of exploratory.

Reusable knowledge:
- `src/utils/get-last-stream-message-timestamp.js` returns the last distinct `oho_created_at` from the payload, so any guard that uses it must ensure the payload really represents a successful reply, not merely a batched attempt.
- In `src/services/member-send-message/bulk/bulk.class.js`, the new `hasSuccessfulDelivery` guard protects `updateContactAfterBulkSend()`, but the timestamp fed into that function comes from the merged payload across all responses.
- The `oho-api` model for `chatSession` has `unread_by` and `is_unresponded` explicitly absent by default, which supports the "flag off means field absent" contract.

Failures and how to do differently:
- The mixed-success bulk-send guard was only partly correct: the code now skips the clear when all deliveries fail, but still derives the timestamp from the entire merged payload, which can include failed deliveries.
- Bulk-send test coverage was shallow in the active path; the serious LINE path regression tests existed, but the mixed-success guard was not exercised in a way that would fail if the new logic were reverted.

References:
- [1] `src/services/member-send-message/bulk/bulk.class.js:218-276`, `:300-377`, `:451-528`, `:615-676`
- [2] `src/utils/get-last-stream-message-timestamp.js:3-8`
- [3] `src/services/contact-send-message/contact-send-message.hooks.js:585-602`
- [4] `src/services/chat-session/hooks/emit-chat-session-event.js:245-389`
- [5] `src/models/chat-session.model.js:31-97`

### Task 2: oho-websocket message.read and group broadcast changes

task: read-only correctness review of oho-websocket read-path/broadcast/cache changes
task_group: websocket review
task_outcome: partial

Preference signals:
- when the user highlighted the new `message.read` realtime broadcast and independently reimplemented `channel-eligible-members.js` as counterexample targets -> future reviews should actively try to falsify the safe-by-design claims.
- when the user asked whether the websocket port was “actually faithful” to the oho-api version -> compare semantics, not just line similarity.

Reusable knowledge:
- `src/webhook/stream.js:215-240` uses `modifiedCount` to decide whether to emit `chat-session/status updated` with `is_read_by_me: true`.
- `src/handlers/stream-webhook.handler.js:447-483` scopes group chat broadcasts to eligible members via `getEligibleMemberIds()` and per-member channels; it skips the broadcast entirely when the eligible set is unknown or empty.
- `src/utils/channel-eligible-members.js:4-39,58-92` caches eligible IDs in memory for 60s with a 20k-entry cap and returns `null` on over-cap or lookup failure.
- `src/firebase-remote-config.js:25-68` implements single-flight and TTL backoff by holding `refreshPromise` and bumping `templateFetchedAt` on both success and failure.

Failures and how to do differently:
- The new group broadcast helper is fail-closed, but the in-memory TTL cache means revoked channel permission can still receive message content until cache expiry; future reviews should treat cached audience computation as a security boundary, not just a performance optimization.
- The helper does not cache in-flight Promise state, so concurrent cold/expired lookups can stampede Mongo.
- The `message.read` broadcast now depends on `modifiedCount > 0`, so it avoids double-broadcast on no-op writes, but the emitted `updated_at` comes from the Stream event time, which downstream frontend code can still treat as stale and drop.

References:
- [1] `src/webhook/stream.js:171-240`
- [2] `src/handlers/stream-webhook.handler.js:447-483`
- [3] `src/utils/channel-eligible-members.js:41-99`
- [4] `src/utils/channel-eligible-members.spec.js:69-110`
- [5] `src/firebase-remote-config.js:1-136` and `src/firebase-remote-config.spec.js:91-161`
- [6] `src/handlers/stream-webhook.handler.spec.js:70-118`
- [7] `src/webhook/stream.spec.js:82-239`

### Task 3: oho-web-app optimistic counters, scoping, and conversation flow

task: read-only correctness review of oho-web-app unread/unresponded optimistic counters and UI guards
task_group: frontend review
task_outcome: partial

Preference signals:
- when the user specifically questioned whether `checked_channels` semantics could now under-count when “no channels selected = show all” -> inspect empty-selection semantics carefully instead of assuming they are harmless.
- when the user wanted both `Conversation.vue` try/catch rollback and the `optimistic-flag-count-tracker` semantics checked against doc comments/specs -> verify the helper against both the implementation and its callers.

Reusable knowledge:
- `utils/optimistic-flag-count-tracker.js` now does `set.add(id)` on every increment and `set.delete(id)` on every decrement; its doc comment says the Set must reflect “currently counted true” regardless of whether the item was loaded locally or not.
- `store/modules/smartchat.js:694-767` and `store/modules/groupchat.js:217-254` now gate aggregate count commits behind `checked_channels`; empty `checked_channels` means no channel filter is active and all channels are in scope.
- `components/Smartchat/RoomList.vue` now applies `filter_unresponded` to groupchat as well, while keeping `filter_unread` smartchat-only.
- `plugins/firebase-remote-config.js:52-56` makes later browser-side remote config updates non-authoritative if the API already committed a flag key.
- `store/index.js:103-129` tracks `feature_flags_api_keys` so the browser plugin does not silently overwrite API-authenticated values.

Failures and how to do differently:
- `markRoomRead()` wraps `addMembers()` and `markRead()` in one catch, but the rollback path still assumes an unread decrement already happened; if `addMembers()` fails before the decrement, the increment rollback can overstate the badge.
- The optimistic counter helper fixes the documented offscreen repeat bug, but it still depends on module-level Sets that are never seeded/reset from authoritative API fetches; future reviews should check API refresh and filter-scope changes for stale Set drift.
- `checked_channels=[]` is treated as “all channels in scope,” which matches the query helper semantics, so the real question is whether room channel IDs are always available on the event/local-state path.

References:
- [1] `utils/optimistic-flag-count-tracker.js:1-40` and `test/utils/optimistic-flag-count-tracker.spec.js:103-160`
- [2] `store/modules/smartchat.js:694-767` and `test/store/modules/smartchat.spec.js:1002-1070`
- [3] `store/modules/groupchat.js:217-254` and `test/store/modules/groupchat.spec.js:34-101`
- [4] `components/Smartchat/Conversation.vue:1640-1717` and `test/components/Smartchat/Conversation.spec.js:216-333`
- [5] `components/Smartchat/RoomList.vue` diff and `test/components/Smartchat/RoomList.spec.js:332-356`
- [6] `store/index.js:103-129`, `test/store/index.spec.js:118-179`, and `plugins/firebase-remote-config.js:52-56`
- [7] `pages/business/_biz_id/groupchat/index.vue:557-585`

### Cross-task reusable lessons / deploy-gate signals

- Always verify branch/status/diff in each repo before trusting a rollout summary.
- For realtime badge fixes, trace the whole chain: event payload source, guard, write result, broadcast result, and frontend merge/filter logic.
- `modifiedCount > 0` is a useful guard against double-broadcast/no-op writes, but it does not solve stale `updated_at` filtering downstream.
- Caching audience resolution is dangerous when the payload contains content; fail-closed is safer than fallback, but TTL-based leakage can still be a blocker if permission revocation matters.
- Regression tests are strongest when they would fail if the fix is reverted; wiring-only tests are useful but shallow, and they do not prove semantic correctness by themselves.

References worth keeping verbatim:
- `oho-websocket/src/handlers/stream-webhook.handler.js:447-483`
- `oho-websocket/src/webhook/stream.js:215-240`
- `oho-websocket/src/utils/channel-eligible-members.js:41-99`
- `oho-web-app/components/Smartchat/Conversation.vue:1640-1717`
- `oho-web-app/utils/optimistic-flag-count-tracker.js:1-40`
- `oho-api/src/services/member-send-message/bulk/bulk.class.js:218-276`
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:245-389`
- `oho-api/src/models/chat-session.model.js:31-97`
- `oho-web-app/plugins/firebase-remote-config.js:52-56`
- `oho-web-app/store/index.js:103-129`

## Thread `019f6358-6a26-7531-ab13-b4360a1b5799`
updated_at: 2026-07-15T01:29:28+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T08-16-06-019f6358-6a26-7531-ab13-b4360a1b5799.jsonl
rollout_summary_file: 2026-07-15T01-16-06-ttm9-cross_repo_unread_unresponded_deploy_gate_review.md

---
description: cross-repo read-only deploy-gate review of unread/unresponded fixes; found websocket cleanup mostly sound, but frontend optimistic counter reconciliation and mark-read rollback drift remained risky, plus backend mixed-success timestamp collateral risk
task: cross-repo unread/unresponded deploy-gate review across oho-api, oho-websocket, oho-web-app
task_group: /Users/tualek/ohochat cross-repo unread-unresponded deploy-gate reviews
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: unread, unresponded, deploy gate, code review, git diff, git status, bulk.class.js, channel-eligible-members, optimistic-flag-count-tracker, markRoomRead, findOneAndUpdate, updated_at, last_active_at, single-flight, pagination, Vue 2 reactivity
---

### Task 1: oho-api bulk-send round-2 fixes

task: review latest round-2 bulk-send timestamp fix in oho-api worktree

task_group: oho-api deploy-gate review

task_outcome: partial

Preference signals:
- the user explicitly required read-only review and severity-ranked findings with file:line evidence -> future similar reviews should stay read-only and evidence-first
- the user asked to check Instagram shape parity and mentally revert the new test -> future reviews should inspect both platform paths independently and judge test strength by reverting the fix in mind

Reusable knowledge:
- Instagram reply-message service returns `response.data` on success and throws `GeneralError` on failure, same contract shape as Facebook
- `handleCallFacebook` was exported so the new Facebook regression test could call it directly; the `afterAll` spy restore was scoped so sibling describe blocks were not polluted
- `getLastStreamMessageTimestamp()` is called twice in the mixed-success Facebook test: once on the full merged payload and once on the successful-only filtered payload

Failures and how to do differently:
- the clear-write now uses the last successful timestamp, but `lastMessageTimestamp` is still computed across all attempts and the helper still uses that timestamp concept for `$max last_active_at`, so mixed-success batches can still affect ordering semantics beyond the clear guard
- the new Facebook regression test is strong, but there is no equivalent Instagram-specific regression test, so Instagram could regress without the suite catching it

References:
- `src/services/member-send-message/bulk/bulk.class.js:365-392` (Facebook successful-only clear guard)
- `src/services/member-send-message/bulk/bulk.class.js:531-552` (Instagram successful-only clear guard)
- `src/services/integration/instagram/reply-message/reply-message.class.js:20-50`
- `src/services/integration/facebook/reply-message/reply-message.class.js:20-49`
- `src/services/member-send-message/bulk/bulk.class.spec.js:363-505`

### Task 2: oho-websocket eligibility scoping and message.read refresh

task: review websocket round-2 eligibility scoping and message.read refresh

task_group: oho-websocket deploy-gate review
task_outcome: success

Preference signals:
- the user asked whether removing caching creates load problems and whether the refreshed broadcast payload still has the right fields -> future reviews should trace both call frequency and consumer payload contract

Reusable knowledge:
- `getEligibleMemberIds()` is fresh-query only with single-flight dedup; it intentionally does not cache results because group message content is broadcast directly to per-member socket channels
- `message.read` is fail-closed on missing/unparseable timestamps and still carries `maxTimeMS`, `new:true`, `.select('business_id updated_at')`, and `.lean()`
- the downstream broadcast only needs the fields it now supplies: `_id`, `type`, `business_id`, `is_read_by_me`, and `updated_at`

Failures and how to do differently:
- no new bug was found in the websocket round-2 changes; the main tradeoff is deliberate correctness over stale-cache risk
- the code does not expose enough production telemetry to prove or disprove a QPS/load regression, so load concern remains unproven rather than established

References:
- `src/utils/channel-eligible-members.js:10-28,31-95`
- `src/handlers/stream-webhook.handler.js:447-483`
- `src/webhook/stream.js:193-233`

### Task 3: oho-web-app optimistic badge and read rollback fixes

task: review frontend realtime unread/unresponded badge fixes and optimistic rollback

task_group: oho-web-app deploy-gate review
task_outcome: fail

Preference signals:
- the user wanted a severity-ranked list with file:line citations and a one-line verdict -> future review responses should stay compact and judgmental
- the user explicitly asked to check pagination wiring and performance of Set reconciliation -> future reviews should inspect append paths as carefully as full replacement paths

Reusable knowledge:
- `reconcileOptimisticFlagSet()` records every increment in its Set and deletes on every decrement; it only stays correct if every authoritative list replacement and pagination path seeds or reconciles the Set appropriately
- `Conversation.vue` now uses a function-local `did_decrement_unread_count` flag, so the rollback path does not leak across rooms/calls
- `RoomList.vue` sorts by `last_active_at` in the client fallback, and the smartchat/groupchat pages expose `unread_count` / `unresponded_count` directly from list state

Failures and how to do differently:
- reconciliation is only hooked to full list replacement mutations; pagination append mutations do not reconcile, so offscreen items can still double-count when they reappear through realtime events
- `markRead()` rollback does not revert the optimistic `last_read` cursor, so a retry after failure can mis-detect the room as already read and skip the needed decrement

References:
- `utils/optimistic-flag-count-tracker.js:25-75`
- `store/modules/smartchat.js:70-91,128-130`
- `store/modules/groupchat.js:46-61,92-95`
- `components/Smartchat/Conversation.vue:1640-1733`
- `store/modules/smartchat.js:760-789`

### Task 4: Cross-repo deploy-gate takeaways

task: cross-repo deploy-gate review of unread/unresponded fixes

task_group: cross-repo review workflow
task_outcome: partial

Reusable knowledge:
- the durable contract across these reviews is: SET writes are flag-gated, CLEAR writes are unconditional, and realtime broadcasts are flag-gated
- round-2 frontend fixes fixed one known double-count path, but correctness still depends on seeding/reconciling the optimistic Sets from authoritative fetches on every relevant list commit path
- the websocket audience scoping change is fail-closed and fresh-query based; if group permissions are revoked, stale cached audience would be a security regression
- sandboxed read-only Jest runs can fail before tests execute because Jest tries to write haste-map temp files; `git diff --check` may pass even when semantic bugs remain

Failures and how to do differently:
- do not trust prior rollout summaries or memory alone; always verify live `git status` / `git diff` in each repo before concluding anything about the current round
- compare behavior contracts, not line similarity, especially for websocket ports and frontend consumers
- treat cache TTL, revocation behavior, and single-flight as part of the security review surface, not just performance tuning

References:
- `git status` / `git diff --check` were run in all three repos; targeted Jest was blocked by sandbox `EPERM` haste-map writes
- frontend and backend review context came from the actual branches/worktrees: `oho-api/.claude/worktrees/mr-1285-fixes`, `oho-websocket` feature branch, and `oho-web-app` `uat`

## Thread `019f649e-9cc4-7813-bcca-a102cb1b4a2a`
updated_at: 2026-07-15T07:21:36+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T14-12-24-019f649e-9cc4-7813-bcca-a102cb1b4a2a.jsonl
rollout_summary_file: 2026-07-15T07-12-24-BMSu-oho_api_badge_count_redis_cache_review.md

---
description: Review of a new 8s Redis cache for unread/unresponded badge counts in oho-api; main durable takeaways are that key isolation looked correct, but stale-write/queueing behavior and lack of single-flight could still undermine the mitigation.
task: review-only code review of unread/unresponded badge-count cache change
 task_group: oho-api / review
 task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api
keywords: badge-count-cache, compute-badge-counts, cacheService, raceCommandTimeout, Redis, Bluebird, ObjectId, buildCountBaseQuery, unread_by, is_unresponded, Promise.allSettled, offline_queue, single-flight, stampede, EPERM, Jest haste map
---

### Task 1: Review badge-count cache correctness and risk

task: review unread/unresponded badge-count cache change for correctness and cross-member poisoning
 task_group: oho-api / review
 task_outcome: partial

Preference signals:
- when the user said "do NOT modify files" for a review-only task -> future similar reviews should stay read-only and not start editing as a default.
- when the user asked for "findings ranked by severity with file:line references" and an "overall verdict" -> future similar reviews should default to concise, judgmental, evidence-backed output.
- when the user emphasized "correctness bugs (especially cross-member cache poisoning)" -> future similar cache reviews should prioritize scope isolation, member identity, and stale-data correctness before style or minor test coverage.

Reusable knowledge:
- `computeBadgeCounts` is called from both `src/services/contact/chat-search/chat-search.class.js` and `src/services/chat-session/group/search/search.class.js`; both pass `countBaseQuery`, `countMemberId`, and a label.
- `buildCountBaseQuery()` in `src/services/contact/chat-search/build-count-base-query.ts` strips meta fields and typed unread/unresponded fields, so the scope is intended to live in the base query.
- `getCachedBadgeCount()` returns numeric `0` as a valid hit and `undefined` as miss; `runCount()` checks `cached !== undefined`.
- Redis TTL is passed as numeric seconds via `cacheService.set(key, value, ttl)`.
- `src/index.js` sets `global.Promise = require('bluebird')`, so production promise inspection differs from Jest’s native Promise shape.

Failures and how to do differently:
- The first-pass concern that ObjectId/stringification might cause collisions was not the main issue; direct runtime probes showed equal ObjectIds stringify the same and different ObjectIds stringify differently.
- Jest could not run cleanly in the read-only environment because it tried to write a haste map under `/private/var/...` and hit `EPERM`; in similar environments, rely more on direct source inspection and targeted runtime probes.
- The cache module is mocked in the new spec, so orchestration tests do not prove real helper-boundary behavior.

References:
- `src/utils/badge-count-cache.ts:20-78` — TTL 8s, key format, fail-soft get/set.
- `src/utils/compute-badge-counts.ts:119-219` — cache lookup, DB fallback, `Promise.allSettled`, Bluebird-compatible settlement handling, and fire-and-forget write-through.
- `src/utils/compute-badge-counts.spec.ts:22-29, 266-363` — cache module mocked; tests do not exercise real Redis helper behavior.
- `src/services/contact/chat-search/build-count-base-query.ts:37-41` — count base query stripping rules.
- Runtime probe evidence — same ObjectId stringified identically; different ObjectIds differently.

### Task 2: Trace Redis timeout, offline queue, and stale-write behavior

task: review Redis timeout and late-write behavior for badge-count cache
 task_group: oho-api / review
 task_outcome: partial

Preference signals:
- when the user asked about the fire-and-forget write path and unhandled-rejection risk -> future similar reviews should inspect async helper semantics, not just the caller line.
- when the user asked about staleness vs realtime -> future similar reviews should separate freshness trade-offs from actual correctness bugs.

Reusable knowledge:
- `raceCommandTimeout()` in `src/utils/cache/index.js` races a promise against a timeout; it does not cancel the underlying Redis command.
- Node Redis 3.x defaults `enable_offline_queue` to true; commands issued while disconnected are queued and replayed on reconnect.
- `src/services/chat-session/hooks/emit-chat-session-event.js` emits `chat-session/status updated` payloads carrying `is_unresponded`, but there is no badge-count push path.

Failures and how to do differently:
- A timed-out Redis write can still be queued and later applied after reconnect, which can violate the intended short-TTL staleness bound. In similar cases, treat "timeout does not cancel command + offline queue enabled" as a serious stale-write risk.

References:
- `src/utils/cache/index.js:27-55` — timeout/race implementation.
- `node_modules/redis/index.js:97-103, 476-480, 766-792` and `node_modules/redis/README.md:181-183` — offline queue default behavior.
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-323` — realtime payload contains `is_unresponded`, not badge count.

### Task 3: Judge overall ship readiness

task: consolidate review findings and verdict for badge-count cache change
 task_group: oho-api / review
 task_outcome: partial

Preference signals:
- when the user asked for a ranked list and a final one-paragraph verdict -> future similar reviews should end with a clear recommendation rather than an ambiguous recap.

Reusable knowledge:
- Verified non-findings: cross-member cache poisoning was not substantiated, `countMemberId` is part of the unread filter, the base query keeps business/tab scope, `0` remains a valid cached value, and the helper swallows normal Redis errors/timeouts.
- Remaining concern: late Redis writes plus lack of single-flight mean the cache can still violate its intended bounded-staleness and load-smoothing goals.

Failures and how to do differently:
- The mitigation looked correct on key isolation, but not yet fully safe on stale-write and stampede behavior; future reviews should treat those as the main risks once collision is ruled out.

References:
- `src/utils/compute-badge-counts.ts:139-149` and `src/utils/badge-count-cache.ts:20` — no single-flight or distributed lock.
- `src/utils/compute-badge-counts.ts:139-145` and `src/utils/cache/index.js:19,27-55` — cache GET timeout and fallback timing.
- `src/utils/cache/index.js:113-120, 75-80` and `src/utils/compute-badge-counts.ts:139-140` — `0` is handled as a real hit.
- `src/utils/compute-badge-counts.ts:154-160` — unread cache key carries member scope via `unread_by: countMemberId`.

## Thread `019f6506-8353-7c13-9dda-4d97fcfab9ad`
updated_at: 2026-07-15T09:18:31+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-05-53-019f6506-8353-7c13-9dda-4d97fcfab9ad.jsonl
rollout_summary_file: 2026-07-15T09-05-53-eBHL-oho_api_uncommitted_review_startup_blocker_and_behavior_pres.md

---
description: Read-only review of uncommitted `oho-api` unread/unresponded diff on `feature/tk-sprint-2613/oho-1018-unrespone`; found one blocking Feathers service-startup regression in contact-send-message hook registration, while items 1–5 and 7 were behavior-preserving under current repo config.
task: review uncommitted working-tree changes in oho-api
 task_group: code_review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api
keywords: git status, git diff, Feathers hooks, service.hooks, contact-send-message, notify.service.js, compute-badge-counts, build-clear-unread-unresponded-payload, get-message-preview-text, paginate.max, checkJs, startup blocker
---

### Task 1: Review uncommitted unread/unresponded diff

task: review uncommitted working-tree changes in `/Users/tualek/ohochat/oho-api`
task_group: code_review
task_outcome: partial

Preference signals:
- user explicitly said `Review the UNCOMMITTED working-tree changes ... This is a REVIEW ONLY task. Do not edit any files.` -> future similar work should stay strictly read-only and evidence-led
- user required exact file paths and line numbers in all claims -> future reviews should answer in the same citation-heavy format
- user called out pre-existing failing suites that must not be blamed on this diff -> future reviewers should separate repo noise from diff-caused regressions

Reusable knowledge:
- Feathers 4 `service.hooks()` validates hook-module keys; whole-module registration only works when the module exports lifecycle keys (`before/after/error/finally`) and nothing else
- `config/default.json` sets `paginate.max` to 50, so the new `context.app?.get('paginate')?.max ?? 50` fallback preserves current behavior when config is present or missing
- `buildClearUnreadUnrespondedPayload()` treats omitted, `undefined`, and `null` member IDs the same; call sites switching from `undefined` to `()` do not change payload shape
- `getMessagePreviewText()` now safely ignores non-string `data.label` values from `qs.parse` and falls back to `message.text` or `กดปุ่ม`
- the diff removed named exports from several local hook files, but those functions are still invoked from their local hook arrays; repository search found no surviving external imports of those hook helpers

Failures and how to do differently:
- `contact-send-message.service.js:12` is a blocking regression: `service.hooks(hooks)` receives the whole module, but `contact-send-message.hooks.js:497` still exports `getContactSendMessagePreviewText`, so Feathers throws `'getContactSendMessagePreviewText' is not a valid hook type` and startup aborts
- `notify.service.js:15` is fine because its hooks module only exports lifecycle keys
- Jest in this sandbox was blocked by read-only haste-map persistence / duplicate-worktree collisions, so future reviews should not over-interpret Jest failures as diff regressions; static tracing was the usable path here

References:
- `src/services/contact-send-message/contact-send-message.service.js:12` — `service.hooks(hooks)`
- `src/services/contact-send-message/contact-send-message.hooks.js:497-500` — `getContactSendMessagePreviewText` export and caller
- `src/services/index.js:439` — service configuration reaches `contactSendMessages`
- `node_modules/@feathersjs/feathers/lib/hooks/index.js:141-166` — unknown hook types are rejected during registration
- `src/services/chat-session/group/search/search.hooks.js:41-44` and `config/default.json:6-8` — paginated limit fallback to 50
- `src/utils/build-clear-unread-unresponded-payload.ts:51-62` — `undefined`/`null`/absent member IDs all resolve identically
- `src/utils/get-message-preview-text.ts:19-27` and `src/utils/message-converter/youpin-to-stream.js:296-301` — string-label preservation and object-label fallback
- `src/services/contact/close-chat/end-case/end-case.hooks.js:457` and `src/services/contact/close-chat/no-case/no-case.hooks.js:448` — direct helper invocation after alias removal
- `src/services/bot-send-message/notify/notify.service.js:15` — safe whole-module hook registration
- `tsconfig.json:9-10,17` — JS allowed, JS checking disabled, only TS sources included

### Task 2: Capture review workflow facts

task: capture review workflow facts from the diff review
task_group: code_review
task_outcome: success

Preference signals:
- user preferred a review-only pass and forbade edits/commits/write git commands -> keep future similar sessions read-only unless the user changes scope
- user wanted pre-existing failing tests excluded from findings unless directly caused by the diff -> preserve that separation rule in future reviews

Reusable knowledge:
- `service.hooks(hooks)` is only safe when the hooks module is a pure hook registry; if the module also exports utilities, split the module or revert to `{ before, after, error }`
- `allowJs: true` with `checkJs: false` means JS callers are not statically typechecked even when a utility adds a TypeScript interface

Failures and how to do differently:
- Jest in this sandbox is noisy because multiple worktrees create duplicate mock/path collisions and the environment cannot persist haste-map files; do not treat those failures as evidence of a diff bug

References:
- `src/services/index.js:439` configures `contactSendMessages`, making the startup regression user-visible immediately
- `src/services/contact-send-message/contact-send-message.hooks.js:497` is the extra export that breaks whole-module hook registration
- `node_modules/@feathersjs/feathers/lib/hooks/index.js:141-166` is the validation path that throws on unknown hook types

## Thread `019f650a-4163-70e3-b3ce-6fa49d681272`
updated_at: 2026-07-15T09:20:54+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-09-58-019f650a-4163-70e3-b3ce-6fa49d681272.jsonl
rollout_summary_file: 2026-07-15T09-09-58-II02-oho_api_uncommitted_unresponded_review_boot_regression_and_c.md

---
description: Read-only review workflow for an uncommitted oho-api unread/unresponded diff; confirmed a Feathers boot regression caused by exporting a helper alongside hooks, while the business_id guard, paginate.max=50 change, and postback preview typing were safe; the largest remaining risk was deleted coverage not fully replaced.
task: review uncommitted oho-api unread/unresponded diff for runtime regressions and coverage loss
task_group: oho-api review workflows
cwd: /Users/tualek/ohochat/oho-api
keywords: unread, unresponded, Feathers hooks, service.hooks(hooks), hook export, computeBadgeCounts, business_id guard, paginate.max, getMessagePreviewText, qs.parse, deleted specs, coverage loss, read-only review
---

### Task 1: Live diff review of unread/unresponded changes

task: review uncommitted unread/unresponded MR !1285 diff

task_group: oho-api review workflows
task_outcome: partial

Preference signals:
- The user explicitly said “This is a READ-ONLY REVIEW. Do not edit any code or files.” -> keep similar review tasks strictly read-only.
- The user required “run git status/git diff to see them” and “verify with actual code inspection (not assumption)” -> always inspect the live repo state first, not summaries.
- The user asked for a compact report in fixed sections (`CONFIRMED REGRESSIONS`, `RISKS / NEEDS-HUMAN-JUDGMENT`, `VERDICT ON QUALITY`, `CONCRETE SUGGESTIONS`) -> use a tight, findings-first format on similar reviews.
- The user asked direct safety questions about runtime behavior, not implementation help -> default to judgmental review, not fix proposals.

Reusable knowledge:
- `computeBadgeCounts()` must be guarded by explicit `business_id`, not just truthiness, because `buildCountBaseQuery()` can return `{}` on api-key paths.
- `config/default.json` has `paginate.max: 50`; the new dynamic max in group search resolves to the same value.
- `getMessagePreviewText()` now treats non-string `data.label` as invalid; the real malformed shape comes from query-string parsing of postback data.
- `service.hooks(hooks)` is only safe when the module exports exactly hook namespaces; any extra enumerable export becomes an invalid Feathers hook type.

Failures and how to do differently:
- `contact-send-message.service.js` still passed the whole hooks namespace while `contact-send-message.hooks.js` exported a helper, which caused a boot-time invalid hook type error.
- In this sandbox, Jest is not reliable as a proving step because duplicate manual mocks under `.claude/worktrees` and haste-map write permission errors prevent clean runs; report those blockers explicitly instead of overstating validation.

References:
- `src/services/contact-send-message/contact-send-message.service.js:12`
- `src/services/contact-send-message/contact-send-message.hooks.js:497`
- `node_modules/@feathersjs/commons/src/hooks.ts:163-167`
- `src/utils/compute-badge-counts.ts:96-102`
- `src/services/contact/chat-search/chat-search.hooks.js:40-44, 78-80`
- `src/services/chat-session/group/search/search.hooks.js:26-44, 111-157`
- `config/default.json:6-9`
- `src/utils/get-message-preview-text.ts:19-25`

### Task 2: Coverage and regression judgment

task: compare deleted specs against remaining coverage

task_group: oho-api review workflows
task_outcome: partial

Preference signals:
- The user asked whether deleted specs still had coverage elsewhere or whether “real test coverage was lost” -> compare deleted assertions against surviving tests, not just file names.
- The user wanted “concrete improvements only where clearly warranted” -> only recommend restoring tests when there is a real gap.

Reusable knowledge:
- The deleted `contact.model.spec.ts` and `chat-session.model.spec.ts` were the only direct proof of the schema “absence contract” via `toObject()` on new documents.
- Several deleted hook specs covered distinct branches that are not all recreated elsewhere: guarded clears, `$lte` ordering, fallback-message exclusion, and emitter wiring.
- Shared-helper specs can validate payload shape, but they do not replace hook-registration or service-boot assertions for concrete services.

Failures and how to do differently:
- The review found that many deleted tests were not fully redundant; at least one exact write-shape or pipeline-level test per path is still warranted.
- The duplicate-helper alias approach in `is-unresponded.spec.ts` does not prove that end-case and no-case pipelines actually register the helper in the service hook chain.

References:
- `src/models/contact.model.js:223-235`
- `src/models/chat-session.model.js:78-90`
- `src/services/contact/close-chat/is-unresponded.spec.ts:36-40, 62-112`
- `src/services/bot-send-message/broadcast/broadcast.hooks.spec.js:502-508`
- `src/services/bot-send-message/inform-message/inform-message.hooks.spec.js:291-297`
- `src/services/member-send-message/bulk/bulk.class.spec.js:552-681`

### Task 3: Final review verdict and suggestions

task: judge net quality of cleanup and spec deletions
task_group: oho-api review workflows
task_outcome: partial

Preference signals:
- The user wanted an explicit verdict on whether the change set is a genuine improvement and whether the comment sweep / un-export / spec deletions are net-positive or net-negative -> provide an explicit quality judgment.

Reusable knowledge:
- The one confirmed runtime blocker was caused by `contact-send-message.service.js` booting Feathers with an extra exported helper in the hooks module.
- `notify.service.js` is safe because its hooks module exports only `before`, `after`, and `error`.

Failures and how to do differently:
- The change set is not a clean net-positive until the deleted coverage is restored or replaced, because the cleanup removed direct tests for model default behavior and several hook write paths.

References:
- `src/services/contact-send-message/contact-send-message.service.js:12`
- `src/services/contact-send-message/contact-send-message.hooks.js:497, 523-580`
- `src/services/bot-send-message/notify/notify.service.js:15`
- `src/services/bot-send-message/notify/notify.hooks.js:739-800`
- `src/utils/build-clear-unread-unresponded-payload.spec.ts:36-63`

## Thread `019f654e-423f-7483-bdd6-494aba0e6b12`
updated_at: 2026-07-15T10:56:47+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T17-24-15-019f654e-423f-7483-bdd6-494aba0e6b12.jsonl
rollout_summary_file: 2026-07-15T10-24-15-fwAy-mr1285_unread_unresponded_cross_repo_review.md

---
description: Read-only cross-repo review of MR !1285 unread/unresponded changes; core backend path improved, but websocket/frontend drift risks and rollout/migration concerns remained.
task: code-review MR !1285 unread/unresponded across oho-api, oho-websocket, oho-web-app
task_group: /Users/tualek/ohochat
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api
keywords: mr-1285, unread, unresponded, code-review, read-only, exact file:line, emitContactUnrespondedStatusUpdatedEvent, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, message.read, Remote Config, optimistic-flag-count-tracker
---

### Task 1: Backend review in oho-api

task: code-review MR !1285 unread/unresponded backend changes
task_group: oho-api review
task_outcome: partial

Preference signals:
- The user said to read prior review docs first and “do not re-flag findings already documented as fixed there” -> rebase on prior review history and avoid duplicate findings.
- The user asked for “structured findings report, ranked by severity” and “every finding must cite an exact file:line” -> keep reviews line-precise, severity-ranked, and evidence-first.
- The user said “do not modify any files” -> keep review flows read-only.

Reusable knowledge:
- `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for both `unread_by` and `is_unresponded:true`.
- `buildClearUnreadUnrespondedPayload()` intentionally builds unconditional CLEAR payloads to avoid flag-toggle stuck-state bugs.
- `emitEligibilityScopedUnrespondedUpdate()` is the actual gate for the contact clear broadcasts; notify/inform/broadcast/bulk all reach it.

Failures and how to do differently:
- Contact-side scoped broadcast is correct for unresponded but only covers channel-eligible members; sale-visibility audience mismatches are a separate issue.
- Bulk-send still needs success-aware review because it can clear state even when platform delivery fails.

References:
- `src/services/contact-send-message/contact-send-message.hooks.js:227-259`
- `src/services/chat-session/group/contact-user/send-message/send-message.class.js:40-50`
- `src/services/member-send-message/member-send-message.hooks.js:690-728`
- `src/services/member-send-message/bulk/bulk.class.js:218-285`
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-372`

### Task 2: oho-websocket review

task: code-review websocket unread/unresponded behavior in MR !1285
task_group: websocket review
task_outcome: fail

Preference signals:
- The user wanted the review to “cover all 3 repos” and keep findings separated by repo/axis -> keep repo boundaries explicit.
- The user called out the rule that realtime broadcasts of these fields must be flag-gated, not the writes.

Reusable knowledge:
- `src/webhook/stream.js` has a `message.read` branch that directly `$pull`s from `unread_by`; this is the websocket-side CLEAR site to scrutinize for unconditional behavior.
- The Stream webhook handler’s customer-message broadcasts are split into single-chat and group-chat paths, with group broadcasts using the broader `businessChannel(businessId, 'member')` audience.

Failures and how to do differently:
- `message.read` clear is currently flag-gated and lacks the backend ordering guard.
- Group customer-message broadcasts go to the whole business member room, not a channel-eligibility-scoped audience.

References:
- `src/webhook/stream.js:149-160`
- `src/handlers/stream-webhook.handler.js:361-449`
- `src/webhook/stream.spec.js:93-108`

### Task 3: oho-web-app review

task: code-review frontend unread/unresponded behavior in MR !1285
task_group: frontend review
task_outcome: partial

Preference signals:
- The user wanted a careful senior review before production rollout, not implementation suggestions.
- The user explicitly asked for complete flag/write/broadcast inventory behavior in the audit -> include UI state mutation paths from sockets and optimistic logic.

Reusable knowledge:
- `store/index.js` bootstraps feature flags from backend auth, but `plugins/firebase-remote-config.js` later fetches client config and commits to the same state again.
- `store/modules/smartchat.js` and `store/modules/groupchat.js` both use the shared optimistic flag tracker; validate offscreen increment/decrement behavior, not just visible-room updates.

Failures and how to do differently:
- Client Remote Config can race backend-authenticated flags.
- Optimistic count tracking can drift without authoritative reconciliation.
- Groupchat badge/list behavior is not fully aligned with Smartchat.

References:
- `plugins/firebase-remote-config.js:8-52,81-85`
- `store/index.js:476-485`
- `store/modules/smartchat.js:692-749`
- `store/modules/groupchat.js:215-321`
- `pages/business/_biz_id/groupchat/index.vue:26-31,449-567`
- `utils/optimistic-flag-count-tracker.js:1-27`

## Thread `019f6ae5-4dea-7a62-b818-7b3d28db18df`
updated_at: 2026-07-16T12:35:11+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/07/16/rollout-2026-07-16T19-27-20-019f6ae5-4dea-7a62-b818-7b3d28db18df.jsonl
rollout_summary_file: 2026-07-16T12-27-20-o4b5-oho_1177_pagination_select_all_read_only_review.md

description: Read-only review of OHO-1177 pagination/select-all changes found async selection races, stale page responses, duplicate-name validation race, and overlong comments; cross-page checkbox model and last-page recursion were verified correct
 task: review uncommitted OHO-1177 pagination and select-all work in oho-backoffice
 task_group: /Users/tualek/ohochat/oho-backoffice external-message Vue/Nuxt admin review
 task_outcome: success
 cwd: /Users/tualek/ohochat/oho-backoffice
 keywords: OHO-1177, Vue2, Nuxt2, element-ui, pagination, select-all, checkbox-group, stale-response, whitelist_request_seq, duplicate-name, $limit, BadRequest

### Task 1: Pagination and select-all correctness review

task: read-only line-cited review of external-message app catalog and whitelist pagination/select-all changes
task_group: oho-backoffice external-message admin UI
 task_outcome: success

Preference signals:
- when the user said “read-only, do NOT edit any files” and requested a report only -> inspect strictly without editing, staging, committing, or creating files.
- when the user required every correctness claim to cite actual lines and requested ranked findings -> report evidence-first, severity ordered, and omit speculative issues.
- when the user supplied a specific checklist for cross-page state, select-all, races, recursion, contract adherence, and comments -> use that checklist explicitly in similar reviews.

Reusable knowledge:
- `components/ExternalMessage/WhitelistAppChecklist.vue:19-28,80-105` uses Element UI's full checkbox-group model, so visible-page toggles preserve IDs from other pages; this mechanism was checked and is not a bug.
- `components/ExternalMessage/WhitelistAppChecklist.vue:86-95` derives all/indeterminate from `selected_app_ids.length` versus catalog `total`; under the supplied cascade-delete contract this is correct.
- `pages/external-message-apps.vue:173-195` has bounded last-page step-back recursion; it refetches the corrected page and does not leave loading stuck.
- `pages/external-message-whitelist.vue:174-186,224-259` select-all fetches the whole catalog asynchronously but does not bind the result to the initiating business/request sequence.
- `pages/external-message-whitelist.vue:145-172` and `pages/external-message-apps.vue:173-199` page fetches lack request sequencing, so rapid paging can display stale rows and mishandle loading/error state.
- `pages/external-message-apps.vue:147-149,201-216,235-256,267-289` starts full-catalog validation without awaiting it; because the backend does not enforce unique names, duplicate-name validation can be bypassed by a fast submit.
- `api/externalMessageApps.js:12-13,26-33` clamps invalid limits instead of preserving the verified API behavior where `$limit > 50` returns BadRequest. Current callers use valid limits, so this is a contract mismatch rather than confirmed current-call failure.

Failures and how to do differently:
- Disable Save or otherwise serialize it while select-all is loading; otherwise a save can persist old IDs and then incorrectly mark the newly selected IDs as clean locally.
- Associate select-all with the current business/request sequence and discard results after a business switch.
- Add stale-response guards to both catalog page loaders so older page requests cannot overwrite newer page state or clear the latest loading flag.
- Await or gate validation-catalog loading before allowing Save; do not rely on the server to catch duplicate names because the supplied contract says it does not.
- Remove dead `.pagination-wrap .selected-text` SCSS at checklist lines 174-185 and reduce comments that merely narrate obvious code, especially API header comments and single-use `impact_text` explanation.

References:
- `pages/external-message-whitelist.vue:77-83,174-186,276-304` — Save/select-all race.
- `pages/external-message-whitelist.vue:174-186,224-259` — select-all/business-switch race.
- `pages/external-message-whitelist.vue:145-172` — whitelist page fetch without stale-response guard.
- `pages/external-message-apps.vue:173-199` — catalog page fetch and step-back logic.
- `pages/external-message-apps.vue:147-149,201-216,235-256,267-289` — duplicate-name validation race.
- `api/externalMessageApps.js:12-13,26-33` — silent `$limit` clamping.
- `components/ExternalMessage/WhitelistAppChecklist.vue:19-28,80-105` — cross-page checkbox model verified safe.
- `components/ExternalMessage/WhitelistAppChecklist.vue:86-95` — total-based select-all state verified safe.

## Thread `019f7d53-c7cc-7ea2-9fb1-76d2f5ace193`
updated_at: 2026-07-20T02:28:26+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/20/rollout-2026-07-20T09-21-10-019f7d53-c7cc-7ea2-9fb1-76d2f5ace193.jsonl
rollout_summary_file: 2026-07-20T02-21-10-WqUb-oho_backoffice_mr32_external_message_code_review.md

---
description: code review of GitLab MR !32 for oho-backoffice external-message admin UI; found two correctness blockers and two medium async-state risks, plus a Prettier warning on api/endpoint.js
task: code review of GitLab MR !32 for external-message admin UI changes
task_group: oho-backoffice code review / nuxt2 admin UI
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: glab, merge request 32, code review, external-message, whitelist, pagination, request_seq, race condition, prettier, git diff --check, nuxt2, element-ui
---

### Task 1: Review MR !32 external-message catalog/whitelist UI

task: code review of GitLab MR !32 for external-message admin UI changes
task_group: oho-backoffice code review / nuxt2 admin UI
task_outcome: partial

Preference signals:
- when the user asked “review mr นี้ให้หน่อย” with the `code-reviewer` skill, they wanted a real review workflow rather than an implementation task.
- the accepted review shape was severity-ranked, actionable, and line-cited; the final response gave P1/P2 findings instead of generic comments.

Reusable knowledge:
- `glab mr view 32 -F json` and `glab mr diff 32` were the main reliable sources for MR metadata and patch content.
- `git diff --check` passed on the reviewed diff, but Prettier still warned on `api/endpoint.js`.
- The feature introduces several async state transitions that must be guarded separately: business switching, save, page refresh, dialog reopen, and debounced search.
- `fetchAllExternalMessageApps()` walks every page because the API wrapper supports paginated reads only; it is used for whole-catalog validation and select-all behavior.
- The edit flow intentionally keeps `app_id` immutable to avoid orphaning existing whitelists.

Failures and how to do differently:
- Do not assume a page reset also reloads the visible data; verify the fetch call follows the state change.
- Bind save/validation to a dialog token or snapshot form state before `await`, otherwise a reopened dialog can inherit the prior task.
- Debouncing search is not enough by itself; older in-flight responses can still overwrite newer results.

References:
- `pages/external-message-whitelist.vue:321-333` — late save can overwrite `loaded_app_ids` for a newer business.
- `pages/external-message-whitelist.vue:269-279` — resetting `app_page = 1` without fetching leaves stale rows visible.
- `pages/external-message-apps.vue:284-301` — save path awaits validation before snapshotting state.
- `pages/external-message-whitelist.vue:211-226` — debounced business search can still be overwritten by an older response.
- `api/externalMessageApps.js`
- `glab mr view 32 -F json`
- `glab mr diff 32`
- `git diff --check b3a96113c8c15408a487352d5e38a7ec5d50c3ef 18d4af10d7c74fd8a736a4e839df8052f9c02900`

## Thread `019f83c2-4d93-7f91-b205-955f99879506`
updated_at: 2026-07-21T08:28:49+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T15-19-37-019f83c2-4d93-7f91-b205-955f99879506.jsonl
rollout_summary_file: 2026-07-21T08-19-36-jN8a-unread_migration_flag_ordering_adversarial_review.md

---
description: Read-only adversarial review of unread/unresponded migration and flag-ordering claims; main durable takeaway is that clear-write paths are flag-ungated but still ordering-guarded, while Step 0 legacy read_by backfill can overwrite live unread_by and makes "flag-on-first" unsafe without additional write-prep gating.
task: adversarial review of migrate-unread.ts claims and rollout ordering
 task_group: /Users/tualek/ohochat/script-oho + /Users/tualek/ohochat/oho-api
 task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: migrate-unread.ts, unread_by, is_unresponded, feature flags, ordering guards, read_by cleanup, secondaryPreferred, checkpoint, status file, analyze-business-size, computeBadgeCounts, channel-eligible-members, firebase-remote-config, master branch, read-only review
---

### Task 1: Verify/refute 13 migration and flag-order claims

task: adversarial code review of claims 1-13 against source
 task_group: /Users/tualek/ohochat/script-oho + /Users/tualek/ohochat/oho-api
 task_outcome: success

Preference signals:
- when the user said "Adversarial code review, READ-ONLY" and "Do not trust the draft findings file's claims at face value" -> do independent re-derivation from source, not agreement with the draft.
- when the user required "Every claim you make must cite file:line evidence you actually read" -> keep review citation-dense and grounded in direct source reads.
- when the user requested per-claim verdicts `CONFIRMED / PARTIALLY CORRECT / REFUTED / CANNOT VERIFY` -> preserve a structured itemized format for similar future reviews.

Reusable knowledge:
- `buildCustomerMessageUnreadPayload()` gates SET writes on flags, but clear writes remain unconditional and are still protected by `last_contact_date` / timestamp ordering guards.
- `migrate-unread.ts` Step 0 legacy `read_by` conversion can recompute or unset `unread_by` from stale legacy state and can therefore conflict with live writes if run in the wrong order.
- `script-oho`'s migration/checkpoint model is stateful: checkpoint membership, status totals, and cleanup eligibility are separate artifacts and should not be conflated.
- The current `oho-api` master schema and runtime code are the truth source, not the checked-out `script-oho` worktree or a prior draft findings file.

Failures and how to do differently:
- Do not collapse "ungated by feature flag" into "unguarded"; the runtime clear paths still use ordering guards.
- Be conservative about claims that depend on live production state (e.g. whether an index exists in prod) unless an explicit artifact verifies it.
- Flag-on-first is unsafe when legacy backfill can still overwrite live `unread_by` from `read_by`.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:1-84, 108-183, 356-464, 588-966, 971-1168, 1190-1437, 1441-1671, 1679-1879, 1888-2328`
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38`
- `oho-api@master:src/utils/build-clear-unread-unresponded-payload.ts:17-33`
- `oho-api@master:src/webhook/stream.js:94-172`
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:634-686`
- `oho-api@master:src/services/member-send-message/bulk/bulk.class.js:171-208`
- `oho-api@master:src/services/bot-send-message/bot-send-message.hooks.js:540-576`
- `oho-api@master:src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-69`
- `oho-api@master:src/services/contact-send-message/contact-send-message.hooks.js:213-237`
- `oho-api@master:src/utils/channel-eligible-members.ts:10-38, 40-116`
- `oho-api@master:src/utils/compute-badge-counts.ts:32-95, 114-139`
- `oho-api@master:src/services/contact/helper-hook/convert-unread-unresponded-query.ts:29-84`
- `oho-api@master:src/models/contact.model.js:211-219, 638-664`
- `oho-api@master:src/models/chat-session.model.js:78-86, 128-152`
- `oho-api@master:src/firebase-remote-config.js:184-215`
- `script-oho/unread-unresponded/analyze-business-size.ts:47-65, 246-345`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:1-75`
- `script-oho/reports/migrate-unread-report-prod-gate-small-2026-07-08T14-33-49.md:45-58`

### Task 2: Decide migration/flag rollout ordering

task: determine whether to migrate before or after enabling flags
 task_group: migration ordering / rollout safety
 task_outcome: success

Preference signals:
- when the user asked for "the central question: is it safe to run the migration BEFORE turning the flags on?" -> answer with a concrete safe protocol, not just a generic risk summary.
- when the user asked to evaluate the "third option" `flag || field-exists` -> test that proposal against the actual guards and failure modes, rather than accepting it as a fix.
- when the user asked about per-tenant migrate-then-flip timing and cited per-business durations -> use the actual runtime spread when deciding whether a manual paired rollout is operationally realistic.

Reusable knowledge:
- The current code supports a stronger ordering than either pure flag-first or pure migrate-first: treat migration as write-prep, then enable public reads after the tenant is proven correct.
- The backfill can still rewrite live `unread_by` from stale `read_by`; that is the dominant reason flag-on-first is unsafe without more gating.
- `flag || field-exists` is not an ordering fix once the fields already exist; it mainly duplicates current clear-write behavior.
- A few long-running businesses mean "migrate then flip within minutes" is not an atomic safety boundary.

Failures and how to do differently:
- Do not reason only about state decay; also reason about live write races and about read/count-side exposure while the tenant is half-migrated.
- Cross-check both write paths and read/count paths together before recommending rollout order.

References:
- `oho-api@master:src/webhook/stream.js:127-172`
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:667-685`
- `oho-api@master:src/services/member-send-message/bulk/bulk.class.js:186-202`
- `oho-api@master:src/services/bot-send-message/bot-send-message.hooks.js:564-575`
- `oho-api@master:src/services/contact/helper-hook/convert-unread-unresponded-query.ts:29-84`
- `oho-api@master:src/utils/compute-badge-counts.ts:62-95`
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:28-38`
- `script-oho/unread-unresponded/migrate-unread.ts:393-464, 615-674, 733-791, 857-946, 971-1155, 1215-1257, 1394-1420, 1546-1560, 2012-2177`
- `script-oho/reports/migrate-unread-report-prod-gate-small-2026-07-08T14-33-49.md:45-58`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:1-75`

### Task 3: Surface missed bugs/races/operational hazards

task: identify hazards not in the draft findings
 task_group: migration correctness / ops review
 task_outcome: success

Preference signals:
- when the user asked for "What the Claude agents missed" -> prioritize latent correctness and operational hazards over the obvious claim-by-claim verdicts.
- when the user called this the "highest-value section" -> spend review effort on cross-cutting issues such as checkpoint semantics, stale reads, and drift between producer/consumer artifacts.

Reusable knowledge:
- `secondaryPreferred` reads can make migration/reconcile think a guarded write did not happen, while the code may still checkpoint the business.
- Cleanup uses a fresh runtime view of complete channels and checkpoint membership, so a business/channel snapshot can drift between backfill and cleanup.
- Status writes are atomic-renamed, but checkpoint writes are direct and parse errors degrade to empty-set restart behavior.
- The monitor and migration report schemas are already out of sync; shared step definitions should be reused if the tool remains maintained.

Failures and how to do differently:
- Treat intent counters as intent, not proof of successful mutation.
- Checkpoint files and status files have different durability properties; do not assume both are equally safe.
- If a migration script reuses live runtime lookup logic, long-running per-business windows can introduce stale eligibility drift even without a direct write race.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:1441-1459, 1465-1535, 1660-1671, 1704-1739, 1793-1868, 2012-2177, 2248-2309`
- `script-oho/unread-unresponded/analyze-business-size.ts:151-165, 246-345, 417-442`
- `script-oho/unread-unresponded/monitor-migrate-unread.ts:78-176`
- `script-oho/unread-unresponded/helpers/biz-summary.ts:1-72`
- `script-oho/unread-unresponded/helpers/classify-is-unresponded.ts:31-52`
- `oho-api@master:src/utils/channel-eligible-members.ts:59-93`
- `oho-api@master:src/firebase-remote-config.js:19-70`

### Task 4: Rank script improvements

task: propose CLI, dry-run, confirmation, split, dedup, observability changes
 task_group: migration tooling / rollout hardening
 task_outcome: success

Preference signals:
- when the user asked for a ranked improvement plan with CLI ergonomics, dry-run default, confirmation banner, file split, deduplication, and observability -> keep P0/P1/P2 separation and recommend what is required before prod.
- when the user asked whether a file split is worth it for a one-shot migration script -> do not over-engineer into a large module split right before a prod run; prefer a minimal extraction if any.

Reusable knowledge:
- `package.json` exposes `migrate:unread`, `migrate:unread:cleanup-read-by`, `monitor:unread`, and `analyze:business-size`; `ecosystem.config.js` hard-codes `NODE_ENV: "prod"` and PM2 restart behavior.
- The current runbook is local/ignored and uses `db.chat_sessions` even though the model collection name is `chat-sessions`.
- Mongoose defaults to `autoIndex:true` unless configuration disables it, so model-init index creation can happen unless deployment config says otherwise.
- Migration, analysis, and monitor output have step-label drift; one shared step-definition source would reduce that.

Failures and how to do differently:
- A full `config / db / passes/* / runner / state / reporting` split is likely too much before a one-shot production run; the high-risk surface is ordering/state, not file count.
- Dry-run defaults must fail closed and require explicit scope and confirmation tied to the actual target DB/host, not just a generic env label.
- Index readiness should be verified explicitly rather than assumed from boot behavior.

References:
- `script-oho/package.json:8-11`
- `script-oho/ecosystem.config.js:1-77`
- `script-oho/unread-unresponded/migrate-unread.ts:1888-2328`
- `script-oho/unread-unresponded/analyze-business-size.ts:1-450`
- `script-oho/unread-unresponded/monitor-migrate-unread.ts:1-230`
- `script-oho/unread-unresponded/helpers/biz-summary.ts:1-72`
- `script-oho/unread-unresponded-deploy-runbook.md:24-183`
- `oho-api@master:src/mongoose_connector.js:12-21, 72-87, 117-120`
- `node_modules/mongoose/lib/index.js:66-71, 196-198`
- `node_modules/mongoose/lib/model.js:1304-1316`

## Thread `019f8412-1e0f-7e93-b5dd-807abd10d7d0`
updated_at: 2026-07-21T09:58:39+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl
rollout_summary_file: 2026-07-21T09-46-47-Fnuo-script_oho_catchup_adversarial_review.md

---
description: Adversarial read-only review of a proposed script-oho catchup mitigation against oho-api@master; key takeaway is that exact reconstruction is not possible from current live inputs, catchup needs stronger guards and likely a best-effort/baseline framing rather than a ship-ready exact repair.
task: review proposed catchup mitigation for unread_by / is_unresponded
 task_group: /Users/tualek/ohochat/script-oho
 task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: script-oho, unread-unresponded, migrate-unread.ts, catchup, unread_by, is_unresponded, oho-api@master, Stream read state, last_contact_date, last_active_at, feature flags, queryChannels, maxTimeMS, checkpoint, guardMisses, overCap, streamMissing, adversarial review
---

### Task 1: Review proposed catchup mitigation

task: adversarial read-only design review of proposed `--mode=catchup --since=<watermark>` mitigation

task_group: /Users/tualek/ohochat/script-oho

task_outcome: partial

Preference signals:
- when the user says `Design review, READ-ONLY, adversarial. Do NOT edit files. Do NOT run the migration or anything that connects to a database. Do NOT commit or switch branches.` -> future similar reviews should stay strictly read-only and non-invasive
- when the user asks for `file:line evidence` for every answer and says `If evidence is not in the repo, say 'cannot verify from repo' rather than guessing` -> future similar reviews should default to hard citations and explicit uncertainty
- when the user asks for `Answer EACH question below` and wants a final verdict on whether the mitigation is `sound enough to ship` -> future similar reviews should stay structured, question-by-question, and end with an explicit ship/no-ship judgment

Reusable knowledge:
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` shows customer-message SET payloads are split by feature flags; `unread_by` is only written when unread is enabled and eligible members are known, and `is_unresponded` is only written when unresponded is enabled.
- `oho-api@master:src/utils/channel-eligible-members.ts:12-18,59-93` shows the runtime cap is 2000 eligible members; above cap it returns `null` and skips unread tracking entirely.
- `oho-api@master:src/webhook/stream.js:94-149` shows Stream `message.read` only `$pull`s unread_by and uses a `last_contact_date` ordering guard; it does not advance timestamps.
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:661-685`, `src/services/member-send-message/bulk/bulk.class.js:186-202`, `src/services/chat-session/group/member/send-message/send-message.hooks.js:419-428`, `src/services/chat-session/group/bot/send-message/internal/internal.class.js:24-35`, and `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-68` show the main CLEAR paths are unconditional CLEARs with timestamp guards.
- `script-oho/unread-unresponded/migrate-unread.ts:2244-2447` defines catchup as an unconditional recompute over docs touched since `--since`, using Stream read state plus `classifyIsUnresponded()` and write guards on only `last_contact_date`/`last_active_at`.
- `script-oho/unread-unresponded/helpers/steps.ts:129-140` defines the proposed catchup watermark as `last_contact_date >= since OR last_active_at >= since`.
- `script-oho/unread-unresponded/helpers/migration-cli.ts:476-480` rejects catchup without `--include-stream`, and `:502-507` gives catchup its own state-file suffix so it cannot be mistaken for backfill.
- `script-oho/unread-unresponded/migrate-unread.ts:2391-2403` shows the actual catchup write guard only checks `_id`, `last_contact_date`, and `last_active_at`, which is insufficient for exact reconstruction under concurrent live writes.
- `script-oho/unread-unresponded/migrate-unread.ts:2724-2743` shows completion in catchup depends on guard/skip counters, not a read-only residual scan like backfill.

Failures and how to do differently:
- The proposed catchup is not an exact repair because it recomputes from current eligibility and Stream state rather than from a historical event log; this can retroactively change unread state for members whose permissions changed during the window.
- `classifyIsUnresponded()` is not a faithful live state-machine clone; customer messages can leave `chat_status` stale, and CLEARs occur independently of the feature flag, so the classifier can flip state incorrectly.
- The catchup watermark is not sufficient to find every doc whose badge state can change, because several CLEAR paths do not advance either `last_contact_date` or `last_active_at`.
- Group `is_unresponded` is omitted by the current catchup pass, so the proposal as written is incomplete even before correctness/race issues.
- Over-cap / missing-Stream docs should be treated as explicit exclusions or separate repair classes, not silently counted as success.
- Aggregate numeric completion checks (`guardMisses/overCap/streamMissing`) are too weak for a busy large tenant; future work should use identity-based retry/residual verification or explicitly frame the pass as best effort.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:568-624` — unread_by derivation from Stream read state + current eligible members.
- `script-oho/unread-unresponded/migrate-unread.ts:2354-2434` — catchup pass, skip logic, and guarded write shape.
- `script-oho/unread-unresponded/migrate-unread.ts:2488-2499` — group sessions are unread_by-only in catchup; no `is_unresponded` repair.
- `script-oho/unread-unresponded/migrate-unread.ts:2724-2743` — catchup completion criteria.
- `oho-api@master:src/services/contact-send-message/contact-send-message.hooks.js:157-236` and `oho-api@master:src/services/chat-session/group/contact-user/send-message/send-message.class.js:19-36` — customer-message SET paths.
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:661-685`, `src/services/member-send-message/bulk/bulk.class.js:186-202`, `src/services/chat-session/group/member/send-message/send-message.hooks.js:419-428`, `src/services/chat-session/group/bot/send-message/internal/internal.class.js:24-35`, `src/services/bot-send-message/broadcast/broadcast.hooks.js:320-330`, `src/services/bot-send-message/notify/notify.hooks.js:527-537`, `src/services/bot-send-message/inform-message/inform-message.hooks.js:418-428`, `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-68` — CLEAR paths.

### Task 2: Assess scale/index/completion feasibility

task: review 5-6M scale, query-plan risk, `maxTimeMS`, and completion criteria for the proposed catchup/backfill flow

task_group: /Users/tualek/ohochat/script-oho

task_outcome: partial

Preference signals:
- when the user asks `assess the query plan risk ... what index/paging change would make 5-6M feasible` -> future similar reviews should include concrete index/paging recommendations, not just risk commentary
- when the user asks whether the tightened completion criteria are satisfiable on a busy large tenant -> future similar reviews should include an operational realism check, not just logical correctness

Reusable knowledge:
- `script-oho/unread-unresponded/migrate-unread.ts:185-198` centralizes paged reads through `_id` sort plus `maxTimeMS=QUERY_MAX_TIME_MS`.
- `oho-api@master:src/models/contact.model.js:429-432,562-565,632-665` shows the relevant contact indexes, but none naturally matches `_id`-sorted pagination over the catchup OR predicate.
- `oho-api@master:src/models/chat-session.model.js:109-152` shows similar limitations for group sessions.
- `script-oho/unread-unresponded/migrate-unread.ts:2332-2434` shows Stream pacing (`STREAM_QUERY_BATCH=30`, `STREAM_DELAY_MS=300`) and write throttling.
- `script-oho/unread-unresponded/migrate-unread.ts:2788-2849` writes a catchup report; `:2421-2433` emits per-batch heartbeat metrics.

Failures and how to do differently:
- `maxTimeMS` is a failure shield, not a scalability fix. If the plan is not indexable, a 60s timeout simply turns the issue into a hard stop.
- Aggregate completion criteria are too weak for large busy tenants; identity-based residuals or explicit best-effort framing are needed when Stream state, eligibility, and timestamps can diverge.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:185-198` — paged read helper.
- `oho-api@master:src/models/contact.model.js:429-432,562-565,632-665` — contact indexes.
- `oho-api@master:src/models/chat-session.model.js:109-152` — chat-session indexes.
- `script-oho/unread-unresponded/migrate-unread.ts:2332-2434` — catchup pacing.
- `script-oho/unread-unresponded/migrate-unread.ts:2724-2743` and `:3142-3160` — completion criteria and residual checks.

## Thread `019f8442-2665-7082-a710-f24709dca055`
updated_at: 2026-07-21T10:51:30+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl
rollout_summary_file: 2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md

---
description: third-pass read-only review of unread/unresponded migration; decided Option A (backfill unread_by only, leave is_unresponded absent), with follow-on plan to remove unresponded migration paths and use explain-based preflight plus minimal indexing
task: third-and-final-review-pass-on-mongodb-migration
task_group: /Users/tualek/ohochat/script-oho / migrate-unread correctness review
task_outcome: success
cwd: /Users/tualek/ohochat/script-oho
keywords: migrate-unread, unread_by, is_unresponded, option A, explain preflight, hint, checkpoint v3, residual IDs, group index, chat-sessions, fail-closed CLI, read-only review
---

### Task 1: Decide whether to backfill `is_unresponded`

task: third-pass source audit of `oho-api@master` and `script-oho/unread-unresponded` for whether `is_unresponded` can be reconstructed

task_group: /Users/tualek/ohochat/oho-api + /Users/tualek/ohochat/script-oho migration review
task_outcome: success

Preference signals:
- when the user said “do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns” -> future similar reviews should converge to one choice and avoid handing back a concern list
- when the user required “Verify every factual claim in the brief against source before relying on it” and “cite file:line for each load-bearing claim” -> future similar work should default to line-cited proof and explicitly say “cannot verify from repo” when proof is missing
- when the user said “If you must assume, name the assumption” -> future plans should separate evidence from assumptions instead of blending them into conclusions

Reusable knowledge:
- Contact customer-message handling writes `last_active_at` and `last_contact_date` via separate guarded updates; same-timestamp behavior is normal but not an invariant.
- `chat_status` is not a reliable historical reply classifier because it conflates customer-message fallback and bot fallback cases.
- The inbox send path is a known asymmetry: it advances `last_active_at` but does not clear `is_unresponded`.
- The safest migration policy from the audited source is to leave historical `is_unresponded` absent rather than infer it.

Failures and how to do differently:
- The brief’s timestamp-classifier draft relied on insufficient provenance; future runs should reject heuristics unless the repo exposes a true reply ledger.
- Do not assume the migration is the only actor affecting user-visible state; clear paths remain unconditional when the field exists.

References:
- `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:164-167, 230-237`
- `oho-api/src/services/chat-session/group/contact-user/send-message/send-message.class.js:19-36`
- `oho-api/src/utils/update-contact-last-active-at.js:12-19`
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:634-686`
- `oho-api/src/services/bot-send-message/bot-send-message.hooks.js:540-576`
- `oho-api/src/utils/build-customer-message-unread-payload.ts:24-38`
- `oho-api/src/models/contact.model.js:211-219`
- `oho-api/src/models/chat-session.model.js:78-86`

### Task 2: Decide classifier / filter shape

task: determine whether a pure classifier or Mongo filter should be used for `is_unresponded`

task_group: migration design review
task_outcome: success

Preference signals:
- when the user asked for “the final classifier rule, as a pure function and as a Mongo filter” but the audit concluded the honest answer was that the classifier should not exist -> future similar reviews should answer “not applicable” when the evidence says the feature should be omitted
- when the user asked to “Attack the draft above” -> future similar work should actively reject unsafe heuristics rather than merely weakening them

Reusable knowledge:
- `first_chat_at` can exclude contacts that never messaged, but it does not prove whether later activity was a reply.
- `assigned_at` was unsafe because the contact schema uses `assign_at`, not a top-level `assigned_at`; whether historical documents persisted an undeclared top-level `assigned_at` could not be verified from the repo.
- Timestamp tolerance increases false matches rather than fixing the ambiguity.

Failures and how to do differently:
- A timestamp-based heuristic can misclassify assignment/status/comment/spam actions as replies.
- The migration CLI still exposes unresponded passes unless the operator explicitly skips them; relying only on an opt-out flag is weaker than deleting the path.

References:
- `script-oho/unread-unresponded/helpers/migration-cli.ts:479-485`
- `oho-api/src/models/contact.model.js:154-164, 185-188`

### Task 3: Decide index and paging strategy

task: adjudicate contact vs group indexing and paging preflight for the migration
task_group: migration execution hardening
task_outcome: success

Preference signals:
- when the user asked to “Adjudicate the index/paging disagreement” and “Give one answer” -> future similar decisions should pick one side and tie it to a concrete preflight rule
- when the user insisted the checked-out tree is stale and `oho-api@master` is the source of truth -> future similar repo decisions should trust branch `master` evidence, not the working tree

Reusable knowledge:
- `pagedFind()` currently does keyset pagination on `_id` but does not use `hint()` or `explain()`.
- Contacts already have a `business_id + _id` index on `master`; group sessions do not have the needed `_id`-ordered index for this migration path.
- The explain-based preflight should refuse execution if the plan is a collection scan or blocking sort.

Failures and how to do differently:
- It is not enough to say a plan is “probably fine”; the rollout only accepted the plan after tying it to concrete index declarations and a fail-closed explain check.
- The residual-count logic can numerically cancel unrelated documents, so “done” must be exact-ID based rather than aggregate-count based.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:177-190, 238-250`
- `oho-api/src/models/contact.model.js:621-624`
- `oho-api/src/models/chat-session.model.js:109-137`

### Task 4: Produce an ordered production plan

task: write one ordered plan from current state to production rollout completion
task_group: migration runbook / production readiness
task_outcome: success

Preference signals:
- when the user required “one ordered plan” including dependencies, parallelism, and explicit human decisions -> future similar plans should be sequenced, not freeform
- when the user’s rollout shape already agreed on per-tenant migration followed by immediate tenant flag-on -> future plans should preserve that operational sequencing unless the user changes it

Reusable knowledge:
- The current code already has a separate `cleanup-read-by` mode that is gated by checkpoint membership and dedicated confirmation.
- The CLI is fail-closed: `.env.<env>` selection, a matching `--confirm`, and explicit `--execute` are required.
- Production rollout should only proceed after explicit database authorization and explain/index verification.

Failures and how to do differently:
- Current checkpoint/residual logic is count-based in places where exact identity is safer; exact ID tracking should be a prerequisite, not an optional enhancement.
- The old status file’s cumulative counters cannot be trusted as per-tenant proof; treat them as advisory until exact IDs are reconciled.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:2084-2112, 2126-2134`
- `script-oho/unread-unresponded/helpers/migration-cli.ts:321-334, 401-412`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69`

### Task 5: Identify incorrect or missing claims

task: final pass over the brief for overstated claims and missing constraints
task_group: evidence audit / postmortem
task_outcome: success

Preference signals:
- when the user asked for “Anything in the above you believe is still wrong or missing” -> future similar reports should explicitly enumerate corrections and not just provide the main answer
- when the user demanded evidence-dense language and “cannot verify from repo” rather than guessing -> future similar reports should keep uncertainty visible

Reusable knowledge:
- The inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that turns on the unresponded flag must either accept that false-positive path or defer the feature until API behavior changes.
- The old status file proves a prior run happened, but not that the named three tenants each received the cumulative `s0a` total.
- External operational facts, production state, and retention assumptions should not be encoded as repo facts.

Failures and how to do differently:
- Do not treat cumulative counts as proof of per-tenant effect unless the artifact explicitly preserves per-tenant attribution.
- Do not convert assumptions about production state into assertions about the codebase.

References:
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:143-159`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69`

### Task 6: Final plan synthesis

task: synthesize final production plan from source audit and migration code review
task_group: migration readiness / final recommendation
task_outcome: success

Preference signals:
- the user required the final output to be machine-consumed and terse, so future similar syntheses should remain compact, decision-oriented, and citation-heavy
- the user wanted the rollout shaped as a per-tenant migration with immediate tenant flag enablement, not a catchup mode

Reusable knowledge:
- Keep `is_unresponded` absent; do not backfill it.
- Use explain-based preflight and a minimal group index rather than broad new contact indexes.
- Treat guard misses, Stream-missing docs, over-cap docs, and residual counts as exact-ID reconciliation problems, not just counters.
- `read_by` cleanup remains a separate gated mode to run after the main rollout.

Failures and how to do differently:
- The old status file could not cleanly attribute its cumulative numbers to the named tenants, so future rollouts should not use it as proof of tenant-specific writes.
- There is a known inbox-send asymmetry that may require product-owner acceptance before enabling `is_unresponded`-related behavior.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:730-735, 884-888, 1024-1057, 1406-1469, 1729-1734`
- `oho-api/src/utils/channel-eligible-members.ts:28-35, 78-92`
- `oho-api/src/models/chat-session.model.js:109-137`
- `oho-api/src/models/contact.model.js:621-624`
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:143-159`

## Thread `019f8a65-96f5-7a71-a99e-19040bdcad19`
updated_at: 2026-07-22T15:22:38+00:00
cwd: /Users/tualek/ohochat/oho-webhook
rollout_path: /Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-15-41-019f8a65-96f5-7a71-a99e-19040bdcad19.jsonl
rollout_summary_file: 2026-07-22T15-15-41-t20F-oho_api_member_send_message_locking_retry_review.md

---
description: Read-only source review of six `member-send-message` performance/locking claims in `oho-api`; confirmed lock/retry/axios/reference_id behaviors, found dead 429 retry branches, and identified early-ack redesign hazards plus safe backgroundable hooks.
task: verify claims about member-send-message performance/locking behavior with exact file:line evidence
task_group: /Users/tualek/ohochat/oho-api read-only code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: oho-api, member-send-message, redlock, retry-backoff, axios timeout, StreamChat, reference_id, early-ack, socket-reconcile, chat_session lock, code review
---

### Task 1: Verify six claims about `member-send-message` internals and produce redesign risk review

task: read-only verification of six claims about member-send-message locking, retries, timeouts, Stream retries, after-hook dependencies, and reference_id propagation
task_group: oho-api code review / performance + correctness
task_outcome: success

Preference signals:
- when the user said "read the actual source code" and "precision matters — every verdict must cite exact file:line evidence from the real code, not inference" -> future similar reviews should stay strictly evidence-backed and cite exact lines.
- when the user said "Do not modify any code — this is a read-only verification and review task" -> keep similar tasks read-only and avoid opportunistic fixes.
- when the user asked for claim verdicts plus an independent "second-reviewer opinion" and "Top 3 highest-impact, lowest-risk changes" -> structure future review output as verdicts plus a separate risk/mitigation section.
- when the user asked to trace whether `reference_id` reaches Stream and/or the API response -> verify correlation IDs end to end rather than assuming they propagate.

Reusable knowledge:
- `member-send-message` acquires `contact:$1:chat_session` in the before-hook and releases only in after/error hooks, so platform/Stream work sits inside the lock window unless hook order changes.
- The lock auto-extension timer is 200ms, but extension happens only when the lock is close to expiry; `LOCK_MS` is 3000ms and `LOCK_EXTEND_GAP_MS` is 1000ms.
- Other `contact:$1:chat_session` users include member assignment, bot assignment, member respond, and close-chat actions; `active-case` / `case` create flows use `contact:$1:active_case` instead.
- `shouldRetryOnFacebookTooManyRequests`, `shouldRetryOnInstagramTooManyRequests`, and `shouldRetryOnLineTooManyRequests` each contain a dead later `else if (status === 429)` branch because the first `if` already returns false on 429.
- `createAxiosApi()` defaults to `timeout: 60000`, so omitted per-call timeouts are still bounded to 60s.
- `callWithStreamChatRetry()` uses `maxRetry: 5` with exponential backoff from 5000ms, yielding delays of 5s, 10s, 20s, 40s, 80s (155s total backoff) and 6 total attempts.
- `reference_id` is accepted by the schema and preserved in final API responses, but it is not forwarded into the Stream payload in this snapshot.

Failures and how to do differently:
- The initial claim wording about redlock extension cadence was too strong; use the actual timer/threshold behavior from `resource-lock.js`.
- The LINE timeout claim needed correction: there is no explicit timeout at the call site, but the shared axios instance still enforces 60s.
- For worst-case latency, compute both per-bubble retry cost and the total across sequential bubbles because the hook uses `mapSeries`.

References:
- `src/services/member-send-message/member-send-message.hooks.js:1252-1307, 1313`
- `src/hooks/lock-resource.js:48-105`
- `src/utils/resource-lock.js:7-34`
- `src/services/contact/member-assign/self/self.hooks.js:841`, `src/services/contact/member-assign/team/team.hooks.js:1318`, `src/services/contact/member-assign/member/member.hooks.js:1202`, `src/services/contact/close-chat/no-case/no-case.hooks.js:433`, `src/services/contact/close-chat/end-case/end-case.hooks.js:453`, `src/services/contact/bot-assign/request/request.hooks.js:685`, `src/services/contact/bot-assign/team/team.hooks.js:777`, `src/services/contact/bot-assign/member/member.hooks.js:670`, `src/services/contact/member-respond/reject/reject.hooks.js:590`, `src/services/contact/member-respond/accept/accept.hooks.js:629`, `src/services/contact/member-respond/cancel/cancel.hooks.js:625`
- `src/utils/retry-backoff.js:117-183, 206-245, 296-305`
- `src/utils/axios.js:6-14, 94-99`
- `src/services/integration/facebook/reply-message/reply-message.class.js:30-35`
- `src/services/integration/instagram/reply-message/reply-message.class.js:30-35`
- `src/services/member-send-message/member-send-message.class.js:177-192`
- `src/services/member-send-message/member-send-message.hooks.js:537-670, 673-707, 1008-1043, 1178-1230`
- `src/utils/message-converter/validator-youpin.js:73-105`
- `src/utils/message-converter/youpin-to-stream.js:32-320`
- `src/services/member-send-message/member-send-message.hooks.spec.js:693-837`
- `src/utils/get-error-message-send-message-fail.js:142-156`
- `src/services/member-send-message/bulk/bulk.hooks.js:139-169, 649-655`
- `src/services/member-send-message/member-send-message.class.js:98-171, 239-276, 286-337`
- `src/hooks/send-oho-webhook-events.js:71-106, 333-420`
- `src/services/business/hooks/update-last-active-at.js:5-33`
- `src/utils/hooks/promise-all.js:1-8`
- `src/sdk/streamChat.js:12-14, 55-67`

## Thread `019f8a8e-191c-7740-8373-583d8f41643f`
updated_at: 2026-07-22T16:09:45+00:00
cwd: /Users/tualek/ohochat/oho-webhook
rollout_path: /Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-59-56-019f8a8e-191c-7740-8373-583d8f41643f.jsonl
rollout_summary_file: 2026-07-22T15-59-56-ExfV-blind_audit_send_message_webhook_oho_api_webhook.md

---
description: Blind source-code audit of oho-api and oho-webhook send-message/webhook flows; captured exhaustive call-chain tracing, retry/timeout arithmetic, sibling-path deltas, and several correctness risks (dedup/retry, swallowed Cloud Tasks failures, unreachable retry branches, ack-before-work patterns).
task: blind audit of send-message flows and webhook receipt/worker paths across oho-api and oho-webhook
task_group: source-code-audit / send-message-webhook-flows
task_outcome: success
cwd: /Users/tualek/ohochat/oho-webhook
keywords: oho-api, oho-webhook, member-send-message, Facebook webhook, LINE webhook, Cloud Tasks, Redlock, Redis dedup, retry-backoff, axios timeout, Stream Chat, bulk send, partner send-message, contact-send-message, bot-send-message, inform-message, tiktok, correctness bugs, silent drop, duplicate message
---

### Task 1: oho-api outbound send-message flows

task: blind audit of /member-send-message plus sibling send paths in oho-api
task_group: oho-api send-message audit
task_outcome: success

Preference signals:
- when the user said "Independent BLIND audit" and "Do NOT read any *.md report/plan files", treat the audit as source-only and avoid any documentation or prior-plan contamination.
- when the user said "Exhaustively inventory" and "Before finalizing, grep for every awaited call", run a completeness sweep over async primitives before closing out.
- when the user required file:line citations for every claim, keep evidence anchored to exact lines in the source tree.

Reusable knowledge:
- `/member-send-message` validates `messages.max(25)` and acquires a Redlock on `contact:$1:chat_session` via `data.contact_id`.
- Lock TTL is 3s and the extension gap is 1s; the same lock serializes member assignment, bot assignment, accept/reject/cancel, close-chat, and `/member-send-message`.
- Facebook/Instagram integration services use `axios.create({ timeout: 60000 })` and the shared retry wrappers, but the 429 retry branches are unreachable; effectively the outer service gets one 60s attempt plus wrapper overhead.
- LINE outbound in the main member-send path is chunked by 5, processed serially, and retries only ECONNRESET via the shared wrapper; worst-case per chunk is `4*60 + 7 = 247s`.
- TikTok send path uploads image media first (timeout 60s, concurrency 5), then sends messages serially; failed uploads fall back to sending without `tiktok_media_id`.
- Stream Chat send calls use `callWithStreamChatRetry` (`maxRetry: 5`, exponential starting at 5s), so a single Stream call can contribute `6*60 + 155 = 515s` worst-case.

Failures and how to do differently:
- Some helper code swallows errors and returns partial success objects; future audits should check whether downstream hooks ever see the error or only `{ok:false}`.
- The repo contains several overlapping send paths with similar names; future retrieval should key off route file + service file, not just the service name.

References:
- `src/services/member-send-message/member-send-message.hooks.js:1243-1317` — before/after/error hook chain.
- `src/services/member-send-message/member-send-message.class.js:37-339` — platform dispatch and helpers.
- `src/utils/retry-backoff.js:296-360`, `src/utils/axios.js:6-16` — retry and Axios defaults.
- `src/hooks/lock-resource.js:43-105`, `src/utils/resource-lock.js:7-13` — lock key pattern and TTL.
- `src/services/integration/facebook/reply-message/reply-message.class.js:20-50`, `src/services/integration/instagram/reply-message/reply-message.class.js:20-50`, `src/utils/api/tiktok.js:68-72`, `src/services/channel/utils/tiktok.js:131-217` — platform-specific integrations.

### Task 2: oho-webhook inbound receipt, worker chains, and retry/dedup paths

task: blind audit of Facebook/LINE webhook receipt and worker chain in oho-webhook
task_group: webhook audit
task_outcome: success

Preference signals:
- when the user asked for "platform webhook receipt -> ack" and Cloud Tasks worker tracing, start from controller ACK timing and follow through the worker chain.
- when the user said to "state the ambiguity explicitly", treat dynamic config/feature-flag branches as open questions only if they cannot be resolved from code.
- when the user required completeness, end with a final async-primitive sweep to make sure every implementation file is represented.

Reusable knowledge:
- Facebook controller writes source-message metrics, resolves external-app whitelist caches, optionally inserts Cloud Tasks, and can bypass queueing when `USE_QUEUE !== 1`.
- Facebook worker `handleWebhook` processes entries in `Promise.all`, and errors are turned into HTTP 200 to force Cloud Tasks completion.
- Facebook dedup is Redis-based and non-atomic (`get` then `setEx`), so concurrent workers can both pass the check; retry tasks can also be dropped as duplicates if they reuse the same key.
- LINE controller can route through Cloud Tasks or direct worker mode depending on `USE_QUEUE` and `isThrottled`; worker verification and event processing are parallelized over `events[]`.
- LINE manual retry scheduling composes RMQ and DLQ delays into `330,125s` total scheduled delay (about `91h 42m 5s`) based on the inspected arrays.
- `send-oho-webhook-events` is intentionally detached, uses a 3s Axios timeout, and is observability-only.

Failures and how to do differently:
- Some helper failures are swallowed and replaced by 200 responses; future audits should distinguish intended "force completion" from accidental loss of durability.
- Webhook worker chains contain detached helpers (e.g. forwarding, some state updates); future audits should explicitly mark whether a helper is awaited and whether its failure is user-visible.

References:
- `src/controllers/facebook/facebook.controller.ts:47-245`, `:247-413` — Facebook receipt + worker.
- `src/controllers/line/line.controller.ts:38-346`, `src/controllers/line/handler.ts:1146-1347` — LINE receipt + worker.
- `src/controllers/facebook/block.ts:53-83`, `src/services/redis.service.ts:73-176` — Redis dedup implementation.
- `src/helpers/external-app-whitelist.ts:17-94`, `src/helpers/cached-channel-profile.ts:31-77` — whitelist cache path.
- `src/helpers/retry-message.ts:21-455` — retry queue scheduling.
- `src/helpers/send-oho-webhook-events.js:71-108` — detached outgoing webhook delivery.

### Task 3: sibling send-path divergence audit

task: compare bulk, bot-send-message, partner/send-message, partner-send-message, inform-message, and contact-send-message against main member-send-message
task_group: sibling send-path audit
task_outcome: success

Preference signals:
- when the user asked for "PART C" deltas only, compare against the main path and do not restate identical calls.
- when the user asked to tag deltas as "concrete risk or benign", separate correctness risk from harmless implementation differences.
- when the user asked for "one subsection per sibling flow", preserve route-by-route organization.

Reusable knowledge:
- `bulk` returns `{ok:true}` before all sends settle and does not use the main contact lock.
- `bot-send-message` and `inform-message` update contact state and log after/around sends, but LINE in `inform-message` does not use the main retry wrapper and Instagram/TikTok are unsupported there.
- `partner/send-message` is API-key authenticated, validates platform/messages, but does not re-check that the provided `business_id` matches the loaded contact business; it reuses the same platform integration helpers.
- `partner-send-message` is a separate legacy route that only writes to Stream Chat and does not call platform send helpers.
- `contact-send-message` updates contact state before Stream writes and swallows Stream failures; it also expands long texts into 5000-character chunks.

Failures and how to do differently:
- Legacy and new routes have similar names but very different semantics; future audits should identify them by file and route path to avoid mixing them up.
- Some sibling flows share helpers but differ in sequencing; future comparisons should focus on commit order and await placement, not just helper reuse.

References:
- `src/services/member-send-message/bulk/bulk.class.js:35-109`, `bulk.hooks.js:636-669` — bulk.
- `src/services/bot-send-message/bot-send-message.class.js:15-190`, `src/services/bot-send-message/bot-send-message.hooks.js:504-688` — bot-send-message.
- `src/services/partner/send-message/send-message.hooks.ts:39-480`, `send-message.class.ts:18-161` — partner/send-message.
- `src/services/partner-send-message/partner-send-message.class.js:1-69`, `partner-send-message.hooks.js:1-163` — legacy partner-send-message.
- `src/services/bot-send-message/inform-message/inform-message.class.js:18-133`, `inform-message.hooks.js:1-171` — inform-message.
- `src/services/contact-send-message/contact-send-message.class.js:20-67`, `contact-send-message.hooks.js:242-556` — contact-send-message.

## Thread `019f92b8-19b7-75b3-bdd9-8d9231dfb910`
updated_at: 2026-07-24T06:05:35+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-02-46-019f92b8-19b7-75b3-bdd9-8d9231dfb910.jsonl
rollout_summary_file: 2026-07-24T06-02-46-CTIY-realtime_badge_fix_adversarial_review_partial.md

description: Partial read-only review of OHO-1272 realtime unread/unresponded badge fix; live diff inspected but no final verdict was produced. Highest-value takeaways are strict evidence/read-only requirements, branch mismatch, and a possible count-state reset edge case.
task: adversarial code review of smartchat/websocket realtime badge diff
task_group: /Users/tualek/ohochat/oho-web-app realtime unread-unresponded badge review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
keywords: code-review, OHO-1272, smartchat, websocket, unread_count, unresponded_count, is_read_by_me, is_unresponded, DEFAULT_UPDATE_FIELDS, optimistic-flag-count-tracker, Vuex, Vue 2

### Task 1: Review realtime badge fix

task: trace realtime unread/unresponded badge update diff and identify confirmed defects
 task_group: frontend realtime badge review
 task_outcome: partial

Preference signals:
- The user said “Read the actual files, do not guess” and required file:line grounding -> future reviews should inspect the live worktree and cite exact evidence.
- The user requested a “read-only critical review” and prohibited edits, commits, and checkout -> do not modify the worktree during similar reviews.
- The user required a one-line verdict, issue headings, and a concise “Checked, no issue” section -> preserve that exact output shape.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` is at `store/modules/smartchat.js:719-760`; it gates `rt_unread_feature_enabled` and `rt_unresponded_feature_enabled`, maps `contact_id` to `_id`, injects badge fields, and dispatches `handleSmartchatRealtimeUpdate` with `DEFAULT_UPDATE_FIELDS` and `is_fetch_contact: !in_list`.
- `handleSmartchatRealtimeUpdate` matches by `_id` at `smartchat.js:779-783` and picks only requested fields at `:792`; `DEFAULT_UPDATE_FIELDS` contains `_id`, `is_unresponded`, and `is_read_by_me` (`constants/contact.js:3-28`).
- Count transitions use `resolveOptimisticFlagTransition` (`smartchat.js:826-873`; tracker `utils/optimistic-flag-count-tracker.js:25-40`) and list replacement/pagination reconcile the tracking Sets (`smartchat.js:70-147`).
- The four socket handlers preserve existing notifications and add badge dispatches at `store/modules/websocket.js:255-313`.

Failures and how to do differently:
- The requested branch was not active: live worktree branch was `tk-sprint-2615/develop`, while the user named `fix/oho-1272-unread-unresponded-realtime-badge`; `HEAD` and `origin/master` were both `619b6182`. Disclose this scope mismatch or stop before approval.
- The rollout ended without a final verdict, so the six review points were not fully verified. Do not treat the implementation as approved.
- Investigate `store/modules/smartchat.js:175-181`: `resetContactList` replaces `contact_list` with only `total`, `limit`, `skip`, and `data`, omitting `unread_count` and `unresponded_count` that exist in initial state at `:22-29`. This may create a Vue 2 reactivity/count reset edge case; it was not conclusively classified in this rollout.

References:
- `git -C /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge diff`
- `store/modules/smartchat.js:719-760, 779-873, 175-181`
- `store/modules/websocket.js:255-313`
- `constants/contact.js:3-28`
- `utils/optimistic-flag-count-tracker.js:25-40, 42-76`

## Thread `019f92d6-2878-7423-a00f-1e523deebd71`
updated_at: 2026-07-24T06:40:00+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-35-36-019f92d6-2878-7423-a00f-1e523deebd71.jsonl
rollout_summary_file: 2026-07-24T06-35-36-jLZD-oho_1272_realtime_badge_read_only_review.md

---
description: Read-only adversarial review of Vue 2/Vuex realtime unread/unresponded badge fix; found fetch-merge badge/count desync and unconditional no-op dispatches
task: review OHO-1272 realtime chat-list badge diff
 task_group: frontend realtime badge code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
keywords: Vue 2, Vuex, smartchat, realtime, unread_count, unresponded_count, reconcile Set, DEFAULT_UPDATE_FIELDS, feature flags, code review
---

### Task 1: Review OHO-1272 realtime badge fix

task: adversarial read-only review of realtime unread/unresponded badge patch
task_group: frontend realtime badge code review
task_outcome: success

Preference signals:
- The user said “do not modify any files — review only” and requested “real defects, not style nits” -> similar reviews should stay read-only and focus on correctness defects.
- The user requested six yes/no verdicts with `file:line` evidence and a final `VERDICT: LGTM` or issue count under ~400 words -> use a compact evidence-first review format.

Reusable knowledge:
- Existing-room repeated events do not double-count because `resolveOptimisticFlagTransition` consults the reconciliation Sets and prior row state (`store/modules/smartchat.js:826-873`).
- New-room processing updates aggregate counts/Set before fetching complete contact data; merging `res.data[0]` afterward can overwrite the injected `is_unresponded`/`is_read_by_me` values, leaving the row inconsistent with counters (`store/modules/smartchat.js:927-940`). Fix by reapplying injected badge fields after the fetch merge or otherwise preserving them.
- Both feature flags independently gate badge injection (`store/modules/smartchat.js:723-739`), but all four websocket handlers still dispatch the helper (`store/modules/websocket.js:267,282,296,311`). The helper returns before nested work when no badge is enabled, so external state is unchanged, but this is not literal byte-for-byte behavior; an outer feature-flag guard would eliminate the no-op dispatches.
- `DEFAULT_UPDATE_FIELDS` excludes documented raw socket keys such as `business_id`, `contact_id`, `preview_message`, `platform`, `contact_name`, `channel_id`, `channel_name`, `contact_image_url`, and `is_team_notification`; only selected fields plus injected `_id` and badge fields are merged (`constants/contact.js:3-28`, `smartchat.js:744-757,792`).
- `_id: contact_id` matches the existing row key and is used consistently for fetch, route/current-contact, and removal paths (`smartchat.js:779-783,930-933,947-963,1018-1023`).
- Missing `updated_at` was not shown to cause a material defect for deterministic badge assertions; exact `skipUpdateChatRoom` behavior was outside the permitted source scope.
- For a new room under an active filter, the action refetches the filtered list rather than directly inserting; nonmatching rooms are omitted (`smartchat.js:965-1007`).

Failures and how to do differently:
- Do not assume that “counts are updated through the shared action” guarantees row/count consistency: inspect later fetch merges for overwrites.
- Distinguish semantic no-op behavior from literal byte-for-byte behavior: an unconditional Vuex dispatch still differs even if the helper immediately returns.

References:
- Diff path: `/private/tmp/claude-501/-Users-tualek-ohochat/e09208f3-facf-4303-8b26-c1c18904dc1b/scratchpad/oho1272.diff`
- Worktree: `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge`
- Key evidence: `smartchat.js:826-873`, `927-940`, `965-1007`; `websocket.js:267,282,296,311`; `constants/contact.js:3-28`

## Thread `019f9319-959c-7630-8f42-e17b70c0d6ef`
updated_at: 2026-07-24T07:53:27+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T14-49-15-019f9319-959c-7630-8f42-e17b70c0d6ef.jsonl
rollout_summary_file: 2026-07-24T07-49-15-1jYz-vue2_realtime_badge_recheck_four_issues.md

description: Read-only adversarial re-review of Vue 2/Vuex realtime unread/unresponded badge fix; found synthetic-timestamp false unread, pre-fetch aggregate drift, incomplete/blocked new-room handling, and stale unresponded reassertion.
task: review realtime unread and unresponded badge fix
task_group: /Users/tualek/ohochat/oho-web-app frontend review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Vue2, Vuex, smartchat.js, RoomList.vue, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, unread, unresponded, last_contact_date, already_read_locally, triggerFilteredListRefetch

### Task 1: Realtime badge fix re-review

task: determine whether realtime unread/unresponded badges work across in-list and new-room paths
 task_group: Vue2 frontend realtime badge review
 task_outcome: partial

Preference signals:
- The user said “read ONLY these, do not explore the repo broadly” -> constrain future reviews to explicitly named files/line ranges.
- The user said “Review only, do not modify files” -> do not edit, stage, commit, or run mutating commands.
- The user required “yes/no verdict + file:line evidence” and an adversarial search for real defects -> provide compact, line-cited verdicts and avoid speculative findings.

Reusable knowledge:
- `RoomList.room_list()` prioritizes current-room false, then `state.read[my_id]` timestamp comparison, then presence of `state.read`, and only finally `is_read_by_me` fallback (`RoomList.vue:161-177`). Because backend rows may contain `state.read`, injecting only `is_read_by_me:false` is insufficient; a timestamp is needed for the `my_read` branch.
- Injecting a client “now” timestamp is unsafe. `smartchat.js:730-733` creates `last_contact_date`, while `smartchat.js:836-845` compares it with the local read cursor. A delayed event after the real message was read can make the cursor appear older and falsely mark the room unread; `RoomList.vue:163-165` repeats the same comparison. Use the real message timestamp/version or authoritative fetch, and discard synthetic badge fields when stale.
- Aggregate transitions run before new-room API reconciliation (`smartchat.js:779,813-860` before `915-927`), so authoritative `is_read_by_me`/`is_unresponded` values fetched for a new room do not update aggregate counts. Calculate deltas after fetch using final data.
- New-room insertion is skipped when `is_show_reload_chat_list_btn` is true or ascending pagination is incomplete (`smartchat.js:966-994`). Only active filtered lists refetch, so legitimate rooms can be absent until a later poll. Refetch or queue insertion in the blocked path.
- Failed/empty new-room fetches leave socket-only payloads (`smartchat.js:904-931`); missing badge fields then render as read/not-unresponded under `RoomList.vue:169-180`, and incomplete data may fail visibility/filter checks (`smartchat.js:952-965`). Avoid inserting incomplete rows or retry/refetch authoritatively.
- `is_unresponded:true` is injected independently for in-list rooms (`smartchat.js:725-738`) and can be counted/merged (`smartchat.js:813-825,869-880`), but stale inbound events lack causal ordering and can reassert true after a bot/member reply clears it. Add event ordering metadata or authoritative reconciliation.
- No direct flag-combination hole was identified: unread and unresponded feature flags are checked independently (`smartchat.js:710-715,727-733`); shared new-room defects affect either combination.

Failures and how to do differently:
- Do not treat a synthetic timestamp as equivalent to the socket message’s real ordering metadata; it breaks both the stale-read guard and RoomList derivation.
- Do not evaluate aggregate badge deltas before the authoritative new-room fetch completes.
- Do not silently skip blocked new-room insertion without a refetch path.

References:
- `/private/tmp/claude-501/-Users-tualek-ohochat/e09208f3-facf-4303-8b26-c1c18904dc1b/scratchpad/oho1272-recheck.diff`
- `store/modules/smartchat.js:730-733,772-779,813-860,904-931,952-994`
- `components/Smartchat/RoomList.vue:149-177,191-205`
- Final verdict from the review: `VERDICT: 4 issues`.

## Thread `019f98cc-014a-72d2-94c9-0a10127e2259`
updated_at: 2026-07-25T10:38:58+00:00
cwd: /Users/tualek/Documents/Codex/2026-07-25/new-chat
rollout_path: /Users/tualek/.codex/sessions/2026/07/25/rollout-2026-07-25T17-22-14-019f98cc-014a-72d2-94c9-0a10127e2259.jsonl
rollout_summary_file: 2026-07-25T10-22-14-ZNOx-thai_event_flow_google_docs_export.md

---
description: สร้าง flow งานพิธีภาษาไทยแบบตารางพร้อมพระนามเต็มและสคริปต์ แล้วส่งออกเป็น Google Docs สำเร็จ โดยตรวจข้อความและโครงสร้างตารางหลังนำเข้า
 task: create_thai_event_flow_and_export_google_docs
 task_group: thai-event-planning-documents
 task_outcome: success
 cwd: /Users/tualek/Documents/Codex/2026-07-25/new-chat
 keywords: Thai, event-flow, ceremony-script, Google Docs, Google Drive, python-docx, title-sanitize, table-import
---

### Task 1: จัดทำ flow และสคริปต์พิธีการ

task: create consolidated Thai event flow with full royal names and concise thank-you script
task_group: thai-event-planning-documents
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ขอ “แทรกชื่อองค์ภาและพระพันปีชื่อเต็มพร้อมบทเข้าไว้อาลัย” -> งานพิธีการควรใช้พระนามเต็มและมีบทนำเข้าสู่ช่วงถวายความอาลัย
- เมื่อผู้ใช้ขอ “บทพูดให้คุณแดนด้วยสั้นๆ” -> ควรเขียนสคริปต์คุณแดนให้สั้น ประมาณ 1 นาที
- เมื่อผู้ใช้ขอ “รวมทั้งหมดรวบเดียว” -> ควรส่งมอบฉบับรวมเดียวในตารางที่พร้อมใช้งาน

Reusable knowledge:
- ลำดับสุดท้ายใช้เวลา 18.55–19.20 น. โดยมีบทเข้าสู่ไว้อาลัย ยืนสงบนิ่ง 1 นาที คุณแดนกล่าวขอบคุณ นายกและประธานที่ปรึกษากล่าวโอวาท นายกประกาศเปิดงาน และส่งต่อพิธีกรหลัก
- ช่วงไว้อาลัยต้องปิดเพลง งดเสียงปรบมือ ใช้ไฟนิ่งโทนสุภาพ; เพลงสนุกและไฟสีสันเริ่มหลังคำว่า “ณ บัดนี้”

Failures and how to do differently:
- Local DOCX render แสดงอักษรไทยได้ไม่สมบูรณ์ แม้เปลี่ยนฟอนต์และใช้ `SAL_FONTPATH`; future agents should report visual QA as limited unless Thai glyph rendering is independently confirmed.

References:
- `/Users/tualek/Documents/Codex/2026-07-25/new-chat/outputs/Flow-กิจกรรม-แบ่งปันน้ำใจสู่สังคม.docx`

### Task 2: ส่งออกเป็น Google Docs

task: import the prepared DOCX as a native Google Docs document
task_group: Google Drive document export
 task_outcome: success

Preference signals:
- ผู้ใช้ขอ export เป็น Google Docs -> ควรสร้างเอกสาร native และส่งลิงก์ พร้อมตรวจเนื้อหาและตารางหลังนำเข้า

Reusable knowledge:
- Workflow ที่ใช้ได้: สร้าง DOCX ด้วย `python-docx` → รัน `google_docs_title_sanitize.py` → import ผ่าน Google Drive ด้วย `upload_mode: "native_google_docs"` → ตรวจ `_get_document_text` และ `_get_document_tables`
- เอกสารที่สร้างสำเร็จมี ID `1NVjW2EBlV4WKJOjm7NN00CDBBBNczivck-cWSlbSeSo` และตาราง 16 แถว × 3 คอลัมน์

Failures and how to do differently:
- ตรวจยืนยันข้อความและโครงสร้างได้ แต่ไม่ได้ยืนยันภาพที่แสดงใน Google Docs โดยตรง; อย่าอ้าง visual QA เต็มรูปแบบจากหลักฐานนี้

References:
- `https://docs.google.com/document/d/1NVjW2EBlV4WKJOjm7NN00CDBBBNczivck-cWSlbSeSo/edit`
- Sanitizer output: `[OK] no Google Docs title border/rule residue detected`
- Import output included `converted:true` and `mimeType:"application/vnd.google-apps.document"`

## Thread `019fadbd-7acb-76b2-8d60-108475540831`
updated_at: 2026-07-29T11:58:28+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-58-23-019fadbd-7acb-76b2-8d60-108475540831.jsonl
rollout_summary_file: 2026-07-29T11-58-23-dnwJ-unread_unresponded_report_verification_request.md

description: Read-only, line-cited independent review of unread/unresponded chat performance optimization report was requested; no inspection results were recorded
 task: verify unread/unresponded optimization report against oho-api and oho-web-app
 task_group: performance-review
 task_outcome: uncertain
 cwd: /Users/tualek/ohochat/oho-web-app
 keywords: unread_by, is_unresponded, performance-review, maxTimeMS, N+1, socket-broadcast, Vuex, read-only

### Task 1: Verify unread/unresponded optimization report

task: independently audit report claims and proposals O1-O14 against source code
task_group: performance-review
task_outcome: uncertain

Preference signals:
- The user said “Every claim you make must cite an actual file path and line number I read in this session” -> future reviews must inspect source directly and cite exact paths/lines, not rely on report references.
- The user said “Do not modify, stage, or commit any files” -> preserve strict read-only behavior.
- The user requested output in a fixed order and “Be direct and concise” -> follow the required verdict/missed-findings/ranking/impact-audit structure.

Reusable knowledge:
- Review targets are `/Users/tualek/ohochat/unread-unresponded-optimize-review.md`, `/Users/tualek/ohochat/oho-api`, and `/Users/tualek/ohochat/oho-web-app`.
- The review must check the five named claims plus missed hot-path costs: unbounded queries, N+1 queries, missing `maxTimeMS`, socket per-member fan-out, and Vuex event-driven store update costs.

Failures and how to do differently:
- The supplied rollout contains only the user request and no tool inspection or findings. Treat outcome as unverified; do not claim any report item was confirmed or disproved.

References:
- `oho-api/src/services/chat-session/group/search/search.class.js:112-116`
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:47-128`
- `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:233-239`
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:667-684` and approximately line 1290
- `badge-count-cache.ts`
- Report proposals O1-O14, section 5

## Thread `019fadbe-9f4b-7e81-955d-a4ab24c396a9`
updated_at: 2026-07-29T12:13:38+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-59-38-019fadbe-9f4b-7e81-955d-a4ab24c396a9.jsonl
rollout_summary_file: 2026-07-29T11-59-38-K1iF-unread_unresponded_optimization_report_verification.md

description: Read-only cross-repo audit of unread/unresponded performance report; found bounded-but-uncapped group totals, inline populate/audience fan-out, a customer-delivered/Stream-missing failure window, frontend fallback fetch amplification, and unsafe optimization proposals.
task: verify unread/unresponded optimization report claims and O1-O14 against live oho-api/oho-web-app code
task_group: cross-repo unread-unresponded performance review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: unread, unresponded, countDocuments, maxTimeMS, populate, sendMessage, Stream, Redlock, badge-count-cache, channel-eligible-members, Remote Config, refreshChatRoomBadgeRealtime, bulk-send, Vuex

### Task 1: Verify performance claims and deploy safety
task: audit report claims (a)-(g), missed query/fan-out risks, and optimization proposals O1-O14
task_group: cross-repo unread-unresponded deploy-gate review
task_outcome: partial

Preference signals:
- when the user says “READ-ONLY review” and “Do not modify any files” -> inspect live repositories and report findings only; do not patch, stage, or commit.
- when the user requires “Cite file:line for every claim” and an exact section contract -> produce structured, judgmental, evidence-first verdicts with explicit CONFIRMED/WRONG/PARTIAL labels.
- when the task spans API and web, the user expects the full chain: query/write cost, socket audience, frontend merge/fetch cost, and behavior preservation—not isolated file review.

Reusable knowledge:
- `group/search/search.class.js:110-114` runs unbounded `countDocuments(findQueryPayload)` but applies `maxTimeMS`; service timeout is 75s. It is frequently refetched by UI watchers, not proven to be timer-polled.
- `emit-chat-session-event.js:47-128` has one `findOne`, nine top-level populates, nested team populates, and no query-level maxTimeMS. Audience resolution can add team/member reads at `socket.io.js:359-417`. Contact inbound awaits emit hooks through `promiseAll`; member reply awaits full and narrow emitters sequentially.
- `contact-send-message.hooks.js:220-243` split one update into two sequential writes. The writes are error-unguarded, but the second has an ordering guard on `last_contact_date`.
- Critical failure window: platform delivery completes before after-hooks (`member-send-message.class.js:26-64`); clear writes at `member-send-message.hooks.js:667-686` run before `sendMessagesToChatStream()` at `:1289`, all inside Redlock `:1250-1310`. A clear-write failure can return an error after customer delivery while skipping Stream persistence.
- `badge-count-cache.ts:18-25` lacks environment/service prefix, but `channel-eligible-members.ts:8-9` also lacks one. Do not claim cross-environment collision without shared-Redis evidence.
- Web Remote Config `minimumFetchIntervalMillis=0` is configured at `plugins/firebase-remote-config.js:16-17`; plugin fetch is fire-and-forget at `:85-89`, so “network on every page load” is possible but not proven to block page open.
- `smartchat.js:706-763,927-948` only fetches contact details for qualifying fallback realtime events; there is no debounce, cancellation, or in-flight coalescing in `services/contact-api-service.js:54-66`.
- Bulk send starts platform handlers without awaiting and returns `{ok:true}` at `member-send-message/bulk/bulk.class.js:31-68`; serial contact loops and awaited per-contact writes/emits can fail-stop after the HTTP response succeeds.
- Flag-off does not avoid emitter cost: flag evaluation occurs after read/populate/audience work at `emit-chat-session-event.js:47-200`; only the payload field is removed at `:201-203`.
- Eligible-member cache misses have no single-flight (`channel-eligible-members.ts:50-76`) and accepted writes can carry up to 2,000 IDs into `unread_by` (`:10-18,74-78`).
- Socket.IO uses one `io.to(channelNames).emit()` call (`socket.io.js:420-440`), but recipient fan-out and room construction scale with eligible members; inbound bubbles add B message emits plus status emits.
- Web fallback uses the heavyweight `query_params.contact_default` population set (`smartchat.js:927-936`, `api/query-params.js:2-68`); realtime list/store paths perform multiple O(n) scans and rendering passes.

Failures and how to do differently:
- Do not describe `countDocuments` as literally unbounded when a timeout exists; distinguish work/cardinality bound from time bound.
- Do not label every socket event as causing a fallback fetch; separate qualifying fallback events from timestamped in-list and stale events.
- Do not approve raw fire-and-forget emits: it changes ordering, permits cross-request state races, and can lose events on shutdown.
- Do not merge clear writes by simply removing the `$exists` guard; legacy documents without `is_unresponded` require preserving field-absence semantics.
- Do not skip off-list fallback fetches without an authoritative polling/reconciliation path; this can leave rooms absent or counters stale.
- Treat O10/O14 as one Remote Config authority/refresh design, not independent quick fixes.
- Label conclusions as structural/source-only when no benchmark, explain, or production telemetry was run.

References:
- `/Users/tualek/ohochat/unread-unresponded-optimize-review.md`
- API revision: `5971ebf5673a838010ac5c9ca810e6d76163f555`; web revision: `5fc4ef224814aec240b55891ef36664e0abce5cd`; timestamp commit: `bbe0ac735`.
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:667-686,1281-1289`
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:47-128,239-289`
- `oho-api/src/utils/badge-count-cache.ts:18-25`
- `oho-api/src/utils/channel-eligible-members.ts:50-76`
- `oho-api/src/services/member-send-message/bulk/bulk.class.js:31-68`
- `oho-web-app/store/modules/smartchat.js:706-763,927-948`
- `oho-web-app/plugins/firebase-remote-config.js:16-17,85-89`
- No tests or benchmarks were run; review was read-only/source-only.

## Thread `019faef2-a12e-78c2-b951-01d71a1deffd`
updated_at: 2026-07-29T18:06:31+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T00-36-04-019faef2-a12e-78c2-b951-01d71a1deffd.jsonl
rollout_summary_file: 2026-07-29T17-36-04-EvVz-oho_1272_final_single_flight_timeout_verification.md

description: Final read-only verification of OHO-1272 unread/unresponded worktree; final single-flight timeout/write redesign passed and overall verdict was ship.
task: review uncommitted unread/unresponded badge fixes and single-flight cache concurrency
 task_group: /Users/tualek/ohochat/oho-api / unread-unresponded code reviews
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge
keywords: oho-1272, badge-count-cache, single-flight, staggered-GET, Promise.race, Bluebird, wall-clock-timeout, expired-flag, stale-cache-write, Jest

### Task 1: Final single-flight timeout/write verification

task: verify final cache-flight redesign and full changeset readiness
task_group: oho-api unread/unresponded code review
task_outcome: success

Preference signals:
- The user required a read-only review with actual current-file inspection and exact file:line evidence -> similar reviews should not rely on summaries or claimed deltas.
- The user requested a decisive ship/no-ship conclusion and explicit concurrency/test-timing analysis -> proactively validate race windows, timer cleanup, and whether regression tests truly exercise them.

Reusable knowledge:
- `getOrComputeBadgeCount` now registers the whole cache-read-plus-compute lifecycle synchronously: the outer function is non-async, checks the map, starts `run()`, constructs the bounded flight, and sets the map without an outer await (`src/utils/badge-count-cache.ts:63-111`). This closes the staggered-GET admission race.
- Each flight has a local `expired` flag (`:73`); the timeout callback sets it before rejecting (`:95-103`), and `run()` checks it immediately before `setCachedBadgeCount` (`:80-86`). A computation resolving after timeout cannot perform a stale late cache write.
- `Promise.race(...).finally(...)` clears the timer and deletes the in-flight map entry on all settlement paths (`:106-109`). Joiners return the existing flight without creating additional timers (`:69-71`).
- Production sets `global.Promise` to Bluebird (`src/index.js:12-13`); a focused runtime probe confirmed Bluebird `Promise.race` assimilates native async promises and supports `.finally()`.
- Final specs directly cover concurrent one-read/one-compute behavior (`src/utils/badge-count-cache.spec.ts:200-225`), pending-GET join (`:228-250`), timeout and fresh retry (`:253-280`), and late-success-after-timeout stale-write prevention (`:311-347`).

Failures and how to do differently:
- Earlier review rounds identified the admission race, missing wall-clock bound, and stale late-write bug. The durable prevention rule is: register the complete lifecycle before the first await, bound the flight independently of Mongo `maxTimeMS`, and gate all post-compute side effects after timeout.
- Jest and TypeScript were not independently rerun in this environment due known Node 24/config incompatibility and pre-existing type errors; report this as static/spec verification plus a focused Promise probe, not full suite validation.

References:
- `src/utils/badge-count-cache.ts:63-111`
- `src/utils/badge-count-cache.spec.ts:228-250,311-347`
- `src/index.js:12-13`
- Final review verdict: `VERDICT: ship`

## Thread `019fb213-6e6a-7ca2-9032-29a514b9a891`
updated_at: 2026-07-30T08:16:29+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-10-45-019fb213-6e6a-7ca2-9032-29a514b9a891.jsonl
rollout_summary_file: 2026-07-30T08-10-45-wXG9-firebase_remote_config_multitab_race_review.md

---
description: Read-only cross-repo review found a real same-origin multi-tab Firebase Remote Config cache collision; recommend removing the browser fetch path after server flags are verified.
task: analyze web Firebase Remote Config caching, multi-tab business-signal race, and mobile-pattern port
 task_group: oho-web-app/firebase-remote-config-design
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Firebase Remote Config, minimumFetchIntervalMillis, onConfigUpdate, onConfigUpdated, IndexedDB, custom signals, multi-tab, feature_flags_api_keys, JERA
---

### Task 1: Evaluate multi-tab cache race and web implementation strategy

task: determine whether a large web minimum fetch interval can reuse another tab’s business-evaluated config, inspect Flutter cache reset behavior, verify JS real-time support, and recommend whether to port mobile behavior.
task_group: Firebase Remote Config design review
task_outcome: success

Preference signals:
- When the user required “Design consultation only. Do NOT modify any files” -> keep future reviews read-only and do not edit, stage, or commit.
- When the user required every SDK claim to be tagged as actual source/typings or documented-architecture reasoning -> cite exact local SDK paths/lines and label external documentation separately.
- When the user specified a fixed six-part output order and asked for a direct verdict -> preserve that structure and provide a concrete recommendation rather than a generic pros/cons list.

Reusable knowledge:
- Installed `@firebase/remote-config@0.8.0` uses IndexedDB database `firebase_remote_config`. Its composite key is app ID, app name, namespace, and record key; custom-signal values are not part of the key (`node_modules/@firebase/remote-config/dist/index.cjs.js:1024-1040,1253-1256`).
- `active_config`, `last_successful_fetch_response`, fetch timestamp, and `custom_signals` are single records per app/namespace (`:1081-1121`). Cache freshness checks timestamp only (`:586-610`), so a Tab A for business X can consume Tab B’s recently evaluated business-Y blob. This makes the multi-tab race real.
- Flutter starts with a 12-hour interval (`oho-flutter-mobile/lib/core/services/remote_config_service.dart:21-23`), but `clearRemoteConfigCache()` sets `Duration.zero`, fetches, and never restores 12 hours (`:62-75`). The first signal update therefore leaves that instance permanently unthrottled.
- The JS SDK supports `onConfigUpdate`, documented in installed typings (`node_modules/@firebase/remote-config/dist/remote-config-public.d.ts:289-304`) and implemented at `index.cjs.js:523-545`. Real-time fetches use cache age zero (`:1788-1805`) and callbacks require explicit `activate()` (`:1820-1830`). Real-time does not isolate per-business cached values.
- Server-side correctness is already primary: login adds four evaluated flags (`oho-api/.claude-worktrees/jera-tab-is-missing/src/services/authentication-member/login/login.hooks.js:119-140,175-187`), while Vuex marks API-set keys authoritative and filters later browser values (`oho-web-app/store/index.js:103-128,502-512`).
- Recommended strategy is the simpler safer variant: after verifying rollout, remove automatic browser initialization/custom-signal setting/fetch/activate fallback from `plugins/firebase-remote-config.js`; retain synchronous Vuex getters, E2E overrides, API bootstrap, and fail-closed defaults. Do not port interval bypass or real-time listeners.

Failures and how to do differently:
- Do not assume Firebase cache entries are keyed by custom-signal combinations; local SDK source shows they are not.
- Do not claim the exact behavior is always “reactivation”: a fresh tab may load the shared active config, and `activate()` can return false when the shared ETag is already active (`index.cjs.js:290-315`).
- Do not infer OHO fetch volume. The review found no repository measurement; inspect Firebase usage dashboards before prioritizing cleanup.

References:
- `oho-web-app/plugins/firebase-remote-config.js:16-17,36-41,52-57,85-89`
- `oho-web-app/components/SwitchBusiness.vue:202-215`
- `node_modules/@firebase/remote-config/package.json` reports `@firebase/remote-config` version `0.8.0`.
- Firebase pricing/quota documentation reviewed: 100,000 fetches/day free under announced September 1, 2026 model; real-time connection itself is not a continuous series of fetches, but invalidation-triggered downloads count.
- Suggested validation: two same-origin tabs on different businesses, alternating hard reloads, verify each tab’s flags against its own login response; simulate server Remote Config failure and ensure authentication succeeds with false defaults.

## Thread `019fb230-e359-7f60-893d-3467569eb66b`
updated_at: 2026-07-30T08:50:25+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-42-56-019fb230-e359-7f60-893d-3467569eb66b.jsonl
rollout_summary_file: 2026-07-30T08-42-56-lECv-oho_api_jera_login_feature_flags_review.md

description: Read-only review of JERA login feature-flag diff found original export/rejection fixes valid but a new cold-start Firebase outage blocker; focused tests passed only via sandbox cache workaround
 task: review jera login feature flags and hook fail-soft behavior
 task_group: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing code review
 task_outcome: partial
 cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
 keywords: jera, feature_flags, firebase-remote-config, addFeatureFlagsToResult, Promise.all, Feathers hooks, warnWithOptions, Jest, EPERM, Node 20

### Task 1: Review JERA feature-flag login diff

task: verify hook export shape, fail-soft behavior, logger contract, standards, tests, and worktree residue
 task_group: oho-api read-only code review
 task_outcome: partial

Preference signals:
- when the user asked for a “fresh thread, not a resume,” required live `git diff`/`git status`, and said “Review only — do not edit any files” -> pin the actual worktree and keep similar reviews strictly read-only; do not trust claimed fixes until verified against source and commands.
- when the user required every claim to have quoted file/path evidence and a structured verdict -> provide compact, severity-ranked, line-cited findings rather than general commentary.

Reusable knowledge:
- The invalid Feathers hook export is fixed in `src/services/authentication-member/login/login.hooks.js`: `module.exports` contains only `before`, `after`, and `error`; `addFeatureFlagsToResult()` is wired only in `after.create`. The regression guard `Object.keys(loginHooks).sort()` equals `['after', 'before', 'error']`.
- The Promise rejection path is fail-soft: `addFeatureFlagsToResult` wraps `Promise.all` in `try/catch`, calls `logger.warnWithOptions({ metadata: { businessId, error: error?.message } }, message)`, and returns `context`. `src/logger.js:339-357` defines and exports `warnWithOptions` with that signature.
- Important failure shield: Firebase fetch failure is swallowed in `src/firebase-remote-config.js:40-52`; missing template becomes `{ value: false, configLoaded: false }` at `:124-129`, but `getBoolean()` discards `configLoaded` at `:140-142`. Since `isJeraFeatureEnabled()` calls `getBoolean(..., false, businessSignal(businessId))`, a cold-start outage resolves as false rather than rejecting. The login hook therefore attaches false flags, and the frontend’s `setFeatureFlags` records them as API-authoritative (`oho-web-app/store/index.js:103-114`), while `setRemoteConfigFeatureFlags` refuses to overwrite API keys (`:122-128`). Future reviews must check that unavailable config remains distinguishable from an evaluated false before server flags become authoritative.
- The hook test’s `mockRejectedValue(new Error('Remote Config unavailable'))` validates only artificial promise rejection, not the real `fetchServerTemplate` outage path.
- Repository standards in `CLAUDE.md` require DRY/SOLID, no dead code/TODOs, deterministic fixture-derived tests, and preference for TypeScript. The diff had no material DRY/SOLID/dead-code/TODO violation, but the new `.js` spec is not TypeScript, generates `new Types.ObjectId()` at runtime instead of using fixtures, and has Prettier/ESLint errors.

Failures and how to do differently:
- Standard Jest command under Node 20 could not start because the sandbox denied writes to `/T/jest_dx/*` with `EPERM`; do not report this as a code test failure. A read-only process-level cache/persistence shim allowed the same focused suites to run.
- Do not treat `11/11` passing as sufficient: those tests mock the Firebase helpers and miss the cold-start outage-to-authoritative-false behavior. Add a regression test that models `fetchServerTemplate()` failure and verifies unavailable config does not produce authoritative false flags.

References:
- Branch/HEAD: `tk-sprint-2616/featurn/jera-tab-is-missing`, `ebfb71e1232797c973f6c7720acf33482db004de`.
- Focused test result: `Test Suites: 2 passed, 2 total; Tests: 11 passed, 11 total` under Node `v20.20.2` using a read-only Jest cache workaround.
- Final status: `M src/firebase-remote-config.js`, `M src/services/authentication-member/login/login.hooks.js`, `?? src/services/authentication-member/login/login.hooks.spec.js`; no `node_modules` entry or symlink.
- Blocker evidence: `src/firebase-remote-config.js:40-42`, `:124-142`, `:228-229`; `src/services/authentication-member/login/login.hooks.js:122-148`; `oho-web-app/store/index.js:103-128`.

## Thread `019fb235-7d01-7910-8c06-037d382b4d1e`
updated_at: 2026-07-30T08:56:35+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-47-57-019fb235-7d01-7910-8c06-037d382b4d1e.jsonl
rollout_summary_file: 2026-07-30T08-47-57-M3ng-firebase_remote_config_tab_cache_review.md

---
description: Read-only review of Firebase Remote Config per-tab cache found three ship-blocking cross-tab correctness flaws and weak tests.
task: review firebase remote config session cache and realtime listener
task_group: oho-web-app frontend code review
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
keywords: firebase-remote-config, sessionStorage, IndexedDB, business_id, onConfigUpdate, activate, custom-signals, cross-tab-race, Jest, EPERM
---

### Task 1: Review Firebase Remote Config cache change

task: review uncommitted plugins/firebase-remote-config.js and test/plugins/firebase-remote-config.spec.js
task_group: oho-web-app frontend code review
task_outcome: fail

Preference signals:
- When the user said “Review-only (do not edit files)” -> keep the worktree strictly read-only; do not edit, stage, commit, or run mutating commands.
- When the user required claims grounded in “actual diff output and actual file contents” with `file:line` citations -> inspect live source and cite exact evidence, not summaries or assumptions.
- When the user required a verdict section first and per-test verdicts -> use compact, blocker-oriented structured reporting.

Reusable knowledge:
- `sessionStorage` is partitioned by origin and top-level browser tab. An opener may initially copy storage, but subsequent stores are independent; the plugin’s business-id equality check rejects copied entries for another business.
- Firebase Remote Config 0.8.0 persists custom signals and `last_successful_fetch_response` in shared IndexedDB. `fetchConfig()` writes the response, while `activate()` later rereads the shared response, so activation is not intrinsically bound to the response fetched by the current tab.
- The cache-hit branch at `plugins/firebase-remote-config.js:109-115` returns before `setCustomSignals()` at `:118-124`, yet registers realtime. Realtime fetch uses SDK-persisted signals, allowing another business’s signal to be used and cached under the current business.
- SDK `setCustomSignals()` catches storage errors (`index.esm.js:512-517`); the plugin logs/continues and can then write an untrustworthy result to sessionStorage. Signal-application failure must disable trusted per-business caching.
- `degradedToSharedCache` correctly prevents writing the explicit `activate()` fallback result (`plugins/firebase-remote-config.js:143-156`), but does not protect successful-path activation races or failed custom-signal application.
- `onConfigUpdate` has the correct two-argument signature. Runtime invokes observer `next` and propagates `error`; it does not invoke `complete`, despite the declaration containing all three callbacks.
- Normal cache hits enforce a five-minute TTL at `plugins/firebase-remote-config.js:109-115`; fetch-failure fallback intentionally accepts any-age same-business cache at `:137-141`.
- API-authoritative flags are preserved by `store/index.js:122-128`, which filters browser Remote Config commits using `feature_flags_api_keys`.

Failures and how to do differently:
- Blocker: establish current business custom signals before any cache-hit return or realtime listener registration.
- Blocker: avoid relying on SDK `activate()` as proof that the current tab’s fetch result was activated; prevent shared-response races before writing the supposedly safe session cache.
- Blocker: distinguish successful, business-scoped fetches from fetches where custom-signal storage failed; never cache the latter under `business_id`.
- Tests mock Firebase completely, so they cannot expose shared IndexedDB races. Add tests for current-signal setup before listener registration, failed/ineffective signal application, and interleaved shared response overwrite.
- The no-business-id test does not spy on `sessionStorage.getItem`, so it proves no observable write but not “never reads.” The stale-cache test proves fetch but not refreshed cache contents/timestamp.
- Jest could not run because the sandbox denied temp haste-map writes (`EPERM`); report syntax/diff checks as shallow validation only.

References:
- `plugins/firebase-remote-config.js:64-70,95,109-159,169-192`.
- `test/plugins/firebase-remote-config.spec.js:76-244`.
- SDK evidence: `/Users/tualek/ohochat/oho-web-app/node_modules/@firebase/remote-config/dist/esm/index.esm.js:286-310,351-369,597-624,1343-1388,1761-1826`; declarations `dist/src/api.d.ts:144` and `dist/src/public_types.d.ts:239-252`.
- Worktree had no local `node_modules`; parent SDK was `@firebase/remote-config@0.8.0`, matching `package-lock.json:3933-3947`.
- `git diff --check` and `node --check` passed; targeted Jest failed with `EPERM`.

## Thread `019fb245-30e8-7533-a6c3-ba67f1a607a4`
updated_at: 2026-07-30T09:14:18+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-06-019fb245-30e8-7533-a6c3-ba67f1a607a4.jsonl
rollout_summary_file: 2026-07-30T09-05-06-mY16-oho_api_jera_login_feature_flags_review.md

description: Read-only review of oho-api JERA login feature-flag fix; P1 closed, 13 targeted tests passed, with cache-boundary comment and unused helper as non-blocking issues
task: review firebase remote config login feature flags
task_group: /Users/tualek/ohochat/oho-api code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: oho-api, firebase-remote-config, getLoginFeatureFlags, getBooleanWithState, cold-start, configLoaded, feature_flags, Jest, Node 20, TTL boundary, review-only

### Task 1: Review JERA login feature-flag fix

task: verify cold-start safety, mapping, regressions, tests, and ship verdict
task_group: oho-api code review
task_outcome: success

Preference signals:
- when the user said “review only, do not edit files” and requested exact lines, real test counts, and a ship verdict -> keep similar reviews strictly read-only and provide concise, evidence-backed, severity-ranked conclusions.

Reusable knowledge:
- Cold-start path is safe: `fetchServerTemplate()` catches fetch errors and returns null; `evaluateServerConfig()` returns null; `getBooleanWithState()` returns `{ value: false, configLoaded: false }`; `getLoginFeatureFlags()` only copies entries with `configLoaded === true`, returning `{}` instead of false-valued keys. The hook assigns that object directly.
- Mapping at `src/firebase-remote-config.js:153-186` is correct: JERA/unread/unresponded use business signals; search optimization uses `{}`; all defaults are false.
- Existing exported flag functions and external callers were unchanged. `isJeraFeatureEnabled` is newly added at `src/firebase-remote-config.js:272-273` but has no caller, a non-blocking dead-code issue.
- The claim that partial loading is impossible is false: shared cache state can be observed across a TTL boundary during one `Promise.all`, yielding mixed loaded/unloaded results. The implementation remains safe because unloaded keys are omitted.
- The signal test’s 3/1 count does not identify search optimization as the no-signal check; add per-key/context assertions in future.

Failures and how to do differently:
- Ordinary Jest execution was blocked by sandbox `EPERM` while writing haste-map/transform caches. A no-write launcher successfully ran the tests; distinguish environment failure from test failure.

References:
- Branch/SHA: `tk-sprint-2616/featurn/jera-tab-is-missing`, `ebfb71e1232797c973f6c7720acf33482db004de`
- Cold-start evidence: `src/firebase-remote-config.js:35-52,55-71,79-85,119-130,172-186`
- Hook wiring: `src/services/authentication-member/login/login.hooks.js:117-129,152-168`
- Tests: `2 passed / 2 suites`, `13 passed / 13 tests`, Node `v20.20.2`
- Final worktree had only the intended modified files plus untracked `src/services/authentication-member/login/login.hooks.spec.js`; no `node_modules` symlink remained.

## Thread `019fb245-9645-7471-8e1c-d06b902e573f`
updated_at: 2026-07-30T09:07:28+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-32-019fb245-9645-7471-8e1c-d06b902e573f.jsonl
rollout_summary_file: 2026-07-30T09-05-32-HGYT-firebase_remote_config_review_partial_jest_blocked.md

description: Partial read-only re-review of Firebase Remote Config cache-hit signal fix; code-path evidence was gathered, but Jest could not run due sandbox EPERM and the review had no final verdict.
task: review firebase remote-config cache-hit signal ordering
task_group: oho-web-app frontend code review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
keywords: firebase-remote-config, setCustomSignals, onConfigUpdate, invocationCallOrder, Jest, EPERM, sessionStorage, degradedToSharedCache

### Task 1: Review cache-hit signal ordering

task: verify `setCustomSignals()` runs before all listener registration paths and validate the regression test
task_group: oho-web-app frontend code review
task_outcome: partial

Preference signals:
- The user said “do NOT edit any files” and required actual `git diff`, exact file:line evidence, and a real test run -> future reviews should stay strictly read-only, verify the live worktree, and clearly separate confirmed code facts from unverified conclusions.
- The user said not to re-litigate accepted SDK residual risks #2/#3 -> future reviews should mention them as accepted unless evidence shows a materially worse or new issue.

Reusable knowledge:
- In the reviewed working tree, `await setCustomSignals(remoteConfig, signals)` is at `plugins/firebase-remote-config.js:125-131`, before listener registration at lines 137, 156, and 175. This structurally covers cache-hit, same-business fallback, and normal paths.
- The cache-hit regression test asserts `business_id: "biz_1"` and compares `mockSetCustomSignals.mock.invocationCallOrder[0]` against `mockOnConfigUpdate.mock.invocationCallOrder[0]` at `test/plugins/firebase-remote-config.spec.js:100-105`.
- Installed Jest typings and implementation confirm `invocationCallOrder` is valid and records mock calls in global invocation order.
- The plugin still visibly retains `minimumFetchIntervalMillis = 0` (line 105), the test feature override (185-190), missing-apiKey early return (202), fire-and-forget call (204-208), and `degradedToSharedCache` guard (147-160).

Failures and how to do differently:
- The Jest command failed before test execution because the sandbox denied writing Jest’s haste-map cache: `EPERM: operation not permitted, open .../T/jest_dx/haste-map-...`. Do not report any pass/fail count or claim the test passed.
- The captured rollout did not complete the requested full review, final verdict, or symlink cleanup/verification. A future agent must resume from the live worktree and re-check status before concluding.

References:
- `git diff -- plugins/firebase-remote-config.js test/plugins/firebase-remote-config.spec.js`
- `plugins/firebase-remote-config.js:16-24` accepted residual-risk comment
- `plugins/firebase-remote-config.js:125-131`, `:137`, `:156`, `:175`
- `test/plugins/firebase-remote-config.spec.js:100-105`
- `npm test -- test/plugins/firebase-remote-config.spec.js --runInBand --no-cache`
- Error: `EPERM: operation not permitted` writing Jest haste-map cache

## Thread `019fb247-9cdc-76a3-a098-2b88906c3dc1`
updated_at: 2026-07-30T09:16:07+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-07-45-019fb247-9cdc-76a3-a098-2b88906c3dc1.jsonl
rollout_summary_file: 2026-07-30T09-07-45-YIjD-firebase_remote_config_cache_hit_rereview.md

description: Read-only re-review confirmed the Firebase Remote Config cache-hit signal-ordering fix and 9 passing Jest tests; no new blockers found.
task: review firebase-remote-config cache-hit signal ordering
task_group: oho-web-app frontend code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
keywords: firebase-remote-config, setCustomSignals, invocationCallOrder, Jest, sessionStorage, degradedToSharedCache, EPERM, read-only review

### Task 1: Verify cache-hit signal ordering

task: review firebase-remote-config cache-hit signal ordering
task_group: oho-web-app frontend code review
task_outcome: success

Preference signals:
- When the user says “review-only” and “Do NOT edit any files,” keep the review strictly read-only and verify every claim against the live worktree.
- When the user requests a verdict up front, exact `file:line` evidence, separate nice-to-haves, and actual test counts, use a compact structured, evidence-first report.
- When the user says accepted risks are not to be re-litigated, do not re-flag them unless the current code makes them worse or reveals a genuinely new mitigation.

Reusable knowledge:
- In the final snapshot, `setCustomSignals()` is awaited at `plugins/firebase-remote-config.js:115-121`, before all listener registrations: cache hit `:123-128`, fetch-failure cache fallback `:141-145`, and normal/shared-cache completion `:137-163`.
- The regression assertion at `test/plugins/firebase-remote-config.spec.js:96-101` checks the correct `business_id` and `mockSetCustomSignals` invocation before `mockOnConfigUpdate`; Jest 27 supports `mock.invocationCallOrder`, and the assertion would fail against the old cache-hit bug.
- Accepted SDK risks are documented at `plugins/firebase-remote-config.js:7-17`; the code still uses `fetchAndActivate()` and `activate()`, so the risk characterization remains applicable.
- Verified invariants remain at `:98` (minimum fetch interval 0), `:173-178` (test override), `:180-190` (missing API key return), `:192-196` (fire-and-forget), and `:132-160` (`degradedToSharedCache`).
- Final test result was 1 suite passed, 9 tests passed, 0 failures, 0 snapshots. The successful run used repository Jest dependencies with `NODE_ENV=test`, `NODE_PATH`, `--runInBand --cache=false --coverage=false`, while suppressing sandbox-rejected cache/coverage filesystem writes in memory.

Failures and how to do differently:
- Direct Jest attempts initially failed before test collection due to sandbox `EPERM` writes to temp haste/transform caches. Distinguish these infrastructure failures from actual test failures and use a controlled in-memory cache-write workaround when permitted.
- The worktree changed concurrently during review. Re-read the latest files, re-run tests, and capture final hashes before issuing a verdict.
- `test/plugins/firebase-remote-config.spec.js` was untracked, so the requested `git diff` did not include it; ensure it is added before commit/MR.

References:
- Worktree: `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing`
- Final plugin SHA-256: `0274d13dc3b82cf6a46cdf9628a9ba6a25c27f9fb3d70c00046ed564335f4a4f`
- Final test SHA-256: `b99dafda71d6a067848e11a5a9bf96594da162572a8810bdeddef8fb3c752419`
- No `node_modules` symlink remained in the worktree.

## Thread `019fb24c-796b-7f70-87ac-e3cbecc0fb7e`
updated_at: 2026-07-30T09:21:40+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-04-019fb24c-796b-7f70-87ac-e3cbecc0fb7e.jsonl
rollout_summary_file: 2026-07-30T09-13-04-OoVw-firebase_remote_config_comment_trimming_review.md

description: Read-only review verified Firebase Remote Config comment trimming preserved executable behavior and load-bearing rationale; all 9 tests passed, with one non-blocking historical-wording concern in a test comment.
task: review firebase remote config comment-only cleanup
task_group: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
keywords: firebase-remote-config, comment-only, AST, sessionStorage, IndexedDB, setCustomSignals, degradedToSharedCache, Jest, NODE_PATH

### Task 1: Review comment trimming

task: verify comment-only cleanup and rerun Firebase Remote Config tests
task_group: frontend code review
 task_outcome: success

Preference signals:
- The user required “Review-only (do not edit files),” actual diff and test evidence, minimal WHY-only comments, and asked not to re-raise two accepted SDK limitations as new bugs -> future reviews should remain tightly scoped, read-only, evidence-based, and distinguish accepted residual risk from regressions.

Reusable knowledge:
- Executable Babel AST comparison with comments/locations removed reported `executable AST identical=true` for both `plugins/firebase-remote-config.js` and `test/plugins/firebase-remote-config.spec.js` against pre-trim snapshots.
- The full `HEAD` diff is intentionally not comments-only because it contains the earlier feature implementation; the untracked test requires `git diff --no-index /dev/null test/plugins/firebase-remote-config.spec.js` for inspection.
- Load-bearing comments remained adequate at the header, the pre-cache-hit `setCustomSignals` ordering note, and the `degradedToSharedCache` note. The header explicitly labels fetch/activate non-atomicity and swallowed signal-storage failures as `Accepted residual risk`.
- Direct Jest writes failed with sandbox `EPERM`; using the main checkout’s dependencies via `NODE_PATH=/Users/tualek/ohochat/oho-web-app/node_modules` and disabling cache/coverage persistence allowed the real test file to run.
- Final test output was `Test Suites: 1 passed, 1 total` and `Tests: 9 passed, 9 total`. Final checks showed `node_modules: absent`; no temporary symlink remained.

Failures and how to do differently:
- Test comment lines 94-95 still say `Regression guard` and `was originally only called`, which narrates historical fix context and is mildly inconsistent with the repository’s timeless WHY-only convention. It was assessed as non-blocking; future cleanup should replace it with a concise rationale for signal ordering.

References:
- `plugins/firebase-remote-config.js:7-18, 113-115, 133-135`
- `test/plugins/firebase-remote-config.spec.js:94-95`
- AST result strings: `plugins/firebase-remote-config.js: executable AST identical=true`; `test/plugins/firebase-remote-config.spec.js: executable AST identical=true`
- Test result: `Tests: 9 passed, 9 total`
- Worktree check: `node_modules: absent`

## Thread `019fb24c-cc6f-7c03-b144-34394eac4620`
updated_at: 2026-07-30T09:22:45+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-25-019fb24c-cc6f-7c03-b144-34394eac4620.jsonl
rollout_summary_file: 2026-07-30T09-13-25-kdFe-review_comment_cleanup_jera_tab.md

description: Read-only review of a supposedly comments-only cleanup found executable scope drift and validated the final snapshot with Node 20.
task: review-uncommitted-comment-cleanup
 task_group: oho-api-read-only-code-review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: git-diff, read-only-review, comments-only, firebase-remote-config, getLoginFeatureFlags, TTL-boundary, Jest, Node-20, worktree-drift

### Task 1: Review comment-only cleanup

task: verify comment-only diff and run targeted specs
task_group: oho-api-read-only-code-review
task_outcome: partial

Preference signals:
- when the user said “Review-only (do not edit files, read-only)” -> keep similar reviews strictly non-mutating; temporary dependency symlinks must be removed and status rechecked.
- when the user required “Run git diff there” and exact `file:line` citations -> inspect the live worktree and ground every finding in quoted source, not prior summaries.
- when the user requested a verdict up front and concise numbered answers -> lead with `SHIP-BLOCKING ISSUES FOUND` or `NONE FOUND`, then answer each requested item directly.

Reusable knowledge:
- Worktree drift matters: the branch changed during review. Final verification was pinned to diff hash `a1b199252c9664f6605a803ac72c17a6fabe7d396468e4033392e5c938cd2c39`; future reviews should capture a final diff hash/status before reporting.
- `getLoginFeatureFlags` preserves the P1 safety rationale at `src/firebase-remote-config.js:154-160`: only include loaded keys because frontend-present keys are session-authoritative; cold-start/outage must omit keys instead of returning confidently false values.
- `addFeatureFlagsToResult` preserves fail-soft behavior at `src/services/authentication-member/login/login.hooks.js:102-105`; Remote Config failure is caught/logged and must not fail login.
- Independent `Date.now()` calls in `getCachedServerTemplate()` can straddle the TTL boundary. The prior comment claiming all four checks “always resolve configLoaded together” was false; the added test at `src/firebase-remote-config.spec.ts:274-314` demonstrated a partial result.
- Node 20 targeted validation passed: 2 suites and 14 tests. The temporary `node_modules` symlink was removed successfully.

Failures and how to do differently:
- The requested comments-only cleanup was not actually comments-only: `src/firebase-remote-config.js:147-168` changed executable tuple shape/consumer, and `isJeraFeatureEnabled()` was removed. Future reviewers should compare executable AST or normalized code and flag any executable drift even when behavior appears equivalent.
- The test file gained executable behavior while the review was in progress, changing expected validation from 13 to 14 tests. Re-run tests only after confirming the worktree has stabilized and report the exact snapshot tested.
- The new TTL test uses magic clock values and private array order; future changes should use named timing constants and avoid coupling tests to private implementation ordering where possible.

References:
- Final diff hash: `a1b199252c9664f6605a803ac72c17a6fabe7d396468e4033392e5c938cd2c39`.
- Verification command shape: `nvm use 20 && npx jest src/firebase-remote-config.spec.ts src/services/authentication-member/login/login.hooks.spec.js --runInBand`.
- Final result: `Test Suites: 2 passed, 2 total; Tests: 14 passed, 14 total`.
- Final status had only the three intended modified files plus the untracked hook spec; no `node_modules` symlink remained.

## Thread `019fb257-6da8-7681-aa63-4c62263ee116`
updated_at: 2026-07-30T09:33:14+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-25-02-019fb257-6da8-7681-aa63-4c62263ee116.jsonl
rollout_summary_file: 2026-07-30T09-25-01-qjNc-final_read_only_jera_login_feature_flags_review.md

description: Final read-only review of oho-api JERA login feature-flag diff; implementation passed behavioral checks and all 14 tests, with only non-blocking test-quality/style nits.
task: review-uncommitted-login-feature-flags-diff
task_group: oho-api-read-only-code-review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: git-diff, read-only-review, firebase-remote-config, getLoginFeatureFlags, configLoaded, cold-start, TTL-boundary, Feathers-hooks, isJeraFeatureEnabled, Jest, Node-20, EPERM

### Task 1: Review JERA login feature flags

task: verify-final-uncommitted-diff-and-run-specs
task_group: oho-api-read-only-code-review
task_outcome: success

Preference signals:
- when the user said to run `git diff` yourself and not trust the prior-round summary -> independently verify the live worktree, line-numbered final files, and all claimed fixes before reporting.
- when the user required read-only review and removal of any temporary symlink -> do not edit, stage, commit, or leave filesystem artifacts; confirm final git status.
- when the user requested an explicit verdict, exact file:line evidence, and real pass/fail counts -> give a compact evidence-first report with separate ship blockers and non-blocking nits.

Reusable knowledge:
- `getLoginFeatureFlags()` evaluates the four flags using `[key, usesBusinessSignal]` pairs and uses the same key for Remote Config evaluation and returned object keys (`src/firebase-remote-config.js:147-175`). The constants are identical to their Remote Config/result names.
- Cold-start failure is fail-safe: fetch failure leaves `cachedTemplate` null (`src/firebase-remote-config.js:35-52`), `getBooleanWithState()` returns `{ value: false, configLoaded: false }` (`:119-130`), and the reducer excludes unloaded keys (`:172-175`).
- Login feature-flag enrichment is auxiliary and fail-soft: the after-hook catches errors, logs with `warnWithOptions`, leaves `feature_flags` unset, and returns the login context (`src/services/authentication-member/login/login.hooks.js:102-118`).
- Whole-repo searches found zero `isJeraFeatureEnabled` references. The hook module exports only Feathers lifecycle keys, verified by the new spec.
- Under Node `v20.20.2`, both specs passed: 2 suites and 14 tests, 0 failures. The sandbox blocked Jest cache writes with `EPERM`; an in-process filesystem shim suppressed only Jest cache persistence so actual transforms/tests ran.

Failures and how to do differently:
- Standard Jest invocation could not write its haste/transform cache in the restricted sandbox and failed before tests ran. Report this as an environment limitation, not a test failure; if using a cache-write workaround, disclose it.
- Non-blocking cleanup opportunities: prefer TypeScript for `login.hooks.spec.js`; derive the repeated four-flag fixture from one named object; name remaining timing margins; rename `mod` to a meaningful module variable; remove the remaining WHAT-only comment.

References:
- `src/firebase-remote-config.js:35-52,119-130,147-175`
- `src/firebase-remote-config.spec.ts:274-317`
- `src/services/authentication-member/login/login.hooks.js:102-118,121-172`
- `src/services/authentication-member/login/login.hooks.spec.js:48-118`
- Exact validation result: `Test Suites: 2 passed, 2 total; Tests: 14 passed, 14 total`.
- Final status: intended modified files only; no `node_modules` symlink; `git diff --check` clean.

## Thread `019fb713-0b24-7323-941a-c766d20f9d78`
updated_at: 2026-07-31T07:56:34+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-28-26-019fb713-0b24-7323-941a-c766d20f9d78.jsonl
rollout_summary_file: 2026-07-31T07-28-26-vltS-mr872_realtime_badge_final_merge_review.md

---
description: Final read-only review of oho-web-app MR !872; prior raw badge-field and open-room blockers were fixed, and the MR was verified mergeable with focused tests passing.
task: review GitLab MR !872 merge readiness
 task_group: /Users/tualek/ohochat/oho-web-app / realtime smartchat badge reviews
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: MR-872, 8150150f, smartchat, refreshChatRoomBadgeRealtime, is_read_by_me, is_unresponded, feature-flags, open-room, Vuex, websocket, mergeable, Jest
---

### Task 1: Final MR !872 merge review

task: determine whether MR !872 can merge after iterative fixes
task_group: oho-web-app realtime unread/unresponded badge review
task_outcome: success

Preference signals:
- The user asked whether the MR could merge and repeatedly requested another check -> future reviews should re-fetch current GitLab metadata and re-review the latest exact head, not rely on prior conclusions.
- The review was explicitly read-only and avoided a dirty main checkout -> preserve user worktrees and inspect the MR via GitLab or an isolated clean worktree.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` spreads raw socket payloads before `handleSmartchatRealtimeUpdate` picks `DEFAULT_UPDATE_FIELDS`; feature flags must strip raw `is_unresponded` and `is_read_by_me`, not only gate synthesized fields.
- Final fix computes `is_open_room` before the optimistic/fallback split and strips `is_read_by_me` when `!is_unread_enabled || is_open_room`; this protects the contract that open-room read state is owned by `markRoomRead`.
- Final MR head `8150150f4fc9955cb7816288c90e511ff28a28b8` is based directly on `develop` `897245556ae6062ba6146996d527e212e5d334ce`; GitLab reported mergeable, conflict-free, zero divergence, and resolved discussions.
- Focused validation passed on Node `22.23.1`: `test/store/modules/smartchat.spec.js` and `test/store/modules/websocket.spec.js`, 2 suites and 79 tests.

Failures and how to do differently:
- Earlier heads had two real blockers: raw badge fields bypassed disabled flags; then raw `is_read_by_me:false` bypassed the open-room guard. Always test raw payload fields for both optimistic and fallback paths, including open-room behavior.
- No GitLab pipeline or manual QA was available; merge approval should state those limitations explicitly.

References:
- Final MR state: `sha=8150150f4fc9955cb7816288c90e511ff28a28b8`, `detailed_merge_status=mergeable`, `has_conflicts=false`, `diverged_commits_count=0`, `head_pipeline=null`.
- Test command: `rtk /Users/tualek/.nvm/versions/node/v22.23.1/bin/node /Users/tualek/.nvm/versions/node/v22.23.1/lib/node_modules/npm/bin/npm-cli.js test -- --runInBand --no-cache test/store/modules/smartchat.spec.js test/store/modules/websocket.spec.js`
- Result: `Test Suites: 2 passed, Tests: 79 passed`.
- Code: `store/modules/smartchat.js:798,815,837-848`.
- Tests: `test/store/modules/smartchat.spec.js:1832-1896`.

## Thread `019fb73d-b08e-7d42-947c-493c374ac7c0`
updated_at: 2026-07-31T08:25:23+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T15-15-01-019fb73d-b08e-7d42-947c-493c374ac7c0.jsonl
rollout_summary_file: 2026-07-31T08-15-01-Mjxm-rev2_unread_unresponded_refactor_plan_adversarial_review.md

description: Read-only adversarial review of rev.2 unread/unresponded one-sprint refactor plan; verdict NEEDS-CHANGES. Highest-value takeaway: land OHO-1272 and establish production-safe measurement/data-contract/rollout foundations before implementing dark state dual-write.
task: review-rev2-unread-unresponded-one-sprint-refactor-plan
task_group: /Users/tualek/ohochat/oho-api unread-unresponded code/design review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: unread-unresponded, contact_chat_states, dark-write, dark-verify, badge-counts, countBaseQuery, feature-flags, eligible-members, last_contact_date, OHO-1272, applyClearUnreadUnrespondedWrites, Atlas Search, production-canary

### Task 1: Review rev.2 and prioritize a two-week production-enablement backlog

task: review-rev2-unread-unresponded-one-sprint-refactor-plan
task_group: oho-api read-only architecture and performance review
task_outcome: success

Preference signals:
- The user required an “Adversarial review round 2,” asked to challenge scope aggressively, and requested “verdict ... numbered findings with file:line evidence ... prioritized 2-week backlog with explicit cut-line” -> similar reviews should be concise, judgmental, source-cited, and end with a hard scope boundary.
- The user required branch/worktree verification and “read-only, do NOT modify” -> pin revisions, inspect live diffs, and never edit/stage/commit during review.

Reusable knowledge:
- `buildCustomerMessageUnreadPayload` resolves eligible members only when `rt_unread_feature_enabled` is enabled (`src/utils/build-customer-message-unread-payload.ts:28-37`). CLEAR and mark-read remain unconditional by design (`src/utils/build-clear-unread-unresponded-payload.ts:18-20`, `src/webhook/stream.js:94-160`). A Track B shadow write therefore needs its own kill switch and must not silently run whenever existing flags are off.
- Badge counts preserve the current tab/search scope. `buildCountBaseQuery` strips pagination/meta and badge filters but keeps other query fields (`src/services/contact/chat-search/build-count-base-query.ts:17-21`); the integration contract explicitly covers status, assignment, starred, tags, and visibility (`test/integration/chat-search-badge-count-scope.test.ts:4-18`). State with only business/channel/spam/unread fields cannot reproduce current counts without a contract change or additional join/mirror design.
- Existing customer SET uses `last_contact_date` as an ordering guard (`src/services/contact-send-message/contact-send-message.hooks.js:230-239`). A copied timestamp alone does not establish cross-collection ordering when old/new writes race or fail independently; use a monotonic event timestamp/sequence and reject stale events.
- Search currently computes badge counts before returning data (`src/services/contact/chat-search/chat-search.class.js:96-115`). An API-only separate badge endpoint produces no performance win until web stops requesting inline counts; group search has a separate model/path and starred-scope behavior (`src/services/chat-session/group/search/search.hooks.js:92-147`, `search.class.js:69-98`).
- OHO-1272's uncommitted worktree centralizes clear writes through `src/utils/apply-clear-unread-unresponded-writes.ts:28-57` across eight call sites. `origin/develop` overlaps six relevant files after `bbe0ac735`; land/rebase this work before adding Track B.
- Exact raw `diff = 0` is unsuitable for dark verification because dual writes can interleave and fail-soft writes intentionally tolerate stale badges. Compare normalized semantics, track mismatch age, repair old mismatches, and require zero persistent aged mismatches over repeated scans.
- Existing feature-flag infrastructure supports per-business canary and emergency rollback (`docs/feature-flags.md:370-379`); reuse it for a dedicated dark-write flag rather than coupling state writes to customer-facing flags.

Failures and how to do differently:
- Do not treat rev.2's Track B scope as automatically justified. The plan's own reference phase says to measure eligible-member distribution, document size, and SET latency before deciding whether collection separation is worthwhile (`plan:237-240`). Make that measurement a prerequisite.
- Do not accept an API-only Track A as a performance deliverable. Add a minimal web consumer that disables inline counts, or remove Track A from the sprint.
- Do not use a snapshot exact-zero dark-verify gate. Use semantic normalization, grace windows, repair, mismatch age/error metrics, and repeated scans.
- Do not implement Track B before the OHO-1272 clear-write consolidation; overlapping uncommitted/current-develop changes create conflict and can regress fail-soft semantics.
- Do not place a nonessential shadow write inside close-case transactions during dark phase: state failure can abort the existing business transaction. Atomic cross-collection transactions belong when state becomes authoritative.

References:
- `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md:107-151,237-240`
- `src/utils/build-customer-message-unread-payload.ts:28-37`
- `src/services/contact-send-message/contact-send-message.hooks.js:213-239`
- `src/utils/build-clear-unread-unresponded-payload.ts:18-20`
- `src/services/contact/chat-search/build-count-base-query.ts:17-21`
- `test/integration/chat-search-badge-count-scope.test.ts:4-18`
- `src/services/contact/chat-search/chat-search.class.js:96-115`
- `src/utils/apply-clear-unread-unresponded-writes.ts:28-57`
- `src/webhook/stream.js:135-160`
- `docs/feature-flags.md:370-379`
- Review revisions: local `develop@fadce8537`, `origin/develop@a98fb25a`, OHO-1272 worktree `bbe0ac735`.

