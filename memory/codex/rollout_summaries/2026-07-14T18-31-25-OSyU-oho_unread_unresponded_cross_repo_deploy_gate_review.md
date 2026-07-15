thread_id: 019f61e5-e958-75d1-ae40-e7dc4ffd3d5c
updated_at: 2026-07-14T18:42:39+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T01-31-25-019f61e5-e958-75d1-ae40-e7dc4ffd3d5c.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: uat

# Cross-repo read-only deploy-gate review of unread/unresponded realtime badge fixes

Rollout context: The user asked for a strict read-only correctness review across `/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes`, `/Users/tualek/ohochat/oho-websocket`, and `/Users/tualek/ohochat/oho-web-app`, with every claim grounded in actual diff/file lines. The review had to group findings by severity and focus areas, falsify any “safe/fixed/unaffected” claims, and end with a deploy verdict.

## Task 1: Review `oho-api` fix round, especially clear-write paths and tests

Outcome: partial

Preference signals:

- The user explicitly said: “Do NOT trust the summary below as fact — run git diff / git status yourself in each repo and verify every claim against the actual diff.” This indicates future reviews should always pin the real worktree state first and treat summaries as suspect.
- The user also said: “Do NOT edit, stage, commit, or run any command that mutates files or git state.” This strongly signals read-only inspection only for similar review tasks.
- The user requested severity-ranked findings with file:line evidence and a one-line verdict, so future outputs should stay compact and judgmental rather than exploratory.

Key steps:

- Verified worktree status and branch state in all three repos before reading diffs.
- In `oho-api`, confirmed the landed commit plus additional working-tree edits, and read the live diff for contact-send-message and bulk-send paths.
- Traced `updateContactAfterBulkSend()` and the per-platform loops in `bulk.class.js` to see when `is_unresponded` / `unread_by` are actually cleared.

Failures and how to do differently:

- The mixed-success bulk-send guard was only partly correct: the code now skips the clear when *all* deliveries fail, but still derives the timestamp from the entire merged payload, which can include failed deliveries. Future reviews should trace the timestamp source, not just the boolean guard.
- The bulk-send spec coverage was shallow in the active path: the serious LINE path regression tests existed, but the mixed-success guard was not exercised in a way that would fail if the new logic were reverted.

Reusable knowledge:

- `src/utils/get-last-stream-message-timestamp.js` returns the last distinct `oho_created_at` from the payload, so any guard that uses it must ensure the payload really represents a successful reply, not merely a batched attempt.
- In `src/services/member-send-message/bulk/bulk.class.js`, the new guard `hasSuccessfulDelivery` protects `updateContactAfterBulkSend()`, but the timestamp fed into that function comes from the merged payload across all responses.
- The `oho-api` model for `chatSession` has `unread_by` and `is_unresponded` explicitly absent by default, which supports the “flag off means field absent” contract.

References:

- [1] `src/services/member-send-message/bulk/bulk.class.js:218-276` guarded clear-write; `:300-377`, `:451-528`, `:615-676` compute `lastMessageTimestamp` from all merged responses.
- [2] `src/utils/get-last-stream-message-timestamp.js:3-8` uses `.map('oho_created_at').sortedUniq().last()`.
- [3] `src/services/contact-send-message/contact-send-message.hooks.js:585-602` adds the wider `emitContactUnrespondedStatusUpdatedEvent` alongside the narrower chat-session broadcast.
- [4] `src/services/chat-session/hooks/emit-chat-session-event.js:245-389` shows the shared, channel-eligible, fail-closed emitter pattern and the 1:1 contact broadcaster.
- [5] `src/models/chat-session.model.js:31-97` confirms group chat sessions have no `sale_owner` / `assign_to` fields.

## Task 2: Review `oho-websocket` read-path and group broadcast changes

Outcome: partial

Preference signals:

- The user specifically highlighted the new `message.read` realtime broadcast and the independently reimplemented `channel-eligible-members.js` as potential counterexample targets. Future reviews should actively try to falsify those safe-by-design claims.
- The user emphasized checking whether the websocket port is “actually faithful” to the oho-api version, which suggests future port reviews should compare semantics, not just line-by-line similarity.

Key steps:

- Read `src/webhook/stream.js` and `src/handlers/stream-webhook.handler.js` diffs directly, plus the new websocket-specific `src/utils/channel-eligible-members.js` and its tests.
- Verified that `message.read` now does an unconditional `$pull` first and gates only the post-write broadcast on `isUnreadFeatureEnabled`.
- Traced the new group-message audience scoping through the in-memory eligible-member cache and per-member socket channels.
- Compared the websocket `firebase-remote-config.js` port to the oho-api version.

Failures and how to do differently:

- The new group broadcast helper is fail-closed, but the in-memory TTL cache means revoked channel permission can still receive message content until cache expiry; future reviews should treat cached audience computation as a security boundary, not just a performance optimization.
- The helper does not cache in-flight Promise state, so concurrent cold/expired lookups can stampede Mongo. Future reviewers should check for single-flight when a cache guards a hot path.
- The `message.read` broadcast now depends on `modifiedCount > 0`, so it avoids double-broadcast on no-op writes, but the emitted `updated_at` comes from the Stream event time, which downstream frontend code can still treat as stale and drop.
- The Remote Config port is faithful in single-flight and backoff behavior, but the review had to compare it against the oho-api implementation directly to verify that it wasn’t just “similar enough.”

Reusable knowledge:

- `src/webhook/stream.js:215-240` uses `modifiedCount` to decide whether to emit `chat-session/status updated` with `is_read_by_me: true`.
- `src/handlers/stream-webhook.handler.js:447-483` scopes group `message.new` broadcasts to eligible members via `getEligibleMemberIds()` and per-member channels; it skips the broadcast entirely when the eligible set is unknown or empty.
- `src/utils/channel-eligible-members.js:4-39,58-92` caches eligible IDs in memory for 60s with a 20k-entry cap and returns `null` on over-cap or lookup failure.
- `src/firebase-remote-config.js:25-68` implements single-flight and TTL backoff by holding `refreshPromise` and bumping `templateFetchedAt` on both success and failure.
- `src/models/contact.model.js:9-67` and `src/models/chat-session.model.js:10-27` both declare `unread_by` as a mirrored field with timestamps; the contact model also includes `sale_owner` and `assign_to`, while `chatSession` does not.

References:

- [1] `src/webhook/stream.js:171-240` unconditional pull, ordering guard, `modifiedCount` check, and gated realtime `is_read_by_me` broadcast.
- [2] `src/handlers/stream-webhook.handler.js:447-483` group chat audience scoping via `getEligibleMemberIds()`.
- [3] `src/utils/channel-eligible-members.js:41-99` in-memory TTL cache and fail-closed null behavior.
- [4] `src/utils/channel-eligible-members.spec.js:69-110` only checks sequential cache/fail-closed/over-cap behavior, not revocation/TTL-expiry/concurrency.
- [5] `src/firebase-remote-config.js:1-136` and `src/firebase-remote-config.spec.js:91-161` verify single-flight/backoff/retry behavior.
- [6] `src/handlers/stream-webhook.handler.spec.js:70-118` confirms the group broadcast no longer falls back to the whole-business channel.
- [7] `src/webhook/stream.spec.js:82-239` exercises the read-path guard, the unconditional pull, and the flag-gated post-write broadcast.

## Task 3: Review `oho-web-app` optimistic counters, channel scoping, conversation flow, and request sequencing

Outcome: partial

Preference signals:

- The user explicitly questioned whether `checked_channels` semantics could now under-count when “no channels selected = show all,” so future frontend reviews should inspect empty-selection semantics carefully rather than assuming they are harmless.
- The user wanted both `Conversation.vue` try/catch rollback and the `optimistic-flag-count-tracker` semantics checked against their doc comments/specs, which suggests future review should verify the counter bookkeeping against both the helper and its callers.

Key steps:

- Read the optimistic counter helper, the smartchat/groupchat Vuex modules, and `Conversation.vue` around the read/send flows.
- Traced `checked_channels` from `plugins/api-service-helper.js` and `plugins/filter-helper.js` through `store/modules/smartchat.js` and `store/modules/groupchat.js`.
- Inspected the new tests for channel-scoped aggregate counts, groupchat filter behavior, and API-vs-browser Firebase precedence.

Failures and how to do differently:

- `markRoomRead()` wraps `addMembers()` and `markRead()` in one catch, but the rollback path still assumes an unread decrement already happened; if `addMembers()` fails before the decrement, the increment rollback can overstate the badge. Future reviews should separate pre-markRead and post-markRead failure paths.
- The optimistic counter helper now records every increment in its Set, which fixes the documented offscreen repeat bug, but the implementation still depends on module-level Sets that are never seeded/reset from authoritative API fetches; future reviews should check API refresh and filter-scope changes for stale Set drift.
- The `checked_channels` gate treats an empty list as “all channels in scope,” which matches the query helper semantics, but that means the correctness question becomes whether room channel IDs are always available on the event/local-state path. Future reviewers should verify fallback behavior for unknown channels rather than assuming empty selection is the only edge.
- The new request-sequencing guard in `pages/business/_biz_id/groupchat/index.vue` is plausible, but it was not deeply validated against a concrete stale-response reproduction.

Reusable knowledge:

- `utils/optimistic-flag-count-tracker.js` now does `set.add(id)` on every increment and `set.delete(id)` on every decrement; its doc comment says the Set must reflect “currently counted true” regardless of whether the item was loaded locally or not.
- `store/modules/smartchat.js:694-767` and `store/modules/groupchat.js:217-254` now gate aggregate count commits behind `checked_channels`; empty `checked_channels` means no channel filter is active and all channels are in scope.
- `components/Smartchat/RoomList.vue` now applies `filter_unresponded` to groupchat as well, while keeping `filter_unread` smartchat-only.
- `plugins/firebase-remote-config.js:52-56` makes later browser-side remote config updates non-authoritative if the API already committed a flag key.
- `store/index.js:103-129` tracks `feature_flags_api_keys` so the browser plugin does not silently overwrite API-authenticated values.

References:

- [1] `utils/optimistic-flag-count-tracker.js:1-40` and `test/utils/optimistic-flag-count-tracker.spec.js:103-160`.
- [2] `store/modules/smartchat.js:694-767` and `test/store/modules/smartchat.spec.js:1002-1070`.
- [3] `store/modules/groupchat.js:217-254` and `test/store/modules/groupchat.spec.js:34-101`.
- [4] `components/Smartchat/Conversation.vue:1640-1717` and `test/components/Smartchat/Conversation.spec.js:216-333`.
- [5] `components/Smartchat/RoomList.vue` diff and `test/components/Smartchat/RoomList.spec.js:332-356`.
- [6] `store/index.js:103-129`, `test/store/index.spec.js:118-179`, and `plugins/firebase-remote-config.js:52-56`.
- [7] `pages/business/_biz_id/groupchat/index.vue:557-585` request-sequencing comment/guard.

Overall takeaway: this rollout contained multiple real correctness improvements, but the review also surfaced a live security boundary issue in websocket audience caching, a rollback-path bug in `Conversation.vue`, and a timestamp/guard mismatch risk in bulk-send. A future agent should always compare the claimed fix against the exact update/emit path, not just the obvious intent.
