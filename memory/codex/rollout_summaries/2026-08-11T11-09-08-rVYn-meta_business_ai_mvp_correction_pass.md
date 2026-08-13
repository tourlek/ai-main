thread_id: 019ff083-0ff1-7601-a36c-8514dad1e62b
updated_at: 2026-08-11T13:57:23+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-09-08-019ff083-0ff1-7601-a36c-8514dad1e62b.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI MVP correction pass completed with local validation but runtime/UAT still pending

Rollout context: Work was performed in `/Users/tualek/ohochat`, limited to `oho-api`, `oho-webhook`, and `docs/meta-business-ai/plan-fix-meta-ai-profile.md`. Existing dirty changes were preserved; no commit, push, reset, revert, delete, or staging was performed.

## Task 1: Implement approved Facebook Meta Business AI corrections

Outcome: partial

Preference signals:
- The user explicitly required preserving all existing uncommitted/user changes and stopping without commit/push/stage -> future agents should pin and report dirty state before edits and avoid destructive Git operations.
- The user required “Facebook Messenger only,” no `oho-web-app` changes, and no unrelated refactors -> keep future implementation narrowly scoped to the approved repos and platform.
- The user required exact commands/results, remaining runtime/UAT gaps, and changed-file reporting -> provide an evidence-first review handoff rather than claiming production readiness from focused tests.

Key steps:
- Inspected dirty diffs, repository instructions, and the named plan before editing.
- Added explicit persisted `channel.meta_business_ai_enabled`, default `false`, authenticated channel update validation, Facebook-only propagation into contact/upsert and automation/control paths.
- Implemented strict `message.ai_generated === true` author evidence without using it as activation or ownership evidence; removed nested `meta_business_ai.identity` handling.
- Moved external-app whitelist rejection after Facebook/page/contact validation and added a narrow strict-AI exception; mixed batches continue processing valid AI/customer events while unknown non-AI external events remain fail-closed.
- Ensured standby customer messages persist before automation blocking when the Facebook channel is enabled.
- Bound exact Thai handoff text to the enabled Facebook activation context and fresh bot/no-assignee state; replay, stale, assigned, disabled, non-Facebook, and unmatched control events do not trigger handoff.
- Wired existing Accept/Close actions to Graph `take_thread_control`/`pass_thread_control`, with tenant scoping, success-only authority persistence, and fail-closed behavior.
- Kept lazy `${businessId}@meta-ai` Stream provisioning and `${businessId}@inbox` fallback while preserving `ai_generated:true`; no cold provisioning/backfill/repair.
- Restored canonical-event and dedup regression coverage and added duplicate-create activation snapshot coverage.
- Updated the plan with actual implementation/validation status and explicit remaining UAT items.

Failures and how to do differently:
- Initial duplicate-create regression test failed because its mocked query shape did not match the actual fallback query; the test was corrected and then passed.
- Test runs emitted pre-existing duplicate Jest mock warnings, missing `OHO_FB_APP_ID`, and unavailable local Redis connection warnings. These did not fail the focused suites, but live Redis/Mongo/Stream and Meta behavior remain unverified.
- Do not treat focused tests, TypeScript checks, or HTTP 200 as production/canary evidence; perform captured-payload replay and terminal datastore/Stream verification separately.

Reusable knowledge:
- API HEAD inspected: `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`; webhook HEAD inspected: `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`.
- API focused validation passed: 10 suites / 50 tests.
- Webhook focused validation passed: 5 suites / 46 tests.
- Webhook TypeScript validation passed: `TypeScript: No errors found`.
- `git diff --check` passed in both repositories; `git diff --cached --quiet` confirmed nothing staged.
- Remaining unverified: full suites, live Meta standby/AI replay, real Graph take/return, terminal Mongo/Redis/Stream inspection, canary/rollback, and approved target app configuration.

References:
- `/Users/tualek/ohochat/oho-api/src/models/channel.model.js`
- `/Users/tualek/ohochat/oho-api/src/services/contact/upsert/upsert.class.js`
- `/Users/tualek/ohochat/oho-api/src/services/contact/meta-business-ai/control-hooks.js`
- `/Users/tualek/ohochat/oho-api/src/utils/meta-business-ai-stream.js`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/meta-business-ai.ts`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/helper.ts`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts`
- `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- Exact handoff text: `เอเจนต์ AI ของคุณโอนแชทนี้ให้คุณ`
