thread_id: 019feaaa-5edf-7453-8fdb-0bf9b642ca0c
updated_at: 2026-08-10T10:38:39+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-54-21-019feaaa-5edf-7453-8fdb-0bf9b642ca0c.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration hardening and runtime configuration audit

Rollout context: In `/Users/tualek/ohochat`, the user asked whether `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts` fully covered a production-safe LINE webhook domain migration, then requested a plan-only revision and a cross-repo audit of required env/config changes.

## Task 1: Review existing LINE webhook migration script

Outcome: partial

Preference signals:
- The user explicitly required DB discovery of non-whitelisted domains, verification of the new endpoint via LINE API before changing it, LINE PUT before DB update, complete backup before any mutation, and rollback capability. Future reviews should trace this exact ordering and failure recovery rather than only checking the happy path.
- The user wanted an evidence-first review without edits initially; the assistant was asked to provide file/line-based findings before changing code.

Key steps:
- Reviewed `migrate-line-webhook.ts`, README, plan, `oho-api` LINE integration hooks, and `oho-webhook` routes.
- Confirmed URL construction matches the existing connect flow: `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed LINE API flow supports `POST /webhook/test`, then `PUT /webhook/endpoint`, then `GET` verification, followed by MongoDB update.
- Found production blockers: backup was persisted only after LINE/DB mutations; rollback could include dry-run-only entries; DB backup did not preserve all mutated fields; `--old-host` semantics did not implement “DB domain not in whitelist”; confirmation token was not bound to the exact candidate manifest; partial failures did not force non-zero exit.
- Verdict was rework before production.

Failures and how to do differently:
- Do not treat “backup exists in the code” as sufficient. Verify the persisted-before-mutation invariant and crash window explicitly.
- Treat LINE `success: true` as endpoint communication proof only; require a real-message canary and terminal processing evidence before expanding rollout.

Reusable knowledge:
- `oho-api/src/services/channel/line/line.hooks.js` constructs the canonical endpoint and validates it against `app.get('webhook_endpoint')`.
- `oho-webhook/src/controllers/line/line.controller.ts` exposes `/line/webhook/:businessId`; its empty-event response can make LINE’s test pass without proving the full queue/processing pipeline.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `oho-api/src/services/channel/line/line.hooks.js:237-285, 373-403`
- LINE endpoints: `POST /v2/bot/channel/webhook/test`, `PUT /v2/bot/channel/webhook/endpoint`, `GET /v2/bot/channel/webhook/endpoint`

## Task 2: Produce implementation-ready hardening plan

Outcome: success

Preference signals:
- The user clarified: “`register_webhook_at` อาจจะไม่ต้องอัปเดตนะ” and then narrowed the work to “plan มาอย่างเดียวก่อน”; future agents should not implement until the user explicitly asks.
- The user requested delegation to `5.6luna` max effort, but that model was unavailable; the user then chose plan-only instead of silently substituting another model.

Key steps:
- Rewrote `script-oho/migrate-line-webhook-endpoint/plan.md` with explicit whitelist inventory, immutable manifest, digest-bound apply, journaled mutation phases, exact rollback, conflict detection, timeout/retry behavior, non-zero exit semantics, tests, and rollout gates.
- Locked that `line.register_webhook_at` is never written or restored.
- Verified the plan changed without editing the migration implementation in that turn.

Reusable knowledge:
- Production apply should consume a reviewed dry-run manifest and must not regenerate candidates from a fresh query.
- Backup/manifest and journal files should be atomic, immutable where appropriate, secret-free, and mode `0600`.

References:
- `script-oho/migrate-line-webhook-endpoint/plan.md`
- Required sequence: `DB inventory → LINE inventory → immutable manifest → revalidate → test → PUT → GET verify → DB update → final verify`

## Task 3: Inspect already-applied implementation changes

Outcome: partial

Key steps:
- Found new helper/tests and manifest-first implementation in `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, and `migrate-line-webhook.ts`.
- Verified presence of `--allowed-host`, manifest digest, atomic writer, journal phases, exclusion of `register_webhook_at`, manifest-bound confirmation token, candidate revalidation, and rollback selection based on mutation state.
- The review output indicated remaining subtle concerns around rollback summary wording and the need to validate exact runtime behavior through focused tests and dry-run/apply/rollback scenarios.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`

## Task 4: Audit repositories and runtime config for domain migration

Outcome: partial

Preference signals:
- The user challenged an incorrect conclusion: “`web-app ต้อง deploy ใหม่หรอในเมื่อมัน comment code ไว้`”. Future agents must inspect enclosing comments, feature gates, route registration, and render/call reachability before recommending a deployment.

Key steps:
- Confirmed `core-api` loads `webhook_endpoint` from the `APP_CONFIG` JSON Secret Manager secret, not a direct `WEBHOOK_ENDPOINT` environment variable.
- Confirmed deployment mapping in `oho-api/load-config.sh`, `prepare-app-config.sh`, and `deploy.sh`: config comes from GitLab config project `294`, is stored as `core-api-config--json--<env>`, and injected as `APP_CONFIG`.
- Confirmed live `webhook--production` uses `OHO_WEBHOOK_URL` pointing to an internal Cloud Run URL, used for Cloud Tasks callbacks to `/line/message/...`; this is a different contract and should not be changed for the public LINE webhook migration.
- Initially recommended an `oho-web-app` deployment because a legacy URL was found, but corrected this after inspection: the entire relevant `<el-table>` block is HTML-commented from approximately lines 824-1140, so the URL is unreachable and does not require a web-app change or deployment.
- Final practical conclusion: update the `core-api` environment config (`webhook_endpoint`), deploy `core-api` with the new Secret Manager version, and leave `oho-webhook`, `oho-web-app`, and other repos unchanged unless separate route/runtime validation finds a real dependency.

Failures and how to do differently:
- The first cross-repo result overclaimed a required frontend deployment from a text search alone. Always inspect execution context before classifying a match as runtime-active.
- A production Secret Manager read was correctly refused when it would retrieve the entire secret; use source/deployment mapping or a narrowly scoped safe mechanism instead of exposing unrelated secrets.

Reusable knowledge:
- `oho-api/src/config/local.js` parses `APP_CONFIG` into runtime config.
- `oho-api/src/services/channel/line/line.hooks.js` and validation cron consume `webhook_endpoint`.
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99` uses `OHO_WEBHOOK_URL` for internal task callbacks; it is not the LINE public endpoint setting.
- `oho-web-app/pages/business/_biz_id/setting/integration.vue:824-1140` is commented out, including the stale `webhook.oho.chat` text at ~953.

References:
- `oho-api/load-config.sh`
- `oho-api/prepare-app-config.sh`
- `oho-api/deploy.sh`
- `oho-api/config/local.js`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99`
- `oho-web-app/pages/business/_biz_id/setting/integration.vue:824-1140`
- Live Cloud Run inspection showed `webhook--production` `OHO_WEBHOOK_URL` is an internal `*.run.app` URL.

## Task 5: Correct final scope statement

Outcome: success

Reusable knowledge:
- For this migration, the required runtime config change is the `core-api` environment’s `webhook_endpoint`, e.g. production `https://api2.oho.chat/webhook`, followed by deploying `core-api` so the new `APP_CONFIG` secret version is active.
- Do not change `OHO_WEBHOOK_URL` merely because the public LINE endpoint changes; it serves internal Cloud Tasks callbacks.
- Do not deploy `oho-web-app` for the discovered stale URL because its containing template block is commented out.
