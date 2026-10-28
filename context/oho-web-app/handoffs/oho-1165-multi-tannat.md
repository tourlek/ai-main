# OHO-1165 Multi-Tannat QA handoff

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/context/oho-web-app/handoffs/oho-1165-multi-tannat.md

**Verdict: Blocked for QA handoff.** The source-to-surface map and test focus are ready, but the candidate has not passed focused tests or a real app/API smoke. Do not mark Ready for QA from code inspection or mocked tests alone.

- **Web candidate:** branch `Multi-tannat`, HEAD `743e354218e0250fcd4cfc77a5f33172afdcf85c`; worktree clean when inspected.
- **Work item:** OHO-1165, Stream Chat credential lifecycle (`846fe8df1`); current candidate includes the later recovery fix `be05a2a37`.
- **Changed contract:** Oho member login still chooses a `business_id` from the route/current-business cookie and calls `authentication-member/login` (`store/index.js:259-303, 498-503`). The change moves Stream SDK authentication from the old `streamToken` read in `Conversation.vue` to a `POST chat-credential` bundle (`api/endpoint.js:20`, `store/modules/smartchat.js:579-643`). This is a Stream Chat credential-flow change, not evidence that the Oho login page/API changed. The backend's business-to-Stream-account mapping is outside this repo and remains unverified.

## Source-to-surface map

| Changed path | Observable behavior to verify |
| --- | --- |
| `store/index.js:259-303, 498-503`; `components/SwitchBusiness.vue:202-216`; `components/AddBusinessCard.vue:326-338` | Initial entry, direct business URL, reload, and business switch authenticate the selected `business_id`; switch tears down the previous Stream client before navigating. |
| `api/endpoint.js:20`; `store/modules/smartchat.js:35-38, 579-643`; `utils/stream-chat-lifecycle.js:246-391, 486-530` | The selected member session fetches `chat-credential`; the returned key/token connect the expected Stream user, and refresh/recovery replaces the client without logging credential values. |
| `components/Smartchat/Conversation.vue:1401-1427, 1600-1728, 1752-1807` | On credential rotation, the active room is re-watched without clearing loaded messages, losing scroll position, or duplicating message/read events. Inspect `#smartchat_conversation` and `#conversation .message-container`. |
| `components/Smartchat/ErrorRoom.vue:1-24`; `components/Smartchat/Conversation.vue:1657-1672, 390-393` | Failed room initialization shows the chat-load error and its `รีเฟรช` action retries initialization. |

**Tenant-isolation checkpoint:** `Conversation.vue:1709-1724` has the client-side `business_id` comparison commented out. This does not by itself establish a defect, but UI state cannot prove tenant isolation; verify server/Stream authorization using synthetic rooms and a restricted non-admin member. Never use customer data for this probe.

## Required smoke matrix

1. Use two QA businesses whose approved mapping specifies distinct Stream accounts, plus a member authorized for the intended test flows. For each business, log in/open Smartchat, reload its direct business URL, and switch B1 → B2 → B1. Confirm member login uses the selected business and `chat-credential` yields that business's expected `account_id` and working Stream client. Record only redacted request evidence; never save token/key values.
2. Open a synthetic room in each business. Confirm the expected room/messages load, and that a room from B1 cannot be read or changed while authenticated in B2. Repeat the access check with a restricted non-admin member where permissions apply.
3. In a safe QA business, exercise one synthetic message/read flow, then allow token refresh or resume a tab after the refresh deadline. Confirm the same room remains usable, the message list/read state is not duplicated or lost, and switching business during a pending refresh cannot restore the old client.
4. Exercise invalid/expired credentials and a transient credential-endpoint failure. Confirm the error state is visible and retry behavior is bounded; inspect logs/evidence for credential redaction.

Existing unit suites cover lifecycle timing/auth recovery, store wiring, and conversation rotation (`test/utils/stream-chat-lifecycle.spec.js`, `test/store/modules/smartchat.spec.js`, `test/components/Smartchat/Conversation.spec.js`). They use mocks; `makeBundle` currently supplies one fixed `account_id`, so they do not prove real business-to-account routing or cross-tenant isolation.

## Verification and QA-E2E readiness

- Attempted: `npm test -- --runInBand test/utils/stream-chat-lifecycle.spec.js test/store/modules/smartchat.spec.js test/components/Smartchat/Conversation.spec.js`; Jest did not start (`sh: jest: command not found`).
- `test/QA-E2E/.env.uat` exists, but its contents were not read or used. Its presence does not establish that UAT runs this candidate HEAD; verify the deployed web/API revisions before execution.
- Root `node_modules` is absent and `playwright` is not on `PATH` (`node v24.14.0`, `npm 11.9.0`); no Playwright browser smoke ran.
- `tests/login.spec.ts` includes successful Oho login (`TC-LOGIN-016`); `tests/business.spec.ts` checks business list/navigation. Neither tests Stream credentials. No `chat-credential`, `account_id`, `credential_version`, `refresh_at`, or `streamToken` assertions appear under `test/QA-E2E`.
- `tests/smartchat.spec.ts` requires FB/LINE/Instagram, webhook, customer, message, media, and saved-reply values at import. It includes inbound webhook and outbound real-channel message/media/bulk-message flows. Do not run it against production or shared customer channels; use isolated synthetic UAT data only.
- **Still blocked:** no candidate QA app/API revision or authorized synthetic test data has been confirmed. The existing `.env.uat` was intentionally not inspected or used.
- **Next prep:** verify the candidate web/API deployment; identify two synthetic business-to-Stream mappings, an authorized QA session/restricted test member, and synthetic room IDs.
- From repo root, run `npm ci && npx playwright install chromium`. These setup commands have not been run.
- From `test/QA-E2E/`, run `npx playwright test tests/login.spec.ts --grep "TC-LOGIN-016"` and `npx playwright test tests/business.spec.ts --grep "TC-BIZ-003"` for Oho login/business navigation only. These do not verify Stream credentials.
- Add/run a read-only Smartchat credential smoke asserting the selected business, response `account_id`, and successful synthetic-room load. Never capture token/key values; do not run write cases outside isolated UAT.

A/B testing is not required for this credential-routing/authentication migration. Treat it as a functional, tenant-isolation, and recovery regression check; use an existing staged/canary rollout if rollout risk needs control, not an experiment comparing product behavior.
