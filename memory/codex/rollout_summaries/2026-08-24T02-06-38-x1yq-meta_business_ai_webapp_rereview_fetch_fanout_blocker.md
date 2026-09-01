thread_id: 01a03185-0c19-7bf2-9a56-536792abf3b2
updated_at: 2026-08-24T10:16:19+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T09-06-38-01a03185-0c19-7bf2-9a56-536792abf3b2.jsonl
cwd: /Users/tualek/ohochat

# Re-reviewed Meta Business AI web-app working diff and found one deploy-blocking scope/performance issue

Rollout context: Review-only work in `/Users/tualek/ohochat/oho-web-app`, branch `tk-sprint-2616/feature/oho-1802-meta-biz-ai`, HEAD `89b81b1f`. Tracked diff was limited to 5 files; unrelated untracked worktrees/files were preserved and excluded. No source edits, staging, commits, or pushes were made.

## Task 1: Review Meta Business AI web-app diff

Outcome: partial

Preference signals:

- The user asked “review อีกรอบ” after the previous plan/review, indicating they expect iterative, evidence-based re-review rather than treating an earlier conclusion as final.
- The review was kept review-only and scoped to Meta Business AI; unrelated dirty/untracked work was not touched.
- Findings were reported in Thai with concrete file/line references, severity, validation status, and exact remediation.

Key steps:

- Pinned branch/HEAD and identified the tracked diff: `Conversation.vue`, `plugins/smart-chat-helper.js`, `store/modules/websocket.js`, and two focused test files.
- Compared the implementation against `docs/meta-business-ai/plan-oho-web-app-2026-08-24.md` and repository `AGENTS.md`.
- Verified sender classification: `ai_generated === true` or `user.id` ending `@meta-ai` becomes sender type `bot`; sender name becomes `Meta AI`; `@inbox` fallback is checked after the AI signal; `Conversation.vue` reuses sender type for bubble positioning.
- Verified `chat/request created` now dispatches `handleSmartchatRealtimeUpdate` with `_id=contact_id`, `DEFAULT_UPDATE_FIELDS`, and `is_fetch_contact:true`.
- Traced the backend contract: request endpoint sets `status='request'`, while the socket payload contains only `contact_id`; the prior badge-refresh path returned early when both badge flags were disabled, which reproduced the need to switch rooms before the UI updated.
- Ran focused Jest tests successfully: 2 suites, 116 tests passed. Initial discovery accidentally included tests under `.claude-worktrees`; rerunning with `--runTestsByPath` isolated the real files and passed.
- `git diff --check` passed. ESLint could not be validated because the checkout has no local `eslint` binary; the attempted command ended with `No such file or directory`.

Failures and how to do differently:

- **P1 blocker:** The direct fetch in `chat/request created` runs for every connected client receiving the event, even when the room is not open and both unread/unresponded flags are disabled. This creates global API fan-out for ordinary request events and conflicts with `AGENTS.md`'s feature-flag boundary. Preserve the existing badge-refresh path and only perform the direct authoritative fetch when needed for the currently open room (or otherwise prove a narrower requirement).
- **P3 code smell:** `Conversation.vue` calls `getSenderType()` but separately recomputes agent classification. Use `sender_type === 'agent'` as the single source of truth.
- **P2 test gap:** The Meta AI test combines `ai_generated:true` with an `@meta-ai` ID, so it does not independently prove the suffix fallback. Add a case with `user.id` ending `@meta-ai` and no `ai_generated` field.
- Focused tests passing do not resolve the P1 fan-out concern or establish staging/UAT readiness.

Reusable knowledge:

- `chat/request created` is emitted after `/contact/:id/bot-assign/request`; backend sets `status='request'` but the socket notification payload only has `contact_id` and notification metadata.
- `refreshChatRoomBadgeRealtime` historically belonged to the unread/unresponded badge feature and returns immediately when both flags are off. It should not be bypassed with unconditional fetches for every client.
- `handleSmartchatRealtimeUpdate` already supports authoritative contact fetch/merge and current-room updates when given `_id`, `DEFAULT_UPDATE_FIELDS`, and `is_fetch_contact:true`.
- The intended frontend contract remains minimal: classify Meta AI authors and reuse existing assign/send/close flows; do not add a Meta-specific state machine, endpoint, Remote Config flag, or composer lock.
- Live staging/UAT remains unverified; local focused tests and HTTP success are not sufficient proof for Meta webhook behavior.

References:

- [1] Branch/HEAD: `tk-sprint-2616/feature/oho-1802-meta-biz-ai`, `89b81b1f3e4ddd4c4270d6048aabcfd811c30b10`.
- [2] Diff files: `components/Smartchat/Conversation.vue`, `plugins/smart-chat-helper.js`, `store/modules/websocket.js`, `test/plugins/smart-chat-helper.spec.js`, `test/store/modules/websocket.spec.js`.
- [3] Focused validation: `npm test -- --runInBand --silent --runTestsByPath /Users/tualek/ohochat/oho-web-app/test/plugins/smart-chat-helper.spec.js /Users/tualek/ohochat/oho-web-app/test/store/modules/websocket.spec.js` → `2 passed`, `116 passed`.
- [4] Review finding: `store/modules/websocket.js:308-317` unconditionally dispatches `handleSmartchatRealtimeUpdate` with `is_fetch_contact:true`; this is the P1 global fetch fan-out.
- [5] Review finding: `test/plugins/smart-chat-helper.spec.js:30-37` does not isolate the `@meta-ai` fallback signal.
