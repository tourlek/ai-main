---
name: oho-badge-cache-review
description: Review OHO unread/unresponded badge-cache changes for Redis key scope, single-flight admission, timeout, and late-write correctness when the user asks whether cache fixes are safe.
argument-hint: "[worktree, diff, or cache concern]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO Badge Cache Review

## When to Use

Use for read-only review of `oho-api/src/utils/badge-count-cache.ts`, `compute-badge-counts`, or related eligible-member cache work, especially for `single-flight`, stampede, Redis timeout, `Promise.race`, stale writes, or OHO-1272 badge fixes.

Do not use it for implementing a cache redesign or for claiming production performance without telemetry.

## Inputs and Context to Gather

1. Pin the exact `oho-api` checkout/worktree, branch, HEAD, status, and diff.
2. Read the helper, its specs, cache key builders, `src/index.js`, and callers before judging a claimed fix.
3. Record whether Jest/TypeScript can actually run; Node 24/config and pre-existing type errors have previously blocked independent runs.

## Procedure

1. Check cache contract first: key namespace/scope, numeric `0` hit semantics, TTL, and whether Redis timeout cancels or can replay an offline-queued write.
2. Trace admission timing. The map must synchronously contain the complete cache-read-plus-compute flight before the first await; otherwise staggered GETs can create duplicate flights.
3. Trace timeout through all side effects. A wall-clock `Promise.race` timeout is not cancellation: require a flight-local expiration/cancellation state before every late cache write.
4. Confirm cleanup: joiners return the same flight, timer cleanup and map deletion happen on success, rejection, and timeout, and late rejection cannot become unhandled.
5. Read regressions, not only their names. Cover concurrent miss, pending-cache-read join, timeout/fresh retry, and a late first compute that cannot overwrite a second flight.
6. Check Bluebird/native Promise interop if `global.Promise` is replaced; use a small focused probe only when static behavior is uncertain.
7. Report exact file:line evidence, validation limits, and a decisive ship/no-ship verdict.

## Efficiency Plan

- Start with `rg -n "getOrComputeBadgeCount|inFlight|Promise.race|expired|setCachedBadgeCount|raceCommandTimeout|enable_offline_queue|global.Promise" src`.
- Read helper and targeted specs together; do not spend time on broad suites until the race model is clear.
- Stop at source/spec verification if the environment blocks tests, and label the result accurately.

## Pitfalls and Fixes

- Symptom: concurrent callers still compute twice. Cause: map registration occurs after Redis I/O. Fix: install the full lifecycle synchronously before the first await.
- Symptom: timeout prevents the response but stale data appears later. Cause: underlying compute kept running and wrote after the race settled. Fix: gate post-compute writes on a flight-local expiration state.
- Symptom: cache review checks only Redis timeout. Cause: key isolation, `0` hits, offline queue replay, admission races, and late writes are separate risks. Fix: review each independently.
- Symptom: tests appear complete but miss the claimed race. Cause: mocks or auto-resolving promises never hold the first flight. Fix: use manually controlled pending GET/compute regressions.

## Verification Checklist

- Exact worktree, branch/HEAD, status, and diff are named.
- Key scope, `0` semantics, timeout behavior, admission, cleanup, and late-write gating were inspected.
- Specs prove concurrent joining, timeout retry, and stale-write prevention.
- Bluebird/native promise behavior is checked when applicable.
- Any unavailable Jest/TypeScript run is reported as a limitation rather than passed validation.
