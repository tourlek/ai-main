thread_id: 019ff944-2c61-78d0-ab18-072ed186d997
updated_at: 2026-08-16T18:03:59+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration review, hardening plan, and rollout-routing investigation

Rollout context: Work centered on `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint` and related `oho-api`/`oho-webhook` services. The user wanted to migrate LINE webhook URLs to a new domain safely, with LINE endpoint verification, DB updates, complete backup, and rollback.

## Task 1: Audit the initial migration script

Outcome: success

Preference signals:
- The user asked whether the script “ครอบคลุมแล้วรึยัง” and explicitly required DB discovery, endpoint verification before PUT, LINE API update before DB update, full backup, and rollback -> future reviews should trace the entire operational flow, not just inspect local code.
- The user expects evidence with concrete file/line references and prefers read-only review before edits.

Key steps:
- Traced the script, `oho-api` LINE connection hooks, and `oho-webhook` route.
- Confirmed URL construction matches first-connect behavior: `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed LINE `POST /webhook/test` → `PUT /webhook/endpoint` → GET verification → Mongo update exists.
- Confirmed gateway smoke test, dry-run, checkpoint, confirmation token, retry, and rollback scaffolding.

Failures and how to do differently:
- Initial implementation was not production-safe: backup was persisted only after `processChannel()` completed, so a crash after LINE mutation could leave no rollback source.
- Dry-run entries were eligible for rollback even when never migrated; rollback needed a durable mutation journal.
- Backup omitted original DB field presence/values for `is_webhook_endpoint_valid`, `is_webhook_active`, and `updated_at`; rollback was not exact.
- `--old-host` semantics did not implement the user’s requirement to identify DB domains outside an explicit whitelist.
- Confirmation tokens were not bound to the exact candidate manifest/count.
- Partial failures were summarized but did not reliably produce non-zero process exit.
- `LINE success: true` only proves the empty test webhook reached the endpoint; it does not prove queueing or end-to-end message processing.

Reusable knowledge:
- `oho-api/src/services/channel/line/line.hooks.js:91` and `:237` define the canonical endpoint shape and LINE registration flow.
- `oho-webhook/src/controllers/line/line.controller.ts` receives `/line/webhook/:businessId`; `GET /line` returns `{ page: 'LINE Home' }`.
- LINE webhook test endpoint is rate-limited (60/hour), so production rollout must avoid excessive repeated tests.
- The repo’s operational standard is fail-closed, per-business canarying, durable checkpoints, and real-cluster writes only (not Atlas Data Lake).

References:
- Initial script: `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- Initial verdict: “rework ก่อน run production”; biggest blockers were backup-after-mutation and rollback scope.
- Validation run: `npm run migrate:line-webhook:help` passed; no DB or LINE mutation was executed.

## Task 2: Write an implementation-ready hardening plan

Outcome: success

Preference signals:
- The user explicitly changed scope to “plan อย่างเดียวก่อน” and asked not to implement or delegate yet -> when scope is narrowed, stop at the requested artifact and do not continue into code changes.
- The user clarified that `register_webhook_at` need not be updated -> preserve this decision in both implementation and rollback plans.

Key steps:
- Replaced `script-oho/migrate-line-webhook-endpoint/plan.md` with a detailed plan.
- Locked the flow: DB inventory → LINE inventory → immutable manifest → revalidation → LINE test → PUT → GET/poll verification → DB update → final verification.
- Specified explicit `--allowed-host`, manifest-bound apply, atomic writes, exact DB field restoration, mutation journal, conflict detection, timeout/retry policy, non-zero exit semantics, unit/orchestration tests, and canary rollout.

Reusable knowledge:
- `line.register_webhook_at` must not be read for candidate logic, written during migration, or restored during rollback.
- Apply must use a reviewed dry-run manifest; it must not recompute a new candidate set.
- Manifest should contain sanitized metadata and exact before-state field presence; never store access tokens or secrets.
- Rollback must exclude dry-run-only entries and detect concurrent DB changes.
- The plan explicitly states that DB, LINE API, gateway smoke, and production canary were not run during the plan-only phase.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/plan.md`
- Key CLI concepts: `--allowed-host`, `--manifest`, `--execute`, `--confirm`, `--rollback`.

## Task 3: Review implemented hardening and investigate webhook2 routing

Outcome: partial

Preference signals:
- The user asked “ลองตรวจสิมีแก้ไปแล้ว” -> future agents should re-open and inspect the actual current files rather than trusting an earlier plan or summary.
- The user corrected that same-day traffic was manually generated and should not count as historical production usage -> always separate test/manual traffic from historical production traffic using the user-specified time window.
- The user wants concise, practical rollout instructions, but not unsupported guarantees; they challenged “ข้อความไม่หายแน่ๆ” and the correct response was to explain residual loss modes.

Key steps:
- Found the implementation had added `migrate-line-webhook.helpers.ts`, helper tests, manifest-first behavior, atomic writes, digest validation, journal phases, whitelist classification, timeout/polling, exact DB snapshots, and no `register_webhook_at` mutation.
- Verified `npm run migrate:line-webhook -- --help` passed.
- GCP checks showed `webhook2.oho.chat` certificate `ACTIVE`, `/line` returned HTTP 200, and URL-map routing can target `webhook--production` by host/path.
- Historical log search found no pre-existing webhook2 traffic in the checked retention window once today’s manual tests were excluded.
- Verified Core API cron validation uses `line.webhook_endpoint` from DB when present and only falls back to `context.app.get('webhook_endpoint')`; there is no discovered cron domain whitelist consumer. Core API config is used by new/reconnect LINE flows.
- Verified current webhook code can swallow Cloud Tasks creation errors (`cloud_tasks.api.ts:125`) while the controller still returns HTTP 200, creating a real message-loss risk.

Failures and how to do differently:
- Earlier routing conclusions were too confident based on resource names and recent requests. Confirm DNS → frontend IP → certificate/target proxy → URL map/backend → logs, and exclude manual traffic before claiming historical use.
- Do not claim zero message loss. `webhook2` routing can limit blast radius, but queue creation failure may still be acknowledged with HTTP 200; LINE redelivery is not guaranteed.
- Do not tell the user to update a nonexistent cron whitelist. The actual validation precedence is DB endpoint first, Core API env fallback.
- The requested sub-agent model `gpt-5.6-luna` was unavailable; only `gpt-5.6-sol` and `gpt-5.6-terra` were available. The user then requested plan-only, so no substitute delegation was performed.

Reusable knowledge:
- Current URL-map pattern for routing two businesses with the same behavior is one route rule with multiple OR `matchRules` using `fullPathMatch`.
- To route all LINE webhook paths on `webhook2.oho.chat`, use `prefixMatch: /line/webhook/`; other paths can continue to the path matcher default backend.
- Existing service route semantics: default backend `oho-webhook-production`; selected `webhook2` path can route to `webhook--production` at 100/0 or 0/100.
- Operational verification must follow `LINE ingress → Cloud Task creation → task processing → source-message terminal status → user-visible message`, not HTTP 200 alone.
- Useful source-message statuses include `receive_webhook`, `add_queue_success`, `add_queue_fail`, `sync_message_inprogress`, `sync_message_success`, `sync_message_fail`, and retry/dead-letter statuses.

References:
- Hardening files: `migrate-line-webhook-endpoint/migrate-line-webhook.ts`, `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, `README.md`, `plan.md`.
- GCP URL map: `oho-webhook-lb`; host `webhook2.oho.chat`; path matcher `line-webhook2-canary`.
- Core API validation: `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:267-283`.
- Queue error swallowing: `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135`; controller acknowledges requests at `oho-webhook/src/controllers/line/line.controller.ts:145-174`.
- User correction: “ไม่นับวันนี้เพราะ ฉันเอามาใช้เอง” — same-day webhook2 logs were manual tests, not historical production evidence.
