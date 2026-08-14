thread_id: 019ff944-2c61-78d0-ab18-072ed186d997
updated_at: 2026-08-13T16:44:14+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration review, hardening plan, and rollout-risk analysis

Rollout context: Work centered on `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint` plus related `oho-api` and `oho-webhook` services. The user asked whether the migration fully met requirements, later requested a plan-only hardening pass, then asked about GCP load-balancer canary routing and zero-message-loss implications.

## Task 1: Audit LINE webhook migration script

Outcome: partial

Preference signals:
- The user explicitly required DB discovery against a whitelist, verification of the new endpoint before changing LINE, LINE API update before DB update, and complete backup/rollback protection. Future reviews should assess the whole operational flow, not just whether the happy-path calls exist.
- The user values concrete production-safety findings with file/line evidence and prefers no edits during review unless explicitly requested.

Key steps:
- Traced `DB query → LINE GET → POST /webhook/test → PUT LINE → GET verify → DB update → rollback`.
- Confirmed URL construction matches `oho-api`: `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed the script’s `POST /webhook/test` before PUT is valid and stronger than the existing connect flow.
- Reviewed related source: `oho-api/src/services/channel/line/line.hooks.js`, validation cron, and `oho-webhook/src/controllers/line/line.controller.ts`.

Failures and how to do differently:
- Original backup was written after `processChannel()` completed, leaving a crash window after LINE/DB mutation but before durable before-state capture. Backup must be persisted atomically before any mutation.
- Rollback used all dry-run backup entries, including channels never migrated. Rollback must be journal/state-based and only include channels that reached a mutation phase.
- Backup omitted DB fields changed by migration and rollback did not restore exact field presence/value. Snapshot every touched field and restore with `$set`/`$unset` semantics.
- `--old-host` semantics did not implement the requirement “move domains outside whitelist”; it only optionally filtered old hosts. Use explicit `--allowed-host` classification and reporting.
- Confirmation token was not bound to the exact candidate manifest/count, allowing scope drift between dry-run and execute.
- Partial failures were printed but did not force a non-zero process exit.
- LINE `success: true` proves the endpoint accepted LINE’s empty test webhook, not that real message processing, Cloud Tasks, and persistence work end-to-end.

Reusable knowledge:
- `oho-api` constructs and strictly validates the endpoint as `${app.get('webhook_endpoint')}/line/webhook/${businessId}`.
- LINE endpoint migration should preserve old service/config until all channels are migrated and monitored.
- LINE webhook test endpoint is rate-limited (60/hour); production concurrency should be conservative.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- Original mutation flow around lines 916–991; original backup capture around 1373–1379; original rollback selection around 1442–1473.
- `oho-api/src/services/channel/line/line.hooks.js:91`, `:237-286`.
- `oho-webhook/src/controllers/line/line.controller.ts:38-76`.

## Task 2: Create implementation-ready hardening plan

Outcome: success

Preference signals:
- The user corrected the scope to “plan only” and specified that `line.register_webhook_at` should not be updated. Future agents should honor scope changes immediately and avoid implementation/delegation without explicit approval.
- The user requested delegation to a specific model, but when unavailable accepted plan-only work instead. Do not silently substitute unavailable models.

Key steps:
- Replaced `plan.md` with a detailed fail-closed implementation plan.
- Locked decisions: explicit whitelist, immutable manifest before mutation, manifest-bound apply, durable journal, exact rollback, timeout/polling, compensation, non-zero exit, tests, and canary validation.
- Explicitly excluded `channels.line.register_webhook_at` from migrate and rollback.
- Verified the plan was written and that the script itself was not edited in that turn.

Reusable knowledge:
- Planned CLI uses `--allowed-host`, dry-run-generated `--manifest`, and manifest-bound `--confirm` for apply/rollback.
- Manifest should include DB/LINE before-state, field-presence markers, candidate IDs, digest, environment, scope, and whitelist; never credentials.
- Apply must revalidate manifest and live state before the first PUT. Rollback must detect conflicts and avoid untouched/dry-run-only entries.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/plan.md`
- Key phrases: `immutable backup manifest`, `line_put_requested`, `rollback_not_needed`, `line.register_webhook_at`, `exit non-zero`.

## Task 3: Review implemented migration hardening

Outcome: uncertain

Key steps:
- Found new files: `migrate-line-webhook.ts`, `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, updated README and plan.
- Verified implementation now includes `--allowed-host`, manifest digest, atomic writes with restricted permissions, journal phases, manifest revalidation, timeouts, and tests asserting `register_webhook_at` is absent from DB payloads.
- The review output was not completed in the captured rollout, so final production readiness was not established.

Failures and how to do differently:
- Tool output was massively truncated during source inspection; future review should inspect focused ranges/functions rather than dumping the whole file.
- Tests and help output were identified but not shown as fully executed in the captured continuation; run focused tests and type validation before declaring success.

References:
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `npm run migrate:line-webhook:help`

## Task 4: GCP load-balancer canary routing

Outcome: partial

Preference signals:
- The user repeatedly asked for exact interpretation of YAML and whether traffic could be lost during updates. Future answers should distinguish routing selection, propagation, backend failure, and fallback behavior explicitly.
- The user wants direct risk statements and does not want unsupported “100% safe” assurances.

Reusable knowledge:
- Priority 1 exact path match takes precedence over Priority 2; Priority 2 is not a fallback after Priority 1 backend failure.
- `defaultService: old` handles unmatched requests only; it does not rescue requests already routed to the new backend.
- A canary such as old 99/new 1 limits blast radius but does not provide zero-loss guarantees.
- GCP documentation indicates URL-map/config changes can take several minutes to propagate; do not assume a globally atomic instant switch.
- Safer initial sequence: keep default old, preserve old backend/NEG, validate YAML, observe both services, canary a small business, and prepare immediate rollback to old 100/new 0.

References:
- Correct YAML nesting requires `routeAction.weightedBackendServices`.
- Business canary path: `/line/webhook/604ee3c35c2d9e573e8e9873`.

## Task 5: Zero-message-loss analysis for Cloud Tasks

Outcome: success

Key steps:
- Inspected `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135` and `oho-webhook/src/controllers/line/line.controller.ts:145-174`.
- Confirmed `createTask` catches/logs errors without rethrowing; controller then records `add_queue_success` and returns HTTP 200.

Failures and how to do differently:
- Current failure path is: Cloud Tasks create fails → error swallowed → controller returns 200 → LINE considers delivery successful → webhook may be lost.
- Fix contract should be: task creation succeeds before 200; on failure record `add_queue_failed` and return 5xx so LINE redelivery can occur.
- Also require webhook-event idempotency using `webhookEventId`, enabled LINE redelivery, terminal-state reconciliation, and monitoring. Absolute zero loss cannot be guaranteed solely by load-balancer configuration or LINE redelivery.

References:
- `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135`
- `oho-webhook/src/controllers/line/line.controller.ts:145-174`
- LINE redelivery is conditional on non-2xx and enabled redelivery; LINE does not guarantee unlimited reliable redelivery.
