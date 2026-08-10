thread_id: 019fcc18-966f-75c1-8bb6-3c8b98c927f4
updated_at: 2026-08-05T03:16:07+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T16-26-31-019fcc18-966f-75c1-8bb6-3c8b98c927f4.jsonl
cwd: /Users/tualek/ohochat

# Narrow Smartchat badge fix for the four QA cases was implemented and validated

Rollout context: Work occurred in `/Users/tualek/ohochat`, primarily `/Users/tualek/ohochat/oho-api`, with related verification in `oho-web-app`. The user wanted the existing plan implemented, but explicitly limited scope to the four QA cases and deferred broader refactor/optimization.

## Task 1: Review and narrow implementation scope

Outcome: success

Preference signals:
- The user said: “ตอนนี้อยากให้ครอบคลุมแค่เคสที่ QA ตีแก้มา 4 case” and approved proceeding with the plan -> similar fixes should be narrowly scoped to the reported QA scenarios, avoiding unrelated refactors or optimization.
- The user asked to “แก้ไขได้เลย” after the scope recommendation -> edits were authorized, unlike earlier review-only phases.

Key steps:
- Traced current API/frontend contracts and found the prior implementation expanded unread realtime behavior into group chat.
- Used TDD: first added failing tests that exposed group-chat scope expansion, then restricted unread-specific behavior to 1:1 contact/Smartchat.
- Preserved group-chat behavior as unresponded-only; contact flow retains per-member unread and unresponded badge updates.
- Added direct feature-flag matrix coverage for both flags enabled, both disabled, unread-only, and unresponded-only.
- Added acceptance-oriented tests named for QA Cases 1–4.

Reusable knowledge:
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js` now distinguishes group and contact contracts. Group uses the existing unresponded-only payload; contact uses `includeUnreadState: true` for per-member `is_read_by_me` emission.
- `buildAttentionEventUnreadPayload` is shared with the customer-message helper, but independently gates `unread_by` and `is_unresponded`; when both flags are off it returns `{}` and skips eligible-member lookup.
- Contact realtime emission partitions recipients into unread/read groups and emits at most two socket broadcasts. Group remains a single shared broadcast.

Failures and how to do differently:
- The first test attempt failed because group tests still expected unread fields and the new helper test auto-mocked too broadly, loading the model index. Fix: restore group projections/expectations and use explicit boundary-factory mocks for Firebase and eligible-member modules.
- Initial review identified that flag-off behavior still performs a contact `findOne()` in the after-hook. This remains a performance residual intentionally deferred to the planned optimization work; badge writes, eligible-member lookup, and badge socket emission are disabled.
- Browser E2E was not run because the local web/API stack was not started; do not describe this as full browser-level proof.

References:
- `/Users/tualek/ohochat/oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:220-400`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.ts:7-45`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.spec.ts`
- `/Users/tualek/ohochat/oho-api/src/services/contact/bot-assign/request/request-attention-badge.spec.ts:83-128`
- API focused command: `node ./node_modules/jest/bin/jest.js --runTestsByPath src/services/chat-session/hooks/emit-chat-session-event.spec.ts src/services/contact/bot-assign/request/request-attention-badge.spec.ts src/utils/build-customer-message-unread-payload.spec.ts src/utils/channel-eligible-members.spec.ts --runInBand --forceExit --detectOpenHandles`
- API focused result: `4 suites passed, 46 tests passed`
- Mongo integration result: `2 suites passed, 28 tests passed`
- Web focused result: `5 suites passed, 135 tests passed`
- Prettier check and `git diff --check` passed. Changes were not committed or pushed.
