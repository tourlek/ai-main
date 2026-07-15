thread_id: 019f6135-9fb1-7b72-b968-52241fd501a2
updated_at: 2026-07-14T15:35:19+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T22-18-52-019f6135-9fb1-7b72-b968-52241fd501a2.jsonl
cwd: /Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes
git_branch: uat/v2.25.0

# Cross-repo review of MR !1285 found a websocket blocker plus several frontend/backend correctness and audience issues.

Rollout context: The user asked for a thorough, findings-first review of the unread/unresponded badge feature across three repos (`oho-api` worktree `mr-1285-fixes`, `oho-websocket`, and `oho-web-app`), while preserving prior-review context in `plan.md`, `mr-1285-consolidated-review.md`, and `review-codex-gpt56sol.md`. The review had to respect the established design rule that SET writes are flag-gated, CLEAR writes are unconditional, and realtime broadcasts are flag-gated.

## Task 1: Backend review in `oho-api`

Outcome: partial

Preference signals:
- The user explicitly said to read prior review docs first and “do not re-flag findings already documented as fixed there” -> future reviews should rebase against prior findings and avoid duplicate reporting.
- The user asked for “structured findings report, ranked by severity” and “every finding must cite an exact file:line” -> future similar reviews should stay line-precise and severity-ranked.
- The user asked “do not modify any files” -> review flows should remain read-only.

Key steps:
- Re-read `plan.md`, consolidated review notes, and the code-review skill before auditing.
- Traced write sites through `contact-send-message`, `member-send-message`, bulk send, close-case, bot reply, and the shared `buildCustomerMessageUnreadPayload` / `buildClearUnreadUnrespondedPayload` helpers.
- Verified the four newly fixed clear/broadcast call sites (`notify`, `inform-message`, `broadcast`, `bulk`) all route into `emitContactUnrespondedStatusUpdatedEvent()` / `emitEligibilityScopedUnrespondedUpdate()`.

Failures and how to do differently:
- The contact-side scoped broadcast emitter is correct for the unresponded flag, but it scopes to channel-eligible members only; it does not account for sale-visibility audience restrictions used by contact search. That should be treated as an audience mismatch rather than a flag-gate bug.
- Bulk-send still needs success-aware behavior review because it can clear state even when platform delivery fails.

Reusable knowledge:
- `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for both `unread_by` and `is_unresponded:true`.
- `buildClearUnreadUnrespondedPayload()` intentionally builds unconditional CLEAR payloads; that behavior is the intended fix for flag-toggle stuck-state bugs.
- `emitEligibilityScopedUnrespondedUpdate()` is the actual gate for the four new contact clear broadcasts; notify/inform/broadcast/bulk all reach it.

References:
- `src/services/contact-send-message/contact-send-message.hooks.js:227-259`
- `src/services/chat-session/group/contact-user/send-message/send-message.class.js:40-50`
- `src/services/member-send-message/member-send-message.hooks.js:690-728`
- `src/services/member-send-message/bulk/bulk.class.js:218-285`
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-372`

## Task 2: `oho-websocket` review

Outcome: fail

Preference signals:
- The user wanted the review to “cover all 3 repos” and to “separate Part 1 (general review) findings from Part 2 (flag-gate audit findings)” -> future similar reviews should keep repo boundaries and audit tables explicit.
- The user called out a design rule for websocket broadcasts: realtime broadcasts of these fields must be flag-gated, not the writes.

Key steps:
- Traced the Stream webhook handler, the shared emit helpers, and the message.read path.
- Verified `git diff --check` and `node --check` on the websocket entry points.
- Compared the websocket code against the established design rule and backend emitter behavior.

Failures and how to do differently:
- The websocket `message.read` path currently gates the `$pull unread_by` clear on the unread feature flag, which conflicts with the user’s established rule that CLEAR writes are unconditional.
- The same path lacks the timestamp ordering guard used in the backend, so a delayed read webhook can clear newer unread state.
- Group customer-message broadcasts are sent to the whole business member room rather than a channel-eligibility-scoped audience, so they can overreach within a business.

Reusable knowledge:
- `src/webhook/stream.js` has a `message.read` branch that directly `$pull`s from `unread_by`; this is the websocket-side CLEAR site that should be scrutinized for unconditional behavior.
- The Stream webhook handler’s customer-message broadcasts are split into single-chat and group-chat paths, with group broadcasts using the broader `businessChannel(businessId, 'member')` audience.

References:
- `src/webhook/stream.js:149-160`
- `src/handlers/stream-webhook.handler.js:361-449`
- `src/webhook/stream.spec.js:93-108`

## Task 3: `oho-web-app` review

Outcome: partial

Preference signals:
- The user wanted a careful senior review before production rollout, not implementation suggestions -> future reviews should remain judgmental and rollout-oriented.
- The user explicitly asked for “complete flag/write/broadcast inventory” behavior in the audit -> frontend verification should include how UI state mutates from socket events and local optimistic logic.

Key steps:
- Reviewed the client Remote Config plugin, store bootstrap, Smartchat and Groupchat socket handlers, and the optimistic counter tracker.
- Checked for duplicate or conflicting flag sources and for UI state mutations that depend on backend broadcast semantics.

Failures and how to do differently:
- The browser Remote Config plugin can overwrite the server-authenticated feature flags in store state; that creates a race between backend authority and client cache.
- The optimistic badge tracker for offscreen events can drift counts because it lacks a true per-contact baseline for unknown prior state.
- Groupchat badge updates and room filtering are not fully aligned with Smartchat behavior, which can leave stale rooms visible or mutate the wrong counter bucket.

Reusable knowledge:
- `store/index.js` bootstraps feature flags from the backend auth response, but `plugins/firebase-remote-config.js` later fetches client config and commits to the same state again.
- `store/modules/smartchat.js` and `store/modules/groupchat.js` both use the shared optimistic flag tracker; it is important to validate offscreen increment/decrement behavior, not just visible-room updates.
- Groupchat UI still depends heavily on local state and watcher-triggered refetches, so overlapping requests and stale socket events can cause visible drift.

References:
- `plugins/firebase-remote-config.js:8-52,81-85`
- `store/index.js:476-485`
- `store/modules/smartchat.js:692-749`
- `store/modules/groupchat.js:215-321`
- `pages/business/_biz_id/groupchat/index.vue:26-31,449-567`
- `utils/optimistic-flag-count-tracker.js:1-27`

## Cross-repo conclusion

Outcome: partial/fail overall

- Backend write gating is largely correct, and the four newly fixed contact clear broadcast call sites are wired properly.
- The websocket repo still has a blocker: `message.read` clear logic is incorrectly flag-gated and lacks the ordering guard.
- The frontend has several state-sync risks: client Remote Config can race the backend, optimistic count tracking can drift, and group chat badge/list behavior is not fully aligned with socket reality.
- Validation was limited by the sandbox: `git diff --check` and `node --check` passed, but targeted Jest could not run because the read-only environment blocked Jest’s haste-map temp-file writes and surfaced duplicate mock collisions.
