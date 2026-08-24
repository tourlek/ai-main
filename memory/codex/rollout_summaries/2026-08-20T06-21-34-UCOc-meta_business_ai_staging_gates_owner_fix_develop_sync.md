thread_id: 01a01dd5-0450-7923-a90f-1997e16484f0
updated_at: 2026-08-20T07:25:12+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T13-21-34-01a01dd5-0450-7923-a90f-1997e16484f0.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI staging-gate fixes were implemented and committed, but staging deployment/UAT was not performed

Rollout context: Work in `/Users/tualek/ohochat` across dirty `oho-api` and `oho-webhook` worktrees. User required ponytail/minimal diff, preservation of unrelated work, no deployment claims, and explicit separation of local validation from staging evidence.

## Task 1: Fix Meta Business AI owner targeting and subscription/onboarding paths

Outcome: partial

Preference signals:
- The user explicitly requested ponytail behavior: “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause” -> future changes should avoid speculative abstractions and inline one-off values where appropriate.
- The user required exact staging readiness evidence and challenged statements that mixed pre-deploy status with UAT -> report gates in order: code validation/commit, staging deploy, staging live proof, staging pass, then UAT.
- The user required honest validation: focused tests/builds are not live Meta or terminal datastore proof -> distinguish `Not run` from failed tests and never claim staging readiness without deployment evidence.

Key steps:
- Inspected existing dirty worktrees before editing; preserved `.codegraph`, `.claude-worktrees`, `plan.md`, and unrelated changes.
- Fixed `oho-api/src/utils/meta-business-ai.js` so only the configured Business AI target App ID is treated as the current owner. Removed hard-coded `263902037430900` from the known-owner list; Page Inbox/Business Suite now causes `pass_thread_control` to target `928891643393937`.
- Added regression coverage for Page Inbox owner versus configured AI target.
- Simplified `request-page-subscribed-app.js` by inlining the single Facebook-only field `messaging_handovers`; retained GET → union → POST → GET verification and App-ID matching via `subscribed_apps[].id`.
- Merged `origin/develop` into `oho-webhook`; resolved `facebook.controller.ts` conflict by preserving canonical per-event dedup and retaining the develop replay/retry bypass in the handler, without restoring request-level `checkDuplicate`.
- Created commits: API onboarding `3ae53be`, API authority fix `96a244b`, webhook merge `6f541808`; webhook merge includes `66233ae` in ancestry. Commits were not pushed.
- Updated Meta onboarding/checklist documentation so app-level standby, Page-level subscription verification, and terminal Mongo/Stream proof are explicit; `message_deliveries` remains optional observability, not an acceptance gate.

Failures and how to do differently:
- API Meta-control/member-send suites could not load under available Node 24/26 because old dependency `buffer-equal-constant-time`/`jwa` fails with `Cannot read properties of undefined (reading 'prototype')`; Node 20 was unavailable. Do not claim those suites passed; rerun in the repo’s Node `^20.0.0` environment.
- An initial merge conflict would have reintroduced request-level dedup from develop; the resolved tree intentionally keeps only canonical handler dedup and skips dedup for internal replay/retry.
- No staging deploy, live Meta subscription check, Meta payload replay, or terminal Mongo/Stream verification occurred. Therefore staging was not passed and UAT was not yet reached.

Reusable knowledge:
- Graph URL prefixing is centralized: both repos use `graphUrl()` for `https://graph.facebook.com/v25.0`; Business AI status intentionally uses `api.facebook.com/v25.0`.
- `message.ai_generated === true` identifies message author, not page activation or thread ownership. `standby` alone only indicates another app may own delivery.
- Correct release sequence is `code validation/commit → deploy staging → staging subscription/replay/terminal proof → staging pass → UAT`.
- HTTP 200, focused unit tests, queue acknowledgement, or a successful local build are insufficient proof of webhook delivery; inspect terminal Mongo and Stream state after replay.

References:
- `/Users/tualek/ohochat/oho-api/src/utils/meta-business-ai.js`
- `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/facebook.controller.ts`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts`
- `/Users/tualek/ohochat/docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- API focused onboarding tests: 3 suites / 12 tests passed.
- Webhook focused tests: 3 suites / 24 tests passed.
- Both builds and `git diff --check` passed.
- User correction: “staging ยังไม่ผ่านจะขึ้น uat ได้ยังไง” -> do not describe UAT evidence before staging has passed.
