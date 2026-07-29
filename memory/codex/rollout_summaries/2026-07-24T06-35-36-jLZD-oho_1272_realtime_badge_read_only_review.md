thread_id: 019f92d6-2878-7423-a00f-1e523deebd71
updated_at: 2026-07-24T06:40:00+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-35-36-019f92d6-2878-7423-a00f-1e523deebd71.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: master

# Read-only adversarial review of OHO-1272 realtime badge fix

Rollout context: The user requested a narrowly scoped Vue 2/Vuex review: read only the diff, the specified `handleSmartchatRealtimeUpdate` range, and `constants/contact.js`; do not modify files or explore broadly. They required six yes/no verdicts with file:line evidence and a concise final verdict.

## Task 1: Review realtime unread/unresponded badge patch

Outcome: success

Preference signals:

- The user explicitly required “do not modify any files — review only” and asked for real defects rather than style issues -> future reviews should remain strictly read-only and adversarial.
- The user requested yes/no answers, exact file:line evidence, and a `VERDICT: ...` line under ~400 words -> preserve this compact, evidence-first format.

Key findings:

- Repeated existing-room events do not double-count because transition logic plus `optimisticallyCountedUnresponded`/`optimisticallyCountedUnread` Set state only increments on state transitions (`smartchat.js:826-873`). However, a new-room fetch can overwrite injected badge fields after aggregate counters/Set state are updated (`smartchat.js:927-940`), causing row/count desynchronization.
- With both flags off, the helper returns before nested dispatch/fetch/badge mutation (`smartchat.js:723-739`), but the websocket handlers still dispatch the helper at four call sites (`websocket.js:267,282,296,311`), so behavior is not literally byte-for-byte identical. Partial flag gating is correct (`smartchat.js:724-735`).
- `_.pick(event_message, DEFAULT_UPDATE_FIELDS)` does not allow the documented raw payload fields to clobber existing rows; only selected fields and injected badge values survive (`constants/contact.js:3-28`, `smartchat.js:744-757,792`).
- Mapping `contact_id` to `_id` is compatible with list matching, API fetch, route/current-contact handling, and removal (`smartchat.js:779-783,930-933,947-963,1018-1023`).
- Missing `updated_at` does not create a material badge-ordering defect for these deterministic badge assertions; exact helper skip semantics were not verifiable within the permitted sources.
- New rooms under an active filter trigger `triggerFilteredListRefetch` rather than direct insertion (`smartchat.js:983-1007`), while nonmatching rooms are omitted correctly.

Final verdict: `VERDICT: 2 issues` — reapply injected badge fields after fetched contact data is merged; optionally guard websocket dispatches when both flags are disabled.

References:

- Diff: `/private/tmp/claude-501/-Users-tualek-ohochat/e09208f3-facf-4303-8b26-c1c18904dc1b/scratchpad/oho1272.diff`
- Reviewed worktree: `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge`
