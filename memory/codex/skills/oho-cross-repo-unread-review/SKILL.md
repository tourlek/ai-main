---
name: oho-cross-repo-unread-review
description: Review OHO unread/unresponded fixes across oho-api, oho-websocket, and oho-web-app when the user wants a read-only deploy gate, MR audit, or "is this actually fixed?" check with file-line evidence.
argument-hint: "[branch, MR, or symptom]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO Cross-Repo Unread Review

## When to Use

Use this when the task spans multiple OHO repos and the core question is whether unread/unresponded behavior is correct end to end, especially:

- deploy-gate review before merge or rollout
- cross-repo MR review touching `oho-api`, `oho-websocket`, and `oho-web-app`
- "is this actually fixed?" or "is the websocket/frontend port faithful?"
- audits of flag gating, `message.read`, badge counters, Remote Config precedence, or channel audience scoping

Do not use this for implementation work, generic Smartchat debugging, or one-repo-only changes unless the user explicitly widens scope.

## Inputs and Context to Gather

1. Confirm review mode and boundaries.
   - read-only review
   - deploy verdict only
   - repo subset if the user narrows scope
2. Pin the actual repo targets before reading summaries:
   - `/Users/tualek/ohochat/oho-api` or the specific worktree
   - `/Users/tualek/ohochat/oho-websocket`
   - `/Users/tualek/ohochat/oho-web-app`
3. If prior review docs are named, read them first and note which findings are already fixed.
4. Capture real worktree state in each repo:
   - `git status --short --branch`
   - `git diff --stat`
   - targeted `git diff -- <path>`
5. Identify the expected contract before inspecting code:
   - SET writes are flag-gated
   - CLEAR writes are unconditional
   - realtime broadcasts are flag-gated

## Procedure

1. Verify the real diff first.
   - Treat user-provided summaries and prior notes as leads, not facts.
   - If the actual worktree does not match the summary, anchor the review to the live diff.
2. Rebase on prior review history.
   - Read `plan.md` or prior consolidated review files if the user names them.
   - Avoid re-reporting findings already documented as fixed.
3. Audit `oho-api`.
   - Trace SET helpers: `buildCustomerMessageUnreadPayload()`.
   - Trace CLEAR helpers: `buildClearUnreadUnrespondedPayload()`.
   - Check bulk-send and reply paths for timestamp source, delivery-success guards, broadcast wiring, and platform parity between Facebook and Instagram.
   - If a new regression test was added, mentally revert the fix and confirm the test would fail for the intended platform path.
4. Audit `oho-websocket`.
   - Inspect `message.read` first: write order, ordering guard, `modifiedCount`, and broadcast gating.
   - Inspect customer-message audience scoping: whole-business room vs eligible-member channels.
   - Inspect the current `channel-eligible-members.js` shape before reasoning about risk: cache TTL, null behavior, fresh-query behavior, and single-flight all change the security/performance tradeoff.
   - If the user asks about load, trace call frequency and payload consumers; state plainly when code lacks telemetry to prove or disprove a QPS concern.
5. Audit `oho-web-app`.
   - Check Remote Config precedence against API-authenticated flags.
   - Trace `optimistic-flag-count-tracker.js`, `Conversation.vue`, and store modules for unread/unresponded counter drift.
   - Inspect full-list replacement and append/pagination mutations together; reconciliation that only runs on `set*List` can still drift on `add*List`.
   - Check whether rollback unwinds both aggregate counters and optimistic cursor state such as `last_read`.
   - Validate `checked_channels` semantics and any request-sequencing guards against the actual callers.
6. Validate the evidence level.
   - `git diff --check` or `node --check` only prove syntax/whitespace.
   - Run targeted tests only if the environment permits safe read-only execution.
   - If sandboxing blocks deeper validation, state that explicitly.
7. Report findings.
   - Rank by severity.
   - Cite exact file:line evidence.
   - End with a one-line merge/deploy verdict.

## Efficiency Plan

- Grep exact high-signal terms first: `message.read`, `buildCustomerMessageUnreadPayload`, `buildClearUnreadUnrespondedPayload`, `modifiedCount`, `channel-eligible-members`, `feature_flags_api_keys`, `optimistic-flag-count-tracker`, `checked_channels`, `markRoomRead`.
- When a review is about counters drifting, grep both replacement and append mutation names early, not just the helper that increments/decrements.
- Stop broad repo searching once the end-to-end path is covered: payload source, write guard, broadcast, frontend merge.
- Compare semantics, not similarity, when code is ported across repos.
- Reuse prior review docs only to suppress duplicate findings, never as a substitute for reading the live diff.

## Pitfalls and Fixes

- Symptom: review repeats stale findings. Likely cause: prior docs were not checked before diff reading. Fix: read prior review docs first, then confirm against current code.
- Symptom: summary says a fix landed but the review is wrong. Likely cause: actual worktree state was never verified. Fix: run `git status` and inspect the live diff in each repo first.
- Symptom: websocket change looks faithful to API logic. Likely cause: line similarity hides different guards, timestamps, or audiences. Fix: compare behavior contracts end to end.
- Symptom: audience helper looks safe because it is fail-closed. Likely cause: TTL cache and concurrent misses were not reviewed as part of the security boundary. Fix: inspect revocation window and single-flight behavior.
- Symptom: a new regression test looks convincing but still misses a platform-specific bug. Likely cause: only one path was tested, or the fix was never mentally reverted. Fix: check Facebook/Instagram parity and ensure the test fails when the fix is removed.
- Symptom: frontend rollback logic looks fine in happy path. Likely cause: pre-write and post-write failures share one catch path. Fix: check rollback assumptions around each async boundary.
- Symptom: Set-based counter reconciliation looks correct in one mutation. Likely cause: append/pagination paths never seed or reconcile the Set. Fix: inspect `set*List` and `add*List` together.
- Symptom: tests or syntax checks give false confidence. Likely cause: they do not exercise semantic regressions, or the sandbox prevented deeper runs. Fix: label validation strength honestly.

## Verification Checklist

- The review states the exact repos/worktrees inspected.
- The live `git status` / `git diff` was checked before trusting summaries.
- Prior review docs were used only to avoid duplicate findings.
- Findings are severity-ranked and include exact file:line citations.
- The review covers API write paths, websocket broadcast paths, and frontend merge/rollback logic when all three repos are in scope.
- Pagination/append paths and rollback cursor state were checked when the review involved frontend aggregate counters.
- Ported-code claims are based on semantics, not visual similarity.
- Validation limits are explicit when tests could not run or only shallow checks were possible.
- The close includes a one-line deploy or merge verdict.
