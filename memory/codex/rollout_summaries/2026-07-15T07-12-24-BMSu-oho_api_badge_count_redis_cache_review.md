thread_id: 019f649e-9cc4-7813-bcca-a102cb1b4a2a
updated_at: 2026-07-15T07:21:36+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T14-12-24-019f649e-9cc4-7813-bcca-a102cb1b4a2a.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/tk-sprint-2613/oho-1018-unrespone

# Review of short-TTL Redis caching for badge counts in oho-api

Rollout context: review-only code review in `/Users/tualek/ohochat/oho-api` of an uncommitted change adding an 8s Redis cache around unread/unresponded badge-count queries. The user required exact file:line citations, ranked severity findings, and an overall ship/needs-fix/block verdict. The review also had to inspect the real current contents of `src/utils/badge-count-cache.ts`, `src/utils/compute-badge-counts.ts`, and `src/utils/compute-badge-counts.spec.ts`, then trace related query builders, Redis helpers, and realtime emit paths.

## Task 1: Review badge-count cache correctness and risk

Outcome: partial

Preference signals:

- The user explicitly asked for a review-only result and said "do NOT modify files" -> future similar reviews should stay read-only and avoid proposing edits as the main deliverable.
- The user asked for "findings ranked by severity with file:line references" and an "overall verdict" -> future similar reviews should default to concise, judgmental, evidence-backed findings rather than broad prose.
- The user emphasized correctness bugs, especially "cross-member cache poisoning" -> future similar cache reviews should prioritize key isolation, scope capture, and stale-data risks before style or minor test gaps.

Key steps:

- Read the modified files and line-numbered them, then traced `computeBadgeCounts` call sites in `chat-search.class.js` and `group/search/search.class.js`.
- Traced `buildCountBaseQuery()` and the surrounding hooks to confirm `countBaseQuery` still contains business/tab/channel/sale-visibility scope, while `countMemberId` is appended for unread counts.
- Verified `Types.ObjectId` stringification behavior directly in Node: same ObjectId stringified identically, different ObjectIds stringified differently.
- Traced `cacheService` / `raceCommandTimeout` in `src/utils/cache/index.js`, `src/redis-connector.js`, and the redis client defaults to evaluate timeout and offline-queue behavior.
- Confirmed the new tests mock the cache module boundary, so they do not exercise real cache-key serialization or Redis behavior.

Failures and how to do differently:

- The initial instinct was to worry about ObjectId or `$in`/`$or` collisions; the evidence showed those were not the main issue. Future reviews should check whether the key already includes the member/business scope before escalating collision risk.
- Jest could not run cleanly in the read-only environment because it tried to persist a haste map under `/private/var/...` and hit `EPERM`. In similar environments, rely more heavily on direct source inspection and targeted runtime probes.
- A first pass through the new tests was misleading because `badge-count-cache` is fully mocked. For cache features, review the helper boundary directly, not just orchestration tests.

Reusable knowledge:

- `computeBadgeCounts` is called from both `src/services/contact/chat-search/chat-search.class.js` and `src/services/chat-session/group/search/search.class.js`; those call sites pass `countBaseQuery`, `countMemberId`, and a label.
- `buildCountBaseQuery()` in `src/services/contact/chat-search/build-count-base-query.ts` strips Feathers meta fields and typed unread/unresponded fields, so scope is intended to live in the base query.
- `getCachedBadgeCount()` treats numeric `0` as a valid hit and `undefined` as miss; `runCount()` checks `cached !== undefined`.
- The cache helper uses Redis `SETEX` seconds through `cacheService.set(key, value, ttl)`; TTL `8` is passed as a number and is not a string-based TTL.
- `src/index.js` sets `global.Promise = require('bluebird')`, so production Promise semantics differ from Jest's native Promise semantics.

References:

- [1] `src/utils/badge-count-cache.ts:20-78` — TTL 8s, cache key format, fail-soft get/set, and key construction by `label`, `kind`, `JSON.stringify(filter)`.
- [2] `src/utils/compute-badge-counts.ts:119-219` — cache lookup, DB fallback, `Promise.allSettled`, Bluebird-compatible settlement handling, and `setCachedBadgeCount()` fire-and-forget call.
- [3] `src/utils/compute-badge-counts.spec.ts:22-29, 266-363` — cache module is mocked; tests cover orchestration, not real Redis/helper behavior.
- [4] `src/services/contact/chat-search/build-count-base-query.ts:37-41` — count base query strips only meta/typed fields.
- [5] Node runtime probe — same ObjectId stringified identically and different ObjectIds differently: `{"unread_by":"64b000000000000000000001"}` vs `{"unread_by":"64b000000000000000000002"}`.

## Task 2: Trace Redis timeout, offline queue, and stale-write behavior

Outcome: partial

Preference signals:

- The user explicitly asked about the fire-and-forget write path and whether there is any unhandled-rejection risk -> future reviews should inspect async helper semantics, not just the caller line.
- The user also asked about staleness vs realtime and whether an 8s stale aggregate is acceptable -> future similar reviews should distinguish freshness trade-offs from correctness bugs.

Key steps:

- Read `src/utils/cache/index.js` and confirmed `raceCommandTimeout()` only races the returned promise; it does not cancel the underlying Redis command.
- Read `node_modules/redis/index.js` and `README.md` to verify the client’s default `enable_offline_queue` is true.
- Reasoned that a timed-out `SETEX` can still be queued and later applied after reconnect, potentially extending stale cache writes beyond the intended TTL window.
- Cross-checked `emit-chat-session-event.js` and `firebase-remote-config.js` to confirm realtime broadcasts carry `is_unresponded` status but not badge counts.

Failures and how to do differently:

- The review did not fully prove the exact production impact of late queued writes under every deployment topology, but the underlying mechanism is real in the Redis client defaults. In similar cases, treat “timeout does not cancel command + offline queue enabled” as a serious stale-write risk even if the exact observed frequency is unknown.

Reusable knowledge:

- `src/utils/cache/index.js:27-55` implements timeout as a race, not as command cancellation.
- Node Redis 3.x defaults `enable_offline_queue` to true; commands issued while disconnected are queued and replayed on reconnect.
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-323` emits `chat-session/status updated` payloads carrying `is_unresponded`, but there is no equivalent badge-count push path.

References:

- [6] `src/utils/cache/index.js:27-55` — `raceCommandTimeout()` timeout/race behavior.
- [7] `node_modules/redis/index.js:97-103, 476-480, 766-792` and `node_modules/redis/README.md:181-183` — offline queue default is on.
- [8] `src/services/chat-session/hooks/emit-chat-session-event.js:271-323` — realtime payload carries `is_unresponded`, not badge count.

## Task 3: Judge overall ship readiness

Outcome: partial

Preference signals:

- The user wanted a ranked list and a final one-paragraph verdict -> future similar reviews should end with a clear recommendation, not a hedge-only recap.

Key steps:

- Consolidated the evidence into severity-ranked findings.
- Separated verified non-findings from actual risks to avoid overstating cross-member poisoning.
- Interpreted the mitigation as correct on key isolation and `0` semantics, but not fully safe because Redis timeout/offline-queue behavior can undermine the short-TTL guarantee and the cache-miss burst can still recreate load spikes.

Failures and how to do differently:

- The change does not appear to have a correctness bug in cache-key membership isolation, but the mitigation still needs guardrails for stale writes and stampede behavior before it should be considered ready.

Reusable knowledge:

- Verified non-findings: cross-member poisoning was not substantiated; `countMemberId` is part of the unread filter, the base query keeps business/tab scope, `0` remains a valid cached value, and the cache write helper swallows normal timeout/error paths.
- Remaining blocking concern: late Redis writes plus lack of single-flight mean the cache can still violate its intended bounded-staleness / load-smoothing goals.

References:

- [9] `src/utils/compute-badge-counts.ts:139-149` and `src/utils/badge-count-cache.ts:20` — no single-flight, so concurrent misses can stampede.
- [10] `src/utils/compute-badge-counts.ts:139-145` and `src/utils/cache/index.js:19,27-55` — cache GET timeout budget and Mongo fallback timing.
- [11] `src/utils/cache/index.js:113-120, 75-80` and `src/utils/compute-badge-counts.ts:139-140` — `0` round-trips correctly and is treated as a hit.
- [12] `src/utils/compute-badge-counts.ts:154-160` — unread cache key still carries member-specific scope via `unread_by: countMemberId`.

