thread_id: 019ff944-2c61-78d0-ab18-072ed186d997
updated_at: 2026-08-14T09:53:26+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration safety review and rollout guidance

Rollout context: Work centered on `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint` and related `oho-api`/`oho-webhook` infrastructure. The user wanted a production-safe migration from non-whitelisted LINE webhook domains to a new endpoint, with verification, backup, rollback, and controlled canary rollout.

## Task 1: Audit the original migration script

Outcome: partial

Preference signals:
- The user explicitly required DB discovery, new-endpoint verification before LINE PUT, DB update only afterward, and complete backup/rollback before any change -> future reviews should trace the entire mutation and recovery path, not just the happy path.
- The user values concise operational certainty but rejects unsupported guarantees; later they corrected that test traffic must not be treated as historical production traffic.

Key steps:
- Verified URL construction matches `oho-api`: `${webhook_endpoint}/line/webhook/${businessId}`.
- Verified LINE flow was `POST /webhook/test` → `PUT /webhook/endpoint` → GET confirmation → MongoDB update.
- Found blockers: backup was persisted only after mutation; rollback could include dry-run-only entries; DB backup did not preserve all modified fields; whitelist semantics were reversed; confirmation token was not bound to the exact candidate set; partial failures exited successfully.
- Verdict was rework before production.

Failures and how to do differently:
- Never treat a post-mutation backup as sufficient. Persist and validate an immutable before-state manifest before the first LINE PUT.
- Rollback must be driven by durable per-channel mutation state, not merely manifest membership.
- Explicitly model `allowed-host`/whitelist semantics; do not infer them from an `old-host` filter.

Reusable knowledge:
- `oho-api/src/services/channel/line/line.hooks.js:237-285` registers and re-reads the endpoint; `generateServicePayload` uses the same endpoint shape.
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:266-283` uses the DB endpoint first and Core API `webhook_endpoint` only as fallback when DB endpoint is absent.
- `oho-webhook/src/controllers/line/line.controller.ts` receives LINE events and queues them; the original implementation can return HTTP 200 even after downstream queue creation errors.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `script-oho/migrate-line-webhook-endpoint/README.md`
- LINE APIs: `GET/POST/PUT https://api.line.me/v2/bot/channel/webhook/{endpoint|test}`

## Task 2: Produce implementation-ready hardening plan

Outcome: success

Preference signals:
- The user clarified: “`register_webhook_at` อาจจะไม่ต้องอัปเดตนะ” and later requested plan-only -> future plans must explicitly preserve fields the user says not to modify and respect plan-only scope without implementing prematurely.
- The user initially requested delegation to `5.6luna max`, but the model was unavailable; the user then said to make only the plan -> do not silently substitute unavailable sub-agent models.

Key steps:
- Replaced `plan.md` with a detailed fail-closed design covering explicit whitelist inventory, immutable atomic manifest, manifest-bound apply, journal phases, exact DB restore, timeout/retry policy, non-zero exit semantics, tests, and canary rollout.
- Locked that `channels.line.register_webhook_at` is never read for decision-making, written, unset, or restored.
- Verified only the plan was changed in that phase; no DB, LINE API, gateway smoke test, or production canary was run.

Reusable knowledge:
- Required flow: DB inventory → LINE inventory → immutable manifest → revalidation → LINE test → PUT → bounded GET polling → DB update → final verification.
- Apply must use the reviewed manifest and reject candidate drift, environment mismatch, digest mismatch, or DB/LINE before-state drift.
- Rollback must restore exact field presence/value for touched DB fields and detect concurrent changes.

References:
- `script-oho/migrate-line-webhook-endpoint/plan.md`
- Important invariant: no `$set`/`$unset` containing `line.register_webhook_at`.

## Task 3: Review implemented hardening and infrastructure rollout

Outcome: partial

Key steps:
- The implementation added `migrate-line-webhook.helpers.ts`, helper tests, manifest digesting, atomic restricted writes, `--allowed-host`, manifest-bound apply/rollback, per-channel journals, request timeouts, polling, and tests.
- `npm run migrate:line-webhook:help` passed. The rollout did not establish full production correctness because no real migration execution was performed.
- GCP checks found `webhook2.oho.chat` had an ACTIVE certificate and returned `{"page":"LINE Home"}`. URL-map state was verified with host/path rules and backend weights.
- Historical log checks excluded the user’s own test traffic; no pre-test evidence of `webhook2.oho.chat` usage was found in the queried retention window.
- The user’s current routing model is suitable for batch canaries: default `webhook2.oho.chat` to old `oho-webhook-production`, then add exact business `fullPathMatch` rules to route selected businesses to `webhook--production`.

Failures and how to do differently:
- Do not claim zero message loss. `cloud_tasks.api.ts:125-135` logs task creation errors without rethrowing; the controller can still return 200, preventing LINE redelivery.
- Do not infer production topology from resource names or today’s logs. Verify DNS, certificate, URL map, backend, and historical logs, while excluding manual test traffic.
- `add_queue_success` alone is not proof; verify the full chain using `LineBotWebhook/2.0`, Cloud Tasks metrics, and `source-messages` terminal states.

Reusable knowledge:
- Useful observability states: `receive_webhook`, `add_queue_success`, `add_queue_fail`, `sync_message_inprogress`, `sync_message_success`, `sync_message_fail`, `dropped`.
- Roll back routing to old `100` / new `0` on any queue creation failure, non-OK Cloud Task attempt, message not reaching terminal success, or canary 5xx/timeout.
- For 2–3 businesses with identical treatment, multiple `matchRules[].fullPathMatch` entries in one URL-map route rule have OR semantics.

References:
- `oho-webhook/src/controllers/line/line.controller.ts:145-212, 324-362`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135`
- `oho-webhook/src/models/source_message.model.ts:19-36`
- Metrics: `cloudtasks.googleapis.com/queue/depth`, `cloudtasks.googleapis.com/queue/task_attempt_count`, `cloudtasks.googleapis.com/queue/task_attempt_delays`
- Verified URL-map pattern: `webhook2.oho.chat` host rule, default old backend, exact business path rules to `webhook--production`.
