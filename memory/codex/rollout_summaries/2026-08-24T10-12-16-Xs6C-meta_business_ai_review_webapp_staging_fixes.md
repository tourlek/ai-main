thread_id: 01a03341-aaf8-71b0-b02d-3f7bdc25fcc2
updated_at: 2026-08-24T10:28:24+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T17-12-16-01a03341-aaf8-71b0-b02d-3f7bdc25fcc2.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI review follow-up and web-app staging fixes

Rollout context: Work occurred under `/Users/tualek/ohochat`, primarily across `oho-api`, `oho-webhook`, and `oho-web-app`. The user requested Ponytail-style minimal scope, evidence-first review, no unrelated edits, and preservation of dirty/untracked work.

## Task 1: Review Meta Business AI staging readiness

Outcome: partial

Preference signals:
- The user asked to use Ponytail review and explicitly wanted only blocker/root-cause issues, without editing files initially -> future reviews should separate required code changes from staging/UAT verification and avoid scope expansion.
- The user expects Thai, evidence-backed readiness verdicts that distinguish local tests/builds from live staging proof -> do not call a branch staging/UAT-ready based only on tests or HTTP success.

Key steps:
- Compared the review’s referenced commits (`oho-api 0075eedb`, `oho-webhook e3b35076`) with current heads (`oho-api eb067226`, `oho-webhook b917fb9`).
- Inspected Meta ownership retry, fail-closed bot guards, standby ingress suppression, authority persistence, onboarding/reconnect status sync, and bot/schedule hook registration.
- Identified D5 as a real residual risk: stale `meta_business_ai_enabled=true` can over-block OHO after Meta AI is disabled; existing reconnect/refresh flow is the minimal mitigation.
- Kept the discovery ownership log until live T9.1 confirms the actual Meta error payload.

Failures and how to do differently:
- The original approval referenced older SHAs and therefore could not be reused unchanged. Re-review current heads before promotion.
- Full API verification was not established: focused webhook tests passed, but broader API tests were affected by Node/Jest/worktree compatibility. Treat the result as conditional staging approval, not production/UAT approval.
- Required live proof remains T9.1 ownership-error replay, T9.2 standby persistence/automation isolation, T9.3 matched latency comparison, plus D5 disable/reconnect verification.

Reusable knowledge:
- `guardFacebookBotSend` intentionally fail-closes on the channel activation flag without a DB read; this prevents bot collision but can over-block if the flag is stale.
- Standby is evidence another app may own delivery, not proof of Meta Business AI; `ai_generated` identifies message author, not ownership/activation.
- Staging verification must correlate webhook receipt -> contact/upsert -> Mongo/Stream persistence -> automation suppression or member delivery. HTTP 200 and focused tests are insufficient.

References:
- `/Users/tualek/ohochat/oho-api/src/utils/meta-business-ai.js:282-292` — fail-closed bot guard.
- `/Users/tualek/ohochat/oho-api/src/services/member-send-message/member-send-message.class.js:153-185` — optimistic Facebook send and ownership retry/discovery logging.
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts:1370-1398` — persistence before standby/authority automation suppression.
- Live checks still required: T9.1, T9.2, T9.3; D5 disable -> reconnect/refresh -> verify flag false.

## Task 2: Correct Meta sender label and preserve `@inbox` behavior

Outcome: success

Preference signals:
- The user corrected that removing the `@inbox` condition would lose the identifier and requested the visible Meta label `Meta Business Agent` -> preserve internal IDs for classification/layout and change only display labels unless explicitly asked otherwise.

Key steps:
- Restored direct `@inbox` detection for corner bubble alignment/color in `components/Smartchat/Conversation.vue`.
- Changed Meta message display name in `plugins/smart-chat-helper.js` to `Meta Business Agent`.
- Added/updated sender tests.

Reusable knowledge:
- `@inbox` is an internal Stream sender ID used for agent-inbox classification and right-side styling; it must not be replaced by a display-name change.
- Meta sender detection supports `ai_generated === true` and `@meta-ai` suffix fallback.

References:
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:2590-2600`.
- `/Users/tualek/ohochat/oho-web-app/plugins/smart-chat-helper.js:51-54,104`.
- Targeted test initially passed `108/108`.

## Task 3: Address web-app staging review findings P1/P2/P3

Outcome: success

Preference signals:
- The user identified P1 global fetch fan-out as a staging blocker, P2 as an independent fallback-test gap, and P3 as duplicated classification -> future patches should preserve existing event paths, minimize fetches, make helpers the source of truth, and test fallback signals independently.
- The user required no staging/commit and no touching untracked files -> preserve dirty work and report exact validation boundaries.

Key steps:
- P1: restored `refreshChatRoomBadgeRealtime` for `chat/request created`; authoritative contact fetch now occurs only when both badge flags are disabled and the event’s `contact_id` matches the currently open room.
- P3: changed `Conversation.vue` to use `sender_type === "agent"` rather than recomputing role-based agent classification; retained direct `@inbox` styling.
- P2: changed the Meta suffix test so `@meta-ai` is tested without `ai_generated`, proving fallback detection independently.
- Added a closed-room test proving no authoritative fetch occurs outside the active room.

Validation:
- Focused tests passed: `117/117` across `test/store/modules/websocket.spec.js` and `test/plugins/smart-chat-helper.spec.js`.
- `git diff --check` passed.
- Lint was not run because local ESLint was unavailable.
- Jest emitted duplicate manual-mock warnings because `.claude-worktrees` is inside the repository, but the targeted test command passed.
- No files were staged or committed; untracked files were left untouched.

References:
- `/Users/tualek/ohochat/oho-web-app/store/modules/websocket.js:298-330`.
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:2588-2608`.
- `/Users/tualek/ohochat/oho-web-app/test/plugins/smart-chat-helper.spec.js:28-45`.
- `/Users/tualek/ohochat/oho-web-app/test/store/modules/websocket.spec.js:116-202`.
- Validation command: `npm test -- --runInBand --runTestsByPath test/store/modules/websocket.spec.js test/plugins/smart-chat-helper.spec.js`.
