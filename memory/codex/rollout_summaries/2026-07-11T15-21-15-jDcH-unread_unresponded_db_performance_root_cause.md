thread_id: 019f51c4-bc6d-7223-a93d-e4ee27e97fe7
updated_at: 2026-07-11T15:24:30+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T22-21-15-019f51c4-bc6d-7223-a93d-e4ee27e97fe7.jsonl
cwd: /Users/tualek/ohochat

# Investigated unread/unresponded performance in `oho-api` and concluded the main slowdown came from unread badge count queries, not from stamping writes.

Rollout context: The user asked (in Thai) whether the unread/unresponded feature has a database performance issue, specifically whether slowdown comes from counting unread/unresponded or from write-side stamping like setting `is_unresponded` and removing ids from `unread_by`. The work happened in `/Users/tualek/ohochat/oho-api`.

## Task 1: Diagnose unread/unresponded slowdown

Outcome: success

Preference signals:
- The user asked, in effect, “ลองดูให้หน่อยว่า Feature unread/unrespone มีจุดไหนหรอที่ทำให้ Performance ของ databse slow” and then narrowed the suspicion to “ตอน count unread unresponded หรอ ตอนที่ ส่ง message แล้วต้อง stamp is_unresponded กับ เอา id ออกจาก unread_by หรอ” -> they want the agent to compare read-path count cost vs write-path stamping cost and identify the dominant bottleneck.
- The user framed it as a performance/root-cause question rather than a fix request -> future similar asks should start with evidence gathering and attribution, not immediate patching.

Key steps:
- Read repo guidance (`debug-mantra`, `diagnosing-bugs`) and the repo’s own incident note about unread-count slowdown before diving into code.
- Searched for `unread|unresponded|unread_by|is_unresponded|countDocuments` and traced the relevant paths in `chat-search`, `member-send-message`, `contact-send-message`, `webhook/stream.js`, and the contact model/indexes.
- Used the existing incident writeup `incident-unread-count-slowdown-2026-07-08.md` as the strongest evidence source.
- Compared the count path with the write path:
  - `chat-search.class.js` now counts unread with `unread_by: countMemberId` and unresponded with `is_unresponded: true`, each capped with `maxTimeMS` and fail-soft handling.
  - Write paths update `unread_by` / `is_unresponded` on message send and message.read, but these are point updates by `_id`.
- Verified the model/index shape: contact model has compound indexes for unread/unresponded, and the code comments/doc say unread uses equality on `unread_by`.

Failures and how to do differently:
- The older unread implementation was the key failure mode: `read_by: { $nin: [null, memberId] }` on a multikey array forced fetch-heavy counting over essentially the whole business, and it had no `maxTimeMS`.
- Writing `unread_by` / flipping `is_unresponded` is a lower-frequency secondary cost; future investigations should not over-weight those writes until the count path is ruled out.
- For performance incidents, the strongest confirmation came from the incident note and explain-style evidence, not from speculative code reading alone.

Reusable knowledge:
- The incident note records that the slow path was the unread `countDocuments` query, not the stamp writes: the old `$nin` unread count on an array field was O(total contacts in business) per poll and could fetch every doc even when the answer was 0.
- The repo already contains the mitigation pattern: unread count switched to equality on `unread_by`, counts got `maxTimeMS`, and fail-soft returns `null` instead of stalling the list response.
- `message.read` handling in `webhook/stream.js` resolves the channel’s business and then `$pull`s from `unread_by`; it is a write load, but the code path is still a targeted `_id` update.
- The contact model uses compound indexes aligned to unread/unresponded query shapes, and the repo explicitly documents unread count / tab filter patterns there.

References:
- [1] `incident-unread-count-slowdown-2026-07-08.md` — states the root cause as `countDocuments` with `read_by: { $nin: [null, memberId] }`, poll frequency, lack of `maxTimeMS`, and business-wide fetch cost.
- [2] `src/services/contact/chat-search/chat-search.class.js:129-167` — current badge-count implementation with `countDocuments({ ...countBaseQuery, unread_by: countMemberId })`, `maxTimeMS(timeout || 30000)`, and fail-soft `null` handling.
- [3] `src/services/contact-send-message/contact-send-message.hooks.js:230-255` — customer message write path sets `unread_by` from eligible members.
- [4] `src/services/member-send-message/member-send-message.hooks.js:648-663` — member reply write path clears `unread_by` and `is_unresponded`.
- [5] `src/webhook/stream.js:520-574` — Stream `message.read` resolves business and `$pull`s the member id from `unread_by` on contact/chat-session.
- [6] `src/models/contact.model.js` — compound indexes include unread/unresponded shapes, including `idx_contact_unread_filter_v3` and `idx_contact_unresponded_count_v1`.
- [7] The final user-facing answer explicitly concluded that the main slowdown was unread count, while `is_unresponded` stamping and `$pull unread_by` were secondary write load.
