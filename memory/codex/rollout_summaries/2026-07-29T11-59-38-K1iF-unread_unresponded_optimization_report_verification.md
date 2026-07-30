thread_id: 019fadbe-9f4b-7e81-955d-a4ab24c396a9
updated_at: 2026-07-29T12:13:38+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-59-38-019fadbe-9f4b-7e81-955d-a4ab24c396a9.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: fix/oho-1272-unread-unresponded-realtime-badge

# Read-only verification of unread/unresponded optimization report against live oho-api and oho-web-app

Rollout context: Reviewed `/Users/tualek/ohochat/unread-unresponded-optimize-review.md` against API `5971ebf...` on `master` and web `5fc4ef22...` on `fix/oho-1272-unread-unresponded-realtime-badge`; only the API timestamp commit `bbe0ac735` differs from the stated branch. No files were modified and no tests/benchmarks were run.

## Task 1: Verify claims (a)-(g)

Outcome: partial

Key findings:
- (a) PARTIAL: group `countDocuments(findQueryPayload)` has no result cap/cache at `oho-api/src/services/chat-session/group/search/search.class.js:110-114`, but does have `maxTimeMS` with a 75s service timeout. The endpoint is frequently refetched, not proven to be timer-polled.
- (b) CONFIRMED structurally: `emitChatSessionStatusUpdatedEvent` performs one `findOne`, nine top-level populates, nested team populates, and additional audience queries at `emit-chat-session-event.js:47-128,167-173` and `socket.io.js:359-417`; callers await it inline. Exact query count is data/Mongoose dependent.
- (c) PARTIAL: the 1→2 sequential `findOneAndUpdate` split is real and errors are not caught at `contact-send-message.hooks.js:220-243`, but the second write is protected by `last_contact_date <= lastMessageTimestamp`.
- (d) CONFIRMED: member delivery completes before after-hooks (`member-send-message.class.js:26-64`); clear writes and emitters run before Stream persistence at `member-send-message.hooks.js:667-686,1281-1289`, inside the lock window `:1250-1310`. A Mongo error can leave the customer-delivered message absent from Stream. Competing requests may return 409 after Redlock retries.
- (e) PARTIAL: badge cache keys omit environment/service namespace at `badge-count-cache.ts:18-25`, but `channel-eligible-members.ts:8-9,40-46` also uses an unprefixed key. Cross-environment collision requires shared Redis and matching keys.
- (f) PARTIAL: web Remote Config sets `minimumFetchIntervalMillis=0` and invokes fetch on client bootstrap (`plugins/firebase-remote-config.js:16-17,36-40`, loaded by `nuxt.config.js:253`), but fetch is fire-and-forget (`:85-89`) and SDK cache/throttling may still apply; it is not proven to block page load.
- (g) PARTIAL: fallback `getContactChatById` has no debounce/in-flight dedupe, but only qualifying fallback events trigger it (`smartchat.js:706-763,927-948`); timestamped in-list events and stale events do not all fetch.

## Task 2: Missed findings and proposal review

Outcome: success

Reusable findings:
- Flag-off still pays most emitter cost because the feature flag is checked after the database read, populates, and audience lookup (`emit-chat-session-event.js:47-200`); only payload field removal occurs at `:201-203`.
- Keyword group search has another unbounded exact-total path via `$facet.metadata.$count` (`chat-session/utils/search-query-converter.ts:144-205`) with only the 75s timeout.
- Eligible-member cache misses have no single-flight (`channel-eligible-members.ts:50-76`), and accepted inbound writes can carry up to 2,000 member IDs in `unread_by` (`:10-18,74-78`; `build-customer-message-unread-payload.ts:24-37`).
- Socket fan-out is one `io.to(channelNames).emit()` call, not one API emit per member (`socket.io.js:420-440`), but recipient delivery and room-name construction scale with eligible members. Inbound bubbles produce B message emits plus full/narrow status emits.
- Bulk send launches platform handlers without awaiting them and returns `{ok:true}` (`member-send-message/bulk/bulk.class.js:31-68`); per-contact loops are serial and failures can stop later contacts after HTTP success (`:210-212,366-368,523-525`).
- Web fallback fetch requests the large `query_params.contact_default` population set (`smartchat.js:927-936`, `api/query-params.js:2-68`), and realtime store/list processing performs multiple O(n) scans and list rendering passes (`smartchat.js:717-718,780-786`, `RoomList.vue:145-205`).

O1-O14 conclusions:
- Safe/low-risk with focused tests: O7 namespace both caches plus robust single-flight; O13 request/context-scoped flag memoization. O4 only as a narrowly scoped failure-policy change with logging/reconciliation and explicit acceptance of stale badge state.
- Separate design/QA: O1 and O9 because count/API semantics change; O2 and O6 because populated/stale snapshot payloads can change; O8 because visible staleness changes; O10/O14 because Remote Config authority and refresh need joint design; O11 only for in-flight coalescing/trailing refresh; O5 only via a redesign preserving legacy field absence.
- Do not do as written: O3 raw fire-and-forget due to ordering, shutdown-loss, and cross-request state risks; O5 simple merged update removing `$exists`; O11 skip-fetch for off-list rooms; O12 timestamp-only optimization because `chat/request created` has bot/request/reject/cancel producers and frontend interprets it as customer unread activity.

Final verdict: NO-SHIP as-is until the customer-delivered/Stream-missing window and detached bulk-send failure semantics are addressed. Source-only review; no production cardinality, explain, or latency measurements were obtained.
