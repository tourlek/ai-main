thread_id: 01a03276-58b0-7101-bb0e-2909ee1da2ff
updated_at: 2026-08-24T07:30:45+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T13-30-11-01a03276-58b0-7101-bb0e-2909ee1da2ff.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI minimal-diff hardening completed locally, with staging/runtime proof intentionally outstanding

Rollout context: In `/Users/tualek/ohochat`, both `oho-api` and `oho-webhook` were on `tk-sprint-2616/feature/oho-1802-meta-biz-ai`. The user requested Ponytail-scoped fixes only, preserving existing dirty files and avoiding Redis lease, ownership matcher, web-app, and unrelated behavior changes.

## Task 1: Implement the seven backend/webhook fixes and cleanup

Outcome: partial

Preference signals:
- The user explicitly required “minimal fix,” “review-only” initially, and “อย่าแก้ Redis lease หรือ matcher ก่อนมี runtime evidence” -> keep Meta work narrowly scoped and do not infer runtime fixes without captured evidence.
- The user repeatedly required preservation of dirty worktrees and no commit/stage/push -> inspect and modify only intended files; report exact validation and remaining runtime gaps.
- Ponytail was explicitly invoked -> prefer deletion and smallest root-cause diff over abstractions or defensive layers.

Key steps:
- Inspected both branches, worktrees, repo instructions, existing dirty files, and relevant Meta Business AI paths before editing.
- Added an API guard so Meta authority/activation fields are accepted only through internal `/contact/upsert`; external `/contact` callers are rejected.
- Added T6 primary retry: when secondary lookup misses and `is_upsert=false`, query primary once with `maxTimeMS(5000)` before returning 404.
- Split T3 `chat_status` update/emit from `is_unresponded` clearing so one failure does not prevent the other.
- Added `/load-tests/meta-business-ai.var.json` to `.gitignore`; made required load-test config fail fast and optional LINE scenario omission conditional.
- Removed takeover scenario from the performance load run; removed unused `META_AUTHORITY.UNKNOWN`, deprecated handoff text list, and redundant Facebook hook `try/catch`.
- Fixed a k6 initialization collision by renaming Trend metrics, then verified `k6 inspect` with dummy non-secret config.

Failures and how to do differently:
- Initial API Jest invocation scanned `.claude/worktrees` and failed before tests due duplicate mocks and old Node/dependency issues (`Utils.isRegExp`, `Utils.isDate`, `buffer-equal-constant-time`). Isolate tests with `--roots src` and a temporary Node compatibility shim; do not report the initial failure as a code regression.
- `k6 inspect` initially failed because metric variables shared names with exported scenario functions. Rename metrics rather than scenario functions.
- Focused tests/builds are not staging proof; no staging replay, actual load, terminal Mongo/Redis/Stream verification, Graph takeover/return, canary, or rollback was run.

Reusable knowledge:
- API tests passed with the repository’s compatibility workaround: 3 suites, 20 tests.
- Webhook focused tests passed: initially 3 suites/23 tests; after later scope correction, 2 suites/21 tests.
- Webhook build and release type-check passed; API build passed; Prettier and `git diff --check` passed.
- The webhook acknowledges HTTP 200 even when processing fails, so runtime validation must inspect terminal datastore/Stream state, not HTTP status alone.

References:
- API files: `src/services/contact/contact.hooks.js`, `src/services/contact/upsert/upsert.class.js`, `src/services/contact/upsert/upsert.hooks.js`, `src/services/member-send-message/inbox/inbox.hooks.js`, `src/services/channel/facebook/facebook.hooks.js`, `src/utils/meta-business-ai.js`.
- Webhook files: `src/controllers/facebook/block.ts`, `src/controllers/facebook/meta-business-ai.ts`.
- Load test: `load-tests/meta-business-ai.js`, `load-tests/meta-business-ai.var.json.example`.
- Validation commands included `npm run build`, focused Jest via `node -e` compatibility shim, `k6 inspect --env VAR_JSON=...`, Prettier checks, and `git diff --check`.

## Task 2: Correct chat-status failure isolation and lifecycle load-test payload

Outcome: success

Preference signals:
- The user precisely requested: “เอา early return context ออก เพื่อให้ยัง clear is_unresponded แม้ update/emit chat_status ล้มเหลว” -> preserve independent failure domains and test both directions.
- The user specified the endpoint contract: lifecycle self-assign payload must be `{ team_id }`, with `assign_member_id` removed -> derive load-test config from the actual endpoint, not prior assumptions.

Key steps:
- Removed the early `return context` from the `chat_status` catch block.
- Added/updated regression coverage proving `is_unresponded` clearing still runs when contact patch fails and chat-status emission still occurs when clearing fails.
- Changed lifecycle self-assign payload to `{ team_id }`, removed `assign_member_id` from required config and example, and increased post-close wait from 1s to 6s to exceed the documented 5s self-assign cooldown.
- Removed the batch-wide denylist patch and its test after the user identified that it could drop allowed events in a mixed webhook batch. The implementation returned to checking only the first event; per-event denylist handling was explicitly deferred as separate work.

Reusable knowledge:
- Final inbox focused test passed: 1 suite, 6 tests.
- Final webhook focused tests passed: 2 suites, 21 tests; webhook build passed.
- Final k6 inspection showed four expected scenarios and no takeover scenario; lifecycle config required only `assign_team_id`.
- Final formatting, JSON formatting, syntax check, and `git diff --check` passed.

Failures and how to do differently:
- Do not treat batch-wide denylist iteration as safe: returning true for any denied event blocks the entire webhook batch and can discard allowed messages. Keep that change out of the candidate until per-event filtering is designed and tested.
- Do not add `meta_on_takeover` to the performance run merely to close a spec gap; the user’s locked scope keeps takeover proof in T9.1 runtime replay.

References:
- Inbox fix: `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:241-285`.
- Lifecycle payload: `oho-api/load-tests/meta-business-ai.js:190-218`.
- Lifecycle example: `oho-api/load-tests/meta-business-ai.var.json.example`.
- Final user constraint: staging must not be called passed until T9.1 ownership-error→take→retry, T9.2 standby replay, and T9.3 load/runtime evidence inspect Mongo/Redis/Stream.
