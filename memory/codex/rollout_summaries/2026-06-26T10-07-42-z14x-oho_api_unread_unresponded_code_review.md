thread_id: 019f0366-4780-7b21-a9b4-c309436efcc5
updated_at: 2026-06-26T10:19:09+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl
cwd: /Users/tualek/ohochat

# Code review of `oho-api` unread/unresponded changes found blocker-level issues.

Rollout context: The user asked in Thai for a code review of modified code in `oho-api`. The assistant followed the `code-reviewer` skill, read local repo instructions, and reviewed the diff in `/Users/tualek/ohochat/oho-api` with focus on security, correctness, performance, and test coverage.

## Task 1: Review `oho-api` unread/unresponded and bulk-send changes

Outcome: fail

Preference signals:
- The user asked for a code review in Thai: `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct and judgmental, not tentative or generic.
- The user only asked whether the changes were okay, not for implementation help -> future agents should default to review-first, findings-first output.

Key steps:
- Read the `code-reviewer` skill and local workspace rules before reviewing the diff.
- Checked `git diff --stat`, then opened the changed files with line numbers.
- Verified the `convertUnreadUnrespondedQuery` behavior with focused Jest.
- Followed the call chain into `chat-search` / `group search` / `search-query-converter` and `addVisibilityFilter` to see whether the new `$or` composition survived later hooks.
- Checked `bulk.class.js` against the existing send-message flows and `updateContactLastActiveAt` helper.

Failures and how to do differently:
- The review exposed a real logic regression: the new unread/unresponded OR branch can be corrupted when `search` is present because the typed-filter handling in the search converters only explicitly preserves `read_by`, `is_unresponded`, and `read_by.0`, not the new `$or` / `$and` shape.
- The review exposed a second composition bug: `addVisibilityFilter()` rebuilds `context.params.query` with its own `$or`, so the unread/unresponded filters can be dropped for `chat.view-sale` style paths.
- The focused unit test for `convertUnreadUnrespondedQuery` failed at the new both-flags case, confirming the behavior change was not yet aligned with the current test contract.
- `npm run type-check` was not useful as validation for this diff because the repo already has unrelated TypeScript errors elsewhere.

Reusable knowledge:
- `convertUnreadUnrespondedQuery.ts` now has a special both-flags path that returns `$or` / `$and` instead of the previous top-level AND-style injection.
- `chat-search.hooks.js` and `chat-session/group/search/search.hooks.js` now omit `$or` from `countBaseQuery`, which shows the author was already trying to account for the new filter shape.
- `search-query-converter.ts` explicitly preserves only `read_by`, `is_unresponded`, and `read_by.0` as typed filters; any future filter-shape change that introduces `$or` / `$and` needs a corresponding update there.
- `bulk.class.js` now writes `is_unresponded: false` and optionally `$addToSet` on `read_by` directly via `contactModel.updateOne(...)` instead of the previous shared helper.

References:
- [1] `rtk proxy npx jest src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts --runInBand --forceExit --detectOpenHandles` → failed at `convert-unread-unresponded-query.spec.ts:106` because `context.params.query.read_by` was `undefined` in the both-flags case.
- [2] `src/services/contact/helper-hook/convert-unread-unresponded-query.ts:43-57` → new both-flags branch injects `$or`/`$and` and deletes the raw params.
- [3] `src/services/contact/chat-search/chat-search.hooks.js:33-36, 84-107, 151-158, 181-188` → typed-filter split only preserves `read_by`, `is_unresponded`, and `read_by.0`, and countBaseQuery now omits `$or`.
- [4] `src/services/chat-session/utils/search-query-converter.ts:9-10, 145-168` → same typed-filter list, same parse boundary.
- [5] `src/services/contact/chat-search/shared-hooks.js:124-150` → parser still coerces by `+currentValue` first, so boolean/null corruption is a real risk if `$or` leaks through.
- [6] `src/services/contact/chat-search/shared-hooks.js:314-413` and `:690-694` → `addVisibilityFilter()` rebuilds `context.params.query` with its own `$or`, which can overwrite unread/unresponded composition.
- [7] `src/services/member-send-message/bulk/bulk.class.js:169-176, 255, 393, 526` → bulk send now updates `contactModel` directly and sets `is_unresponded: false` plus member read tracking.
- [8] `rtk proxy git diff --check` passed; `rtk proxy npm run type-check` failed on unrelated repo-wide TS errors (`config` typings, existing spec type issues, etc.).
