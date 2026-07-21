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

