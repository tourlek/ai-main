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

## Thread `019fb1c7-36c8-7a02-92cc-6ab6c74fcc58`
updated_at: 2026-07-30T06:56:14+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T13-47-30-019fb1c7-36c8-7a02-92cc-6ab6c74fcc58.jsonl
rollout_summary_file: 2026-07-30T06-47-30-iE0E-cross_repo_jera_tab_fix_review_ship_blockers.md

description: Read-only cross-repo review of JERA tab race fix found a Feathers hook-registration startup blocker, fail-open login failure semantics, and weak direct-unit-test coverage; frontend contact-change regression was not reintroduced.
task: review uncommitted JERA tab race fix across oho-web-app and oho-api
task_group: cross-repo code review
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: JERA, MaxPanel, feature_flags, Firebase Remote Config, Feathers hooks, service.hooks, Promise.all, contact_id, EPERM, Jest

### Task 1: Review oho-api login feature-flag hook

task: inspect login hook wiring, security, failure semantics, DRY, and tests
task_group: oho-api login feature flags
task_outcome: fail

Preference signals:
- The user requested a strictly review-only task across two separate worktrees and required every claim to cite actual file lines -> future reviews should inspect live diffs and avoid edits or unsupported speculation.
- The user explicitly required checking whether `e70f8a8a` contact-change refetch behavior was reintroduced -> always compare current watcher/call paths against the removed behavior, not just search for matching text.

Reusable knowledge:
- `login.service.js:16` calls `service.hooks(hooks)`, and Feathers treats every enumerable top-level export as a hook namespace. Exporting `addFeatureFlagsToResult` alongside `before/after/error` causes an invalid hook type and blocks service registration.
- `addFeatureFlagsToResult` reads `context.params.member.business_id` only after authentication, membership lookup, and member refresh (`login.hooks.js:36-70,146-150`), so the business ID is database-derived at that point rather than freely attacker-supplied.
- `Promise.all` at `login.hooks.js:121-126` rejects the entire after-hook when any flag helper rejects; `error.create` has no recovery. Remote Config fetch errors are caught, but `template.evaluate()` is outside that catch (`firebase-remote-config.js:35-52,79-85`).
- The helper reuses `businessSignal()` and `getBoolean()`; the semantic wrappers for unread, unresponded, and JERA do not require another abstraction.
- New login tests mock all Remote Config functions and directly invoke the exported helper. They therefore do not validate Feathers registration, production after-chain wiring, rejection handling, or the real JERA implementation. The handcrafted business ID/context also conflicts with the repo’s fixture-derived test standard.

Failures and how to do differently:
- Do not export helper functions as enumerable properties from a Feathers hook module passed wholesale to `service.hooks()`. Keep helpers non-exported, attach them safely for tests, or test through service registration.
- Do not let auxiliary feature-flag evaluation abort authentication. Use per-flag fail-soft defaults/logging or an explicitly validated fallback policy.
- Add a service-registration test and a rejected-helper test; direct helper tests alone miss the startup blocker and login availability regression.

References:
- `src/services/authentication-member/login/login.hooks.js:121-145,164-180,186-193`
- `src/services/authentication-member/login/login.service.js:3,16`
- `node_modules/@feathersjs/commons/lib/hooks.js:142-147`
- `src/firebase-remote-config.js:35-52,79-85,198-229`
- `src/services/authentication-member/login/login.hooks.spec.js:24-32,42-48,55-127`

### Task 2: Review oho-web-app MaxPanel fix

task: inspect race closure, retry behavior, and contact-change regression
task_group: oho-web-app JERA MaxPanel
task_outcome: partial

Preference signals:
- The user asked for test-by-test assessment, including whether a test would still pass if the fix were reverted -> future reviews should mentally revert each relevant production change and distinguish branch tests from integration proof.

Reusable knowledge:
- `MaxPanel.vue:361-374` watches the reactive feature flag with `immediate: true`; this covers both initial true state and a late browser/API flag transition.
- `MaxPanel.vue:375-383` retries only on focus when the flag is enabled, no fetch is active, and the previous attempt errored. `fetchJeraPartnerConnections()` sets the in-flight guard before awaiting and records errors at `:725-753`.
- The hotfix behavior from `e70f8a8a` remains removed: `contact_id` watcher only sets `active_profile_source` (`:402-406`). Fetch triggers are flag/focus watchers and explicit connect/disconnect methods (`:361-383,754-760`).
- MaxPanel tests directly invoke watcher handlers. They cover branches but not actual Vuex reactivity, watcher scheduling, `immediate: true`, visibility-change propagation, or simultaneous triggers.

Failures and how to do differently:
- Treat direct watcher-handler tests as partial coverage, not proof of the race fix. Add a mounted/component test that changes Vuex state from false to true and verifies the API fetch, plus an in-flight concurrency test.
- The “flag re-evaluates true” test is artificial because a Vue boolean watcher does not naturally rerun for `true → true`; focus retry is the realistic retry path.

References:
- `components/MaxPanel.vue:361-383,402-412,447-449,725-753,754-760`
- `test/components/MaxPanel.spec.js:251-340`
- `layouts/default.vue:468-480`
- `e70f8a8a` removed the old contact-change fetch from the `contact_id` watcher.

### Task 3: Assess frontend/backend interaction

task: trace login flags, browser Remote Config precedence, and double-fetch risk
task_group: cross-repo feature-flag integration
task_outcome: partial

Reusable knowledge:
- `nuxtServerInit` awaits `authOhoMember`, which commits `res.feature_flags` into Vuex (`store/index.js:300-302,502-512`); MaxPanel reads `state.feature_flags.rt_jera_feature_enabled` (`MaxPanel.vue:447-448`).
- `setFeatureFlags` records API-authoritative keys and `setRemoteConfigFeatureFlags` filters those keys (`store/index.js:103-128`), so normal API/browser resolution ordering should not overwrite server decisions.
- MaxPanel’s nonempty-result and in-flight guards prevent ordinary duplicate JERA fetches (`MaxPanel.vue:363-370,725-735`).
- If server Remote Config cold-start evaluation returns default false (`firebase-remote-config.js:35-52,119-129`), that false becomes authoritative and later browser true is discarded, leaving a possible session-level hidden-tab failure.

Failures and how to do differently:
- Review API-authoritative flag systems for both overwrite safety and recovery semantics. Preventing browser overwrite can also suppress recovery from a transient server-side flag-evaluation failure.
- Targeted tests were not executable in this sandbox: both Jest commands failed with `EPERM` writing haste-map files. Record this as unverified rather than claiming tests passed.

References:
- `store/index.js:103-128,300-302,502-512`
- `plugins/firebase-remote-config.js:43-56,85-89`
- `src/firebase-remote-config.js:35-52,119-129`
- Test error: `EPERM: operation not permitted, open .../jest_dx/haste-map-...`

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

## Thread `019fb663-2d39-79b3-9364-4845f05664c6`
updated_at: 2026-07-31T04:25:57+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T11-16-20-019fb663-2d39-79b3-9364-4845f05664c6.jsonl
rollout_summary_file: 2026-07-31T04-16-20-SFMO-cross_repo_review_mr872_mr1291_realtime_badge_blockers.md

description: Read-only cross-repo review of realtime unread/unresponded badge MRs; API timestamp change passed, frontend consumer remained blocked by count reconciliation, equal-timestamp, and duplicate insertion risks
 task: review oho-web-app !872 and oho-api !1291 merge readiness
 task_group: /Users/tualek/ohochat / cross-repo unread-unresponded MR review
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: oho-web-app, oho-api, MR-872, MR-1291, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, oho_created_at, last_contact_date, unread_count, unresponded_count, equal-timestamp, duplicate-fetch, Vuex

### Task 1: Review oho-web-app !872

task: determine whether frontend realtime badge MR is safe to merge
 task_group: cross-repo unread/unresponded frontend review
 task_outcome: fail

Preference signals:
- The user asked whether the two MRs had anything blocking merge; similar reviews should remain read-only, inspect the exact MR head, and give concrete merge blockers with `file:line` evidence rather than edit files.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` computes optimistic aggregate transitions before the optional authoritative fetch. In the reviewed head, count transitions occur at `store/modules/smartchat.js:829-875`, while fetched data is merged later at `:931-943`; final `is_read_by_me` / `is_unresponded` values do not reconcile `unread_count` or `unresponded_count`.
- The equal-timestamp stale guard at `smartchat.js:737-743` uses `<=` and returns before injecting `is_read_by_me:false` at `:745-752`. A `chat-session/status updated` payload may carry `last_contact_date` and `is_unresponded` but no unread field, so a same-timestamp customer-message event can fail to mark unread.
- Missing-room/timestamp-less events can fetch concurrently. The insertion mutations at `smartchat.js:128-159` use blind `push`/`unshift`; `RoomList`'s `uniqBy` only hides duplicates visually and does not repair pagination or aggregate state.
- API emits one customer-message socket event per bubble (`oho-api/src/services/contact-send-message/contact-send-message.hooks.js:386-422`), making concurrent duplicate-fetch exposure realistic.

Failures and how to do differently:
- Symptom: quick-filter red-dot totals remain stale after fallback fetch. Cause: aggregate transition happens before authoritative row merge. Fix: reconcile counts from the final fetched row, or defer transition calculation until after fetch.
- Symptom: unread is missed when status and message events share a timestamp. Cause: `<=` guard drops the message before unread injection. Fix: distinguish status freshness from customer-message unread freshness, or use an event/version contract that preserves unread transitions.
- Symptom: duplicate rows/pagination drift during event bursts. Cause: multiple handlers fetch and insert the same missing room without in-flight dedupe or identity checks. Fix: single-flight per contact and deduplicate before insertion.

References:
- MR head: `5fc4ef224814aec240b55891ef36664e0abce5cd`; base: `619b618208f8643cdd5a7c4cd624eeab1b394f9c`.
- `store/modules/smartchat.js:718,728-743,745-763,829-875,931-943,986-1009`.
- GitLab status: `detailed_merge_status: mergeable`, `has_conflicts: false`, `pipeline: null`, `head_pipeline: null`, `blocking_discussions_resolved: true`.

### Task 2: Review oho-api !1291

task: determine whether backend timestamp payload MR is safe to merge
 task_group: cross-repo unread/unresponded API review
 task_outcome: success

Reusable knowledge:
- `oho_created_at` is populated from the Stream message payload and reused as the timestamp for `last_contact_date` under the guarded update in `src/services/contact-send-message/contact-send-message.hooks.js:164,230-236,296,402-415`.
- The field is additive to socket message payloads and does not alter existing client behavior for clients that ignore it.
- The same payload object is later passed to push notification code (`:428-443`), so adding a socket-specific field also expands the push payload contract; this was judged low-severity scope creep, not a merge blocker.

Failures and how to do differently:
- No code blocker was found in !1291 itself. Before merge, confirm downstream push-notification consumers tolerate the additive `oho_created_at` field.

References:
- MR head: `bbe0ac735634caf91cbe43c91eb18c5578c1d185`; base: `5971ebf5673a838010ac5c9ca810e6d76163f555`.
- Changed file: `src/services/contact-send-message/contact-send-message.hooks.js`.
- GitLab status: `detailed_merge_status: mergeable`, `has_conflicts: false`, `pipeline: null`, `head_pipeline: null`, `blocking_discussions_resolved: true`.
- Both MR diffs passed `git diff --check`; functional suites were not run because local worktrees were not checked out at the MR heads.

## Thread `019fb6c7-39c5-7110-9c61-b4878f375e66`
updated_at: 2026-07-31T06:35:27+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T13-05-37-019fb6c7-39c5-7110-9c61-b4878f375e66.jsonl
rollout_summary_file: 2026-07-31T06-05-37-BMns-oho_1272_second_round_realtime_badge_review.md

---
description: Second-round read-only verification of OHO-1272 realtime badge fixes; correctness blockers fixed, but formatting and a vacuous visibility test caused NO-SHIP
 task: review-uncommitted-smartchat-realtime-badge-fixes
 task_group: oho-web-app-smartchat-code-review
 task_outcome: partial
 cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
 keywords: OHO-1272, smartchat.js, addRealtimeContactToList, is_unresponded, equal-timestamp, dedupe, Jest, Prettier, EPERM, UAT
---

### Task 1: Equal-timestamp raw badge contract

task: verify equal-timestamp realtime event handling
task_group: smartchat realtime badge review
task_outcome: success

Preference signals:
- The user required a read-only review with actual file:line citations and specifically asked to verify raw `is_unresponded` stripping; future reviews should inspect the live diff and prove the raw-payload contract, not rely on synthesized-field reasoning.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` now deletes `event_message.is_unresponded` only when `is_equal_timestamp` is true (`store/modules/smartchat.js:775-805`). Newer events still synthesize `is_unresponded:true` (`:791-797`).
- Equal events retain `is_read_by_me:false` and `last_contact_date`, allowing the downstream local-read cursor guard to run.

Failures and how to do differently:
- The earlier version only avoided synthesizing `is_unresponded`; raw payload fields could still survive. The corrected implementation strips the raw field after the spread.

References:
- `store/modules/smartchat.js:775-805`
- `test/store/modules/smartchat.spec.js:1394-1420`

### Task 2: Atomic realtime dedupe and cap handling

task: verify duplicate-row fix and capped-list behavior
task_group: smartchat realtime insertion
 task_outcome: success

Reusable knowledge:
- `addRealtimeContactToList` performs dedupe first, then optional tail pop, then head/tail insertion and Set reconciliation in one synchronous mutation (`store/modules/smartchat.js:172-201`). This prevents the prior await-separated pop/insert race that could lose an unrelated tail row.
- Realtime insertion maps `from_head: sort_chat_list !== 1` (`store/modules/smartchat.js:1048-1055`), preserving normal unshift behavior and oldest-sort push behavior.
- Repo-wide grep found no executable `handleLimitContactList` or `removeLastContact` references; only the explanatory comment at `smartchat.js:174` remains.
- Pagination still uses `addContactListData`/`addContactListDataFromHead`, which retain dedupe but intentionally do not add cap-pop behavior.

References:
- `store/modules/smartchat.js:178-201`
- `store/modules/smartchat.js:1048-1055`
- `test/store/modules/smartchat.spec.js:1434-1488`

### Task 3: Test and formatting validation

task: validate store/full test results and formatting
task_group: smartchat verification and UAT gate
task_outcome: partial

Preference signals:
- The user asked for decisive UAT gating and explicit separation of unrelated full-suite failures from changed-code failures; future reviews should report exact suite/test counts and causality.

Reusable knowledge:
- Store scope passed 61/61 (`smartchat.spec.js` + `websocket.spec.js`) under a narrowly scoped Jest cache-write workaround. Direct Jest execution otherwise failed before tests due sandbox `EPERM` writes under `/private/var/folders/.../jest_dx`.
- Full test run: 53 suites passed, 4 failed; failures were in unchanged JERA/media suites: `MaxPanel`, `IntegrationExternal`, `MaxPanelJeraProfilePanel`, and media-library `_type`. Changed files were only the Smartchat store/test files.
- Direct installed `./node_modules/.bin/prettier --check` (Prettier 2.8.8) flagged both changed files. An earlier `rtk npx prettier --check` clean result was a proxy false positive; use the repository binary for formatting verification.
- The visibility-negative test is weak/vacuous: it mocks visibility false but leaves `getAvailableMenusForChatRoom` returning `[]` while the active menu is `all`, so insertion is blocked regardless (`test/store/modules/smartchat.spec.js:492-515`; `__mocks__/mock-plugin.js:53-57`; `__mocks__/mock-store.js:41-43`). Set available menus to `['all']` to genuinely exercise visibility.
- No direct test covers `from_head:false` at the cap; implementation was statically verified but this remains a non-blocking coverage gap.

Failures and how to do differently:
- Do not accept formatter validation from optimized wrapper output when it conflicts with the installed binary. Run `./node_modules/.bin/prettier --check` directly.
- Do not treat a negative assertion as meaningful unless other branch predicates are configured to allow the behavior under test.

References:
- Store validation: `smartchat.spec.js` + `websocket.spec.js`, 61 passed.
- Full validation: 53 passed, 4 failed; 702 passed, 25 failed, 2 skipped.
- Formatting command: `./node_modules/.bin/prettier --check store/modules/smartchat.js test/store/modules/smartchat.spec.js`
- Final verdict: `NO-SHIP` until formatting is clean and the visibility test is non-vacuous.

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

## Thread `019fb71f-7572-71d1-b82a-670541b3921c`
updated_at: 2026-07-31T07:51:34+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-42-00-019fb71f-7572-71d1-b82a-670541b3921c.jsonl
rollout_summary_file: 2026-07-31T07-42-00-B5iQ-read_only_review_contact_chat_states_refactor_plan.md

---
description: Read-only audit rejected direct migration of unread_by/is_unresponded into contact_chat_states within one sprint; key takeaway is that ordering, search, authorization, emitters, groups, and cross-repo writes are coupled.
task: audit one-sprint contact_chat_states refactor against live oho-api code
task_group: /Users/tualek/ohochat/oho-api unread-unresponded architecture review
task_outcome: success
cwd: /Users/tualek/ohochat
akeywords: unread_by, is_unresponded, contact_chat_states, Atlas Search, last_contact_date, last_active_at, message.read, oho-websocket, NO-SHIP
---

### Task 1: Review contact_chat_states refactor plan

task: Verify an 8-point refactor plan against live oho-api and related repositories without edits.
task_group: unread-unresponded architecture/code review
task_outcome: success

Preference signals:
- When the user required “READ-ONLY — do not modify any files,” preserve all repo state and use only inspection commands.
- When the user required every finding to cite an actual `file:line` and a verdict-first numbered format, independently verify source lines and keep the final report compact and evidence-first.

Reusable knowledge:
- `contact-send-message.hooks.js:230-239` atomically guards unread SET writes with `last_contact_date: {$lte: timestamp}` and updates the timestamp plus unread payload together. A separate state collection needs its own ordering timestamp and synchronized/atomic semantics.
- `last_active_at` is not `last_contact_date`: `contact.model.js:223-224` defines both, while `update-contact-last-active-at.js:12-14` and many workflows update `last_active_at` independently. A state collection sorted by `last_active_at` needs broad mirror maintenance.
- `emit-chat-session-event.js:47-120` re-queries and populates the contact, including `is_unresponded`; `:248-289` re-queries for eligibility-scoped emits. Existing write sites often discard update results, so a “no extra query” emitter design is not present.
- Atlas Search applies typed unread filters against storedSource before lookup/pagination (`chat-session/utils/search-query-converter.ts:149-195`; contact search pipelines `search-payload-original.js:123-138` and `search-payload-optimized.js:317-332`). State-first paging cannot safely handle keyword filters without joining/filtering before skip/limit.
- Sale visibility is mandatory contact-side authorization (`shared-hooks.js:373-404, 557-601`); channel permission intersects allowed channels and may force `$limit=0` (`validate-member-channel-permission.js:17-28`). State-first pagination can underfill or expose incorrect results.
- `build-count-base-query.ts:17-21` removes only pagination and unread fields, while `compute-badge-counts.ts:78-95` executes the remaining filters directly against the selected model. Counts require mirrored contact fields or a join after migration.
- Group sessions use a separate collection, separate index shapes, and domain `type: messaging|group` (`chat-session.model.js:31-36, 128-153`). A shared state collection needs a non-conflicting discriminator and collision-safe identity.
- Mark-read writes exist in both `oho-api/src/webhook/stream.js:137-150` and `oho-websocket/src/webhook/stream.js:169-199`; websocket also has strict mirror models at `oho-websocket/src/models/contact.model.js:14-17` and `chat-session.model.js:16-19`.
- Production grep found no `unread_by`/`is_unresponded` matches in `oho-cronjob` or `oho-developer-api`.

Failures and how to do differently:
- Do not equate `last_active_at` with `last_contact_date`.
- Do not page state IDs before applying contact keyword, sale-visibility, and permission filters.
- Do not assume emitters receive write results; inspect their actual context and query behavior.
- Do not scope the migration to two builders: include bulk/group clears, both mark-read repos, Atlas indexes/pipelines, model mirrors, deletion cleanup, badge counts, and auth hooks.

References:
- Plan: `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md:99-228`.
- Final verdict: `NO-SHIP`.
- oho-api revision reviewed: `fadce85370eb42828570b91edb1649b401a424a1`.

## Thread `019fb720-b89a-7483-ad06-486d9c12dd1e`
updated_at: 2026-07-31T07:53:55+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-43-22-019fb720-b89a-7483-ad06-486d9c12dd1e.jsonl
rollout_summary_file: 2026-07-31T07-43-22-cSLQ-no_ship_contact_chat_states_refactor_plan_audit.md

---
description: Read-only cross-repo audit of the proposed one-sprint migration of unread_by/is_unresponded into contact_chat_states; verdict NO-SHIP due to missing ordering state, incompatible search/count/filter design, incomplete synchronization, and unrealistic scope
task: audit unread-unresponded contact_chat_states refactor plan against develop
 task_group: /Users/tualek/ohochat/oho-api unread-unresponded architecture review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: contact_chat_states, unread_by, is_unresponded, last_contact_date, last_active_at, Atlas Search, pagination, countBaseQuery, sale visibility, mark-read, oho-websocket, read-only, NO-SHIP
---

### Task 1: Audit one-sprint state-collection refactor

task: Review section 5 of the unread/unresponded refactor plan against pinned develop source across oho-api and oho-websocket.
task_group: unread-unresponded cross-repo plan review
task_outcome: success

Preference signals:
- when the user required “read-only — do NOT modify anything” -> pin branch/object state and preserve all repositories; do not edit, stage, commit, checkout, or fetch.
- when the user required “SHIP/NEEDS-CHANGES/NO-SHIP + numbered findings with file:line and severity” -> produce a direct severity-ranked verdict with exact evidence, not a generic design discussion.
- when the user asked to verify all eight concerns, cross-repo writers, call-site count, and omitted tasks -> trace the full SET -> guard -> storage -> realtime -> search/count/filter contract and enumerate direct writers.

Reusable knowledge:
- Existing SET writes guard on `last_contact_date: {$lte: timestamp}`; CLEAR and mark-read paths use the same ordering field. `last_active_at` is separate and advances for non-customer actions, so a new state document needs both fields plus explicit initialization.
- `contact_chat_states` cannot safely support state-first page-of-20 pagination with current sale-visibility, assignment, tag, label, and keyword filtering. Filtering contacts after selecting 20 state IDs causes skipped/underfilled pages; `$in` also loses state sort order.
- Atlas Search currently relies on `unread_by`/`is_unresponded` in storedSource before `$lookup` in contact and group pipelines. Removing those fields requires redesigning all contact legacy, contact optimized, and group keyword paths.
- `buildCountBaseQuery()` strips only metadata and typed unread fields, while preserving tab and contact visibility filters; `computeBadgeCounts()` sends the resulting filter to `countDocuments`. It cannot be applied directly to a lean state collection lacking contact fields.
- Generic and eligibility emitters re-query contact/session documents and several writes ignore update results or use `updateOne`; there is no universal “write returns state doc” contract.
- Close-case’s second collection write is transaction-compatible only if the new model uses the same app DB connection and receives the existing session. Add rollback tests for both collections.
- `chat-session.type` already means `messaging | group`; using `contact | group` in the new collection is ambiguous. Use an explicit entity discriminator or preserve existing room vocabulary.
- Cross-repo mark-read must update both service models and deployment/test coordination. `oho-cronjob` and `oho-developer-api` had no unread/unresponded references in the checked develop trees.
- The stated prod facts (flags off, no backfill, only canary data) were accepted from user context, not verified from source. They may justify skipping old-field dual-write, but do not remove ordering/scope synchronization requirements.

Failures and how to do differently:
- CodeGraph was unavailable because `/Users/tualek/ohochat/oho-api` had no `.codegraph` index; pivot to `git grep`, `git show`, and pinned remote objects.
- Git emitted macOS temp/cache permission warnings; treat the review as source/structural verification only, not full behavioral or production validation.
- Do not trust plan claims that writes are centralized or that emitters can use write results until every direct model write and returned value is enumerated.

References:
- Plan: `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md:99-159`.
- API target: `origin/develop@6d85562a41dd438ae00fb68409ca484cbcb53e12`.
- Websocket target: `origin/develop@2c766c62da63ab1693a8bff928bdb78eceb64c80`.
- Ordering SET: `src/services/contact-send-message/contact-send-message.hooks.js:230-239`; group SET: `src/services/chat-session/group/contact-user/send-message/send-message.class.js:25-37`.
- Search: `src/services/chat-session/utils/search-query-converter.ts:149-195`; contact search setup: `src/services/contact/chat-search/chat-search.hooks.js:78-105`.
- Count scope: `src/services/contact/chat-search/build-count-base-query.ts:14-21`; `src/utils/compute-badge-counts.ts:71-95`.
- Visibility/pagination: `src/services/contact/chat-search/shared-hooks.js:373-404,557-601`; channel permission: `src/hooks/validate-member-channel-permission.js:8-29`.
- Transaction: `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-69`; callers `end-case.class.js:17-38`, `no-case.class.js:17-42`.
- Emitters: `src/services/chat-session/hooks/emit-chat-session-event.js:47-128,218-289`.
- Mark-read: `src/webhook/stream.js:127-170`; websocket: `/Users/tualek/ohochat/oho-websocket/src/webhook/stream.js:143-205`.

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

## Thread `019fb917-4170-7273-a018-fe437807752a`
updated_at: 2026-07-31T16:57:58+00:00
cwd: /Users/tualek/ohochat/docs/react-migration
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T23-52-16-019fb917-4170-7273-a018-fe437807752a.jsonl
rollout_summary_file: 2026-07-31T16-52-16-hvzY-review_backoffice_react_migration_plan.md

description: Read-only, evidence-based review of the oho-backoffice React migration plan against the actual Nuxt/Vue repository; found route inventory, API/auth contract, cross-app navigation, testing, deployment, and observability gaps requiring rework before implementation
task: review oho-backoffice React migration plan against repository source
 task_group: migration-plan-review
 task_outcome: success
cwd: /Users/tualek/ohochat/docs/react-migration
keywords: oho-backoffice, react-migration, Nuxt2, Vue2, TanStack Router, Cloud Run, path-based-cutover, auth-cookie-contract, external-message, API-inventory, read-only-review

### Task 1: Review migration plan against actual oho-backoffice repo

task: compare backoffice-react-v2-plan.md with live oho-backoffice source without editing
 task_group: migration-plan-review
 task_outcome: success

Preference signals:
- When the user specified “Scope is strictly oho-backoffice only” and “do not edit the plan file or any other files” -> keep future reviews scoped to that repo and strictly read-only.
- When the user required organization by plan section/phase, quoted references, concrete adjustments, and a prioritized top 3–5 -> report findings phase-by-phase, evidence-first, with actionable fixes and a short priority list.
- When the user required grounding in verifiable files and said not to guess repo structure/tooling -> inspect route, API, auth, dependency, and deployment sources before asserting a gap.

Reusable knowledge:
- The v2 plan omitted active production routes `/external-message-apps` and `/external-message-whitelist`, present in `oho-backoffice/store/modules/menu.js:92-103` and implemented by `pages/external-message-apps.vue` and `pages/external-message-whitelist.vue`. Add them to route inventory, feature structure, tests, smoke tests, and cutover sequence.
- The plan’s sample API contract is inaccurate: real endpoints are in `oho-backoffice/api/endpoint.js`, including `/backoffice/business` and `/backoffice/authentication-user`; business data uses `_id`, `is_disabled`, and `is_deleted`, not the simplified `/businesses`, `id`, and `status` example.
- Existing auth behavior is in `store/index.js:96-166`: cookies include `auth_user_token`, `auth_user_id`, and `auth_created_token_at`; token exchange uses the backoffice authentication endpoint. `plugins/axios.js:3-45` attaches the current cookie token to requests.
- Existing cookie writes are host-only with `maxAge`; the plan’s proposed `.oho.chat` domain and deletion on every bootstrap failure require explicit review. Preserve codec, domain/path, SameSite/Secure, expiry, removal attributes, and distinguish 401/403 from transient network/5xx failures.
- The plan introduces Zustand state (`sidebarCollapsed`, `commandPaletteOpen`) without evidence that either behavior exists in the current backoffice. For a 1:1 migration, defer these unless a parity inventory proves they are required.
- Legacy URL state is not equivalent to the proposed React schema. Existing business menu links use `is_disabled` and `is_deleted` (`store/modules/menu.js:19-31`), while payment and list pages use additional legacy query parameters. Preserve compatibility during gradual cutover.
- URL-map path routing can be bypassed by client-side navigation: Nuxt uses `<nuxt-link>` and `$router.push()` (`components/Sidenav.vue`, `components/SubMenu.vue:117-131`). Define a hard-navigation rule at React/Nuxt ownership boundaries, maintain a route ownership manifest, and test navigation in both directions plus browser history.
- Cloud Run and build strategy are coupled decisions. The plan locks Cloud Run but defers build-per-env versus build-once runtime config to Phase 5; decide hosting/runtime config in Phase 0 because it changes Dockerfile, nginx, CI, artifact promotion, and rollback.
- Testing needs implementation gates, not only a locked stack: configure Vitest/RTL/Playwright, controlled staging fixtures, lint/typecheck/unit/build CI gates, and per-route E2E assertions for mutations, uploads, destructive actions, validation, and recovery.
- `Intl.NumberFormat` needs a parity contract before replacing numeral. `plugins/numeral-format.js` supports integer, fixed-decimal, percentage, compact, currency-prefix, and null/Decimal-like formatting. Create separate helpers and golden tests.
- Runtime-liveness audit is required before porting cross-cutting behavior. Socket, window-focus, mobile detection, and widget lifecycle calls are commented out in `layouts/default.vue`; classify active, dead, or intentionally removed behavior.
- Phase 5 needs concrete LB exact/nested matchers, calendar-duration re-estimation, IaC, staging rollback drills, and explicit rollback/decommission exit criteria. A 5–7 day phase conflicts with 2–3 day observation windows per path.
- Cloud/LB metrics and an error boundary do not provide browser observability. Add frontend error reporting, source maps, release/environment tags, and separate React/Nuxt dashboards before production cutover.

Failures and how to do differently:
- A hand-written route list missed active external-message pages. Generate route/menu/page inventories from the repository and compare them with the plan.
- Generic React examples drifted from the real API and auth contract. Derive DTOs, endpoint wrappers, and examples from `api/endpoint.js`, auth actions, and representative page calls.
- Path-based cutover was underspecified for SPA client navigation. Test legacy→React and React→legacy transitions and enforce hard navigation across ownership boundaries.

References:
- `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`
- `/Users/tualek/ohochat/oho-backoffice/api/endpoint.js`
- `/Users/tualek/ohochat/oho-backoffice/store/index.js`
- `/Users/tualek/ohochat/oho-backoffice/plugins/axios.js`
- `/Users/tualek/ohochat/oho-backoffice/store/modules/menu.js`
- `/Users/tualek/ohochat/oho-backoffice/components/Sidenav.vue`
- `/Users/tualek/ohochat/oho-backoffice/components/SubMenu.vue`
- `/Users/tualek/ohochat/oho-backoffice/layouts/default.vue`
- Verified repo baseline: `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1`.

## Thread `019fb925-627a-7253-bc76-6715214f2a22`
updated_at: 2026-07-31T17:26:31+00:00
cwd: /Users/tualek/ai-main
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-07-42-019fb925-627a-7253-bc76-6715214f2a22.jsonl
rollout_summary_file: 2026-07-31T17-07-42-OOQ2-ai_main_workspace_linking_review_and_design_adjudication.md

---
description: Read-only review of ai-main workspace-linking implementation found deployment false-success, incomplete unlink cleanup, weak verification, registry mutation ordering, and broken-import false greens; adjudicated a smaller single-user architecture.
task: review ai-main workspace-linking implementation and compare workspace/prompt/enforcement designs
task_group: ai-main architecture and workspace deployment
 task_outcome: success
cwd: /Users/tualek/ai-main
keywords: bin/aimain, workspaces.json, workspace linking, git info exclude, deploy_all, verify.sh, unlink, generic knowledge, prompt budgets, git hooks, glab PATH shim
---

### Task 1: Review shipped workspace linking

task: static code review of registry-driven workspace deployment
 task_group: ai-main workspace deployment
 task_outcome: success

Preference signals:
- The user required strictly read-only investigation and asked for worst-first, line-referenced real-world bugs -> future reviews should avoid mutating test commands and clearly separate static evidence from unverified runtime claims.
- The user runs ai-main as a daily driver with launchd redeploys every six hours -> prioritize silent failure, false success, data loss, and rollback hazards over cosmetic issues.

Reusable knowledge:
- `bin/aimain:215-224` suppresses all `deploy_one` failures with `|| true`; `install.sh:345-351` and `scripts/sync.sh:56-58` can therefore report successful redeployment when workspace deployment failed.
- `bin/aimain:164` correctly computes exclusions with `git -C "$ws" rev-parse --git-path info/exclude`; the alleged shipped `--git-dir` bug is not present in the exclude path.
- `bin/aimain:159-170` adds five exclude entries, but `cmd_unlink` at `bin/aimain:262-286` never removes them. This disproves a clean unlink round-trip and leaves broad unanchored ignores.
- `scripts/verify.sh:197-210` skips missing directories and warns rather than failing for missing knowledge files, so invalid registry entries can still appear green.
- `bin/aimain:229-255` mutates `config/workspaces.json` before deployment. `--force` bypasses the early tracked-file check, but `deploy_one` still refuses tracked `AGENTS.md`, leaving a broken registry entry after failure.
- `bin/aimain:120-142` continues after missing knowledge imports; `scripts/verify.sh:206-210` checks only the generated marker, allowing incomplete generated files to pass.
- Ordinary non-sync deployment moves unmanaged handwritten instruction files at `bin/aimain:186-205`; this should require explicit force or refuse by default.
- `doctor` at `bin/aimain:316-332` reports drift but returns only Git-leak status, so it can exit zero despite broken attachments.

Failures and how to do differently:
- Do not claim `verify.sh` is fully green or link/unlink is clean from static inspection alone; dynamic verification requires running the commands in a disposable/test workspace, and unlink cleanup is visibly incomplete from code.
- Batch deployment should aggregate errors and return nonzero; registry changes should be atomic with deployment or rolled back on failure.

References:
- `config/workspaces.json:3-48` contains 11 registered workspaces, so a five-workspace equivalence test would be incomplete.
- `install.sh:337-355` delegates workspace deployment to `bin/aimain`; `scripts/sync.sh:53-58` runs it during automated redeploy.
- `bin/aimain:151-156` defines current ownership: alias symlink exactly targets `AGENTS.md`, or regular file has the generated marker.

### Task 2: Architecture adjudication

task: compare Fable and prior Codex proposals for workspace files, tiers, and enforcement
 task_group: ai-main design decisions
 task_outcome: success

Reusable knowledge:
- For this single-user daily-driver setup, a real `AGENTS.md` plus exact-target alias symlinks is preferable to cache-only symlinks because it is readable, debuggable, and more compatible with tools that mishandle symlinks.
- The current ownership heuristic is sufficient for now; a separate `~/.local/state` ledger adds drift/complexity unless stronger provenance or shared-worktree lifecycle requirements emerge.
- Recommended budgets: `full=3200`, `lean=1400`, `minimal=500`; compiler should fail on overrun, while live deployment should retain last-known-good generated output.
- Must-have scope is the lightweight registry CLI, generic fallback knowledge, tracked/unmanaged-file guards, correct `--git-path` exclusion handling, tier compilation, and stronger verification. Defer broad `lib/`, per-tool driver abstractions, cache/state layers, and task-contract orchestration until justified by a real additional host.
- For today’s Claude Code, Codex CLI, opencode, and Qwen usage, plain Git hooks plus a `glab` PATH shim are realistically enforceable. A full immutable task-contract planner/guard is not shared across these tools and is unnecessary for the narrow `glab --json` rule.

References:
- Actual current file sizes/counts used for tier discussion: `config/style.md` 27 lines/1,848 bytes; `config/workflow.md` 64/4,838; `config/profile.md` 49/2,929; `memory/SHARED.md` 11/744; `memory/lessons/LESSONS.md` 86/13,435. Combined: 237 lines/23,794 bytes.
- `knowledge/_generic.md:1-9` is the generic fallback profile and includes an unquoted generated `aimain link {{WORKSPACE_PATH}}` example, which can break for paths containing spaces.

## Thread `019fb948-34df-78c3-acf3-404943218769`
updated_at: 2026-07-31T17:55:34+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-45-44-019fb948-34df-78c3-acf3-404943218769.jsonl
rollout_summary_file: 2026-07-31T17-45-44-dIut-round_2_backoffice_react_migration_plan_review.md

---
description: Partial read-only adversarial review of the backoffice React migration plan found a material baseline SHA mismatch, unresolved state ownership, URL serialization risk, and omitted runtime contracts.
task: review revised backoffice React migration plan against live Nuxt2 repo
task_group: /Users/tualek/ohochat/oho-backoffice
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: react-migration, plan-review, SHA-mismatch, visual-parity, shadcn, radix, Element-UI, TanStack-Router, Zod, Zustand, JERA, external-message
---

### Task 1: Review revised React migration plan

task: verify the revised migration plan against current source, including SHA, inventory, contracts, visual parity, URL behavior, state, and timeline
task_group: migration-plan-review
task_outcome: partial

Preference signals:
- The user explicitly required a read-only review, full plan reading first, source-grounded file:line evidence, explicit scrutiny answers, and a plain final verdict -> similar reviews should not edit artifacts, should distinguish claims from verification, and should put the verdict at both the top and bottom.
- The user locked React migration, visual parity, and fully settled decisions as non-negotiable -> future reviews should verify compliance rather than reopen those strategic decisions.

Reusable knowledge:
- Current checkout SHA is `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`, tagged `v1.62.0`. The plan’s baseline `27d674156fe47d402ed0fefa0bf168aee3b9dc08` is an ancestor, but it predates the two external-message routes/files. Therefore “12 routes verified @ baseline SHA” is not grounded; inventory should be regenerated at the actual current SHA.
- Current tree contains 12 page routes and 35 Vue components; §5.2’s 34-component count is stale.
- `layouts/default.vue:65-83` and `components/SubMenu.vue:121-131` compare full path/query strings after removing `page`, preserving query ordering. TanStack Router’s default JSON-first serialization can alter the externally visible query contract. A passthrough/loose schema alone is insufficient; use explicit query-string serialization and exact URL tests.
- `store/modules/dashboard.js:4-29` has live shared state (`time_period`, `channels`, `checked_channels`) consumed by `components/Business/Dashboard/ChatPerformance.vue` and `components/SelectChannels.vue`. `business`, `partners`, and `api_keys` are also cross-route caches used by `pages/business/_id.vue`, `pages/create-api/_id.vue`, and `components/Business/ApiList.vue`. A plan claiming only three real shared-state values while deferring these ownership decisions to Phase 0 is not fully settled.
- `/external-message-apps` is mutation-heavy: create/edit/delete and duplicate validation in `pages/external-message-apps.vue` and `api/externalMessageApps.js`; it should be included in the mutation E2E/contract matrix.
- `components/JeraForm.vue:652-664` sends a direct full-sync POST to a user-entered JERA URL with `x-jera-api-key`; this is a real external contract absent from the plan’s endpoint inventory and mutation list.
- The Element theme is approximately 500 KB and includes hundreds of selectors/colors. shadcn/Radix is technically suitable because the code is open and Radix primitives are unstyled, but matching Element UI visually is a major design-system effort, not merely token replacement. Estimate core re-skin/style-guide work at roughly 2–4 engineer-weeks, plus page-level migration/parity work.

Failures and how to do differently:
- The review rollout ended before completing all 18 claimed-fix checks and before issuing the required APPROVE or numbered must-change verdict. Treat the outcome as incomplete, not approved.
- The plan’s dependency audit should not be accepted without checking imports. Confirmed live imports include `jquery` at `components/Business/CloseChatSchedulerConfigDialog.vue:43`, `pretty-bytes` in `pages/business/_id.vue`, and `export-to-csv` in both business list and deleted-business pages.

References:
- `git rev-parse HEAD` -> `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`
- `git describe --tags --exact-match HEAD` -> `v1.62.0`
- Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` (833 lines)
- `layouts/default.vue:65-83`
- `components/SubMenu.vue:121-131`
- `store/modules/dashboard.js:4-29`
- `pages/create-api/_id.vue:115-185,266-267`
- `components/Business/ApiList.vue:136-177`
- `pages/external-message-apps.vue`
- `api/externalMessageApps.js`
- `components/JeraForm.vue:652-664`
- `assets/style/oho-theme/theme/index.css`

## Thread `019fb951-ea5f-7483-bc82-456377b2d2df`
updated_at: 2026-07-31T18:07:44+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-56-21-019fb951-ea5f-7483-bc82-456377b2d2df.jsonl
rollout_summary_file: 2026-07-31T17-56-21-UeF9-round_2_react_migration_plan_review_partial.md

---
description: Partial round-2 audit of the Nuxt-to-React migration plan found a stale baseline SHA, incorrect component/dependency inventory, unresolved active-menu/query normalization risk, incomplete navigation-boundary coverage, and unsettled decisions.
task: review revised backoffice React migration plan against live Nuxt repository
task_group: /Users/tualek/ohochat/oho-backoffice migration-plan-review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: react-migration, nuxt2, sha-mismatch, inventory, active-menu, zod-passthrough, tanstack-router, query-serialization, shadcn, element-ui, cutover, MIGRATED_PATHS
---

### Task 1: Round-2 migration plan audit

task: Independently verify revised migration plan claims against the live `oho-backoffice` source.
task_group: migration-plan-review
task_outcome: partial

Preference signals:
- The user required: “SHA check result first,” a cited pass/fail list for all 18 fixes, explicit labeled answers to scrutiny points a-e, and a plainly stated final verdict. Similar future reviews should follow that exact output order and remain read-only.
- The user locked React migration, visual parity, and fully settled/non-contradictory decisions; future reviews should verify compliance rather than reopen those strategic choices.

Reusable knowledge:
- Live repo SHA is `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`, matching the round-1 SHA and differing from the plan baseline `27d674156fe47d402ed0fefa0bf168aee3b9dc08`. The SHA gap contains the external-message feature additions, so §5’s “verified @ baseline SHA” statement is invalid for the current checkout.
- Live component count is 35 (`find components -type f -name '*.vue' | wc -l`), while plan §5.2 says 34.
- `v-clipboard` is stale: `components/Business/ApiList.vue` and `ChannelTable.vue` use `navigator.clipboard.writeText`; there is no active `v-clipboard` import. Plan §5.5’s dependency status is wrong.
- Plan §7.4’s raw query-string active-menu comparison (`layouts/default.vue:65-83`, `components/SubMenu.vue:121-131`) is not automatically compatible with TanStack Router plus Zod passthrough. Passthrough preserves unknown keys but does not guarantee raw query ordering/string preservation. Require either raw-query preservation or canonical order-independent comparison, with tests for reordered/unknown keys.
- Navigation boundary coverage in §13.2 is incomplete. Search found route changes in `components/MyProfileDialog.vue`, `components/Business/QuotaTable.vue`, `components/Business/ApiList.vue`, `pages/payment-history/_id.vue`, `pages/create-api/_id.vue`, `components/ExternalMessage/WhitelistAppChecklist.vue`, `components/Payment/Dialog.vue`, `Sidenav.vue`, `SubMenu.vue`, and page methods. A shared `MIGRATED_PATHS` config must cover all internal links and programmatic navigation, including child-path flips.
- The live app uses a 488KB Element theme and many Element controls (`el-table`, `el-date-picker`, `el-upload`, `el-dialog`, `el-select`, `el-pagination`, etc.). Shadcn/Radix re-skinning is possible but high risk for strict visual/behavior parity; token copying alone is insufficient. The date-range picker/sidebar, table geometry, upload, select, dialog, pagination, and loading behavior require dedicated wrappers and screenshot/interaction gates.
- Plan §5.3 inventories endpoint constants, not all operation-level contracts. Call sites construct additional paths such as payment approval, quota update, API-key operations, webhook operations, file upload/delete, and business/payment mutations. Future review should inventory method + path + body + query at call sites.
- Proposed three Zustand fields are not the whole active shared-state surface: `business`, `partners`, `api_keys`, and `api_keys_biz_id` are used across business detail, create-api, and API-list flows; `platforms.js`/`icon.js` provide active getters/assets. Treat these as unresolved until audited.
- The plan still contains open work/decisions despite the locked-stack requirement: theme extraction, widget/Web App/GTM decisions, dead-state audits, cookie production verification, and Appendix B’s `refetchOnWindowFocus` behavior.
- Phase 5’s 3–4 week estimate may be optimistic: ten top-level cutovers with 2–3 day production soaks already consume 20–30 working days, before implementation, parity testing, UAT, bug bash, and rollback rehearsals. State whether soaks overlap and provide a resource-based schedule.

Failures and how to do differently:
- This rollout did not reach the requested final deliverable: it stopped after evidence collection and did not complete all 18 pass/fail items, scrutiny answers a-e, or the final APPROVE/blocker verdict. Future agents should reserve time to synthesize the required response.
- Do not treat exploratory web research or assistant proposals as verified repo facts; cite the actual plan section and source file:line for every acceptance claim.

References:
- Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` (833 lines).
- Git evidence: `git rev-parse HEAD` → `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`.
- Inventory evidence: `find components -type f -name '*.vue' | wc -l` → `35`; `find pages -type f -name '*.vue' | wc -l` → `12`.
- Relevant files: `layouts/default.vue:65-83`, `components/SubMenu.vue:121-131`, `components/Sidenav.vue`, `components/MyProfileDialog.vue`, `components/Business/QuotaTable.vue`, `components/Business/ApiList.vue`, `pages/payment-history/_id.vue`, `pages/create-api/_id.vue`, `components/ExternalMessage/WhitelistAppChecklist.vue`, `components/Payment/Dialog.vue`, `plugins/axios.js`, `store/index.js`, `api/endpoint.js`, `assets/style/index.scss`, `assets/style/oho-theme/theme/index.css`.

## Thread `019fb976-370c-7e03-b35f-7520e84e70a2`
updated_at: 2026-07-31T18:37:38+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T01-36-00-019fb976-370c-7e03-b35f-7520e84e70a2.jsonl
rollout_summary_file: 2026-07-31T18-36-00-Lk1s-backoffice_react_v2_plan_time_boxed_review.md

description: Time-boxed review of the Backoffice React v2 migration plan found several pre-implementation fixes but no Phase 0 blocker; highest-value takeaway is to resolve state/navigation and cutover-contract contradictions before coding.
task: review backoffice React migration plan for parity, contradictions, active-menu/Zod compatibility, blockers, and verdict
task_group: /Users/tualek/ohochat/oho-backoffice migration-plan-review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: React 19, Nuxt2, shadcn, Radix, visual parity, active-menu, Zod passthrough, MIGRATED_PATHS, cutover, Sentry, GCP Error Reporting

### Task 1: Review migration plan

task: review `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` under strict time and source-file limits
task_group: migration-plan-review
task_outcome: success

Preference signals:
- The user said: “อ่านเฉพาะไฟล์ ... ห้าม re-audit repo ... ทั้งหมด” and required completion within 8 minutes -> similar reviews should remain narrowly scoped, avoid exploratory repo audits, and answer directly.
- The user required five short numbered answers plus `APPROVE` or `NEEDS-FIX` -> preserve that format and give a clear verdict.
- The user locked React migration and required visual parity with no unresolved stack decisions -> prioritize contradictions, parity risks, and operational blockers.

Reusable knowledge:
- The plan’s shadcn/ui re-skin choice is reasonable for visual parity because shadcn is copy-in source with full class/token control; AntD/MUI introduce a different design language. A lower-surface alternative is Radix/headless primitives with bespoke Element-compatible wrappers. The review estimated the design layer/style guide at roughly 15–25 senior frontend engineer-days; the plan’s 5–6 day Phase 1 estimate is likely optimistic and should be treated as an estimate, not verified fact.
- §8.1 forbids moving `bizActiveTab` into the URL, but §13.2.1 chooses `/business/$id?tab=API`; this is an architectural contradiction requiring one contract.
- §4 and §14 do not definitively select Sentry versus GCP Error Reporting, leaving observability unresolved.
- §13.2 inventories 12 navigation locations but later refers to 10 actionable points; dynamic destination #7 is also unresolved. The inventory and required migration behavior need to be made explicit.
- Active-menu matching and Zod passthrough are compatible only with separated responsibilities: preserve unknown query keys through Zod for API requests, but match menus from raw `location.search`, remove only `page`, and compare legacy path/query semantics without serializing a normalized Zod object.
- No blocker prevents Phase 0, but implementation should wait until the above contracts are closed and listed validations (prod cookie attributes, restricted-role account, LB/GCP access) are completed.

Failures and how to do differently:
- No tool or scope failure occurred. Only one source file was opened (`layouts/default.vue`) to verify active-menu behavior, respecting the user’s limit.
- Do not present the 15–25 engineer-day design estimate as measured evidence; label it as an approximate review estimate.

References:
- Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`
- Active-menu implementation: `/Users/tualek/ohochat/oho-backoffice/layouts/default.vue:65-83`
- Relevant sections: §2, §4, §7.4, §8.1, §13.2, §13.2.1, §14
- Baseline SHA: `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`
- Final verdict: `NEEDS-FIX` for the §8.1/§13.2.1 state contract, §4/§14 observability provider, §7.4 active-menu algorithm, and §13.2 navigation inventory/dynamic destination.

## Thread `019fbdea-0a3f-7ed2-a3b3-fddd0046094f`
updated_at: 2026-08-01T15:23:11+00:00
cwd: /Users/tualek/ohochat/backoffice-v2
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T22-20-59-019fbdea-0a3f-7ed2-a3b3-fddd0046094f.jsonl
rollout_summary_file: 2026-08-01T15-20-59-jg2H-react_backoffice_architecture_review.md

---
description: Time-boxed architecture review of migrated React admin app; structure is viable but needs boundary and scaling fixes before multi-person development
 task: review-react-migration-architecture
 task_group: /Users/tualek/ohochat/backoffice-v2
 task_outcome: success
 cwd: /Users/tualek/ohochat/backoffice-v2
 keywords: react-migration, feature-based, layering, payment, business, barrels, query-keys, circular-dependency, eslint
---

### Task 1: Review React migration architecture

task: assess feature-based React structure, layer enforcement, sampled payment/business implementation, and scale risks
task_group: React architecture review
 task_outcome: success

Preference signals:
- เมื่อผู้ใช้กำหนด “TIME-BOX ... อย่า audit ทุกไฟล์” และ “ตอบ 5 ข้อ สั้นๆ ตรงประเด็น ห้ามเขียนยาว” -> รีวิวลักษณะนี้ควรใช้ targeted sampling และสรุป actionable findings โดยไม่ rerun baseline checks เว้นแต่จำเป็น
- ผู้ใช้ล็อกว่า backend contract และ URL contract ห้ามเปลี่ยน ส่วน legacy quirk แก้ได้แต่ต้องจด -> แยก architectural review จาก parity/contract audit ให้ชัด

Reusable knowledge:
- Feature-based architecture เหมาะกับ admin CRUD ขนาดนี้; ไม่จำเป็นต้องรวมโฟลเดอร์หรือรื้อสถาปัตยกรรม
- Layer separation มีจริงในเส้นหลัก: route composer บาง, page ใช้ hooks, API แยก raw I/O, `lib` มี domain/pure logic
- กฎ “components render อย่างเดียว” ยังไม่ตรง implementation: `src/features/business/components/ChannelTable.tsx:123-133` ใช้ `useQuery` และเรียก `getLineWebhook`; `src/features/payment/components/PaymentDialog.tsx:131-151` ใช้ `useQuery` และเรียก API โดยตรง; `PaymentDetailPage` ยังรวม validation/orchestration ได้ในฐานะ feature container
- `shared/lib` หมายถึง I/O/external-bound code; `shared/utils` หมายถึง pure function; feature-level ใช้ `lib/` เดียว ไม่มี `utils/` ถือว่าเป็น convention ที่ชัด
- Query-key convention กระจายหลายตำแหน่ง: payment `hooks/query-keys.ts`, business `lib/query-keys.ts` และ `api/*`, JERA/external-message `api/query-keys.ts`; sample ไม่พบ namespace collision แต่การกระจายนี้เสี่ยง convention เสื่อมเมื่อทีมโต
- Public barrels ใหญ่: `src/features/business/index.ts` 258 lines และ `src/features/payment/index.ts` 232 lines; ควรลดให้เหลือ public API ที่ถูกใช้ข้าม feature/โดย routes จริง
- ESLint feature isolation ตรวจ alias deep imports แต่ config ระบุเองว่า relative imports ที่ไต่ข้าม feature (`../../other-feature/...`) ตรวจไม่ได้; ยังไม่มี circular dependency/dependency-direction gate
- `business` เป็น composition hub ที่ import JERA, payment และ sales-order; ต้องเฝ้าระวัง reverse dependency ที่ทำให้เกิด cycle

Failures and how to do differently:
- ห้ามสรุปว่า layer enforcement ครบเพียงเพราะมีโฟลเดอร์และ ESLint: ต้อง sample call path และค้นหา component ที่ import `features/*/api` โดยตรง
- ก่อนให้ทีมเพิ่มหน้าแบบเต็มสปีด ควรย้าย I/O จาก `ChannelTable` และ `PaymentDialog` เข้า hooks, กำหนดตำแหน่ง query-key factory เดียว, ลด barrels, และเพิ่ม CI ตรวจ circular dependencies กับ relative cross-feature imports
- ใน snapshot นี้ git commands ใช้ไม่ได้เพราะ cwd ไม่ใช่ git repository; อย่าใช้ git status/log เป็นหลักฐานหลักของ review

References:
- Plan: `/Users/tualek/docs/react-migration/backoffice-react-v2-plan.md`, sections 6, 8, 9
- `src/features/business/components/ChannelTable.tsx:123-133`
- `src/features/payment/components/PaymentDialog.tsx:131-151`
- `src/features/payment/components/PaymentDetailPage.tsx:157-184`
- `src/app/routes/_authenticated/business.tsx:26-50`
- `src/features/business/components/BusinessPage.tsx:98-138`
- `eslint.config.js:235-238`
- Component sizes: `PaymentDialog.tsx` 659 lines, `PaymentDetailPage.tsx` 664 lines, `BusinessDetailPage.tsx` 632 lines

## Thread `019fc38b-2163-7081-8ab6-b42248952f08`
updated_at: 2026-08-02T20:11:49+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T00-35-03-019fc38b-2163-7081-8ab6-b42248952f08.jsonl
rollout_summary_file: 2026-08-02T17-35-03-puSA-meta_business_ai_poc_second_opinion_review.md

---
description: Evidence-first Thai second-opinion review of Meta Business AI POC OHO-1215; docs and code reviewed successfully, prod log recheck only partially completed due sandbox credential refresh failure; main takeaway is to rework owner/state model before implementation
task: review_meta_business_ai_poc_oho1215
task_group: meta-business-ai-messenger-handover
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: OHO-1215, Meta Business AI, standby, messaging, ai_generated, hop_context, pass_thread_control, take_thread_control, thread_owner, bot gate, gcloud logging, queue ordering, HUMAN_AGENT
---

### Task 1: Meta Business AI POC second-opinion review

task: review six POC answers against findings, payloads, official guide, code paths, and prod logs
 task_group: meta-business-ai-messenger-handover
 task_outcome: success

Preference signals:
- ผู้ใช้ขอรายงานภาษาไทยแบบละเอียด และกำหนดโครงสร้างปัญหา/หลักฐาน/ความรุนแรง/ข้อเสนอแนะ -> งาน review คล้ายกันควรตอบไทยและ cite หลักฐานละเอียด
- ผู้ใช้กำชับ “Do not fabricate log output” และให้แยก verified/not verified -> ห้ามเปลี่ยน timeout หรือ credential failure เป็น no data; ใช้ `Not run: <reason>` ตามจริง
- ผู้ใช้กำหนด read-only, ห้ามแก้ไฟล์และ commit -> ควรตรวจโดยไม่แก้ repo และ pin สถานะ worktree/commit ก่อน trace

Reusable knowledge:
- คำตอบ POC ทั้งหกไม่ควรถูกใช้เป็น implementation contract โดยตรง: Q1 replay ยังเป็น hypothesis; Q2 observational flag คือ recently observed ไม่ใช่ enabled state; Q3 channel ไม่พอระบุว่า AI/OHO/Business Suite เป็น owner; Q4 เป็น eventual/best-effort detection; Q5 structured reason ไม่มีใน payload; Q6 standby gate ถูกหลักแต่ต้องมี send-time guard
- `meta-biz-ai-payload-samples.md:33–39` มี AI echo ทาง `messaging` พร้อม `hop_context.app_id=388207815496149`; ห้ามตีความ `messaging=OhoChat` หรือ `standby=Meta AI` แบบ binary
- `meta-biz-ai-payload-samples.md:71–77` แสดง `take_thread_control` metadata `axon_take_thread_control`, previous owner `388207815496149`, new owner `928891643393937`, timestamp เป็นวินาที และส่งซ้ำ 4 ครั้ง; ต้อง deduplicate logical transition
- `meta-biz-ai-payload-samples.md:53–69` แสดง read-channel switch หลัง AI farewell; arrival `entry.time` ประมาณ 3.69s แต่ embedded event timestamp ประมาณ 2.13s; ต้องเก็บทั้ง clocks และไม่ใช้ “~4s” เป็น universal SLA
- `meta-biz-ai-queue-routing-design.md:68–72` ระบุ hop_context พบเพียง 113/796 requests และ AI echoes 25 รายการไม่มี hop; finding เก่าที่บอก `is_ai_thread_owner` มาทุกข้อความขัดกับหลักฐานใหม่
- `handler.ts:857–875` ทิ้ง channel หลังเลือก `messaging[0] || standby[0]`; `handler.ts:945–992` จัดการ read แล้ว return ก่อน bot path; `handler.ts:1612–1632` schedule fallback bot; ดังนั้น standby ingress gate อย่างเดียวไม่กัน scheduled/in-flight send และไม่ implement read-based ownership flip
- `helper.ts:1465–1541` และ `facebook.controller.ts:124–168` เลือก queue จาก entry/event แรกและ enqueue request ทั้งก้อน; ต้องแตก canonical event envelope ต่อ page/PSID/event ก่อนจัด queueเพื่อกัน mixed-entry misrouting
- control event อย่าง `take_thread_control` ไม่มี `message` แต่เข้า handler เดียวกัน; `helper.ts:1294–1304` fallback เป็น unsupported text ได้ จึงควร branch control event ก่อน transform และห้ามสร้าง chat bubble/bot trigger
- Official PDF local (15 หน้า, extract ด้วย `pypdf`) ระบุ Business AI App ID `622851382610562`, `ai_generated:true`, standby, `HUMAN_AGENT`, และ reactivation ผ่าน `pass_thread_control`; ต้องแยก official expected behavior จาก observed Axon rollout

Failures and how to do differently:
- gcloud month-wide query hung; ใช้รายวัน/รายสัปดาห์ + `--limit` + shell alarm/timeout 90s เสมอ
- gcloud continuation ล้มก่อน query เพราะ sandbox ปฏิเสธเขียน `~/.config/gcloud/credentials.db`; รายงาน slice เหล่านั้นเป็น `Not run: gcloud credential refresh ถูก sandbox ปฏิเสธ` ไม่ใช่ “ไม่พบข้อมูล”
- direct public Meta docs fetch ล้ม (`Failed to fetch`/URL unsafe); cite local PDF และระบุ live comparison not verified
- adoption scan ที่ค้นเฉพาะ `ai_generated:true` ไม่สามารถพิสูจน์ coverage 100% ได้เพราะไม่มี independent denominator; Instagram “ไม่เคยเก็บ payload” ไม่เท่ากับ “ไม่มี payload”

References:
- `docs/meta-business-ai/meta-biz-ai-poc-6-answers.md:7–121`
- `docs/meta-business-ai/meta-biz-ai-poc-result.md:93–105, 163–177, 187–229, 235–254, 308–331`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:53–93`
- `docs/meta-business-ai/meta-biz-ai-queue-routing-design.md:48–85`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/handler.ts:857–875,945–992,1242–1274,1612–1632,1940–1960`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/helper.ts:1294–1304,1317–1343,1465–1541`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/facebook.controller.ts:124–168`
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:7–25`
- Direct completed query: `resource.type="cloud_run_revision" AND resource.labels.service_name="webhook--production" AND jsonPayload.message:"pass_thread_control" --freshness=24h --limit=100` -> empty output/no data found for available 24h window

## Thread `019fc64c-3291-73a0-9abc-8400c6838b3d`
updated_at: 2026-08-03T06:38:46+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-03/r
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T13-25-10-019fc64c-3291-73a0-9abc-8400c6838b3d.jsonl
rollout_summary_file: 2026-08-03T06-25-10-otHf-audit_and_fix_cursor_ai_main_rules_symlinks.md

description: Verified Cursor still loads ai-main-managed skills, commands, and workspace rules; removed a conflicting stale home-level AGENTS.md while preserving a backup.
task: audit_and_fix_cursor_ai_main_rules
task_group: ai-main-cursor-integration
task_outcome: success
cwd: /Users/tualek/Documents/Codex/2026-08-03/r
keywords: Cursor, ai-main, symlink, AGENTS.md, CLAUDE.md, skills, commands, aimain, workspace rules

### Task 1: Audit Cursor integration

task: verify_cursor_rules_and_symlinks
task_group: ai-main-cursor-integration
task_outcome: success

Preference signals:
- The user asked whether Cursor still used the rules and symlinks configured in ai-main -> similar audits should verify actual runtime loading, not only filesystem presence.

Reusable knowledge:
- `~/.cursor/skills/` contained 22 valid symlinks to `/Users/tualek/ai-main`, with no broken links.
- `~/.cursor/commands/worklog.md` points to `/Users/tualek/ai-main/commands/worklog.md`.
- Cursor 3.14.7 loaded workspace `AGENTS.md`/`CLAUDE.md` as `always_applied_workspace_rule`; absence of `~/.cursor/rules/` did not prevent ai-main workspace rules from loading.
- `/Users/tualek/ai-main/bin/aimain list` showed all 11 registered workspaces as `ok`.

Failures and how to do differently:
- Use native `find` rather than `rtk find` for compound predicates/actions.
- `cursor-agent` was unavailable and network installation failed; use Cursor runtime state/logs when CLI testing is impossible.

References:
- `/Users/tualek/ai-main/install.sh`
- `/Users/tualek/ai-main/bin/aimain list`
- Cursor version: `3.14.7`

### Task 2: Remove stale conflicting rule

task: remove_conflicting_home_agents_rule
task_group: ai-main-cursor-integration
task_outcome: success

Preference signals:
- The user said “จัดการให้หน่อย” -> make the corrective change, preserve a recoverable backup, and avoid touching unrelated dirty work in `ai-main`.

Reusable knowledge:
- `/Users/tualek/AGENTS.md` was an old generic rule source loaded in addition to ai-main workspace rules and could conflict with repo-specific conventions.
- It was moved, not deleted, to `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`.
- After removal, workspace files remained intact and `aimain list` still reported every workspace `ok`.
- Existing Cursor sessions may cache rules; reload the window or start a new chat after changing rule files.

Failures and how to do differently:
- Do not edit or clean unrelated changes in `/Users/tualek/ai-main`; preserve the user’s dirty worktree.

References:
- Removed: `/Users/tualek/AGENTS.md`
- Backup: `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`
- Verification: `ls -la /Users/tualek/AGENTS.md` returned no such file; `aimain list` returned all workspaces `ok`.

## Thread `019fc66d-6db1-7253-a396-dfde3105523c`
updated_at: 2026-08-05T03:30:55+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T14-01-28-019fc66d-6db1-7253-a396-dfde3105523c.jsonl
rollout_summary_file: 2026-08-03T07-01-28-EQdm-meta_business_ai_facebook_page_onboarding_clickup_handoff.md

---
description: Created and externally verified a Meta Business AI Facebook Page onboarding runbook, added onboarding readiness gates/T0 to MVP docs, and synchronized the canonical artifacts to ClickUp OHO-1634.
task: onboard Facebook Page for Meta Business AI MVP and sync ClickUp documentation
task_group: /Users/tualek/ohochat / Meta Business AI onboarding and stakeholder handoff
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, Facebook Page onboarding, Conversation Routing, default app, messaging_handovers, standby, thread_owner, pass_thread_control, take_thread_control, HUMAN_AGENT, ClickUp, OHO-1634, fresh-message E2E
---

### Task 1: Facebook Page onboarding runbook

task: define prerequisites and verification gates for Meta Business AI Facebook Page onboarding
task_group: Meta Business AI onboarding

task_outcome: success

Preference signals:
- when asked what Facebook Page onboarding is necessary, the rollout separated Oho-controlled setup from Page-admin Meta setup -> future onboarding responses should cover both sides proactively.
- the rollout required fresh-message E2E evidence before calling a Page ready -> distinguish `configured` from `verified`; do not treat OAuth/API 200/banner as readiness.
- the user’s established evidence boundary was preserved: separate official Meta documentation, Oho-observed POC, and pending Meta confirmation.

Reusable knowledge:
- Runbook created at `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`.
- Required gates: identity mapping; Page access token and permissions; HTTPS webhook/signature verification; union-safe Page subscriptions; standby ingress and send-time bot guards; Page-admin Business AI activation; Conversation Routing/default app; takeover setting; fresh-message E2E for AI active, standby suppression, human takeover, and return-to-AI.
- Required webhook fields documented: `messages`, `message_echoes`, `message_deliveries`, `message_reads`, `messaging_postbacks`, `messaging_referrals`, `messaging_handovers`, `standby`.
- Subscription migration procedure is `GET → union required fields → POST → GET verify`; never replace existing Page fields.
- Onboarding states are `not_started | blocked | configured | verified | rolled_back`; `configured` must not be presented as `verified`.
- Business AI eligibility/status API and complete Unified Onboarding contract were not available in the reviewed public/partner documentation; keep these as manual/interim steps and pending Meta confirmation.
- Silent `take_thread_control` requires Conversation Routing/default-app readiness in the tested setup; retain a `send_first` + `HUMAN_AGENT` fallback for human takeover.
- Return-to-AI requires a positive fresh runtime signal after `pass_thread_control`; HTTP 200, banner, `standby`, or one owner snapshot alone is insufficient.
- Rollback: stop Oho outbound but retain webhook ingestion, stop automated take/pass/release calls, restore routing/default-app baseline, and unsubscribe only as an approved final step.

Failures and how to do differently:
- Meta documentation conflicts on `messaging_handovers` vs singular naming, generic vs Business AI-specific take control, `ai_generated` guarantees, App IDs, and endpoint forms. Preserve these as explicit clarification questions rather than assuming a universal contract.
- Research agent timeouts occurred, but the completed runbook contains the verified source boundary; do not claim broader verification than the document supports.

References:
- `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `docs/meta-business-ai/04-mvp-implementation-solutions-2026-08-04.md:407`
- `docs/meta-business-ai/05-mvp-implementation-task-plan-2026-08-04.md:43` (`T0 — Onboard Facebook Page and establish readiness baseline`)

### Task 2: ClickUp documentation synchronization

task: upload canonical onboarding/MVP documents and update ClickUp OHO-1634
 task_group: ClickUp external handoff
 task_outcome: success

Preference signals:
- when updating a card, the rollout verified the persisted card after reload -> future external handoffs should treat reload verification as part of completion, not optional.

Reusable knowledge:
- Successful ClickUp task lookup used `task_id: "OHO-1634"`; an incorrect workspace/task combination returned `{"error":"Team not authorized"}`.
- Uploaded canonical artifacts: `04-mvp-implementation-solutions-2026-08-04.md`, `05-mvp-implementation-task-plan-2026-08-04.md`, `06-facebook-page-onboarding-2026-08-05.md`.
- Card description now includes Canonical 6 files, the Facebook Page onboarding gate, the onboarding runbook link, and T0-T10 planning.
- Old duplicate attachment IDs were removed; reload verification showed old `04` and `05` links absent and canonical files present.
- Local and downloaded ClickUp attachment SHA-256 values matched for all three files.

Failures and how to do differently:
- Long ClickUp descriptions can be truncated by connector reads. Restore from the full local source and verify key tail sections (MVP plan, Definition of Done, Related documents) after reload.

References:
- ClickUp: `https://app.clickup.com/t/86eyce35p`
- Verification signals: `canonical6=true`, `onboardingGate=true`, `mvpPlan=true`, `taskT0=true`, `definitionDone=true`, `relatedDocuments=true`, `old04=false`, `old05=false`.

## Thread `019fc8d3-33e3-7132-b93a-a21e3685223b`
updated_at: 2026-08-03T18:11:52+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T01-11-52-019fc8d3-33e3-7132-b93a-a21e3685223b.jsonl
rollout_summary_file: 2026-08-03T18-11-52-TXSz-meta_business_ai_doc_split_clickup_update_blocked.md

description: แยก Meta Business AI official/current, coming soon/planned, observed POC และ communication pack สำเร็จ; เตรียม ClickUp OHO-1634 description แต่บันทึกการ์ดจริงไม่ได้เพราะไม่มี ClickUp connector และ browser ยังไม่ล็อกอิน
task: meta-business-ai-doc-split-and-clickup-card-update
task_group: /Users/tualek/ohochat
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, OHO-1634, OHO-1215, ClickUp, Conversation Routing, standby, ai_generated, thread_owner, pass_thread_control, HUMAN_AGENT, source-matrix

### Task 1: แยกเอกสาร Meta และผล POC

task: split Meta documented capabilities from coming soon/planned items and Oho observed behavior
task_group: Meta Business AI documentation
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ขอ “แยก document ที่เกี่ยวกับ docs จาก meta” และ “แยก docs ที่เป็น coming soon” พร้อมเอกสารที่ส่งคุย Meta ได้ -> ควรสร้าง source-separated documents และ communication pack โดยไม่ปน official contract กับ local observation
- ผู้ใช้ต้องการหลักฐานตรงและไม่ fabricate logs -> ระบุ observed, not verified และขอบเขตของ POC อย่างชัดเจน

Reusable knowledge:
- สร้าง source matrix จาก official partner PDF 15 หน้าและ public Meta docs พร้อมข้อขัดแย้ง 10 จุด; ใช้เป็นจุดเริ่มต้นก่อน implementation
- เอกสารใหม่อยู่ใน `docs/meta-business-ai/`: `meta-official-source-matrix-2026-08-04.md`, `meta-official-available-2026-08-04.md`, `meta-official-coming-soon-2026-08-04.md`, `oho-poc-observed-behavior-2026-08-04.md`, `meta-partner-communication-pack-2026-08-04.md`, `meta-business-ai-dev-questions-2026-08-04.md`
- POC evidence: test page `104613548045675`, 13 subscribed fields, live self-handoff 4/4 รอบไม่พบ `pass_thread_control`, `thread_owner` 8 threads บน v20/v25 ไม่คืน `app_id`, `pass_thread_control` ไป `622851382610562` ทำงาน, control event เคย duplicate 4 ครั้ง
- Implementation ต้องแยก delivery authority, agent identity และ latest event; ใช้ send-time guard/cancel scheduled sends และ canonicalize/dedupe events

Failures and how to do differently:
- อย่าใช้ `standby`, `messaging`, `app_id` หรือ `ai_generated` เพียงค่าเดียวเป็น universal owner contract; current evidence จำกัดตาม Page/rollout

References:
- `docs/meta-business-ai/meta-official-source-matrix-2026-08-04.md`
- `docs/meta-business-ai/meta-official-coming-soon-2026-08-04.md`
- `docs/meta-business-ai/oho-poc-observed-behavior-2026-08-04.md`

### Task 2: เตรียม ClickUp description และ cross-reference

task: update ClickUp OHO-1634 description and related documentation
task_group: ClickUp card update
 task_outcome: partial

Preference signals:
- ผู้ใช้ขอ “update description ในการ์ด” และรวมไฟล์ที่เกี่ยวข้อง -> ต้องทำ external update จริงและตรวจผลหลัง save ไม่ควรนับ draft เป็น completion

Reusable knowledge:
- Draft พร้อมวางอยู่ที่ `docs/meta-business-ai/clickup-OHO-1634-description-2026-08-04.md`
- Related files ถูกอัปเดตให้ชี้ไปยัง draft/source split: `clickup-OHO-1634-poc-results.md`, `meta-biz-ai-card-review-2026-08-03.md`, `meta-biz-ai-summary-solutions-2026-08-03.md`, `HANDOFF.md`
- ClickUp browser เปิดได้แต่ redirect ไป `https://app.clickup.com/login`; active tool search ไม่พบ ClickUp connector/plugin

Failures and how to do differently:
- Card ยังไม่ได้แก้จริง; รอ authenticated ClickUp browser session แล้ววาง draft ลง OHO-1634 และ verify saved description/toast

References:
- `https://app.clickup.com/t/90182460598/OHO-1634`
- `docs/meta-business-ai/clickup-OHO-1634-description-2026-08-04.md`
- Exact blocker: browser resolved to `https://app.clickup.com/login`; no ClickUp tool available

## Thread `019fca5a-c19e-7761-966a-95f4e7276aae`
updated_at: 2026-08-04T01:21:08+00:00
cwd: /Users/tualek/retourapac
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T08-19-33-019fca5a-c19e-7761-966a-95f4e7276aae.jsonl
rollout_summary_file: 2026-08-04T01-19-33-sccm-find_retour_form_dashboard_slides.md

description: Search for ReTour APAC slides explaining form access and dashboard usage; no matching deck was found, but authoritative replacement documentation and the prior Claude session were identified
 task: locate existing ReTour form-opening and dashboard-usage slides
 task_group: retourapac-documentation
 task_outcome: partial
 cwd: /Users/tualek/retourapac
 keywords: ReTour, slides, dashboard, submission-form, Claude-session, Google-Drive, apps-script

### Task 1: Locate existing form/dashboard slides

task: locate previously created slides for opening the submission form and using the dashboard
task_group: retourapac-documentation
task_outcome: partial

Preference signals:
- The user asked: “ฉันน่าจะเคยมีทำ slide ของ step การเปิดปุ่ม form และการใช้ dashboard ช่วยหา slide ให่หน่อยเคยทำไว้ใน claude” -> when asked to find a prior artifact, search both Claude history and the workspace/Drive before proposing to recreate it.

Reusable knowledge:
- No ReTour-specific `.pptx`, `.ppt`, or Google Slides deck was found in the repository or the searched Google Drive presentation results.
- The practical substitute is `/Users/tualek/retourapac/apps-script/README.md`, covering setup, form webhook flow, dashboard roles, and daily use.
- `/Users/tualek/retourapac/dashboard-plan.md` contains the form test-access and dashboard implementation details.
- The prior Claude session is `/Users/tualek/.claude/projects/-Users-tualek-retourapac/f39934f0-c004-4206-853a-18ffda63f30b.jsonl`, titled “สร้าง dashboard สำหรับ review และ approve forms”.
- Master dashboard sheet: `https://docs.google.com/spreadsheets/d/1ktQ8F00uR4rLJiawR964bSYcNILl7pb0O8NhMwCA4u4/edit`.

Failures and how to do differently:
- Broad `rg` searches across Claude JSONL files generated massive truncated output. Narrow searches to the relevant Claude project directory, metadata fields such as `ai-title`/`last-prompt`, and exact artifact extensions.
- The search ended without direct user confirmation or a recovered deck; treat the result as partial and offer to create a new slide deck from the identified documentation.

References:
- `/Users/tualek/retourapac/apps-script/README.md`
- `/Users/tualek/retourapac/dashboard-plan.md`
- `/Users/tualek/.claude/projects/-Users-tualek-retourapac/f39934f0-c004-4206-853a-18ffda63f30b.jsonl`
- `https://docs.google.com/spreadsheets/d/1ktQ8F00uR4rLJiawR964bSYcNILl7pb0O8NhMwCA4u4/edit`

## Thread `019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd`
updated_at: 2026-08-04T05:01:22+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T11-50-48-019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd.jsonl
rollout_summary_file: 2026-08-04T04-50-48-0WTj-backoffice_v2_ui_design_dark_mode_plan.md

description: สร้างแผน audit UI และ dark mode สำหรับ backoffice-v2 สำเร็จ โดยตรวจ source + rendered UI และยืนยัน Markdown formatting
 task: backoffice-v2 UI/UX audit and detailed dark-mode implementation plan
 task_group: /Users/tualek/ohochat/backoffice-v2 UI design workflow
 task_outcome: success
 cwd: /Users/tualek/ohochat/backoffice-v2
 keywords: backoffice-v2, ui-audit, dark-mode, responsive-layout, spacing, padding, margin, Playwright, jwt-malformed, prettier

### Task 1: UI audit and dark-mode plan

task: inspect backoffice-v2 UI and create a detailed Markdown implementation plan
task_group: UI design and frontend planning
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ขอ “ทำเป็น plan อย่างละเอียด” และ “สร้าง md plan มาเลย” พร้อม “รวมถึงทำโหมด dark” -> ควรสร้างเอกสาร implementation-ready ที่มี design specs, file references, rollout phases, tests และ acceptance criteria ไม่ใช่แค่สรุปปัญหา
- ผู้ใช้ขอวิเคราะห์ padding/margin/ความสวยงามจาก UI จริง -> ควรตรวจ source ควบคู่กับ rendered screenshots/viewport checks
- งานรอบนี้เป็น plan-only -> ต้องไม่แก้ implementation หรือ commit โดยไม่ได้รับคำสั่งเพิ่ม

Reusable knowledge:
- แผนที่สร้างแล้วอยู่ที่ `ui-design-dark-mode-plan.md` และครอบคลุม spacing scale 4px, typography roles, responsive shell, shared page patterns, semantic dark tokens, page-by-page work, implementation phases, visual matrix, accessibility และ acceptance criteria
- Source baseline ที่สำคัญ: `src/styles/globals.css` มี light tokens แต่ไม่มี `.dark`, `color-scheme`, `theme-color` หรือ pre-paint bootstrap; มี global heading sizes และ `div:focus { outline: none }`
- `src/shared/components/layout/AppLayout.tsx` ใช้ `p-10`; `SubMenu.tsx` ใช้ `w-60`; ที่ 1024px โครงสร้าง rail 64px + submenu 240px + main padding ทำให้ content/table ถูกบีบ
- พบ light-only coupling จำนวนมาก เช่น `bg-white`, `text-black-*`, `border-black-*`, hardcoded hex/rgba และ `transition-all` ใน business, payment, external-message, JERA และ dashboard; dark-mode migration ควรเริ่มจาก theme foundation และ shared primitives ก่อน feature pages
- Visual smoke check ใช้ Playwright ผ่าน `bash /Users/tualek/.codex/skills/playwright/scripts/playwright_cli.sh`; เรียก script ตรง ๆ ทำให้ `Permission denied`

Failures and how to do differently:
- Authenticated visual review ใช้ dummy cookies และ API ตอบ `jwt malformed`; ให้รายงานเป็นข้อจำกัดและอย่าอ้างว่าหน้า data จริงหรือ feature behavior ผ่าน
- ระหว่าง dev server มี process/session อื่นแก้ source หลายไฟล์; ก่อนสรุปควรตรวจ timestamps และ re-check line references เสมอ
- Full validation ยังไม่ได้รันใน rollout นี้; ห้ามอ้าง lint/typecheck/test/build ผ่านจากงานนี้

References:
- `ui-design-dark-mode-plan.md`
- `output/playwright/login-desktop.png`
- `output/playwright/login-mobile.png`
- `output/playwright/business-desktop.png`
- `output/playwright/business-1024.png`
- `pnpm exec prettier --check ui-design-dark-mode-plan.md` -> `All matched files use Prettier code style!`
- Local API limitation: `jwt malformed`

## Thread `019fcc18-966f-75c1-8bb6-3c8b98c927f4`
updated_at: 2026-08-05T03:16:07+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T16-26-31-019fcc18-966f-75c1-8bb6-3c8b98c927f4.jsonl
rollout_summary_file: 2026-08-04T09-26-31-tqzG-smartchat_four_qa_badge_fix_scoped_validation.md

---
description: Implemented a narrowly scoped Smartchat unread/unresponded badge fix for four QA cases, preserving group behavior and validating API/Mongo/frontend contracts.
task: smartchat-realtime-badge-fix-four-qa-cases
task_group: /Users/tualek/ohochat/oho-api
 task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: smartchat, unread_by, is_unresponded, is_read_by_me, feature-flags, group-chat, contact, emit-chat-session-event, TDD, QA-case-1, QA-case-2, QA-case-3, QA-case-4
---

### Task 1: Scope and implement four-case Smartchat badge fix

task: constrain realtime badge behavior to the four reported QA cases
 task_group: cross-repo Smartchat badge workflow
 task_outcome: success

Preference signals:
- when the user said “ตอนนี้อยากให้ครอบคลุมแค่เคสที่ QA ตีแก้มา 4 case” -> keep the patch focused on those QA cases and defer broad refactor/optimization.
- when the user said “ได้ทำ plan แล้วแก้ไขได้เลย” -> edits were authorized after the scope discussion.

Reusable knowledge:
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js` preserves group-chat’s existing unresponded-only contract. Contact/Smartchat alone opts into unread state via `includeUnreadState: true`.
- `buildAttentionEventUnreadPayload` independently gates `unread_by` and `is_unresponded`; both flags off returns `{}` and does not call `getEligibleMemberIds`.
- Contact socket recipients are partitioned into unread/read groups, producing at most two `emitMessages` calls; group emits remain one shared payload.
- Focused verification passed: API `46/46`, Mongo-backed integration `28/28`, web focused tests `135/135`; Prettier and `git diff --check` passed.

Failures and how to do differently:
- Initial TDD run correctly exposed group scope expansion and an over-broad Jest mock that loaded `models/index.js`; restore group expectations and mock only boundary exports.
- Flag-off user-visible behavior is disabled, but the request after-hook still performs one contact `findOne()` and flag lookup before returning. Treat this as deferred optimization, not as proof that the feature is entirely absent at runtime.
- No browser E2E was run; distinguish focused/unit/Mongo contract proof from real UI proof.

References:
- `/Users/tualek/ohochat/oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:220-400`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.ts:7-45`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.spec.ts`
- `/Users/tualek/ohochat/oho-api/src/services/contact/bot-assign/request/request-attention-badge.spec.ts:83-128`
- Key test command: `node ./node_modules/jest/bin/jest.js --runTestsByPath src/services/chat-session/hooks/emit-chat-session-event.spec.ts src/services/contact/bot-assign/request/request-attention-badge.spec.ts src/utils/build-customer-message-unread-payload.spec.ts src/utils/channel-eligible-members.spec.ts --runInBand --forceExit --detectOpenHandles`
- Final status: changes remained uncommitted/unpushed; browser E2E was not run.

## Thread `019fcc78-6964-7c40-b51c-34e9b65b8d10`
updated_at: 2026-08-04T11:26:49+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-11-11-019fcc78-6964-7c40-b51c-34e9b65b8d10.jsonl
rollout_summary_file: 2026-08-04T11-11-11-39xm-uat_facebook_login_consent_meta_app_change_history.md

description: Diagnosed UAT Facebook consent discrepancy and dated the UAT App ID change; source code is shared, but UAT uses a different Meta app and Meta app-type history remains unverified.
task: diagnose-uat-facebook-login-consent-and-app-id-history
task_group: oho-web-app/deployment-debugging
task_outcome: partial
cwd: /Users/tualek/ohochat
authentication: Facebook OAuth, Meta Login for Business, Cloud Run, Nuxt build-time config
keywords: facebook-login, consent, login-for-business, FACEBOOK_APP_ID, Cloud-Run, UAT, staging-4, production, gcloud-logging, meta-dashboard

### Task 1: Diagnose UAT Facebook consent difference

task: compare Facebook login and consent behavior across UAT, staging-4, and production
task_group: oho-web-app/deployment-debugging
task_outcome: partial

Preference signals:
- The user asked to compare `prod`, `staging-4`, and `uat` and explain why only UAT differs -> future debugging should compare deployed environment configuration and browser requests before editing code.
- The user requested read-only history checking when asking when the change occurred -> preserve the distinction between verified deployment facts and unverified Meta-side history.

Reusable knowledge:
- `components/LoginCard.vue` calls `this.$auth.loginWith("facebook")`; `plugins/fb-auth.js` configures the strategy with `clientId: process.env.FACEBOOK_APP_ID` and `scope: ["public_profile", "email"]`.
- The frontend source path is shared across environments; no consent-specific endpoint or divergent Facebook code path was found in the searched web/API repositories.
- UAT bundle used App ID `1092549003000749`; production used `388207815496149`; staging-4 OAuth used `1121209881887696`. UAT OAuth was observed as standard flow without `config_id` / `is_business_login=1`.
- Facebook App ID is baked into the Nuxt client at build time. Updating only Cloud Run runtime env vars is insufficient; update GitLab `DOTENV`, rebuild, deploy, and route traffic to the new revision.
- UAT traffic was 100% on `web-app--uat--26a0dd06--v1-115-0`; revision `web-app--uat--9d797cbb--v1-115-1` was ready but not routed.

Failures and how to do differently:
- Post-login consent could not be verified because the browser had no authenticated Facebook session. Do not claim the exact Meta consent request without an authenticated repro or captured request.
- Staging-4 had a configuration inconsistency: Cloud Run runtime metadata showed App ID `906298295642485`, while the served OAuth bundle used `1121209881887696`; always inspect both baked bundle config and runtime env.

References:
- `/Users/tualek/ohochat/oho-web-app/components/LoginCard.vue:259-264`
- `/Users/tualek/ohochat/oho-web-app/plugins/fb-auth.js:19-25`
- `/Users/tualek/ohochat/oho-web-app/nuxt.config.js:44-51`
- `web-app--uat--26a0dd06--v1-115-0`

### Task 2: Date UAT App ID change

task: identify when UAT changed from the previous Facebook App ID
task_group: Cloud-Run-audit-history
task_outcome: success

Preference signals:
- The user asked whether the change could be dated because the rollback button was unavailable -> future responses should provide exact timestamps and clearly state what the evidence does and does not prove.

Reusable knowledge:
- UAT revisions used App ID `265344702138419` through 2026-03-06.
- First revision using `1092549003000749` was `web-app--uat-00082-8tn`, created `2026-03-17T16:56:06.462906Z` (2026-03-17 23:56 Thailand time).
- Cloud Logging recorded `google.cloud.run.v1.Services.ReplaceService` at `2026-03-17T16:56:05.742293Z`, principal `rapee@oho.chat`, client `cloud-console`.
- This proves when UAT began using the new App ID, not when the Meta app was created or switched to Facebook Login for Business.
- Meta documentation says rollback is available only for an existing app within 30 days of switching; newly created Business Type apps cannot switch back.

Failures and how to do differently:
- Meta dashboard inspection was blocked by a login page. The Meta app type/switch date remains unverified; continue from the preserved Meta dashboard tab after the user signs in.
- GitLab audit API returned 404; Cloud Run audit logs and revision metadata were the reliable evidence.

References:
- Revision: `web-app--uat-00082-8tn`
- Timestamp: `2026-03-17T16:56:06.462906Z`
- Principal: `rapee@oho.chat`
- Audit method: `google.cloud.run.v1.Services.ReplaceService`
- Meta docs: `https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business`

## Thread `019fcc97-697a-70b0-a137-64ad27e07903`
updated_at: 2026-08-04T11:48:17+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-45-02-019fcc97-697a-70b0-a137-64ad27e07903.jsonl
rollout_summary_file: 2026-08-04T11-45-02-h9iX-clickup_latest_due_date_assigned_ticket.md

---
description: ตรวจสอบ ClickUp tickets ที่ assign ให้ผู้ใช้ปัจจุบันและหา ticket ที่มี due date ล่าสุด สำเร็จ โดยพบ OHO-1215 เป็นรายการล่าสุด
 task: find-latest-due-date-for-current-clickup-assignee
 task_group: clickup-task-search
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: ClickUp, clickup_search, clickup_get_task, clickup_resolve_assignees, due_date, assignee, OHO-1215
---

### Task 1: Find latest due date among assigned ClickUp tickets

task: find-latest-due-date-for-current-clickup-assignee
task_group: ClickUp task search
task_outcome: success

Preference signals:
- ผู้ใช้ถามภาษาไทยแบบสั้นว่า “ticket ไหนที่ มี duedate ล่าสุด ที่ assign ฉัน” -> งานลักษณะนี้ควรตอบเฉพาะรายการล่าสุดอย่างกระชับ พร้อม ticket ID, ชื่อ, due date, status และลิงก์

Reusable knowledge:
- Resolve current ClickUp user first with `clickup_resolve_assignees({assignees:["me"]})`; this returned user ID `113526352`.
- Search with `clickup_search({count:100, filters:{asset_types:["task"], assignees:["113526352"]}})` found 39 assigned tasks.
- Search results do not reliably include due dates; call `clickup_get_task` for each result, read `due_date`, sort numerically descending, and format timestamps in `Asia/Bangkok`.
- 24 of the 39 assigned tasks had due dates. The latest was `OHO-1215`, `[MS-PD-0170] นำ Meta Business AI (BizAI) มาใช้กับ OHO Chat ผ่าน Messenger (PAF Pilot)`, due 31 October 2026, status `to do`, URL `https://app.clickup.com/t/86ey96htu`.

Failures and how to do differently:
- Initial broad tool-description/search output was truncated, so inspect structured tool results rather than copying rendered text.
- Do not sort by `dateUpdated`; it is different from `due_date`. Fetch task details before ranking.

References:
- `clickup_resolve_assignees({assignees:["me"]})` -> `{"userIds":["113526352"]}`
- `clickup_search` filter: `asset_types:["task"]`, `assignees:["113526352"]`
- Latest task URL: `https://app.clickup.com/t/86ey96htu`
- Latest due date raw timestamp: `1793394000000`

## Thread `019fcca5-2c2f-7bb1-ad67-039a286e19da`
updated_at: 2026-08-05T04:00:09+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-00-04-019fcca5-2c2f-7bb1-ad67-039a286e19da.jsonl
rollout_summary_file: 2026-08-04T12-00-04-U5UC-clickup_assignee_filter_and_meta_business_ai_estimate.md

description: ClickUp ticket filtering was corrected to use the user's assignee; OHO-1634 Meta Business AI MVP was estimated at 15–20 working days, with important verification limits.
task: ClickUp ticket lookup and OHO-1634 implementation estimation
task_group: /Users/tualek/ohochat
 task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: ClickUp, assignee, OHO-1634, Meta Business AI, BizAI, standby, messaging, Cloud Tasks, HUMAN_AGENT, messaging_handovers

### Task 1: Filter tickets by current assignee

task: Find ClickUp tickets due 14 Aug 2026 and assigned to the user
task_group: ClickUp ticket lookup
task_outcome: success

Preference signals:
- When the user said “เอาแค่ assign ของฉันสิ” after a broad result -> future date-based ticket lists should default to the current user's assigned tickets, not all tickets.

Reusable knowledge:
- User identity verified in ClickUp: `Tualek[Full Stack]`, `sitthiporn@oho.chat`, user ID `113526352`.
- Five verified tickets due 14 Aug 2026: OHO-1811, OHO-1824, OHO-1820, OHO-1828, OHO-1804.

Failures and how to do differently:
- Numeric `assignees: [113526352]` failed validation (`expected string, received number`); retrying with a string caused a ClickUp server error. If search filtering fails, inspect candidate tasks individually with `clickup_get_task`.

References:
- ClickUp search date filter: `due_date_from: "2026-08-14", due_date_to: "2026-08-15"`.
- Candidate verification used `clickup_get_task({task_id, detail_level:"summary"})`.

### Task 2: Estimate OHO-1634 MVP

task: Estimate implementation effort for ClickUp ticket OHO-1634
 task_group: Meta Business AI Messenger integration
 task_outcome: partial

Preference signals:
- The assistant interpreted “MCP” as likely “MVP” because the ticket had no MCP requirement; preserve this ambiguity warning and ask for clarification when needed.

Reusable knowledge:
- Planning estimate: 15–20 working days for one developer; 20 days recommended for ticket planning. Limited POC demo: 5–7 days.
- Scope includes webhook/event canonicalization, dedicated AI queue, ownership state, dedupe, subscription changes, bot/scheduled-send guards, Smartchat UI, takeover/return-to-AI, QA, observability, and canary rollout.
- Current inspected code routes `messaging`/`standby` together in `oho-webhook/src/controllers/facebook/helper.ts`; `oho-webhook/src/helpers/cloud_tasks.api.ts` has no `meta-ai` queue; `oho-api/src/utils/facebook/request-page-subscribed-app.js` lacks `messaging_handovers`; `HUMAN_AGENT` already exists in member send hooks.

Failures and how to do differently:
- Numeric ClickUp task ID `90182460598` returned `Team not authorized`; custom ID `OHO-1634` succeeded.
- No Meta runtime/integration test or Cloud Tasks canary was run, so do not state the estimate as verified delivery capacity.

References:
- Ticket: `OHO-1634`, `[DEV] POC BizAI take control`.
- Relevant paths: `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/helper.ts`, `/Users/tualek/ohochat/oho-webhook/src/helpers/cloud_tasks.api.ts`, `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js`, `/Users/tualek/ohochat/oho-api/src/services/member-send-message/member-send-message.hooks.js`.
- Verification rule: HTTP/API success is insufficient for return-to-AI; require fresh runtime evidence such as `ai_generated`, `hop_context`, control/ownership events, and an actual post-action AI response.

## Thread `019fcca9-5c19-7c82-9846-631245488d38`
updated_at: 2026-08-04T12:07:11+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-04-39-019fcca9-5c19-7c82-9846-631245488d38.jsonl
rollout_summary_file: 2026-08-04T12-04-39-FePe-dynamic_stream_credentials_cloud_run_multitenancy.md

---
description: Secure multi-business Stream Chat credential architecture without duplicating Cloud Run
 task: design dynamic secret-backed Stream Chat configuration per business
 task_group: /Users/tualek/ohochat backend architecture
 task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Stream Chat, business_id, Secret Manager, Cloud Run, multi-account, credential mapping, user token, secret rotation
---

### Task 1: Per-business Stream Chat secrets

task: Store and resolve separate Stream Chat credentials for each business.
task_group: backend secret management and multi-tenancy
task_outcome: success

Preference signals:
- The user clarified: “มันเป็น secreat เลยเพราะต้องทำ multi account streamchat แยกตาม business” -> similar designs should keep Stream `api_secret` server-only and avoid frontend or Remote Config delivery.

Reusable knowledge:
- Store a mapping in MongoDB containing `business_id`, Stream API key, Secret Manager resource, pinned secret version, and enabled state; store the actual `api_secret` only in Secret Manager.
- Resolve `business_id` from the authenticated session and authorize it; never trust an unvalidated request-body business identifier.
- Backend flow: resolve business → load mapping → access the pinned secret version → create/select the Stream server client → generate an expiring user token → return only API key and user token to frontend.
- Cache clients per `connectionId:secretVersion` (with TTL/LRU and invalidation on version change); do not use one global Stream singleton across businesses.
- Rotate by adding a new Secret Manager version and updating the mapping. Pinning a numeric version makes rollback explicit.

Failures and how to do differently:
- Do not put Stream secrets in Firebase Remote Config, frontend runtime config, or one global Cloud Run env var.
- Do not expose the Stream API secret to the browser.

References:
- `/Users/tualek/ohochat`
- `business_id → MongoDB mapping → Secret Manager → backend Stream client → frontend apiKey + userToken`

### Task 2: Cloud Run deployment topology

task: Determine whether each Stream account requires a separate Cloud Run service.
task_group: Cloud Run deployment architecture
task_outcome: success

Reusable knowledge:
- A single Cloud Run service can support multiple Stream accounts by selecting the correct per-business client at request time.
- Duplicate Cloud Run only when infrastructure-level isolation is required, such as separate service accounts, networks, scaling, deployments, or compliance boundaries.
- Cloud Run environment variables are revision-bound; changing them creates a new revision, so they are unsuitable for per-request dynamic secrets.

Failures and how to do differently:
- Do not model each business as a separate Cloud Run service merely because Stream credentials differ.

References:
- Cloud Run environment-variable behavior: configuration changes create a new revision.
- Suggested cache key example: `${config.connectionId}:${config.secretVersion}`

## Thread `019fdb04-3fd5-7162-baaf-6899542d9a88`
updated_at: 2026-08-07T07:05:16+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-07/referenced-chatgpt-conversation-this-is-an
rollout_path: /Users/tualek/.codex/sessions/2026/08/07/rollout-2026-08-07T13-58-36-019fdb04-3fd5-7162-baaf-6899542d9a88.jsonl
rollout_summary_file: 2026-08-07T06-58-36-zLcc-meta_business_ai_3_boxes_documentation_review.md

---
description: Read-only review of Meta Business AI 3-box flow found P0 contract and safety gaps; keep diagrams conceptual until runtime state contract and reducer semantics are fixed
task: review-meta-business-ai-3-boxes-flow
task_group: /Users/tualek/ohochat Meta Business AI documentation and architecture review
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, 3-boxes, take_thread_control, pass_thread_control, return-to-AI, observed_authority, reducer, monotonic, bot guard, dedup, out-of-order, oho-webhook, oho-api
---

### Task 1: Review Meta Business AI 3-box flow documentation

task: assess completeness, inconsistencies, architectural gaps, unclear assumptions, and concrete improvements for `meta-biz-ai-flow-3-boxes-2026-08-07.md`
task_group: Meta Business AI documentation/source-contract review
task_outcome: success

Preference signals:
- when reviewing this work, the user asked for completeness, missing sections, inconsistencies, architectural gaps, and concrete recommendations -> provide severity-ranked findings with file/line evidence rather than a generic summary
- prior user constraints require read-only review and no fabricated logs -> distinguish verified source facts, observed POC, proposed behavior, and `Not verified`
- prior Meta reviews were requested entirely in Thai and detailed -> similar reviews should default to Thai with source-cited rationale

Reusable knowledge:
- The 3-boxes file is suitable as a conceptual communication diagram but must not be treated as the runtime implementation contract until it represents uncertainty and lifecycle states.
- Control direction is not preserved end-to-end: `oho-webhook/src/controllers/facebook/handler.ts:898-914` sends control type but not `previous_owner_app_id` or `new_owner_app_id`. The reducer at `oho-api/src/utils/meta-business-ai.js:250-265` treats every `take_thread_control` as human takeover, so an Axon take can be misclassified.
- Return-to-AI confirmation is too broad: `oho-api/src/utils/meta-business-ai.js:284-297` accepts `meta_human` and `external_app` as confirmation. Confirmation should require a fresh positive Business AI signal, not merely Meta-side authority.
- Bot safety has a pending-state gap. `shouldBlockFacebookBotSend` at `oho-api/src/utils/meta-business-ai.js:318-326` blocks `meta_or_other` and page kill switch, but `return-to-ai.class.js:48-69` can set `reactivation_state=requested` while authority remains `oho`; scheduled/direct bot sends may then pass. The canonical safety rule should block bot outbound during `requested`, `confirmed`, and `unconfirmed` reactivation, plus known Meta authority and page kill switch.
- The task plan requires monotonic state, but `runtime-event.class.js:17-46` performs load/reduce/full-object write and `reduceMetaRuntimeEvent` at `meta-business-ai.js:191-205` does not reject stale events. Cross-queue reordering and concurrent read-modify-write can regress state or lose updates. Define normalized event time, tie-breaker, stable event ID, stale-event rejection, and conditional atomic update.
- The 3-boxes diagram overstates deterministic behavior: `meta-biz-ai-flow-3-boxes-2026-08-07.md:51-59,71-73` skips requested/confirmed/unconfirmed/failed states; `:110` says `ai_generated:true` is always present although POC only verifies captured samples; `:98` presents idle-to-AI takeover as a contract although TTL remains open.
- POC evidence shows self-handoff is not deterministic, `standby` versus `messaging` is not a binary owner test, `thread_owner` is not a universal passive owner oracle, and control events can be duplicated/out-of-order. Preserve these limitations in all diagrams and docs.
- Documentation navigation is stale: `HANDOFF.md` still frames MVP as future work and omits the 7 Aug flow docs, while source repos contain Meta Business AI commits from 6 Aug. Add a single index/status matrix separating official contract, observed POC, proposed design, implemented, verified E2E, and stale archive.
- Data handling and operations need explicit sections for preview retention, redaction/access/deletion, metric thresholds, dashboard/alert owners, kill-switch authority, and canary evidence.

Failures and how to do differently:
- Do not use a diagram arrow as proof of runtime success. Mark edges as verified contract, observed/best-effort, or requested/pending confirmation, and show `unknown`, `requested`, `unconfirmed`, and `failed`.
- Do not equate `take_thread_control` with OHO ownership without inspecting owner direction and target app IDs.
- Do not treat HTTP success, a banner, farewell text, or a generic Meta human/external signal as Return-to-AI confirmation.
- Do not claim monotonic behavior from a reducer design unless stale-event rejection and atomic persistence are verified in source/tests.
- Live official Meta comparison was not verified because URLs returned `429 Too Many Requests` or `Cache miss`; use local official PDF and stored POC evidence while labeling live comparison unavailable.

References:
- `docs/meta-business-ai/meta-biz-ai-flow-3-boxes-2026-08-07.md:51-59,71-73,98,110,117,158-160`
- `docs/meta-business-ai/oho-poc-observed-behavior-2026-08-04.md:35-46,86-142`
- `docs/meta-business-ai/01-meta-docs-vs-oho-poc-2026-08-04.md:20-35,108-120`
- `oho-webhook/src/controllers/facebook/handler.ts:898-914,939-962`
- `oho-api/src/utils/meta-business-ai.js:191-205,250-326`
- `oho-api/src/services/contact/meta-business-ai/runtime-event/runtime-event.class.js:17-46`
- `oho-api/src/services/contact/meta-business-ai/return-to-ai/return-to-ai.class.js:48-69`
- `docs/meta-business-ai/05-mvp-implementation-task-plan-2026-08-04.md:95-113,143-162,273-317`

## Thread `019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc`
updated_at: 2026-08-09T07:19:28+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www
rollout_path: /Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T11-06-11-019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc.jsonl
rollout_summary_file: 2026-08-09T04-06-11-vKu8-canva_section_addition_and_pdf_export.md

---
description: Canva section-addition attempt for foreign-worker presentation; direct page insertion was not completed, but a 13-page Thai PDF export succeeded. Key takeaway: use the logged-in Chrome extension/editor for page insertion or provide a separate importable section.
task: add foreign-worker information as a new section after an existing Canva presentation section and export deliverable
task_group: canva-presentation-editing
 task_outcome: partial
cwd: /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www
keywords: Canva, Chrome extension, Canva editing transaction, page insertion, blank login page, foreign workers, e-WorkPermit, PDF export
---

### Task 1: Add section to existing Canva design

task: append a new section after the existing Canva presentation content
task_group: Canva presentation editing
task_outcome: partial

Preference signals:
- The user asked to add it “ใน section ใหม่ต่อจากอันเดิม” -> append after existing pages and preserve prior content.
- The user accepted making a separate file and importing/copying it later -> offer a standalone importable section when direct insertion is blocked.
- The user wanted the original section/style inspected before editing -> inspect final pages and match the existing visual style.

Reusable knowledge:
- Canva design: `DAGsRNjn95Y`; URL: `https://www.canva.com/design/DAGsRNjn95Y/A0WvLzG-4q4jOq7e0rHRsw/edit`.
- Existing design has 60 editable 1920×1080 presentation pages.
- Canva API transaction `6728889961075207786` was opened for inspection but cancelled; it did not add pages.
- The Chrome extension later exposed the logged-in editor tab titled `สามัคคีทีม จำกัด - Presentation` with “All changes saved.”

Failures and how to do differently:
- The in-app browser reached Canva login but became a blank page after login; use Chrome extension instead when available.
- Do not report the Canva edit as saved or complete unless a page is visibly added and the editor confirms saving.
- The editing API path did not establish a working page-insertion operation; use native Canva Add page/copy-page UI or create a separate section file.

References:
- Source research partially succeeded: Passport article on Cabinet resolution 28 Sep 2021; DOE object 2444 on four-nationality electronic work permits; Chiang Mai DOE object 87182 on Cabinet resolution 24 Sep 2024.

### Task 2: Export section as PDF

task: export the prepared Thai section as a PDF
task_group: document export
 task_outcome: success

Reusable knowledge:
- PDF created with 13 pages, with Thai text and layout reported as matching the PowerPoint.

References:
- `/Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www/outputs/pdf/e-workpermit-detailed-workflow-section-v7-identity-visa.pdf`

## Thread `019fe533-6a13-7ce1-b33a-be843748c46b`
updated_at: 2026-08-09T06:58:19+00:00
cwd: /Users/tualek/Documents/migrant-labor-crm
rollout_path: /Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T13-26-19-019fe533-6a13-7ce1-b33a-be843748c46b.jsonl
rollout_summary_file: 2026-08-09T06-26-19-LLdx-migrant_labor_crm_new_machine_local_setup.md

description: Completed new-machine local setup for Migrant Labor CRM; Docker services, Prisma database, seed, and NestJS API were verified, with an optional sample PDF omitted.
task: setup migrant-labor-crm local environment on new Mac
task_group: local development setup
 task_outcome: success
cwd: /Users/tualek/Documents/migrant-labor-crm
keywords: pnpm, docker-compose, Docker Desktop, Prisma, PostgreSQL, Redis, MinIO, NestJS, CI=true, EPERM, ENOTFOUND, schema engine error

### Task 1: New-machine local stack setup

task: configure env, dependencies, Docker services, database, seed, and API for migrant-labor-crm
task_group: local development setup
task_outcome: success

Preference signals:
- The user asked “นาย run ทั้งหมดให้หน่อย” (“run everything for me”) -> for similar repo setup requests, inspect and execute the complete workflow instead of only providing instructions.
- The agent preserved existing worktree edits and avoided overwriting `.env` contents -> protect user changes during setup.

Reusable knowledge:
- Repo README setup sequence: `pnpm install`, `.env`, `docker compose up -d`, `pnpm db:generate`, `pnpm db:migrate`, `pnpm db:seed`, `pnpm dev`.
- If frontend is already running, start only the API with `pnpm --filter @mlcrm/api dev`.
- `.env` is ignored by Git. Frontend defaults to `http://localhost:3000`; `apps/web/.env.local` with `VITE_API_URL` is only needed for a non-default API URL.
- Docker services expose PostgreSQL `5432`, Redis `6379`, MinIO API `9000`, and MinIO console `9001`.
- Use `CI=true pnpm install` in non-TTY sessions; plain install failed with `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`.
- Prisma generate may require unsandboxed access to `~/.cache/prisma`; sandboxed run failed with `EPERM` on the Prisma query engine cache.
- Migration may require unsandboxed local Docker/network access; sandboxed run produced only `Schema engine error`.
- Docker Desktop installation was blocked by stale broken symlinks; `brew install --cask docker --no-binaries` successfully installed the app without trying to replace privileged helper binaries.
- Migration applied three existing migrations: `20260503135306_init_mvp`, `20260503141100_init_mvp`, and `20260504032732_init_mvp`.
- Seed completed but skipped `/Users/tualek/Downloads/power_of_attorney.pdf`; the PDF can be uploaded later through the UI.
- API verification succeeded: `GET http://localhost:3000/auth/me` returned `401`, and NestJS reported successful startup.

Failures and how to do differently:
- Before running Compose, verify Docker daemon readiness with `docker version`; a valid CLI alone is insufficient if the Docker socket is unavailable.
- If Docker Desktop needs privileged setup, the user must run `sudo /Applications/Docker.app/Contents/MacOS/install --user=tualek` and accept any macOS/Docker prompts themselves.
- Do not treat `pnpm db:migrate` success as sufficient; also verify container status, seed output, API logs, and an HTTP response.

References:
- `CI=true pnpm install`
- `docker compose up -d`
- `pnpm db:generate`
- `pnpm db:migrate`
- `pnpm db:seed`
- `pnpm --filter @mlcrm/api dev`
- `curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/auth/me` -> `401`
- `/Users/tualek/Documents/migrant-labor-crm/.env.example`
- `/Users/tualek/Documents/migrant-labor-crm/docker-compose.yml`

## Thread `019fe9f1-4dfe-7963-a2c9-f930bfbf93e7`
updated_at: 2026-08-10T06:55:37+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T11-32-13-019fe9f1-4dfe-7963-a2c9-f930bfbf93e7.jsonl
rollout_summary_file: 2026-08-10T04-32-13-Idz9-line_webhook_migration_hardening_scoped_dry_run.md

description: Hardened LINE webhook migration with manifest-first backup/rollback and validated a single production channel in read-only mode; production apply remains blocked by unresolved recovery/final-verification review findings.
task: line webhook migration safety review and implementation
task_group: /Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint
task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, whitelist, allowed-host, manifest, rollback, journal, register_webhook_at, dry-run, channel scope, MongoDB, compensation

### Task 1: Harden LINE webhook migration

task: implement safe manifest-first LINE webhook migration and rollback
 task_group: script-oho/migrate-line-webhook-endpoint
 task_outcome: partial

Preference signals:
- The user required explicit DB whitelist checking and full backup before mutation -> future implementations should use manifest-first, fail-closed workflows rather than old-host filtering or post-mutation backups.
- The user explicitly said `register_webhook_at` should not be updated -> never include `line.register_webhook_at` in migration or rollback payloads.
- The user later narrowed live testing to exactly channel `6a794f77fc9340171589accf` -> preserve exact scope and never broaden to `--all-channels` without approval.

Reusable knowledge:
- Implemented files: `migrate-line-webhook-endpoint/migrate-line-webhook.ts`, `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, `README.md`, `plan.md`.
- Flow is manifest-first: DB inventory → LINE inventory → immutable atomic manifest → drift revalidation → LINE test → PUT → poll GET → conditional Mongo update → final checks → journal/rollback.
- Manifest stores DB fields with presence markers, LINE endpoint/active state, candidate IDs/count, whitelist, environment/Mongo target, and digest; it excludes credentials and `register_webhook_at`.
- Production dry-run command used: `npm run migrate:line-webhook -- --env=prod --channel=6a794f77fc9340171589accf --allowed-host=api2.oho.chat --delay-ms=0 --concurrency=1`.
- Dry-run result: one channel, `testabc`; classification `line_db_match`; DB and LINE both pointed to `https://webhook.oho.chat/line/webhook/604ee3c35c2d9e573e8e9873`; target was `https://api2.oho.chat/webhook/line/webhook/604ee3c35c2d9e573e8e9873`.

Failures and how to do differently:
- Do not execute production yet. Review identified missing/unsafe final LINE verification after DB update, incomplete crash/recovery guarantees around `updated_at`, and insufficient explicit live `business_id` validation.
- Add orchestration tests for final LINE drift, crash after DB write before journal persistence, rollback conflict detection, and exact business ID checks before enabling `--execute`.
- Keep unrelated dirty repository changes separate from migration work.

References:
- Focused tests: `npm run test:line-webhook` → 9/9 passed.
- Full tests: `npm test` → 19/19 passed.
- Targeted TypeScript check passed with `npx tsc --noEmit --target ES2022 --module Node16 --moduleResolution Node16 --esModuleInterop --skipLibCheck --types node --ignoreDeprecations 6.0 ...`.
- Main live artifact: `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-20260810065326-230ce054.json`.
- No `--execute`, LINE PUT, or Mongo update was performed.

## Thread `019fea4f-0f09-7031-a11f-8b18c23fcf85`
updated_at: 2026-08-10T07:28:25+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T13-14-37-019fea4f-0f09-7031-a11f-8b18c23fcf85.jsonl
rollout_summary_file: 2026-08-10T06-14-37-ygPX-harden_line_webhook_migration_recovery.md

---
description: Hardened and reviewed a LINE webhook migration script with manifest-first safety, exact rollback, resumability, and explicit preservation of register_webhook_at; tests pass but real integrations remain unverified
task: line-webhook-migration-hardening-and-review
task_group: /Users/tualek/ohochat/script-oho/script-oho/migrate-line-webhook-endpoint
 task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, manifest, rollback, journal, db_update_requested, exclusive lock, register_webhook_at, MongoDB, LINE API
---

### Task 1: Harden LINE webhook migration

task: implement and review production-safety fixes for LINE webhook endpoint migration
task_group: script-oho/migrate-line-webhook-endpoint
task_outcome: partial

Preference signals:
- The user said “plan มาอย่างเดียวก่อน” after the requested sub-agent model was unavailable -> for complex migrations, produce and validate an implementation-ready plan before editing when the user requests it.
- The user said `register_webhook_at` may not need updating -> do not include `line.register_webhook_at` in migration or rollback payloads unless explicitly requested.
- The user asked to “แก้ตาม issue ที่เหลือเลย” after the audit -> use review findings as an explicit implementation checklist, then rerun focused and full verification.

Reusable knowledge:
- Migration now requires explicit `--allowed-host`; the old `--old-host` semantics were replaced to avoid reversing the whitelist requirement.
- Dry-run creates an immutable manifest before mutations, containing DB/LINE before-state, candidate IDs, environment/target metadata, and digest. Apply/rollback require the reviewed manifest and manifest-bound confirmation token.
- Manifest revalidation accepts DB before-state or target-state only when a durable journal marker proves a prior DB mutation; it no longer rebuilds candidates solely from current DB hostname classification.
- Apply/rollback acquire an exclusive `<manifest>.lock` using `open(..., "wx")`, preventing two processes from compensating LINE against each other.
- Journal phase `db_update_requested` is persisted with a planned `updated_at` before Mongo `updateOne()`. Ambiguous Mongo responses are reconciled against target DB state and the planned timestamp; if state cannot be proven, the run records `compensation_failed` and leaves LINE target state for manual recovery.
- Completed `migrated`/`db_synced` entries are re-read from both LINE and Mongo on rerun to detect external drift rather than blindly skipping them.
- `migrationUpdate()` and `restoreUpdate()` do not contain `register_webhook_at`; exact rollback uses field-presence-aware `$set`/`$unset` for the fields migration changes.

Failures and how to do differently:
- Original backup was written after LINE/DB mutation and excluded some failed states; always persist immutable before-state before the first external mutation.
- Original rollback could act on dry-run-only entries; select rollback candidates from mutation journal phases or verified live target state only.
- Original partial failure could exit successfully; treat failed test/PUT/verify/DB, compensation failure, and rollback conflicts as non-zero outcomes.
- Tests are unit/helper and orchestration-oriented only; do not claim production readiness without real-cluster, LINE API, gateway smoke, canary message, and terminal-processing evidence.

References:
- `migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- `migrate-line-webhook-endpoint/README.md`
- `migrate-line-webhook-endpoint/plan.md`
- `npm run test:line-webhook` output: 11 tests passed
- `npm test` output: 21 tests passed
- `npx tsc --noEmit --target ES2022 --module Node16 --moduleResolution Node16 ...` output: `TypeScript: No errors found`
- `npm run migrate:line-webhook:help` completed successfully
- `git diff --check` completed successfully
- No secrets, DB credentials, LINE tokens, or production endpoints were stored; no real DB/LINE/gateway calls were made.

## Thread `019fea86-e89e-79c3-b1e3-68a6504098fc`
updated_at: 2026-08-11T03:38:57+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl
rollout_summary_file: 2026-08-10T07-15-37-7oWo-line_webhook_migration_audit_hardening_and_production_runboo.md

---
description: LINE webhook migration was hardened and reviewed; production-safe workflow requires whitelist inventory, immutable manifest, LINE verification before DB update, exact rollback, and canary-first execution.
task: audit-and-operationalize-line-webhook-migration
task_group: script-oho-line-webhook-migration
task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, manifest, rollback, journal, register_webhook_at, production dry-run, canary, npm test
---

### Task 1: Audit and hardening review

task: Review LINE webhook migration against whitelist, verification, backup, ordering, and rollback requirements.
task_group: script-oho-line-webhook-migration
task_outcome: partial

Preference signals:
- The user requires DB-driven whitelist detection, new endpoint verification before LINE mutation, LINE API update before DB update, complete backup, and rollback protection. Similar migrations should be audited end-to-end, including crash and partial-failure paths.

Reusable knowledge:
- Existing endpoint construction is `${webhook_endpoint}/line/webhook/${businessId}` in `oho-api/src/services/channel/line/line.hooks.js`.
- The webhook service route is `/line/webhook/:businessId`; `/line` returns `{ page: 'LINE Home' }`.
- LINE webhook test proves endpoint communication but not full real-message processing; production rollout needs a real-message canary and queue/terminal-state evidence.

Failures and how to do differently:
- Original backup was persisted after mutation, so crash after LINE/DB changes could leave no rollback source.
- Original `--old-host` semantics did not implement “DB hostname outside whitelist.” Use explicit `--allowed-host` classification.
- Rollback must exclude dry-run-only entries and restore exact modified DB field values/presence.
- Confirmation must bind to the reviewed manifest/candidate set; partial failures must exit non-zero.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `oho-api/src/services/channel/line/line.hooks.js`
- `oho-webhook/src/controllers/line/line.controller.ts`

### Task 2: Plan-only specification

task: Write an implementation-ready safety plan without editing the migration implementation.
task_group: script-oho-line-webhook-migration
 task_outcome: success

Preference signals:
- The user said `register_webhook_at` may not need updating and then explicitly requested “plan only.” Future agents should not edit code when the user requests plan-only.

Reusable knowledge:
- `migrate-line-webhook-endpoint/plan.md` specifies explicit whitelist classification, immutable atomic manifest, manifest-bound apply, durable journal, exact rollback, conflict detection, timeout/retry rules, non-zero exit semantics, and canary rollout.
- `line.register_webhook_at` must not be written or restored.

References:
- `migrate-line-webhook-endpoint/plan.md`

### Task 3: Implementation status review

task: Verify whether the revised implementation fixed the previously identified P0 issues.
task_group: script-oho-line-webhook-migration
 task_outcome: partial

Reusable knowledge:
- Revised source has state-aware manifest revalidation, an exclusive `<manifest>.lock`, and `db_update_requested` with planned `updated_at` before MongoDB commit.
- Migration ordering is test → PUT LINE → poll GET verification → conditional DB update → final verification.
- Exact DB snapshots preserve field presence for `line.webhook_endpoint`, `line.is_webhook_endpoint_valid`, `line.is_webhook_active`, and `updated_at`; `line.register_webhook_at` is intentionally excluded.
- Verification evidence: focused suite passed 11/11; full suite passed 21/21; CLI help passed.
- No live DB, LINE API, gateway, or production canary was run in the rollout.

Failures and how to do differently:
- Full orchestration coverage remains absent for fake Mongo/LINE crash recovery, compensation, concurrent apply, and complete rollback. Treat the result as UAT-canary-ready, not fully production-proven.

References:
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- `npm run test:line-webhook` → 11 passed
- `npm test` → 21 passed

### Task 4: Production command workflow

task: Run a production canary/all-business migration with dry-run manifest and rollback available.
task_group: script-oho-line-webhook-migration
 task_outcome: success

Preference signals:
- The user wants exact copy-pasteable commands. Avoid duplicate flags, trailing spaces after `\`, and literal `<placeholder>` tokens. Use one command per step and substitute actual manifest/token values.
- Prefer one-channel/business canary, inspect manifest, apply the same manifest, send a real LINE message, verify webhook/queue/terminal processing, then expand.

Reusable knowledge:
- Dry-run: `npm run migrate:line-webhook -- --env=prod --channel=<id> --allowed-host=api2.oho.chat`.
- All channels: `npm run migrate:line-webhook -- --env=prod --all-channels --allowed-host=api2.oho.chat`.
- Apply only from generated manifest: `npm run migrate:line-webhook -- --env=prod --manifest="$MANIFEST" --execute --confirm="$MIGRATE_TOKEN" --yes`.
- Rollback requires a separate rollback dry-run token, then `--rollback --execute --confirm="$ROLLBACK_TOKEN" --yes`.
- A rollback summary phase `rollback_not_needed` may still have detail `would restore ...`; inspect the migration journal before interpreting it as untouched.

Failures and how to do differently:
- Duplicate `--execute`/`--confirm` caused `Flag --confirm given more than once`; provide each exactly once.
- A trailing space after `\` broke shell continuation.
- Literal `<rollback-token>` caused zsh redirection; never include angle brackets in the executable command.

References:
- Manifest pattern: `migrate-line-webhook-manifest-<env>-<timestamp>-<scope-hash>.json`
- Journal patterns: `<manifest>.migrate.journal.json` and `<manifest>.rollback.journal.json`

## Thread `019fea91-cc0c-72a0-a973-d5bc782a9d01`
updated_at: 2026-08-10T07:33:25+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-27-31-019fea91-cc0c-72a0-a973-d5bc782a9d01.jsonl
rollout_summary_file: 2026-08-10T07-27-31-raWB-facebook_attachment_ingestion_root_cause_gentle_clinic.md

---
description: Diagnosed recurring Facebook attachment send failures for Gentle Clinic; evidence points to Meta attachment ingestion failure rather than corrupt OHO files or OHO re-upload logic.
task: Diagnose Facebook Messenger attachment failures using GCP logs and source tracing
task_group: /Users/tualek/ohochat Facebook send-path production investigation
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Gentle Clinic, 67121be026ec0ed85e1d9208, Facebook, Meta, Messenger Send API, error_subcode 2018047, Upload attachment failure, GCP Cloud Logging, GCS, mediaUrl, youpin-to-facebook
---

### Task 1: Facebook attachment root-cause investigation

task: Correlate Gentle Clinic Facebook attachment failures across raw Meta errors, GCP logs, GCS file validity, and OHO source code.
task_group: production Facebook send-path diagnosis
task_outcome: success

Preference signals:
- When the user asked for the “rootcause” and whether it was the file, OHO metadata/upload, or Meta -> future debugging should separate raw platform evidence from UI error mappings and explicitly compare competing causes.
- When the user provided a business ID and sample file URL -> search production logs using business ID, page ID, file ID/URL, error code/subcode, and timestamps; preserve read-only investigation unless edits are requested.

Reusable knowledge:
- OHO’s Facebook image path sends the existing public GCS `mediaUrl` in `{ attachment: { type: 'image', payload: { url } } }`; it does not re-encode or re-upload the file to Meta before the Send API request.
- Source locations: `oho-api/src/utils/message-converter/youpin-to-facebook.js:42-52` and `oho-api/src/services/integration/facebook/reply-message/reply-message.class.js:30-35`.
- UI text `ส่งข้อความไม่สำเร็จ เนื่องจาก Facebook ไม่รองรับไฟล์ดังกล่าว` is a mapping for Facebook/Instagram `code=100` + `error_subcode=2018047`, not a precise diagnosis (`oho-api/src/utils/get-error-message-send-message-fail.js:123-126`).
- Production logs repeatedly showed Meta HTTP 400 responses with `(#100) Upload attachment failure`, `type: OAuthException`, `code: 100`, `error_subcode: 2018047`, and different `fbtrace_id` values for Gentle Clinic. The same subcode appeared across unrelated Facebook Pages/businesses, supporting a Meta-side attachment ingestion/fetch incident rather than a business-specific defect.
- The supplied/sample and Gentle-related GCS files returned HTTP 200 and decoded as valid JPEGs. Tested properties included RGB/sRGB, no alpha, standard JPEG encoding, and ordinary dimensions/sizes. Older reused images and a newly uploaded image failed in the same time window, weakening hypotheses involving one corrupt file, new-upload race, or OHO metadata.
- The original sample JSON’s business ID (`604e2c63...`) is not Gentle Clinic’s business ID (`67121be...`); correlate actual send logs before attributing it to Gentle.

Failures and how to do differently:
- Broad `gcloud logging read` searches generated truncated output. Use tight filters for `resource.labels.service_name`, exact `2018047`, business/page identifiers, and narrow UTC time ranges; format only timestamp, severity, text payload, and relevant labels.
- A local gcloud warning reported that `/Users/tualek/.config/gcloud/logs` was not writable; logging access through the proxy still worked. Do not confuse that local warning with an application failure.
- Do not store or repeat access tokens found in raw Axios log lines; redact them as `[REDACTED_SECRET]`.
- Meta’s public status page showed “No known issues,” but that is weaker evidence than synchronized cross-business production failures and does not rule out a partial attachment-ingestion incident.

References:
- Raw Meta error shape: `HTTP 400`; `(#100) อัพโหลดไฟล์แนบไม่สำเร็จ` / `(#100) Upload attachment failure`; `code=100`; `error_subcode=2018047`.
- Gentle Clinic Facebook Page ID: `1626745224287212`.
- Representative Gentle `fbtrace_id` values: `A3afHY6EcLdo3J09SOyuUV8`, `AqGswMbobZ-r0fkNQ6vyAtZ`, `AS4Ixcoke0f2L-ISRYhGG_l`.
- Production service/project: `core-api--production` in GCP project `oho-platform`.
- Operational conclusion from the rollout: retry only failed attachments after failures cease for roughly 10–15 minutes; do not resend a whole saved reply because successful messages may duplicate.

## Thread `019feaaa-5edf-7453-8fdb-0bf9b642ca0c`
updated_at: 2026-08-10T10:38:39+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-54-21-019feaaa-5edf-7453-8fdb-0bf9b642ca0c.jsonl
rollout_summary_file: 2026-08-10T07-54-21-Wlnm-line_webhook_migration_review_config_audit.md

---
description: Reviewed and hardened a production LINE webhook domain migration; established fail-closed manifest/rollback requirements and identified the only required runtime config change.
task: LINE webhook migration safety review and cross-repo config audit
task_group: /Users/tualek/ohochat/script-oho / production migration workflow
task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, whitelist, manifest, rollback, register_webhook_at, APP_CONFIG, core-api, OHO_WEBHOOK_URL, Cloud Run
---

### Task 1: Review migration safety

task: Audit `migrate-line-webhook-endpoint/migrate-line-webhook.ts` against DB whitelist, LINE verification, mutation ordering, backup, and rollback requirements.
task_group: script-oho production migration review
task_outcome: partial

Preference signals:
- The user required: check DB for LINE webhook domains outside the whitelist; verify the new endpoint with LINE before PUT; update LINE first and MongoDB afterward; back up everything before mutation for rollback.
- The user initially requested a read-only, evidence-based review with file/line citations.

Reusable knowledge:
- Canonical endpoint shape is `${webhook_endpoint}/line/webhook/${businessId}`, matching `oho-api/src/services/channel/line/line.hooks.js`.
- The original flow had test → PUT LINE → GET verify → DB update, but backup persistence occurred after `processChannel`, leaving a crash window.
- Original `--old-host` filtered hosts to migrate, which did not implement the requirement “migrate domains not in whitelist.”
- LINE `success: true` proves the endpoint accepted LINE’s test event, not full message ingestion/queue processing; real-message canary evidence is still required.

Failures and how to do differently:
- Never approve production migration when backup is written after external mutations.
- Rollback must select only entries that actually reached a mutation phase, not every dry-run entry.
- Bind apply confirmation to an immutable manifest/candidate set and return non-zero on unresolved partial failures.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `oho-api/src/services/channel/line/line.hooks.js:237-285`
- `oho-webhook/src/controllers/line/line.controller.ts:38-76`

### Task 2: Plan-only hardening

task: Produce an implementation-ready plan without modifying implementation code.
task_group: script-oho migration planning
task_outcome: success

Preference signals:
- The user explicitly said `register_webhook_at` need not be updated.
- The user explicitly narrowed the task to “plan only”; do not implement or delegate until explicitly requested.
- Requested model `gpt-5.6-luna` was unavailable; the user chose plan-only instead of silently substituting another model.

Reusable knowledge:
- `script-oho/migrate-line-webhook-endpoint/plan.md` specifies explicit `--allowed-host`, immutable manifest before mutation, manifest-bound apply, durable per-channel journal, exact DB field-presence restore, timeout/polling, compensating rollback, conflict detection, and non-zero exit semantics.
- `line.register_webhook_at` must not appear in migration or rollback `$set`/`$unset` payloads.

Failures and how to do differently:
- Respect plan-only scope; do not edit implementation or run DB/LINE/gateway operations during planning.

References:
- `script-oho/migrate-line-webhook-endpoint/plan.md`
- Required flow: `DB inventory → LINE inventory → immutable manifest → revalidate → test → PUT → GET verify → DB update → final verify`

### Task 3: Cross-repo runtime configuration audit

task: Determine which repos/env/secrets must change for the new public LINE webhook domain.
task_group: cross-repo deployment/config audit
task_outcome: partial

Preference signals:
- When a search result appears in UI code, inspect enclosing comments and reachability before recommending a deployment; the user corrected an overclaim about `oho-web-app`.

Reusable knowledge:
- `oho-api` runtime config is loaded from `APP_CONFIG` (`oho-api/config/local.js`), backed by Secret Manager `core-api-config--json--<env>` and sourced from GitLab config project `294` via `load-config.sh`/`prepare-app-config.sh`.
- The required runtime update is the environment config field `webhook_endpoint`, e.g. production `https://api2.oho.chat/webhook`, followed by deploying `core-api` with the new secret version.
- `oho-webhook`’s `OHO_WEBHOOK_URL` is an internal Cloud Run callback base used by Cloud Tasks to call `/line/message/...`; it is a separate contract and does not need changing for this public LINE endpoint migration.
- The stale `https://webhook.oho.chat/...` string in `oho-web-app/pages/business/_biz_id/setting/integration.vue` is inside a commented `<el-table>` block (`~824-1140`) and is not rendered; no web-app deployment is needed for it.
- A production Secret Manager read that would retrieve the entire JSON secret was refused to avoid exposing unrelated credentials; source/deployment mapping was sufficient to identify the config path.

Failures and how to do differently:
- Do not infer runtime impact from `rg` matches alone. Verify comments, feature gates, route registration, and call/render path.
- Do not retrieve an entire production secret merely to inspect one field; use a safe narrow inspection or source/deployment mapping.

References:
- `oho-api/load-config.sh`
- `oho-api/prepare-app-config.sh`
- `oho-api/deploy.sh`
- `oho-api/config/local.js`
- `oho-api/src/services/channel/line/line.hooks.js`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99`
- `oho-web-app/pages/business/_biz_id/setting/integration.vue:824-1140`
- Live Cloud Run: `webhook--production` had `OHO_WEBHOOK_URL=https://webhook--production-...run.app`.

## Thread `019fead6-e1dd-77a1-84ca-e7b90cfc6323`
updated_at: 2026-08-10T17:19:20+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T15-42-58-019fead6-e1dd-77a1-84ca-e7b90cfc6323.jsonl
rollout_summary_file: 2026-08-10T08-42-58-K9az-meta_business_ai_scoped_review_and_luna_fixes.md

---
description: Scoped review and partial implementation of Facebook Meta Business AI MVP; corrected identity contract, authority transitions, tenant safety, dedup lease races, and send guards, with focused validation but remaining rollout risks.
task: review-and-fix-facebook-meta-business-ai-mvp
task_group: ohochat-meta-business-ai
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, ai_generated, standby, facebook_delivery_authority, oho-webhook, oho-api, Redis lease, Lua CAS, tenant scope, Graph API, primary read, performance, Luna max
---

### Task 1: Review Meta Business AI MVP

task: review-facebook-meta-business-ai-branch
 task_group: ohochat-meta-business-ai-review
 task_outcome: success

Preference signals:
- when reviewing this feature, the user asked for a detailed plan focused on worst cases such as “ข้อความไม่เข้าหรอ ? หรือ performance drop” -> future reviews should separate message delivery, authority correctness, security/tenant scope, and performance with concrete evidence.
- the user explicitly constrained the work to `oho-api` and `oho-webhook` first and asked not to expand into web-app/design -> keep implementation scope limited to backend/webhook seams.

Reusable knowledge:
- The intended branch refs initially pointed at staging, so pin the actual feature commits via reflog/topology: `oho-api afccdd74e`, `oho-webhook c3dbadd`.
- Prior implementation had high-risk paths: messaging did not restore authority, Take/Pass persisted state before Graph success, contact lookup lacked business scoping, Redis dedup completion/release lacked ownership tokens, and AI identity incorrectly required `app_id`.
- Canonical Facebook events are flattened from `entry.messaging[]` and `entry.standby[]` and tagged with `__ohoChannel`; `message.ai_generated` is nested inside each canonical event.

Failures and how to do differently:
- GitLab MR lookup failed due sandbox DNS; rely on local refs/reflog/source evidence and label remote verification unavailable.
- Do not treat POC diagrams or prior plans as runtime contracts without tracing parser → persistence → bot/send paths.

References:
- `/Users/tualek/ohochat/oho-api` commit `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`
- `/Users/tualek/ohochat/oho-webhook` commit `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`
- Error: `dial tcp: lookup gitlab.boonmeelab.com: no such host`

### Task 2: Implement scoped fixes

task: implement-facebook-meta-business-ai-safety-fixes
 task_group: ohochat-meta-business-ai-implementation
 task_outcome: partial

Preference signals:
- when the user requested `5.6 Luna max`, the assistant initially selected `gpt-5.6-sol` and the user corrected: “ฉันบอกให้ใช้ 5.6 Luna max” -> never substitute a nearby model without explicit approval; stop and report model availability.
- the user said to fix “แค่ scope ที่เป็น feature meta business ai ก่อน” -> preserve dirty worktree and avoid unrelated cleanup or channel changes.
- the user clarified: `ai_generated === true` on a Facebook `standby` event is sufficient Meta Business AI identity even when `app_id` is absent -> implement `entry.__ohoChannel === 'standby' && entry.message.ai_generated === true`; do not require `app_id`.

Reusable knowledge:
- Authority is represented by `facebook_delivery_authority` (`oho|other`) plus observation timestamp. `standby` customer events observe `other`; customer `messaging` observes `oho` only as recovery from prior `other`, avoiding a Mongo write on normal OHO traffic.
- Take/Return services now query by `_id + business_id`, validate Facebook, call Graph first, and persist authority only after Graph success. Graph failure leaves prior authority unchanged.
- Authority persistence uses conditional primary updates and avoids writes when the authority is unchanged or the event is stale.
- Webhook dedup now uses a pending lease and ownership token. `completeWithTtl` and `releaseWithToken` use Lua/CAS token checks so an expired worker cannot mutate a newer worker’s lease.
- Automated Facebook send guard performs a primary read and should fail closed if the authoritative contact cannot be found; this adds primary-read cost that must be measured.
- Stream identity for AI messages is `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox`.

Failures and how to do differently:
- Campaign broadcast still filters recipients once before the batch; authority changes during the batch can create a TOCTOU send window. Either accept/document this risk or add a carefully measured per-recipient/send-time check.
- Focused tests/builds passed, but full suite, production E2E, load testing, and production logs were not run. Do not call the change merge/canary-ready until those gates are completed.
- Redis tests pass with warning because no local Redis was available: `EPERM 127.0.0.1:6379`; distinguish this environment warning from a test failure.
- Worktrees remain dirty with pre-existing and newly added files. Before commit, capture baseline status and review only the intended Meta Business AI delta.

References:
- Identity: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:20-24`
- Authority observation: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:42-95`
- Canonical event extraction: `oho-webhook/src/controllers/facebook/helper.ts:1532-1561`
- Webhook handling and dedup completion: `oho-webhook/src/controllers/facebook/handler.ts:966-989,1230-1415`
- Redis lease/CAS: `oho-webhook/src/services/redis.service.ts:1-20,230-305`
- API tenant-scoped loader/update: `oho-api/src/services/contact/meta-business-ai/shared.js:5-75`
- Automation guard: `oho-api/src/utils/meta-business-ai-automation-guard.js`
- Validation: API focused `4 suites/17 tests`; webhook focused `3 suites/17 tests`; both builds passed; `git diff --check` passed.

## Thread `019febf6-d717-7103-a1de-872be9834c91`
updated_at: 2026-08-11T03:33:02+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T20-57-30-019febf6-d717-7103-a1de-872be9834c91.jsonl
rollout_summary_file: 2026-08-10T13-57-30-8fJv-meta_business_ai_minimal_integration_flag_scope_correction.md

---
description: Meta Business AI MVP was simplified to Facebook-only authority observation, but the claim that the feature flag was fully removed was incorrect because web-app and legacy references remain.
task: review-and-simplify-meta-business-ai-mvp-and-verify-feature-flag-removal
task_group: /Users/tualek/ohochat cross-repo Meta Business AI workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, rt_meta_business_ai_enabled, oho-api, oho-webhook, oho-web-app, standby, facebook_delivery_authority, Redis lease, campaign race, primary Mongo, feature flag
---

### Task 1: Simplify and review Meta Business AI MVP

task: review branch MVP across oho-api/oho-webhook for performance, webhook safety, and worst-case failures; reduce scope before implementation.
task_group: Meta Business AI backend/webhook review
task_outcome: partial

Preference signals:
- The user asked to recheck existing MVP work, worried that new fields could hurt performance, and explicitly asked about worst cases such as messages not arriving or performance dropping -> future reviews should trace webhook throughput, DB writes/queries, queue/dedup behavior, and delivery failure modes.
- The user asked to prioritize `oho-api` and `oho-webhook` while waiting for web-app design -> keep backend/webhook scope separate from UI work.
- The user prefers detailed Thai, source-cited findings with clear evidence/severity/recommendation structure, and no fabricated logs or verification.

Reusable knowledge:
- Original feature commits were `oho-api afccdd74e` and `oho-webhook c3dbadd`; the branch refs later pointed at staging, so review required reflog/commit inspection rather than assuming a normal branch diff.
- The minimal direction removed backend Remote Config gating and large runtime-state writes, using Facebook-only `standby` authority observation, durable customer-message persistence before automation suppression, primary Mongo reads, timestamp-conditional authority updates, and a 5-second query bound.
- `standby` means another app may own delivery; it is not proof of Meta Business AI. `ai_generated` identifies an echo author, not ownership.
- Validation completed: both builds passed, focused tests passed, and `git diff --check` passed. Full captured-payload replay, terminal Mongo/Stream verification, load testing, and canary were not completed.

Failures and how to do differently:
- Redis dedup leases use no owner token/CAS; a worker running beyond the 300-second lease can race a reclaimed worker. Fix before canary.
- Broadcast authority filtering is batch-snapshot-only; add send-time per-recipient authority checks or gate campaigns.
- Legacy `meta_business_ai.observed_authority` remains as compatibility state; measure/backfill/expire it before removal.
- Do not treat HTTP 200 or unit tests as webhook delivery proof; replay captured payloads and inspect terminal Mongo/Stream state.

References:
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md` (remaining blockers B1–B5)
- `oho-api/src/services/contact/upsert/upsert.hooks.js`
- `oho-api/src/services/contact/meta-business-ai/shared.js`
- `oho-webhook/src/controllers/facebook/handler.ts`
- `oho-webhook/src/controllers/facebook/helper.ts`

### Task 2: Correct feature-flag removal scope

task: investigate why `rt_meta_business_ai_enabled` still exists after the assistant claimed no feature flag remained.
task_group: cross-repo flag/config verification
task_outcome: fail

Preference signals:
- The user challenged the contradiction directly: “บอกว่าไม่มี feature flag แล้วทำไมยังมี ใน firebase config” -> acknowledge the overclaim and distinguish backend removal from repository-wide removal.

Reusable knowledge:
- A workspace-wide search found active web-app flag usage:
  - `oho-web-app/store/index.js:52` initializes `rt_meta_business_ai_enabled: false`.
  - `oho-web-app/plugins/firebase-remote-config.js:23` defines the flag.
  - `oho-web-app/components/Smartchat/Conversation.vue`, `RoomHeader.vue`, and `SendMessageDisabled.vue` read the flag to gate UI/badges/actions.
  - `oho-web-app/utils/meta-business-ai.js` contains feature-enabled checks.
- Backend RC lookup was removed from `oho-api`/`oho-webhook`, but Meta Business AI backend domain code remains for Stream labeling and takeover/return endpoints. Thus the accurate claim is “no backend RC lookup remains,” not “no feature flag exists anywhere.”
- Use a workspace-wide search before claiming global removal: `rg -n -i "meta[_-]?business[_-]?ai|rt_meta_business_ai|business_ai" . --glob '!node_modules/**' --glob '!dist/**' --glob '!coverage/**' --glob '!.claude-worktrees/**' --glob '!*.lock'`.

Failures and how to do differently:
- The assistant searched backend/runtime scope but failed to account for web-app, docs, and legacy/config references. Future agents must classify all hits as active runtime, UI, config, docs, tests, or compatibility before making removal claims.

References:
- `oho-web-app/store/index.js:52`
- `oho-web-app/plugins/firebase-remote-config.js:23`
- `oho-web-app/components/Smartchat/Conversation.vue:1000-1006,3789-3839`
- `oho-web-app/components/Smartchat/RoomHeader.vue:118-130`
- `oho-web-app/components/Smartchat/SendMessageDisabled.vue:263-273`
- Search output also showed `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`, `oho-api/config/default.json`, takeover/return services, and compatibility references.

## Thread `019fef13-d776-7dc0-b2b5-fce38b9ab737`
updated_at: 2026-08-11T04:28:15+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-28-02-019fef13-d776-7dc0-b2b5-fce38b9ab737.jsonl
rollout_summary_file: 2026-08-11T04-28-02-vw3l-meta_ai_plan_review_aborted.md

---
description: User requested a detailed, prioritized review of a Meta AI profile-fix plan, but the rollout was aborted before any file inspection or analysis.
task: review-meta-ai-profile-plan
task_group: plan-review
task_outcome: uncertain
cwd: /Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an
keywords: Meta AI, plan review, assumptions, risks, edge cases, validation, rollback, testing, observability, dependencies, migration, security, acceptance criteria
---

### Task 1: Review Meta AI profile plan

task: review `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md` in detail
task_group: Meta AI implementation planning
 task_outcome: uncertain

Preference signals:
- The user explicitly requested a comprehensive review covering "assumption/risk/edge case/validation/rollback/testing/observability/dependency/migration/security หรือ acceptance criteria" -> future reviews should proactively inspect each of these categories.
- The user asked for "การแก้ไขที่ actionable และจัดลำดับความสำคัญ" -> provide concrete proposed changes and prioritize them rather than only listing omissions.

Reusable knowledge:
- The requested plan file is `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`.

Failures and how to do differently:
- The user aborted before the file was opened, so there are no validated findings, edits, tests, or implementation facts to preserve.

References:
- Prior conversation ID: `6a7aa49b-df20-83ec-a0b6-c5704cce2124`
- Exact requested review dimensions: assumptions, risks, edge cases, validation, rollback, testing, observability, dependencies, migration, security, and acceptance criteria.

## Thread `019fef19-a05e-7773-9301-06b8ab7c9e37`
updated_at: 2026-08-11T14:18:06+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-34-21-019fef19-a05e-7773-9301-06b8ab7c9e37.jsonl
rollout_summary_file: 2026-08-11T04-34-21-HTzp-meta_business_ai_plan_review_and_mvp_correction.md

---
description: Meta Business AI plan was narrowed from an oversized profile/state migration to a Facebook-only MVP, but implementation still requires rework before merge due to hidden writes, duplicated authority logic, lease expiry risk, and unguarded bulk broadcast.
task: review-and-correct-meta-business-ai-plan-and-mvp
task_group: /Users/tualek/ohochat/meta-business-ai
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, ai_generated, meta_business_ai_enabled, standby, facebook_delivery_authority, @meta-ai, @inbox, Stream, Redis lease, Lua CAS, Graph API, upsert.hooks.js, upsert.class.js, broadcast
---

### Task 1: Narrow and rewrite implementation plan

task: review-plan-fix-meta-ai-profile
 task_group: Meta Business AI planning
 task_outcome: partial

Preference signals:
- ผู้ใช้แก้ว่า `ai_generated คือ field ที่ webhook จาก meta ส่งมาถ้า meta ai เป็นคนตอบ` -> preserve strict incoming `message.ai_generated === true`; never claim OHO creates/infer it from app/channel/metadata.
- ผู้ใช้ขอให้อัปเดต plan ให้ “พร้อมทำงาน” -> include explicit scope/non-goals, phases, files, tests, rollout/rollback, and honest local-vs-UAT status.

Reusable knowledge:
- Correct contract: `message.ai_generated === true` identifies the author of one Meta message only. It is not activation or thread-owner evidence.
- AI Stream identity is tenant-scoped `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox` while preserving `ai_generated: true`.
- `standby` means another app may own delivery; it does not itself prove Meta Business AI.
- The revised plan removed `meta_ai_profile`, cold provisioning/backfill, Redis/Cloud Tasks migration, send-first/HUMAN_AGENT fallback, TypeScript conversion, and UI work from the MVP.

Failures and how to do differently:
- Do not combine schema/state-machine migration, optimization, Stream provisioning, and webhook cleanup into one rollout. Separate correctness scope from later performance work.
- Do not call focused tests or a plan update runtime verification; live payload replay and terminal Mongo/Stream state remain separate gates.

References:
- `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19,45-55`

### Task 2: Implement and review MVP corrections

task: implement-approved-facebook-meta-business-ai-mvp
 task_group: oho-api + oho-webhook
 task_outcome: partial

Preference signals:
- Approved scope was Facebook-only in `oho-api`/`oho-webhook`; preserve dirty worktree and do not commit, push, reset, revert, delete, or stage.
- Treat HTTP 200, focused tests, and queue acknowledgement as insufficient; verify terminal datastore/Stream state for live claims.

Reusable knowledge:
- Implemented flow wires explicit `channel.meta_business_ai_enabled` through webhook context, contact upsert, automation guard, and control services.
- Strict AI exception must occur only after Facebook/page/contact validation; unknown external apps without strict `ai_generated:true` remain fail-closed.
- Enabled Facebook standby customer messages should persist first, then skip OHO chatbot/ARP/greeting/fallback/referral/scheduled automation.
- Existing Accept/Close Graph control remains tenant-scoped and persists authority only after Graph success.
- Primary send-time automation guard is tenant-scoped, bounded, and fail-closed on missing/error; however raw bulk Facebook broadcast is outside this guard.

Failures and how to do differently:
- Final review found disabled channels still trigger contact activation snapshot writes in `upsert.hooks.js:184-240`; remove this traffic-driven write so feature-off has no new side effects.
- Authority/evidence persistence is duplicated in `upsert.hooks.js:184-390` and `upsert.class.js:51-248`; extract one shared atomic updater or simplify the duplicate fallback.
- Redis dedup uses a fixed 300-second lease with no renewal (`block.ts:289-321`, `redis.service.ts:224-303`); add renewal or an explicit maximum processing policy and real expiry/CAS integration tests.
- Remove unused `checkDuplicate()` and deprecated dedup methods if no callers remain, or document why compatibility requires them.
- Remove `skipped_authority_count` from bulk broadcast unless campaigns are explicitly brought into MVP and guarded per recipient/send time.
- `upsert.class.spec.js` failed to load on Node 24 due `config` calling `Utils.isRegExp`; report as environment/dependency failure, not a passing code test.

References:
- Focused webhook tests: 3 suites / 24 tests passed; warnings included missing `OHO_FB_APP_ID` and unavailable local Redis.
- API guard/control: 2 suites / 13 tests passed; `upsert.class.spec.js` blocked by Node 24/config incompatibility.
- `git diff --check` passed in both repositories.
- Final verdict: rework before ship; live Meta replay, real Graph take/return, terminal Mongo/Redis/Stream verification, load test, canary, and rollback remain unverified.

## Thread `019ff026-fc80-7881-8a12-5ba2c15991bb`
updated_at: 2026-08-11T10:24:33+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T16-28-34-019ff026-fc80-7881-8a12-5ba2c15991bb.jsonl
rollout_summary_file: 2026-08-11T09-28-34-wXtp-meta_business_ai_plan_review_and_scope_correction.md

description: Reviewed and reworked Meta Business AI implementation plan; corrected ai_generated semantics, narrowed MVP, and blocked unsupported authority/control side effects pending activation evidence
 task: review-and-update-meta-business-ai-plan
 task_group: /Users/tualek/ohochat / Meta Business AI Messenger
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, ai_generated, standby, activation source, delivery authority, Stream @meta-ai, take_thread_control, pass_thread_control, oho-api, oho-webhook, focused tests
---

### Task 1: Review Meta Business AI plan

task: review-and-update-meta-business-ai-plan
task_group: Meta Business AI Messenger architecture
task_outcome: success

Preference signals:
- ผู้ใช้ยืนยันว่า `ai_generated` คือ field ที่ Meta webhook ส่งมาเมื่อ Meta AI เป็นผู้ตอบ -> ในงานต่อไปต้อง preserve incoming field และแยก message author identity ออกจาก thread/delivery authority
- ผู้ใช้ต้องการแผนที่พร้อมทำงาน ไม่ใช่ migration ขนาดใหญ่ที่รวมหลาย concern -> เริ่มจาก scope และ contract ที่พิสูจน์ได้จริง
- งาน Meta ควรตอบภาษาไทย พร้อม evidence/path และระบุข้อจำกัดอย่างตรงไปตรงมา

Reusable knowledge:
- `message.ai_generated === true` เป็น per-message author signal สำหรับ Meta AI; ไม่ใช่ Page activation, contact eligibility หรือ delivery ownership
- `app_id`, `metadata`, `hop_context`, `standby`, `thread_owner` และ `subscribed_apps` ไม่ใช่ activation source ที่เชื่อถือได้โดยลำพังจากหลักฐานใน rollout
- ไม่มี supported Page/contact activation source ใน repo ณ rollout นี้; Meta Eligibility API ถูกระบุเป็น coming soon ในเอกสารที่เก็บไว้
- Existing legacy `meta_business_ai` state/schema ต้องไม่ถูกลบโดยไม่มี backfill และ volume verification

Failures and how to do differently:
- แผนเดิมรวม `meta_ai_profile`, state machine, Redis/Cloud Tasks, provisioning, webhook cleanup และ TypeScript conversion ไว้ด้วยกัน -> แยก concerns และเริ่มจาก sender identity/author labeling ที่เล็กที่สุด
- ห้ามเปลี่ยน `ai_generated` ให้กลายเป็น authority observation หรือใช้ `standby` เป็นหลักฐานว่าเป็น Meta Business AI โดยอัตโนมัติ
- Exact handoff text ใช้ได้เฉพาะ handoff-to-queue contract; ห้ามใช้เป็น Page activation หรือปลดล็อก Graph take/return

References:
- `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19`
- `docs/meta-business-ai/meta-official-coming-soon-2026-08-04.md:9-15,29-31`

### Task 2: Update plan and implementation safeguards

task: narrow-meta-business-ai-mvp-and-validate
 task_group: oho-api/oho-webhook Meta Business AI MVP
 task_outcome: partial

Preference signals:
- เมื่อผู้ใช้แก้ว่า `ai_generated` มาจาก Meta webhook -> ใช้ strict boolean จาก payload เท่านั้น; ห้ามสร้างจาก `app_id`, metadata หรือ channel

Reusable knowledge:
- Updated plan path: `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `hasMetaBusinessAiActivation()` intentionally returns `false` until an explicit activation source exists; this prevents unsupported Meta take/return and Meta-specific send blocking
- AI echoes from Facebook `messaging`/`standby` can route to `${businessId}@meta-ai`; provisioning failure should fall back to `${businessId}@inbox` while preserving `ai_generated:true`
- Generic standby and non-Meta external app behavior should remain unchanged until activation is confirmed
- API focused validation passed 5 suites / 31 tests; webhook focused validation passed 1 suite / 17 tests; both builds and `git diff --check` passed

Failures and how to do differently:
- Do not call the implementation ready to ship: no real UAT or terminal Mongo/Stream replay was performed, and type-check still has unrelated existing failures
- Worktrees contained many pre-existing uncommitted changes and deleted canonical/dedup tests; isolate the intended diff before commit/review
- Verify terminal datastore/Stream state, not HTTP 200 or unit-test success alone

References:
- API test command: `npm test -- --runInBand --coverage=false src/services/contact/meta-business-ai/control-hooks.spec.js src/utils/meta-business-ai.spec.js src/utils/meta-business-ai-automation-guard.spec.js src/services/member-send-message/inbox/inbox.hooks.spec.js src/utils/meta-business-ai-stream.spec.js`
- Webhook test command: `npm test -- --runInBand --forceExit --coverage=false __tests__/facebook-meta-business-ai.test.ts`
- Activation seam: `oho-api/src/utils/meta-business-ai.js:42-50`
- Author detection: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:34-39`
- Final status: blocked pending explicit Meta activation/eligibility source and real replay verification

## Thread `019ff083-0ff1-7601-a36c-8514dad1e62b`
updated_at: 2026-08-11T13:57:23+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-09-08-019ff083-0ff1-7601-a36c-8514dad1e62b.jsonl
rollout_summary_file: 2026-08-11T11-09-08-rVYn-meta_business_ai_mvp_correction_pass.md

---
description: Implemented and locally validated a narrowly scoped Facebook Meta Business AI MVP correction pass; runtime/UAT remains unverified.
task: facebook-meta-business-ai-mvp-corrections
task_group: /Users/tualek/ohochat backend-webhook workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, meta_business_ai_enabled, ai_generated, Facebook standby, external-app whitelist, handoff, take_thread_control, pass_thread_control, Stream meta-ai, Redis lease, duplicate-create race, git diff check
---

### Task 1: Facebook Meta Business AI MVP corrections

task: implement approved Meta Business AI corrections in oho-api/oho-webhook without disturbing dirty work
 task_group: backend/webhook Meta Business AI
 task_outcome: partial

Preference signals:
- The user required preserving dirty work and explicitly forbade commit, push, reset, revert, delete, or stage -> future agents should inspect and report worktree state first and never perform destructive Git actions.
- The user required Facebook Messenger-only scope, no web-app changes, and no unrelated refactors -> keep similar work narrowly bounded.
- The user required exact validation results and remaining UAT gaps -> distinguish local test success from runtime readiness.

Reusable knowledge:
- Activation is persisted `channel.meta_business_ai_enabled`, default `false`, manually configured, and not Firebase Remote Config. It is propagated through webhook channel context, contact upsert, persisted contact snapshot, automation guards, and control services.
- `message.ai_generated === true` is strict per-message author evidence only. It must not be used as activation, thread ownership, or app identity evidence; unknown extra fields including `meta_business_ai.identity` are ignored.
- External-app whitelist handling must occur after Facebook/page/contact validation. Strict AI evidence is a narrow exception; unknown non-AI external apps remain fail-closed, and mixed batches must not be dropped wholesale.
- Enabled Facebook standby customer messages are persisted before OHO chatbot/ARP/greeting/fallback/referral/scheduled automation is blocked.
- Existing Accept/Close hooks invoke Graph takeover/return only under activation/source checks, with tenant scoping and authority persistence only after Graph success. Graph failure leaves prior state unchanged.
- Lazy Stream identity is `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox` while retaining `ai_generated:true`. No cold provisioning/backfill/repair.
- Focused validation passed: API 10 suites/50 tests; webhook 5 suites/46 tests; webhook TypeScript reported no errors; `git diff --check` clean in both repos; nothing staged.

Failures and how to do differently:
- A duplicate-create race initially lacked activation snapshot coverage. The fallback now persists the channel activation snapshot before applying standby authority, and `src/services/contact/upsert/upsert.class.spec.js` covers it.
- Local tests showed pre-existing duplicate Jest mock warnings, missing `OHO_FB_APP_ID`, and unavailable localhost Redis. Treat these as environment warnings, not runtime proof.
- Full suites, live Meta payload replay, Graph calls, terminal Mongo/Redis/Stream checks, canary/rollback, and target app configuration were not verified. Do not label this production-ready without those gates.

References:
- API HEAD: `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`
- Webhook HEAD: `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`
- Exact handoff text: `เอเจนต์ AI ของคุณโอนแชทนี้ให้คุณ`
- Plan: `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- Core files: `oho-api/src/models/channel.model.js`, `oho-api/src/services/contact/upsert/upsert.class.js`, `oho-api/src/services/contact/meta-business-ai/control-hooks.js`, `oho-api/src/utils/meta-business-ai-stream.js`, `oho-webhook/src/controllers/facebook/meta-business-ai.ts`, `oho-webhook/src/controllers/facebook/helper.ts`, `oho-webhook/src/controllers/facebook/handler.ts`

## Thread `019ff094-bfe0-7330-b67d-5c37089d39fe`
updated_at: 2026-08-11T18:47:31+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-28-28-019ff094-bfe0-7330-b67d-5c37089d39fe.jsonl
rollout_summary_file: 2026-08-11T11-28-28-MoHA-trace_querychannels_call_sites_and_doc_updates.md

---
description: Traced Stream Chat queryChannels usage in ohochat and identified the exact backend hot paths plus documentation corrections.
task: querychannels-call-site-analysis
task_group: ohochat-stream-chat
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: queryChannels, Stream Chat, contact/chat/search, chat-session/group/search, skip_stream_channel_sync, Flutter, docs/queryChannels.md
---

### Task 1: Locate queryChannels usages

task: repository-wide Stream Chat queryChannels call-site inventory
task_group: ohochat-stream-chat
task_outcome: success

Preference signals:
- The user asked where `queryChannel` is used; future answers should search the workspace, distinguish exact Stream calls from unrelated `queryChannel` variables, and provide paths/lines plus runtime flow.

Reusable knowledge:
- Active backend calls are `oho-api/src/services/contact/chat-search/chat-search.class.js:46` for `/contact/chat/search` and `oho-api/src/services/chat-session/group/search/search.class.js:28` for `/chat-session/group/search`.
- Flutter directly calls it at `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:331`, invoked from `oho-flutter-mobile/lib/modules/home/controllers/chat_list_controller.dart:915`; chunks are size 10.
- Manual callers are `script-oho/unread-unresponded/migrate-unread.ts:716`, `script-oho/unread-unresponded/probe-stream-authority.ts:355`, `oho-cli/lib/fix/fix-chat-room-attachment.js:307`, and `oho-cli/lib/fix/fix-contact.js:74`.
- `oho-api/src/services/conversations/facebook/facebook.hooks.js:372` is commented out; Flutter test verifications are mocks.

Failures and how to do differently:
- Broad `queryChannel` searches include docs, incidents, tests, comments, and unrelated export variables. Narrow with `rg '\.queryChannels\\('` and inspect surrounding comment delimiters.

References:
- `oho-api/src/services/contact/chat-search/chat-search.class.js:46-68`
- `oho-api/src/services/chat-session/group/search/search.class.js:28-47`
- `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:323-344`

### Task 2: Review docs/queryChannels.md coverage

task: compare queryChannels documentation with active code and identify required updates
task_group: ohochat-stream-chat-documentation
task_outcome: success

Preference signals:
- The user asked what additional points should be updated in `docs/queryChannels.md`; future documentation reviews should state scope explicitly and verify both positive call paths and no-call guards.

Reusable knowledge:
- For web hot-path changes, update only the two backend search classes; frontend Smartchat/Groupchat actions converge on those endpoints.
- Qualify `docs/queryChannels.md:68-70` because Stream is not queried for `$limit === 0`, empty database results, Smartchat `feature_flag.skip_stream_channel_sync`, or unresolved Groupchat starred scope.
- Add Flutter as a separate direct production caller only if documenting all system calls; scripts/CLI are manual/non-hot-path callers.
- `Conversation.vue` uses `channel.watch()`, not the search endpoints.

Failures and how to do differently:
- `git status` from the workspace root failed because the relevant git repository is under a project subdirectory; use `/Users/tualek/ohochat/oho-api` (or the relevant component directory) for git operations.
- Avoid editing every UI caller when the intended fix is backend Stream-query behavior.

References:
- `docs/queryChannels.md:68-70`
- `oho-api/src/services/contact/chat-search/chat-search.class.js:41-63,113-162`
- `oho-api/src/services/chat-session/group/search/search.class.js:69-84,116-138`

## Thread `019ff11b-e580-7052-b2d7-ee32d28d724d`
updated_at: 2026-08-11T14:09:31+00:00
cwd: /Users/tualek/ai-main
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T20-56-05-019ff11b-e580-7052-b2d7-ee32d28d724d.jsonl
rollout_summary_file: 2026-08-11T13-56-05-3WLH-ai_main_obsidian_caveman_token_context_analysis.md

---
description: Compared Obsidian cold memory, ai-main memory, and caveman token savings; verified ai-main is sufficient and enabled caveman full.
task: compare-memory-and-output-token-efficiency
task_group: ai-main-memory-workflow
 task_outcome: success
cwd: /Users/tualek/ai-main
keywords: ai-main, Obsidian, caveman, AGENTS.md, context, tokens, cold-memory, prompt-profiles
---

### Task 1: Memory architecture and Obsidian viability

task: compare Obsidian memory with ai-main/Codex memory
task_group: ai-main-memory-workflow
task_outcome: success

Preference signals:
- User asked for an evidence-based check of what is installed and whether it truly saves tokens/context -> inspect configured paths and repository structure before recommending a change.

Reusable knowledge:
- ai-main already has per-repo knowledge, shared cross-tool memory, `full`/`lean`/`min` prompt profiles, and guard scripts that reduce reliance on prompt rules.
- `/Users/tualek/.codex/AGENTS.md` measured 12,897 bytes and 1,836 words; README documents a 4,000-token ceiling for the full profile.
- Obsidian should be treated as cold memory: retrieve only relevant notes/excerpts, never load the whole vault. It adds organization and multi-AI portability more than direct token savings.
- Obsidian skill expects `/mnt/d/Obsidian Vault/AI Research/`, but filesystem verification on this macOS setup found that path absent.

Failures and how to do differently:
- Verify configured vault paths on the current OS; do not infer availability from an installed skill.
- Avoid storing the same knowledge in Obsidian and ai-main memory; duplication increases context and can create stale/conflicting facts.

References:
- `/Users/tualek/.agents/skills/obsidian-vault/SKILL.md`
- `/Users/tualek/ai-main/README.md`
- Configured but missing path: `/mnt/d/Obsidian Vault/AI Research/`
- ai-main memory locations: `memory/SHARED.md`, `memory/codex/`, `memory/lessons/`, and `knowledge/<repo>.md`

### Task 2: Caveman behavior

task: verify caveman operation and select response compression level
task_group: response-style-and-token-efficiency
task_outcome: success

Preference signals:
- User explicitly said `/caveman full` -> keep responses compressed at full level until `/caveman off`, `normal mode`, or session end.

Reusable knowledge:
- Caveman compresses generated responses and may reduce later conversation-history size, but does not reduce system prompt, `AGENTS.md`, source code, or tool-output context.
- It is a formatting/prompt skill, not an automatic context-retrieval mechanism.
- Available controls: `/caveman lite`, `/caveman full`, `/caveman ultra`, `/caveman off`.

Failures and how to do differently:
- Do not claim the skill's stated “65%” reduction is a verified reduction for Thai or this workflow; it was only a claim in the skill documentation.

References:
- `/Users/tualek/.agents/skills/caveman/SKILL.md`
- Exact user command: `/caveman full`

## Thread `019ff914-9f48-7db3-aec9-3c772585e8f1`
updated_at: 2026-08-13T06:57:27+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-05-06-019ff914-9f48-7db3-aec9-3c772585e8f1.jsonl
rollout_summary_file: 2026-08-13T03-05-06-BsgF-jera_tab_minimal_watcher_fix_and_mr_squash.md

---
description: Minimal JERA tab race fix completed in Web MR; over-engineered API/Remote Config changes were excluded, Web commits squashed and force-pushed.
task: fix JERA tab missing after late feature-flag resolution and clean up MR scope
task_group: /Users/tualek/ohochat/oho-web-app JERA feature-flag workflow
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: JERA, MaxPanel, rt_jera_feature_enabled, immediate watcher, partner connections, MR 874, c67c0018, Luna, force-with-lease, over-engineering
---

### Task 1: Minimal Web-only JERA fix

task: replace mount-only JERA partner fetch with late-flag watcher and remove unrelated complexity
task_group: JERA tab race / GitLab MR cleanup
task_outcome: success

Preference signals:
- when the user clarified the bug, they said `completeClaimedDedup()` was unrelated and asked whether the tab disappears because it renders before the flag arrives -> keep future fixes on the actual JERA render/fetch path; do not pull Facebook webhook or dedup work into this scope.
- the user required `Luna 5.6 max` -> use that exact model when available; never substitute another model silently.
- the user wanted the smallest fix and to close unnecessary MR scope -> prefer one immediate watcher and focused tests over cache, realtime, retry, or cross-repo architecture.

Reusable knowledge:
- Root cause: `MaxPanel` mounted while `rt_jera_feature_enabled` was false, so the old `mounted()` fetch did not run. When the flag later became true, the tab rendered but `fetched_jera_partner_connections` remained empty.
- Final watcher in `components/MaxPanel.vue` uses `immediate: true`, returns when flag is false, when a request is in flight, or when connections are already non-empty, then calls `fetchJeraPartnerConnections()`.
- The fetch method itself has an in-flight guard. No interval, focus listener, session cache, or Firebase realtime listener remains, so the watcher does not continuously spam requests.
- `completeClaimedDedup()` belongs to `/Users/tualek/ohochat/oho-webhook` and is unrelated to this JERA UI path.

Failures and how to do differently:
- The initial over-engineered Web MR added `sessionStorage` Remote Config caching, realtime updates, window-focus retry, and error state. These were outside the direct late-flag bug and were removed.
- Direct agent spawning with `gpt-5.6-luna` failed because that API surface reported it unavailable; a Codex task-creation route supported Luna and completed the work. Do not replace the requested model with Sol/Terra without permission.
- Full Web tests still had four pre-existing verification-token failures; report them separately rather than claiming the full suite is green.
- Manual Smartchat/contact-tab UAT and a fresh Web build were not completed, so do not call the MR fully merge-ready solely from focused tests.

References:
- Final commit: `c67c0018d436139d1a74002055ec7e489698daed` (`fix: fetch JERA connections after feature flag resolves`).
- Final effective diff against `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608`: only `components/MaxPanel.vue` and `test/components/MaxPanel.spec.js`, `54 insertions(+), 5 deletions(-)`.
- Validation: watcher `4/4` passed; store/Remote Config suite `34/34` passed; `git diff --check` passed; full MaxPanel suite `7 passed, 4 pre-existing failures`.
- Branch `tk-sprint-2616/feature/jera-tab-is-missing` was squashed and pushed with `git push --force-with-lease`; remote matched local and worktree was clean.
- Web MR: `oho/oho-web-app!874`; API MR `oho/oho-api!1293` was intentionally not modified.

## Thread `019ff9cf-2564-7b40-af25-0306981e9625`
updated_at: 2026-08-13T06:44:50+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T13-28-50-019ff9cf-2564-7b40-af25-0306981e9625.jsonl
rollout_summary_file: 2026-08-13T06-28-50-Iwy9-minimal_jera_tab_watcher_fix_and_commit.md

---
description: Minimal Web-only fix for JERA tab missing after delayed Firebase flag resolution, validated with focused tests and committed on the feature branch
 task: fix delayed JERA feature-flag watcher in oho-web-app
 task_group: oho-web-app JERA MR workflow
 task_outcome: success
 cwd: /private/tmp/oho-web-mr874
 keywords: JERA, MaxPanel, is_jera_feature_enabled, immediate watcher, sessionStorage, onConfigUpdate, Firebase Remote Config, Jest, git diff --check, ffe26f0e
---

### Task 1: Fix delayed JERA tab rendering

task: Replace mount-only JERA connection fetching with a minimal reactive watcher.
task_group: oho-web-app JERA MR !874
task_outcome: success

Preference signals:
- The user required work only in `/private/tmp/oho-web-mr874`, explicitly forbade touching API MR `!1293`, and required inspecting/preserving dirty work first -> future similar work should verify worktree and scope before edits.
- The user required the smallest root-cause fix and explicitly prohibited cache, realtime listener, focus retry, extra error state, messaging/webhook changes, and merge-ready claims without UAT -> keep implementation narrow and disclose unrun UAT.

Reusable knowledge:
- `components/MaxPanel.vue` now uses an immediate watcher on `is_jera_feature_enabled`; it returns when false, when `is_fetching_jera_partner_connections` is true, or when `fetched_jera_partner_connections` is non-empty, otherwise it fetches.
- `plugins/firebase-remote-config.js` was restored to target base parity. The final patch removes `sessionStorage` cache, `onConfigUpdate`, focus retry, and `has_jera_partner_connections_error`.
- Focused watcher tests passed 4/4. Store/API-vs-browser Remote Config precedence tests passed 34/34. `git diff --check` passed.
- Full `MaxPanel.spec.js` retained 4 pre-existing verification-token failures outside the patch; report them separately rather than claiming the full suite passed.

Failures and how to do differently:
- Dependencies were initially absent (`sh: jest: command not found`); `npm ci` restored them. Node `v26.5.0` is outside the repo’s declared Node `^22.0.0` engine.
- Build and manual Smartchat/contact-tab UAT were not run. Required residual checks include delayed `false -> true`, hard refresh/deep-link `?room=...`, and connected/incomplete JERA flows.

References:
- Worktree: `/private/tmp/oho-web-mr874`
- MR: `oho/oho-web-app!874`
- Base SHA: `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608`
- Focused test: `npm test -- --runInBand test/components/MaxPanel.spec.js -t 'MaxPanel JERA partner connection fetch'`
- Store test: `npm test -- --runInBand test/store/index.spec.js`

### Task 2: Commit the approved fix

task: Commit the validated MR changes on the requested feature branch.
task_group: oho-web-app git workflow
task_outcome: success

Preference signals:
- After initially forbidding commits, the user explicitly authorized committing on `tk-sprint-2616/feature/jera-tab-is-missing` -> commit only after explicit later approval; do not push without separate authorization.

Reusable knowledge:
- Detached worktree was attached to `tk-sprint-2616/feature/jera-tab-is-missing`; only the three MR files were staged.
- Commit `ffe26f0e fix: fetch jera connections after flag resolution` created successfully.
- Worktree is clean, branch is ahead 1 of origin, and no push occurred.

Failures and how to do differently:
- The commit-helper skill said not to mutate git, but the user’s later explicit commit authorization superseded that constraint; preserve this distinction when interpreting similar rollouts.

References:
- Commit: `ffe26f0e`
- Branch: `tk-sprint-2616/feature/jera-tab-is-missing`
- Verification: `git rev-list --left-right --count origin/tk-sprint-2616/feature/jera-tab-is-missing...HEAD` returned `0 1`.

