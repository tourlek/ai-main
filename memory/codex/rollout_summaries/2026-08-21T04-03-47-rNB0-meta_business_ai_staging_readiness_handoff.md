thread_id: 01a0227d-3bea-70b1-905c-ba05014690f2
updated_at: 2026-08-21T06:15:26+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/21/rollout-2026-08-21T11-03-47-01a0227d-3bea-70b1-905c-ba05014690f2.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI staging-1 readiness audit and handoff preparation remained incomplete

Rollout context: Work occurred in `/Users/tualek/ohochat`, focused on `oho-api` and `oho-webhook` branch `tk-sprint-2616/feature/oho-1802-meta-biz-ai`, with supporting docs in `docs/meta-business-ai/`. The user’s goal was eventual staging-1 validation followed by safe UAT/production go-live without performance regressions.

## Task 1: Audit and locally harden Meta Business AI

Outcome: partial

Preference signals:
- The user required the work to remain on the working branch and later explicitly said “เบื้องต้น commit ไปที่ brach working” -> future agents should commit only to the named feature branches, while keeping push/deploy as separate approvals.
- The user asked “ขอให้ทำ handoff ก่อนได้ไหม” and then “ได้ไหม” -> prepare a concise evidence-based handoff before proceeding with deployment or further mutation.
- Existing dirty work was preserved; unrelated `.codegraph/`, `.claude-worktrees/`, `plan.md`, and `/private/tmp` artifacts were intentionally excluded from the intended commit scope.

Key steps:
- Pinned API HEAD `8e2370c44ce3a3fc8b9c01e2d97f57adc9f7e7ed` and webhook HEAD `9960270e6595366c417ecc2e7bc68e1b16c74aa4`; both matched their feature remotes at audit time.
- Reviewed the latest handoff and official 18-page Meta integration PDF. Important contract distinctions were preserved: `standby` indicates delivery by another app, `ai_generated === true` identifies message author, and activation/authority are separate state dimensions.
- Added/validated local fixes for immediate live `standby` bot suppression, fail-closed send guards when activation is enabled but authority is not `oho`, authority timestamp ordering, new-contact authority initialization, selective bulk takeover, Firebase Remote Config timeout/single-flight behavior, and prevention of delayed fallback-task races.
- The fallback race fix marks schedules removed before deleting Cloud Tasks and makes scheduled delivery check an active schedule using a primary read, skipping on read failure or when a newer customer message exists.
- Created/updated `docs/meta-business-ai/staging-1-readiness-2026-08-21.md` with verdict, pinned SHAs, local verification, staging routing/performance evidence, missing evidence, and approval gates.

Reusable knowledge:
- Local verification passed: API 12 focused suites, 162 passed and 2 skipped; API SWC compile of 1,564 files; webhook 3 focused suites, 28 passed; webhook release TypeScript check; formatting and `git diff --check`.
- Staging was not mutated. No deploy, push, replay, config/env change, or terminal Mongo/Redis/Stream verification was completed.
- Read-only baseline found API staging p50 19 ms, p95 217 ms, p99 7.63 s, max 31.68 s. `/contact-send-message` had 3 of 7 calls over 5 s and max 31.68 s; this is a serious performance gate, though the slow sample was not attributed to the Meta authority guard.
- Webhook staging had only 14 requests, with p95/p99 7.85 s and max 21.43 s, too little data for a ship decision.
- Staging routing differs: custom-domain probes reached a legacy webhook service while Meta test-page traffic reached the direct Cloud Run webhook URL; both routes must be checked after deployment.
- Official PDF extraction confirmed Business AI App ID `928891643393937`, `standby` subscription requirements, `ai_generated`, Page Status API, Thread Owner API, and `pass_thread_control`; runtime project decision used `622851382610562` only as the return target app ID, not as author/activation/ownership evidence.

Failures and how to do differently:
- The rollout did not prove production readiness. Focused tests and HTTP 200 are insufficient; replay captured `messaging`/`standby` payloads and inspect terminal Mongo, Redis, and Stream state.
- Staging test-page credentials/permissions were unavailable or pointed to a different datastore/Stream app, so exact target channel/contact state and live replay remained unverified.
- Targeted API ESLint initially exposed an existing unrelated unused-variable issue; after removing an unrelated unused import, the touched-file lint passed, but the broader baseline limitation remained documented.
- The user requested a handoff before continuing. The next agent should deliver the handoff first, clearly separating committed/local state, staging evidence, unverified gates, and exact next approvals. There is no reliable tool evidence in the rollout that the authorized commits were actually created; verify current `git log` and `git status` before claiming they exist.

References:
- `/Users/tualek/ohochat/docs/meta-business-ai/staging-1-readiness-2026-08-21.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/handoff-2026-08-21-prod-overlap-staging.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/HANDOFF.md`
- API: `src/utils/meta-business-ai.js`, `src/firebase-remote-config.js`, `src/services/bot-send-message/schedule/schedule.class.js`
- Webhook: `src/controllers/facebook/meta-business-ai.ts`, `src/controllers/facebook/handler.ts`, `src/app.ts`
- Exact local test result: `Test Suites: 12 passed, 12 total; Tests: 2 skipped, 162 passed, 164 total`
