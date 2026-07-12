thread_id: 019f516d-893b-7923-a4b3-96517d54a6c0
updated_at: 2026-07-11T14:32:17+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl
cwd: /Users/tualek/ohochat

# Thai code review of `oho-api` unread/unresponded changes found blocker-level issues.

Rollout context: The user asked in Thai for a code review of modified code in `oho-api` (worktree `mr-1285-fixes` on branch `feature/tk-sprint-2613/oho-1018-unrespone`). The assistant followed the repo’s `code-reviewer` skill and reviewed the local diff with focus on correctness, security, performance, and test coverage.

## Task 1: Review `oho-api` unread/unresponded and bulk-send changes

Outcome: fail

Preference signals:
- The user asked for a code review in Thai: `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct and judgmental, not tentative or generic.
- The user only asked whether the changes were okay, not for implementation help -> future agents should default to review-first, findings-first output.

Key steps:
- Read the repo’s code-review skill and local workspace instructions first.
- Collected `git status`, `git diff --stat`, and the touched file list for the worktree.
- Followed the unread/unresponded call path through `convertUnreadUnrespondedQuery`, search hooks, `search-query-converter`, and `addVisibilityFilter`.
- Checked the write paths for customer-message, member-reply, bot-reply, close-case, bulk-send, and realtime broadcast updates.
- Ran focused Jest on model defaults, helper hooks, badge counts, and related paths; Mongo-backed integration tests could not run because no MongoDB URI was available.

Failures and how to do differently:
- The review exposed a real query-composition regression risk: the new unread/unresponded filter shape interacts badly with the search converters and visibility rewriting.
- `addVisibilityFilter()` can rebuild `context.params.query` with its own `$or`, which can overwrite unread/unresponded composition on sale-visibility paths.
- The focused unit test for `convertUnreadUnrespondedQuery` was useful validation; when it fails or changes semantics, treat that as a blocker before reasoning about downstream hooks.
- Repository-wide `tsc --noEmit` was noisy because of unrelated pre-existing TypeScript errors; targeted tests were more useful than trusting the full typecheck.

Reusable knowledge:
- `convertUnreadUnrespondedQuery.ts` now has a special both-flags path that returns `$or` / `$and` instead of the previous top-level AND-style injection.
- `chat-search.hooks.js` and `chat-session/group/search/search.hooks.js` omit `$or` from `countBaseQuery`, showing the search/count lifecycle has to be traced end-to-end.
- `search-query-converter.ts` explicitly preserves only `read_by`, `is_unresponded`, and `read_by.0` as typed filters; future filter-shape changes need matching parser updates.
- `bulk.class.js` now writes `is_unresponded: false` and optionally updates `read_by` directly via `contactModel.updateOne(...)` instead of the previous shared helper.
- `git diff --check` passed; the diff was otherwise large and touched many files, including docs, feature-flag logic, search hooks, models, cache utilities, and tests.

References:
- `rtk proxy npx jest src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts --runInBand --forceExit --detectOpenHandles` failed at `convert-unread-unresponded-query.spec.ts:106` when the both-flags case did not match the current contract.
- `src/services/contact/helper-hook/convert-unread-unresponded-query.ts:41-49` shows the new both-flags branch injecting both filters directly.
- `src/services/contact/chat-search/chat-search.hooks.js:89-118, 159-177` and `src/services/chat-session/group/search/search.hooks.js` show the typed-filter split and badge-count base query flow.
- `src/services/contact/chat-search/shared-hooks.js:314-413` and `:690-694` show `addVisibilityFilter()` rewriting query state.
- `src/services/member-send-message/bulk/bulk.class.js` now updates contact state directly and has per-request context state.

## Task 2: Deep dive on rollout verification and remaining blockers

Outcome: partial

Preference signals:
- The user’s ask was review-only, so later work focused on verifying blockers rather than proposing fixes.
- The rollout showed the user/branch is working in a Thai-language review flow; the assistant kept the findings concise and judgmental rather than implementation-heavy.

Key steps:
- Ran targeted Jest on the changed model, cache, badge-count, and unread/unresponded-related suites; 12 suites / 128 tests passed, 2 skipped.
- Tried Mongo-backed integration tests for unread-unresponded filter behavior and badge-count scoping, but they failed immediately because `MONGODB_URI` was not available.
- Verified the bot-send-message suite: 6 pre-existing quick-reply tests still failed, while the new atomic `is_unresponded` guard tests passed.
- Checked `git status` and confirmed the worktree had many modified and untracked files, including new utilities and review notes.

Failures and how to do differently:
- Integration coverage for the badge/query behavior remains blocked without a Mongo datasource, so `explain()`-level performance proof is still missing.
- The bot-send-message spec still has unrelated quick-reply failures, so a raw “all tests green” claim would be misleading.
- The review found that the customer-message and reply write paths still need careful race analysis; per-file unit tests exist, but there was no live DB proof for all interleavings.

Reusable knowledge:
- `src/models/contact.model.spec.ts` and `src/models/chat-session.model.spec.ts` verify that `unread_by` and `is_unresponded` are absent on bare documents when flags are off.
- `src/utils/compute-badge-counts.ts` now uses `Promise.allSettled`, so unread and unresponded badge counts fail independently instead of both dropping to null.
- `src/utils/channel-eligible-members.ts` uses Redis caching plus a 2,000-member cap and 5s lookup timeout; on lookup failure or over-cap it returns `null` so callers skip writing `unread_by` instead of wiping state.
- `src/utils/cache/index.js` added a 3s Redis command timeout wrapper, affecting all callers of `cacheService.get/set`.
- `src/webhook/stream.js` moved channel-business resolution to Redis-backed caching with a 7-day positive TTL and 60s negative TTL.

References:
- Focused Jest result: `12 passed, 2 skipped, 128 passed` across the selected suites.
- Mongo-backed tests failed with `Could not find MongoDB URI. Set NODE_ENV to use config file or set MONGODB_URI env var.` and secondary `collection.deleteMany` errors after setup failed.
- `src/services/bot-send-message/bot-send-message.hooks.spec.js` still fails 6 quick-reply expectations; the new `updateContactProfile` atomic guard tests passed.
- `src/utils/cache/index.js:5-13, 21-38, 49-77, 104-121` shows the new Redis command timeout wrapper.
- `src/services/contact-send-message/contact-send-message.hooks.js:226-241` and `src/services/chat-session/group/contact-user/send-message/send-message.class.js:29-42` show the shared customer-message unread payload path.

