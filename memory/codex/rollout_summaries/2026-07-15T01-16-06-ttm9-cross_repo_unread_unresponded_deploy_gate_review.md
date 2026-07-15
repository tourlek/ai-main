thread_id: 019f6358-6a26-7531-ab13-b4360a1b5799
updated_at: 2026-07-15T01:29:28+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T08-16-06-019f6358-6a26-7531-ab13-b4360a1b5799.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: uat

# Cross-repo unread/unresponded deploy-gate review found frontend drift, one backend timestamp risk, and websocket areas that looked clean.

Rollout context: The user asked for a read-only, severity-ranked review of the latest round-2 fixes across three repos (`oho-api`, `oho-websocket`, `oho-web-app`) before production deploy. They required live verification from `git diff` / `git status` in each repo and wanted claims grounded in code actually read, not the summary text.

## Task 1: `oho-api` bulk-send round-2 fixes
Outcome: partial

Preference signals:
- The user explicitly said this was a read-only review and asked for a severity-ranked findings list with file:line evidence -> future similar reviews should stay read-only and evidence-first.
- The user specifically asked to inspect Instagram shape parity, the all-failed guard interaction, and whether the new test would still fail if the fix were reverted -> future reviews should mentally revert new tests and check whether they are truly regression tests.

Key steps:
- Verified the real worktree/branch (`/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes`, branch `uat/v2.25.0`) and diff.
- Read `bulk.class.js` / `bulk.class.spec.js`, including the Facebook + Instagram send paths and the new `hasSuccessfulDelivery` / `lastSuccessfulMessageTimestamp` logic.
- Checked Instagram send-message implementation directly: it returns `response.data` on success and throws `GeneralError` on failure, same shape as Facebook, and both bulk paths normalize to `is_send_fail` plus `oho_created_at`.
- Confirmed the all-failed batch short-circuit still prevents calling the clear-write when every send fails.

Failures and how to do differently:
- The clear-write now uses the last successful timestamp, but the function still computes `lastMessageTimestamp` across all messages and passes the same timestamp concept to `updateContactAfterBulkSend()`, which also drives `$max last_active_at`; this can affect chat-list ordering on mixed-success batches.
- The new Facebook regression test is strong, but there is no equivalent Instagram-specific regression test, so reverting the Instagram branch could still leave the suite green.

Reusable knowledge:
- Instagram reply-message service is semantically aligned with Facebook reply-message service: both return `response.data` on success and throw `GeneralError` on failure.
- `handleCallFacebook` was exported so the new test could directly exercise it; the test’s `afterAll` restore is scoped to the describe block and does not leak into sibling bulk-send tests.
- `getLastStreamMessageTimestamp()` is called twice in the mixed-success Facebook test: once for the pre-existing merged-payload timestamp and once for the filtered successful-only timestamp.

References:
- [1] `src/services/member-send-message/bulk/bulk.class.js:365-392` uses `hasSuccessfulDelivery` and `lastSuccessfulMessageTimestamp` for Facebook; `:531-552` mirrors that for Instagram; LINE remains `!isSendFail` gated at `:686-695`.
- [2] `src/services/integration/instagram/reply-message/reply-message.class.js:20-50` and `src/services/integration/facebook/reply-message/reply-message.class.js:20-49` both return `response.data` on success and throw `GeneralError` on failure.
- [3] `src/services/member-send-message/bulk/bulk.class.spec.js:363-505` contains the mixed-success Facebook regression tests.

## Task 2: `oho-websocket` eligibility scoping and `message.read` refresh
Outcome: success

Preference signals:
- The user asked to verify whether removing cache creates load problems and whether the new `findOneAndUpdate(..., {new:true})` broadcast payload still has the right fields -> future similar reviews should always trace call sites and payload consumers, not just the changed helper.

Key steps:
- Verified the live branch and diff for `oho-websocket` (`feature/tk-sprint-2613/oho-1018-unrespone`).
- Read `src/utils/channel-eligible-members.js`, `src/handlers/stream-webhook.handler.js`, and `src/webhook/stream.js` plus their tests.
- Checked call frequency: the eligible-member helper is used on every group `message.new`, not on 1:1 messages.
- Confirmed `message.read` still has `maxTimeMS`, `new:true`, `.select('business_id updated_at')`, and `.lean()`, and that the broadcast payload only needs the fields it now includes.

Failures and how to do differently:
- No new bug was found in the websocket round-2 changes; the main tradeoff is deliberate: removing TTL cache restores correctness after permission revokes, while single-flight preserves some load control.
- The repo does not expose enough production telemetry in code to estimate actual group QPS or index health, so load concern remains unproven rather than established.

Reusable knowledge:
- `getEligibleMemberIds()` in `oho-websocket` is a fresh-query helper with in-flight dedup only; it intentionally does not cache results because group message content is sent directly to per-member channels.
- The new `message.read` path is fail-closed: if the event has no usable timestamp, it skips the `$pull` instead of doing an unguarded write.
- The downstream `chat-session/status updated` payload from `message.read` only needs `_id`, `type`, `business_id`, `is_read_by_me`, and `updated_at`.

References:
- [1] `src/utils/channel-eligible-members.js:31-95` shows fresh query + single-flight only; `:10-28` explains why TTL caching was intentionally removed.
- [2] `src/handlers/stream-webhook.handler.js:447-483` scopes group `message.new` broadcasts to eligible members and skips broadcast when eligibility is unknown.
- [3] `src/webhook/stream.js:193-233` performs `findOneAndUpdate(..., { new: true })`, `select('business_id updated_at')`, and uses the committed `updated_at` in the broadcast payload.

## Task 3: `oho-web-app` realtime badge / optimistic counter fixes
Outcome: fail

Preference signals:
- The user requested a severity-ranked list with file:line citations, a one-line verdict, and explicit checks on whether round-1 and round-2 fixes conflict -> future review output should stay compact, judgmental, and contract-focused.
- The user also asked to verify performance/load implications of the optimistic-set reconciliation and whether pagination mutations were wired up -> future reviews should inspect append/pagination paths, not only full-list replacement.

Key steps:
- Verified the live branch/diff for `oho-web-app` (`uat`), then read `Conversation.vue`, `smartchat.js`, `groupchat.js`, `optimistic-flag-count-tracker.js`, `RoomList.vue`, and websocket consumers.
- Traced how `markRoomRead()` mutates local read state and how the store increments/decrements unread and unresponded counts.
- Checked the new Set-based optimistic tracker and where reconciliation is called.
- Compared UI count sources with API behavior and list pagination behavior.

Failures and how to do differently:
- The review concluded there is still a real correctness gap: reconciliation only happens on full list replacement mutations, not on append pagination (`addContactListData` / `addGroupchatChatList`), so offscreen items can still double-count when they reappear via realtime events.
- A second correctness issue remained: `markRead()` rollback does not unwind the optimistic `last_read` cursor, so a retry after a failure can think the room is already read and skip the decrement it should apply.
- The assistant also noted a possible mixed-success timestamp collateral risk in `oho-api` that the new tests do not cover, but the frontend review itself was already enough to fail deploy readiness.

Reusable knowledge:
- `reconcileOptimisticFlagSet()` now records every increment in its Set and deletes on every decrement; that fixes one known double-count path, but it only stays correct if every authoritative list replacement and pagination path seeds it appropriately.
- `Conversation.vue` now uses a function-local `did_decrement_unread_count` flag, which prevents rollback over-increment when `addMembers()` fails before the decrement runs.
- `RoomList.vue` uses `last_active_at` for client-side sort fallback, and the smartchat/groupchat pages expose `unread_count` / `unresponded_count` directly from list state.

References:
- [1] `utils/optimistic-flag-count-tracker.js:25-75` records every increment/decrement and defines `reconcileOptimisticFlagSet()`.
- [2] `store/modules/smartchat.js:70-91,128-130` reconciles only in `setContactList`; `store/modules/groupchat.js:46-61,92-95` reconciles only in `setGroupchatChatList`.
- [3] `components/Smartchat/Conversation.vue:1640-1733` contains the split try/catch, `did_decrement_unread_count`, and rollback path.
- [4] `store/modules/smartchat.js:760-789` intentionally avoids decrementing unread on `is_read_by_me:true` because the local mark-read path owns that decrement.

Overall deploy-readiness verdict: NOT READY. The websocket changes looked acceptable, but the frontend still had a blocker on offscreen aggregate reconciliation plus a high-risk mark-read retry drift path, and the bulk-send backend kept a mixed-success timestamp collateral risk.
