thread_id: 019fb663-2d39-79b3-9364-4845f05664c6
updated_at: 2026-07-31T04:25:57+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T11-16-20-019fb663-2d39-79b3-9364-4845f05664c6.jsonl
cwd: /Users/tualek/ohochat

# Cross-repo review of oho-web-app !872 and oho-api !1291 found web blockers

Rollout context: Read-only review in `/Users/tualek/ohochat`, verifying exact GitLab MR heads, diffs, repo rules, and cross-repo realtime unread/unresponded badge behavior. No files were edited.

## Task 1: Review oho-web-app !872 realtime badge update

Outcome: fail

Preference signals:
- The user asked to review whether the two MRs had anything blocking merge; the review stayed read-only and reported concrete `file:line` findings rather than making changes.

Key findings:
- **High:** fallback/API fetch updates the row only after aggregate unread/unresponded transitions have already been calculated. `store/modules/smartchat.js:829-875` mutates counts before fetch, while `:931-943` merges authoritative data without reconciling counts. Off-list rooms and timestamp-less events can leave quick-filter red-dot totals stale.
- **High:** equal-timestamp ordering race. `chat-session/status updated` can update `last_contact_date` while carrying `is_unresponded` but no `is_read_by_me`; a subsequent message event with the same timestamp is dropped by the `<=` guard at `smartchat.js:737-743` before unread injection at `:745-752`, allowing unread state/count to be missed.
- **Medium:** concurrent events can all observe a missing room, fetch in parallel, then blindly `push`/`unshift` via mutations at `smartchat.js:128-159`, creating duplicate rows and pagination/count drift. API emits one message event per bubble (`contact-send-message.hooks.js:386-422`).
- The MR description's fallback-fetch/deploy-order contract is therefore not fully satisfied.

Validation: exact MR head `5fc4ef224814aec240b55891ef36664e0abce5cd`; GitLab reported mergeable/no conflicts, but no pipeline or approval. `git diff --check` passed; functional tests were not run because the worktree was not checked out at the MR head.

## Task 2: Review oho-api !1291 timestamp payload

Outcome: success

Key steps:
- Verified exact head `bbe0ac735634caf91cbe43c91eb18c5578c1d185` and one-file diff.
- Confirmed `oho_created_at` comes from the Stream message payload and is the same timestamp used to update `last_contact_date` under the `$lte` guard (`contact-send-message.hooks.js:164,230-236,296,402-415`).
- Confirmed the socket event switch covers customer message events and the web consumer dispatches all relevant handlers.

Findings:
- No code blocker found for !1291 by itself.
- Low-severity scope concern: the shared payload object also passes `oho_created_at` into push notifications (`:402-443`), although the stated requirement only concerns socket payloads.

Validation: GitLab reported mergeable/no conflicts, but no pipeline or approval; `git diff --check` passed and functional tests were not run.

Overall verdict: !1291 is mergeable from code review; !872 should not merge/deploy as the pair until fallback-count reconciliation, equal-timestamp handling, and concurrent insertion/deduplication are fixed.
