thread_id: 019f92b8-19b7-75b3-bdd9-8d9231dfb910
updated_at: 2026-07-24T06:05:35+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-02-46-019f92b8-19b7-75b3-bdd9-8d9231dfb910.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: master

# Partial read-only review of realtime chat badge fix

Rollout context: The user requested an adversarial, evidence-grounded review of an uncommitted two-file diff in `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge`, with no edits and a strict six-point output contract. The rollout read the diff and substantial portions of `smartchat.js`, `websocket.js`, `constants/contact.js`, and `utils/optimistic-flag-count-tracker.js`, but ended before producing the requested final review.

## Task 1: Review realtime unread/unresponded badge fix

Outcome: partial

Preference signals:

- The user explicitly required: “Read the actual files, do not guess” and grounded every claim in file:line evidence -> future reviews should inspect live files and cite exact lines rather than infer from the bug description.
- The user specified a “read-only critical review” and prohibited modifications, commits, and checkout -> similar reviews should remain strictly non-mutating.
- The user required a compact verdict/issues/checked-no-issue format with no generic summary -> preserve that structure in future review responses.

Key steps:

- `git diff` showed exactly two changed files and 66 inserted lines: `store/modules/smartchat.js` and `store/modules/websocket.js`.
- The live worktree did not match the requested branch: it was on `tk-sprint-2615/develop`, with `HEAD` equal to `origin/master` at `619b6182`; this scope mismatch should be disclosed before relying on conclusions.
- The new helper at `smartchat.js:719-760` gates each badge independently, maps `contact_id` to `_id`, injects flags, and dispatches `handleSmartchatRealtimeUpdate` with `DEFAULT_UPDATE_FIELDS` and `is_fetch_contact: !in_list`.
- Four requested socket handlers dispatch the helper after preserving existing notification actions at `websocket.js:255-313`.
- `DEFAULT_UPDATE_FIELDS` includes `_id`, `is_unresponded`, and `is_read_by_me` at `constants/contact.js:3-28`.
- The aggregate-count path uses `resolveOptimisticFlagTransition` at `smartchat.js:826-873`, backed by the Set tracker in `utils/optimistic-flag-count-tracker.js:25-40`; authoritative list replacement and pagination reconcile the Sets at `smartchat.js:70-147`.

Failures and how to do differently:

- No final verdict or issue list was produced, so correctness of all six requested points remained unverified. Future runs must finish the trace and explicitly distinguish confirmed defects from unverified concerns.
- The requested branch was not checked out. Before review, verify branch and base, and if the path is on another branch, either stop or clearly report that the review is of the live diff rather than the named branch.
- A potentially important existing edge case was visible at `smartchat.js:175-181`: `resetContactList` replaces `contact_list` without `unread_count` and `unresponded_count`, despite the initial state defining them at `smartchat.js:22-29`. This should be investigated for Vue 2 reactivity/count behavior before approving, but the rollout did not complete that analysis.

Reusable knowledge:

- `handleSmartchatRealtimeUpdate` identifies rows by `event_message._id` at `smartchat.js:779-783`; the new helper correctly constructs `_id: contact_id` at `smartchat.js:744-747` before dispatch.
- Badge updates are filtered through `_.pick(event_message, options.update_fields)` at `smartchat.js:792`; the explicit `DEFAULT_UPDATE_FIELDS` option is necessary for the injected fields to survive.
- Count transitions are intended to be idempotent through Set membership: `resolveOptimisticFlagTransition` uses `set.has(id)`, adds on increment, and deletes on decrement (`optimistic-flag-count-tracker.js:32-39`).
- The four new dispatches preserve the pre-existing notification dispatches rather than replacing them (`websocket.js:264-267`, `280-282`, `294-296`, `308-311`).

References:

- [1] Diff command: `git -C /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge diff` -> two files, 66 insertions.
- [2] `store/modules/smartchat.js:719-760` -> feature gating, open-room check, contact ID mapping, explicit update fields, fetch decision.
- [3] `store/modules/smartchat.js:762-873` -> row lookup, field picking, count transition logic, local-read timestamp guard.
- [4] `store/modules/smartchat.js:175-181` -> reset shape omits aggregate count fields.
- [5] `store/modules/websocket.js:255-313` -> four socket call sites and preserved notification behavior.
- [6] `constants/contact.js:3-28` -> `DEFAULT_UPDATE_FIELDS` contains `is_unresponded` and `is_read_by_me`.
- [7] `utils/optimistic-flag-count-tracker.js:25-40` -> Set-based transition algorithm; `:42-76` -> reconciliation rationale and implementation.
