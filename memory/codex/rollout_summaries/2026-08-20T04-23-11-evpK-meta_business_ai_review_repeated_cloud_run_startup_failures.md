thread_id: 01a01d68-a198-7300-b70e-054c80cb3a68
updated_at: 2026-08-20T11:51:59+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T11-23-11-01a01d68-a198-7300-b70e-054c80cb3a68.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI branch review exposed repeated deploy-startup failures

Rollout context: In `/Users/tualek/ohochat`, the user asked whether `origin/tk-sprint-2616/feature/oho-1802-meta-biz-ai` was ready for staging. Review covered `oho-api` and `oho-webhook`, preserving unrelated dirty worktree changes. The branch was not staging-ready during this rollout because Cloud Run repeatedly crashed during startup.

## Task 1: Review Meta Business AI branch for staging readiness

Outcome: partial

Preference signals:
- The user asked about staging readiness, so future reviews should verify the exact remote branch and distinguish local focused validation from deploy/canary readiness.
- The user repeatedly requested detailed, evidence-based explanations in Thai and challenged overclaims; report concrete files, commits, logs, severity, and limits rather than saying “ready” from build/tests alone.
- Preserve unrelated worktree files such as `.codegraph/`; commit/push only explicitly scoped fixes.

Key steps:
- Pinned remote commits `oho-api a0157308` and `oho-webhook 3ac7ca22`; found local modifications and did not mix them into the review.
- Reviewed large Facebook-only Meta Business AI changes: channel activation, webhook canonicalization, authority guards, Redis dedup, Stream identities, whitelist handling, and onboarding subscriptions.
- Confirmed the feature branch adds `messaging_handovers` and `standby` subscriptions, explicit `meta_business_ai_enabled`, strict `message.ai_generated === true` labeling, and tenant-scoped `${businessId}@meta-ai` fallback behavior.
- GitLab MR lookup returned `[]`; no MR/spec confirmation was available.

Failures and how to do differently:
- Focused tests/builds and `git diff --check` are insufficient for staging readiness. Required gates include real payload replay, terminal Mongo/Redis/Stream verification, startup smoke test, and canary observability.
- The branch contained broad changes and missing runtime validation; do not call it deploy-ready until the remaining B1–B5 gates are addressed.

Reusable knowledge:
- `standby` indicates another app may own delivery but does not prove Meta Business AI; `ai_generated` is author identity, not ownership or activation.
- The approved Facebook flow uses `channel.meta_business_ai_enabled` as activation state, persists standby customer messages before suppressing OHO automation, and keeps authority separate from author identity.
- Feature-flag claims must be workspace-wide: backend Remote Config removal does not mean the web-app flag `rt_meta_business_ai_enabled` is gone.

References:
- `oho-api`: `a0157308c5efbd4121badbad949bb86f9b55b0ce`
- `oho-webhook`: `3ac7ca224c408a1fb1691576ea236eb6005b752c`
- `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`

## Task 2: Diagnose and fix repeated Cloud Run startup failures

Outcome: partial

Key steps:
- Pipeline `31240` failed because `end-case.hooks.js` referenced `prepareCloseCaseContactUpdateData` and `emitChatSessionStatusUpdatedEvent` after their imports were removed in Meta commit `39c42fb27`.
- Pipeline `31241` revealed the same missing imports in sibling `no-case.hooks.js`.
- Pipeline `31245` failed with Feathers `Error: 'formingChatStreamPayload' is not a valid hook type`; a named helper export was passed through `service.hooks(hooks)`.
- Pipeline `31246` failed with `Error: 'formingCreateDataPayload' is not a valid hook type`; `facebook.hooks.js` exported helpers while `facebook.service.js` passed the entire module to Feathers.
- Restored runtime dependencies and changed Facebook service registration to `service.hooks({ before, after, error })`.
- Restored `STREAM_CHAT_SOURCE`/`loggerSendMessageToStreamChat` in `bot-send-message.hooks.js` and `chatEngine` in `member-assign/self/self.hooks.js`; these were existing runtime dependencies accidentally removed while adding Meta hooks, not new Meta Stream behavior.
- Committed and pushed three-file runtime fix as `b803ae00b fix: restore hook runtime dependencies` to `tk-sprint-2616/feature/oho-1802-meta-biz-ai`.

Failures and how to do differently:
- The first fix repaired only `end-case`, causing the next sibling failure to appear. Audit all changed files and call sites before redeploying.
- CI only built the image with SWC; it did not lint, run tests, register services, or perform a startup smoke test, so compile success did not catch runtime crashes.
- A static hook guard initially gave a false pass because its resolver mishandled `.hooks`; validate the guard itself and inspect every `service.hooks(hooks)` call.
- Focused tests were environment/fixture-limited: Facebook and self-assign suites passed, but bot-send had 6 quick-reply expectation failures; broad lint found pre-existing unrelated errors as well.

Reusable knowledge:
- Feathers services that pass a whole hooks module must expose only `before`, `after`, `error`, or explicitly destructure those exports.
- Adding a Meta hook import must preserve all existing imports and runtime call sites; replacing an import block is unsafe.
- Build validation should be followed by compiled module/service registration or container startup smoke testing before claiming deploy readiness.

References:
- `39c42fb27 feat: add Meta Business AI takeover, return-to-ai, and authority bot safety guard`
- Pipelines/jobs: `31240/#95411`, `31241/#95416`, `31245/#95426`, `31246/#95431`
- Exact errors: `ReferenceError: prepareCloseCaseContactUpdateData is not defined`; `Error: 'formingChatStreamPayload' is not a valid hook type`; `Error: 'formingCreateDataPayload' is not a valid hook type`
- Files fixed: `src/services/contact/close-chat/end-case/end-case.hooks.js`, `src/services/contact/close-chat/no-case/no-case.hooks.js`, `src/services/channel/facebook/facebook.service.js`, `src/services/bot-send-message/bot-send-message.hooks.js`, `src/services/contact/member-assign/self/self.hooks.js`

## Task 3: Clarify pushed test/deploy helper files

Outcome: uncertain

Preference signals:
- When the user said “ไม่เอาไฟล์ selft ที่ไว้เทส deploy push ไป”, they wanted deploy/test helper artifacts excluded from the feature push. Future pushes should explicitly list included and excluded paths and confirm whether “self” means the runtime `self.hooks.js` or only test helper files.

Reusable knowledge:
- `package.json`, `scripts/check-feathers-hooks-shape.js`, and `.codegraph/` were not included in the `b803ae00b` commit. However, `self.hooks.js` was included because its `chatEngine` import was a runtime fix, not a deploy-test file; the user’s final intent was not confirmed.

References:
- Pushed commit: `b803ae00b`
- Excluded artifacts: `package.json`, `scripts/check-feathers-hooks-shape.js`, `.codegraph/`
