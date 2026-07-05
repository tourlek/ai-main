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

