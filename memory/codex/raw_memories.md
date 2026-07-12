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

