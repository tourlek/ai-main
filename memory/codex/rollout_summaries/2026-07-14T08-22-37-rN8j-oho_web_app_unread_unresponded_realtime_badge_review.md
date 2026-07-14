thread_id: 019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df
updated_at: 2026-07-14T08:33:02+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T15-22-37-019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: feature/tk-sprint-2613/oho-1018-unrespone

# Review of the `oho-web-app` unread/unresponded realtime badge diff against backend commit `oho-websocket@9141805`

Rollout context: The user asked for a read-only code review of an uncommitted frontend diff in `/Users/tualek/ohochat/oho-web-app`, explicitly grounding claims in the diff and in sibling backend commit `9141805` from `/Users/tualek/ohochat/oho-websocket`. They wanted findings grouped by severity (Bug / Risk / Nit / Looks fine) and a one-line merge verdict, with no edits.

## Task 1: Review frontend increment/decrement badge logic for realtime unread/unresponded updates

Outcome: fail

Preference signals:

- The user said: "This is a review-only request. Do not fix anything, do not edit any files. Only report findings." -> future similar review tasks should stay read-only and avoid proposing or applying patches unless explicitly asked.
- The user required: "Ground every claim in the actual diff content and the actual oho-websocket commit 9141805 content that you read yourself. Quote or reference specific line/field names. Do not speculate ... If something can't be verified ... say so explicitly." -> future reviews should cite exact file/line/field evidence and clearly separate verified facts from inference.
- The user requested a specific output shape: short list grouped by severity and a one-line merge verdict -> future review responses should preserve that structure instead of giving a generic essay.

Key steps:

- Read the frontend diff for `store/modules/smartchat.js` and `store/modules/groupchat.js`.
- Read backend commit `9141805` in `oho-websocket`, especially `src/handlers/stream-webhook.handler.js` and `src/webhook/stream.js`.
- Traced the existing optimistic decrement paths in `components/Smartchat/Conversation.vue` and the read/unresponded UI logic in `components/Smartchat/RoomList.vue`.
- Checked Vuex state initialization and reset paths in `smartchat.js`/`groupchat.js` to judge whether direct assignment is reactive.

Failures and how to do differently:

- The diff is not safe as-is. The review identified a blocker that the backend `9141805` message.new path does not show any sender-role guard, so the frontend cannot assume every emitted payload corresponds to a customer message.
- The unread path remains incomplete: `markRoomRead()` decrements unread locally but does not synchronize `room.is_read_by_me`, so the new realtime transition logic can still miss or double-handle unread state changes depending on which producer fires.
- The new increment logic can drift when the room is not already loaded in the list/current room, because it treats a missing prior state as if it had already been correctly represented in the aggregate.

Reusable knowledge:

- Backend commit `9141805` in `oho-websocket` emits `is_read_by_me:false` and `is_unresponded:true` on `chat-session/message created` when the stale-event guard passes; it does **not** emit a `true` read flag on `message.read` (that path only `$pull`s `unread_by`).
- `store/modules/groupchat.js` already defines `unread_count` and `unresponded_count` in initial state; `store/modules/smartchat.js`’s `contact_list` initial/reset shape does not include `unread_count`/`unresponded_count`, so assigning those fields later can be non-reactive if the property is created during a reset window in Vue 2.
- `components/Smartchat/Conversation.vue` optimistic unresponded handling already sets `room.is_unresponded = false` before decrementing, which helps avoid a duplicate decrement when the realtime event arrives.
- `components/Smartchat/RoomList.vue` treats missing/legacy `is_read_by_me` as read in the list fallback, which supports the asymmetry used in the diff (`is_unresponded === true` vs `is_read_by_me !== false`) for known rows.

References:

- [1] Frontend diff reviewed: `store/modules/smartchat.js` adds `incrementUnreadCount` / `incrementUnrespondedCount` and a new `is_read_by_me` transition block; `store/modules/groupchat.js` adds `incrementGroupchatUnrespondedCount` and a symmetric `is_unresponded` transition branch.
- [2] Backend commit evidence: `oho-websocket/src/handlers/stream-webhook.handler.js:289-299` stale-event guard uses `oho_created_at` vs `last_contact_date`; `:337-365` emits `is_read_by_me:false` and `is_unresponded:true`; `:407-422` emits only `is_unresponded:true` for group.
- [3] `oho-websocket/src/webhook/stream.js:142-160` handles `message.read` by resolving business and `$pull`ing `unread_by`; there is no `is_read_by_me:true` payload emitted there.
- [4] `components/Smartchat/Conversation.vue:1649-1680` decrements unread on mark-read based on `was_unread`; `:1975-1979` sets `room.is_unresponded = false` before decrementing.
- [5] `components/Smartchat/RoomList.vue:170-176` falls back to `is_read_by_me` when Stream state is not loaded, and treats null/undefined as read.

