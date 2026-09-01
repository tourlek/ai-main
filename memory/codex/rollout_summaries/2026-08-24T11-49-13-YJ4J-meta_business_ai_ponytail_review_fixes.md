thread_id: 01a0339a-6b7c-7ba1-9247-3f8cb0212b69
updated_at: 2026-08-24T12:08:53+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T18-49-13-01a0339a-6b7c-7ba1-9247-3f8cb0212b69.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI cross-repo review fixes completed in working trees, pending staging/UAT

Rollout context: The user asked in Thai to apply the attached review of `origin/tk-sprint-2616/feature/oho-1802-meta-biz-ai` across `oho-api`, `oho-webhook`, and `oho-web-app`, explicitly invoking Ponytail/minimal-diff review. Existing dirty worktrees were preserved; no commit or push was made.

## Task 1: Apply review fixes across the three Meta Business AI repositories

Outcome: partial

Preference signals:
- The user asked “แก้ตามนี้ได้ไหม ponytail มาดู และ matcock ด้วย” -> use aggressive scope reduction, root-cause fixes, and avoid speculative abstractions or broad refactors.
- Existing tracked changes and untracked files were preserved; the agent explicitly avoided reset/revert/commit/push -> future work on this feature should protect dirty worktrees and report exact working-tree state.
- The final response was in Thai and separated focused validation from staging/UAT -> similar work should provide evidence-based Thai reporting and avoid merge/production-ready claims without live verification.

Key steps:
- Pinned the three repos and confirmed the web branch inherited legacy commit `64eb8249`, a 1,231-line Meta UI/state-machine implementation explicitly forbidden by the current plan.
- Removed the legacy web implementation, including old takeover/return endpoints, Firebase flag, room state model, composer lock/state machine, and utility/test files. Retained only the planned W1/W2 behavior: sender identity and open-room realtime refresh.
- Updated web sender classification so `ai_generated === true` or `@meta-ai` is rendered as sender type `bot` with display name `Meta AI`; normal `@inbox` messages remain unchanged.
- Changed `chat/request created` handling to fetch the currently open contact through `handleSmartchatRealtimeUpdate` with `DEFAULT_UPDATE_FIELDS` and `is_fetch_contact:true`, while retaining badge refresh for closed rooms.
- Updated API ownership recovery: when send already produced a positive ownership error, pass `ownershipConfirmed:true` and skip the passive `thread_owner` read before takeover. Normal assign/bulk paths retain defensive owner reads.
- Fixed `facebook_meta_business_ai_observed_at` to advance only for a newer valid observation timestamp rather than behaving as first-observed-only.
- Added structured webhook logging for unmatched pass-control events: `event: 'meta_business_ai_handoff_unmatched'`.
- Updated active docs to distinguish historical/unreproducible `928891643393937` from current `622851382610562` return-to-AI target.

Validation:
- Web focused tests: `117/117`; `Conversation.spec.js`: `14/14`.
- API Meta utility suite: `47/47`; ownership retry suite: `6/6`.
- Webhook Meta suite: `18/18`.
- API build compiled 1,566 files; webhook TypeScript build passed.
- `git diff --check` passed after removing accidental blank lines at EOF.
- Active-code audit found no legacy endpoint/flag/state-machine footprint in the three repos (only docs references remain).

Failures and how to do differently:
- Initial restoration of `Conversation.vue` truncated the file because a large tool output was read in one chunk; this was detected before tests and repaired by restoring the parent file in bounded line ranges. For large files, use chunked reads/writes from the start.
- Running Jest with an incorrectly placed ignore option expanded into full suites and exposed baseline failures (`MaxPanel`, Playwright, `Utils.isRegExp`). Use `--runTestsByPath` for focused tests and distinguish baseline/environment failures from feature assertions.
- API tests required a temporary Node 26 `SlowBuffer` compatibility shim because an old dependency accessed `SlowBuffer`; the shim was deleted afterward. Do not treat this as a repository fix.
- Jest still reported duplicate manual mocks from existing `.claude` worktrees, but the targeted source suites themselves passed. Do not delete those user worktrees merely to silence the warning.

Reusable knowledge:
- Current web-app contract is existing assign/send/close behavior; do not reintroduce `/meta-business-ai/takeover` or `/return-to-ai`, composer locks, Remote Config flags, or room-level Meta state machines.
- `message.ai_generated === true` is author identity only; it must be checked before `@inbox` fallback. It is not activation or delivery authority.
- `thread_owner` reads are unsafe as the recovery-path prerequisite; a real send ownership error is stronger positive evidence and should permit takeover directly in that path.
- `622851382610562` is the current return-to-AI target only. Historical `928891643393937` must not be hardcoded or used as an ownership oracle.

References:
- `docs/meta-business-ai/plan-oho-web-app-2026-08-24.md`
- Legacy commit: `64eb8249` (`feat: show Meta Business AI handoff and room control UI in Smartchat`)
- Web files: `plugins/smart-chat-helper.js`, `store/modules/websocket.js`, `components/Smartchat/Conversation.vue`
- API files: `src/utils/meta-business-ai.js`, `src/services/member-send-message/member-send-message.class.js`, `src/services/contact/upsert/upsert.hooks.js`
- Webhook file: `src/controllers/facebook/handler.ts`
- Exact focused command: `npm test -- --runInBand --runTestsByPath test/plugins/smart-chat-helper.spec.js test/store/modules/websocket.spec.js`
- Final status: changes remain uncommitted/unpushed; staging replay, live ownership verification, and full UAT were not run.
