thread_id: 019faef2-a12e-78c2-b951-01d71a1deffd
updated_at: 2026-07-29T18:06:31+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T00-36-04-019faef2-a12e-78c2-b951-01d71a1deffd.jsonl
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge
git_branch: fix/oho-1272-unread-unresponded-realtime-badge

# Fourth-round verification of OHO-1272 unread/unresponded changes concluded ship

Rollout context: Read-only review of uncommitted changes in `/Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge`, branch `fix/oho-1272-unread-unresponded-realtime-badge`, HEAD `bbe0ac735634caf91cbe43c91eb18c5578c1d185`. The review followed three prior rounds of blocker fixes and focused on the final timeout/write-gating redesign in `src/utils/badge-count-cache.ts` plus its regression tests.

## Task 1: Verify final single-flight timeout/write fix

Outcome: success

Preference signals:
- The user repeatedly required read-only verification, actual current-file inspection, and exact `file:line` citations -> future reviews should inspect live worktree state and avoid relying on the user's fix description.
- The user wanted a decisive final `ship`/`no-ship` verdict and explicitly asked to check event-loop ordering, Promise interop, and test timing -> similar reviews should proactively cover concurrency timing and whether tests truly exercise the claimed race.

Key steps:
- Pinned branch, HEAD, status, and the current diff; confirmed the helper and spec remained uncommitted alongside the broader intended changeset.
- Verified `getOrComputeBadgeCount` is non-async, checks the map, starts the whole `run()` lifecycle, creates the timeout race, and sets the map without an outer `await` (`src/utils/badge-count-cache.ts:63-111`). This structurally closes the staggered Redis-GET admission race.
- Verified each flight has a local `expired` flag; timeout sets `expired = true` before rejecting (`src/utils/badge-count-cache.ts:73,95-103`), while the compute checks it immediately before `setCachedBadgeCount` (`:80-86`). A late successful compute therefore cannot write stale data after timeout.
- Verified `.finally()` clears the timer and deletes the map entry on success, rejection, or timeout (`src/utils/badge-count-cache.ts:106-109`); joiners return the existing promise and do not create another timer (`:69-71`).
- Verified the late-rejection sink (`running.catch(() => {})`, `:90-93`) and inspected Bluebird replacement at `src/index.js:12-13`; a local runtime probe confirmed Bluebird `Promise.race` assimilates native async promises and supports `.finally()`.
- Read the added tests rather than trusting the claim: concurrent misses assert one Redis read/compute/write (`badge-count-cache.spec.ts:200-225`); pending-GET joiner asserts no second GET (`:228-250`); timeout/fresh retry is covered (`:253-280`); and the late-write regression holds the first compute, times it out, lets a second flight cache `7`, then resolves the old compute and asserts only one cache write (`:311-347`).

Failures and how to do differently:
- Earlier rounds found and fixed: single-flight admission race, unbounded flight lifetime, stale bulk expectations, missing helper coverage, and timed-out late cache writes. The final redesign fixed the last blocker by gating the cache write on the flight-local `expired` flag.
- Jest/TypeScript were not independently rerun in this rollout because the documented environment has pre-existing Node 24/config incompatibility and TypeScript errors; conclusions were based on source/spec inspection plus a focused Promise runtime probe. Do not describe this as full behavioral test validation.

Reusable knowledge:
- For single-flight code, register the entire cache-read-plus-compute promise synchronously before its first asynchronous wait; checking the map only after Redis I/O leaves a staggered-GET race.
- A wall-clock timeout alone is insufficient: it rejects joiners and deletes the map, but the underlying computation may still fulfill later. Any side effect after the computation must be gated by a flight-local expiration/cancellation state.
- `Promise.race(...).finally(clearTimeout)` provides timer cleanup on all settlement paths; a pending ref'ed timer may keep shutdown alive until the bounded timeout, but this was judged non-blocking here.
- Cache-hit requests also briefly occupy the in-flight map because the whole lifecycle is deduplicated; this is acceptable when cleanup is shared and bounded.

References:
- [1] `src/utils/badge-count-cache.ts:63-111` — final synchronous registration, timeout race, expiration gating, cleanup.
- [2] `src/utils/badge-count-cache.spec.ts:228-250` — manually controlled pending-GET admission regression test.
- [3] `src/utils/badge-count-cache.spec.ts:311-347` — late-success-after-timeout stale-write regression test.
- [4] `src/index.js:12-13` — production `global.Promise = require('bluebird')`.
- [5] Local runtime probe verified native async promise + Bluebird `Promise.race`/`.finally` interoperability.
- [6] Final verdict from review: `VERDICT: ship`; no remaining blocking issue found, with Jest/tsc not independently rerun.
