thread_id: 019fe9f1-4dfe-7963-a2c9-f930bfbf93e7
updated_at: 2026-08-10T06:55:37+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T11-32-13-019fe9f1-4dfe-7963-a2c9-f930bfbf93e7.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration hardening and scoped dry-run

Rollout context: In `/Users/tualek/ohochat/script-oho`, the user requested an end-to-end review and hardening of `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`. Requirements included DB whitelist detection, verify the new endpoint via LINE before PUT, update DB only after LINE succeeds, complete backup/rollback protection, and later the explicit decision not to update `line.register_webhook_at`. The user ultimately requested testing only channel ID `6a794f77fc9340171589accf`, not the whole business.

## Task 1: Review original migration implementation

Outcome: partial

Preference signals:

- The user required checking DB domains against an explicit whitelist, not merely migrating every channel or filtering by an old host -> future implementations should model `allowed-host` semantics explicitly and report non-whitelisted candidates.
- The user emphasized: “ก่อนจะเปลี่ยน จะต้อง backup ไว้ทั้งหมด” and rollback safety -> backups must be persisted and validated before any LINE or DB mutation.
- The user later specified that `register_webhook_at` should not be updated -> preserve this field exactly in both migration and rollback.

Key steps:

- Traced the original flow and compared it with `oho-api`’s LINE connect implementation. URL construction was confirmed as `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed the original script had `POST /webhook/test → PUT LINE → DB update`, but backup was written after `processChannel`, leaving a crash window.
- Identified that original `--old-host` semantics were opposite the requested whitelist behavior, rollback could include dry-run-only entries, DB backup was incomplete, confirmation tokens were not tied to candidate IDs, and failures did not force non-zero exit.

Failures and how to do differently:

- Do not ship the original flow: it was correctly judged “rework before production.”
- Do not treat LINE `success: true` as proof of full message processing; a real-message canary and runtime evidence are still required.

Reusable knowledge:

- `oho-api/src/services/channel/line/line.hooks.js` builds the endpoint at lines around 237–242 and validates endpoint equality around 91–99.
- `oho-webhook/src/controllers/line/line.controller.ts` exposes `/line/webhook/:businessId`; `GET /line` returns `{ page: 'LINE Home' }`.
- LINE’s webhook test endpoint is rate-limited and only proves the endpoint accepts the empty test event; real-message verification remains necessary.

## Task 2: Plan and implement manifest-first migration hardening

Outcome: partial

Preference signals:

- When the user said “ทำตาม plan ได้เลย”, implementation proceeded from `plan.md`; future work should preserve this plan-first workflow and review against the plan before applying production changes.
- The user requested a narrowly scoped test and the assistant limited live dry-run to `--channel=6a794f77fc9340171589accf`, without `--all-channels` or `--execute` -> default to exact user-provided scope and avoid broader live operations.

Key steps:

- Replaced the original backup/checkpoint approach with an immutable manifest containing DB/LINE before-state, whitelist, candidate IDs/count, environment, Mongo target, and digest.
- Added atomic restricted-permission JSON writes, manifest-bound confirmation tokens, candidate revalidation, conditional DB updates, durable journal phases, timeouts/retries, compensation, exact `$set`/`$unset` rollback, and explicit exclusion of `line.register_webhook_at`.
- Added helpers and tests for whitelist classification, digest tamper detection, exclusive manifest creation, migration/rollback payloads, token binding, and fake LINE ordering (`test → PUT → poll`, with no PUT after failed test).
- Added README/runbook and updated package scripts.
- Performed a read-only production dry-run with `--env=prod --channel=6a794f77fc9340171589accf --allowed-host=api2.oho.chat`; it found one channel (`testabc`), classified `line_db_match`, and showed DB/LINE still on `https://webhook.oho.chat/...` with target `https://api2.oho.chat/webhook/...`.

Failures and how to do differently:

- No production apply was performed. The dry-run manifest is evidence only; do not reuse it without reviewing unresolved code-review findings.
- Independent review still found high-risk gaps: final LINE state is not re-read after the DB update, recovery/rollback handling of `updated_at` can still be unsafe in crash scenarios, and live `business_id` validation needs to be explicit before mutation. These should be fixed before `--execute`.
- Review also noted incomplete orchestration/recovery test coverage and unrelated pre-existing dirty changes in `package.json`/other files; isolate migration changes before committing.

Reusable knowledge:

- Main files: `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`, `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, `README.md`, `plan.md`.
- Production scope discovered: channel ID `6a794f77fc9340171589accf`, business ID `604ee3c35c2d9e573e8e9873`, display name `testabc`; original DB/LINE endpoint host was `webhook.oho.chat`.
- No manifest or journal output contained access tokens or Mongo credentials.

References:

- `npm run test:line-webhook` passed 9/9.
- `npm test` passed 19/19.
- TypeScript check passed with the targeted `npx tsc --noEmit ...` command.
- `npm run migrate:line-webhook:help` passed.
- Read-only dry-run command: `npm run migrate:line-webhook -- --env=prod --channel=6a794f77fc9340171589accf --allowed-host=api2.oho.chat --delay-ms=0 --concurrency=1`.
- Manifest: `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-20260810065326-230ce054.json`.
