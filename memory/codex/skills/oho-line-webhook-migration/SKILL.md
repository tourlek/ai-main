---
name: oho-line-webhook-migration
description: Review or operate OHO's LINE webhook domain migration when the user asks for whitelist selection, manifest safety, rollback, or a production canary command.
argument-hint: "[review | dry-run | apply | rollback] [channel or manifest]"
disable-model-invocation: true
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO LINE Webhook Migration

## When to Use

Use for `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts` and related LINE endpoint domain migrations: audit, plan-only work, a dry-run, manifest-bound apply, rollback, or canary verification.

Do not use it to mutate production unless the user explicitly authorizes that operation. Do not treat unit tests or LINE's webhook test as end-to-end message proof.

## Inputs and Context to Gather

1. Confirm scope: review/plan-only versus an authorized production step; identify one channel/business or all channels.
2. Read the current CLI/help, migration source/helpers/specs, `plan.md`, and the current `oho-api` URL construction.
3. For operations, locate the reviewed manifest and both `<manifest>.migrate.journal.json` and `<manifest>.rollback.journal.json`; never reconstruct candidates during apply. If the request is LINE-only rollback, stop: the existing rollback also writes Mongo and is not authorized for that scope.
4. Confirm the current allowed hostname and that `line.register_webhook_at` is outside all migration/rollback payloads.

## Procedure

1. Audit safety before proposing an operation: classify DB endpoints outside explicit `--allowed-host`, require an immutable atomic before-state manifest, confirmation bound to its digest, exclusive `<manifest>.lock`, non-zero partial-failure exit, and exact `$set`/`$unset` rollback.
2. Verify ordering: LINE test reachability → LINE PUT → poll GET verification → conditional Mongo update. The expected endpoint is `${webhook_endpoint}/line/webhook/${businessId}`.
3. For a dry-run, use one channel first when possible:
   `npm run migrate:line-webhook -- --env=prod --channel="$CHANNEL_ID" --allowed-host=api2.oho.chat`
4. Inspect the manifest before apply. Apply only it:
   `npm run migrate:line-webhook -- --env=prod --manifest="$MANIFEST" --execute --confirm="$MIGRATE_TOKEN" --yes`
5. Before rollback, run its rollback dry-run to obtain the separate token, inspect both journals, then use the same manifest with `--rollback --execute --confirm="$ROLLBACK_TOKEN" --yes`.
   - This command is only for the normal LINE-plus-Mongo rollback contract. Do not adapt it for LINE-only rollback.
6. After a canary, send a real LINE message and verify `LineBotWebhook/2.0` ingress, Cloud Task creation/attempts, `source-messages` terminal `sync_message_success`, and the real OHO message before any broad rollout. Exclude the operator's test traffic when assessing historical production usage.

## Efficiency Plan

- Start with `rg -n "allowed-host|old-host|register_webhook_at|db_update_requested|rollback_not_needed|manifest" migrate-line-webhook-endpoint`.
- Reuse the manifest and journals as the source of truth; do not redo broad repo searches unless the URL/config path changed.
- Stop immediately on missing manifest, conflicting journal state, failed verification, or unauthorized mutation scope.

## Pitfalls and Fixes

- Symptom: `--old-host` selects the wrong candidate set. Fix: use explicit `--allowed-host` whitelist classification.
- Symptom: crash/partial run lacks rollback truth. Fix: persist the immutable before-state manifest before mutation and journal `db_update_requested` before Mongo commit.
- Symptom: `rollback_not_needed` hides a migrated entry. Fix: read its detail plus both journals; `would restore ...` in dry-run is not proof it was untouched.
- Symptom: user requests a LINE-only rollback. Cause: the existing rollback writes Mongo after LINE PUT, so it cannot preserve the requested DB state. Fix: do not run it; require a separate, tested fail-closed workflow with durable before-state, JIT LINE/Mongo refresh, serial LINE PUT, GET verification, conflict stop, and compensation/reconciliation.
- Symptom: zsh command breaks or reports `Flag --confirm given more than once`. Fix: one single-line command, each flag exactly once, actual quoted variable values—never literal angle-bracket tokens or a trailing-space continuation.
- Symptom: certificate, URL-map routing, or `add_queue_success` is treated as delivery proof. Cause: each observes only part of the chain; a swallowed `createTask()` failure can still return HTTP 200. Fix: revert to old `100`/new `0` on queue-create failure, non-OK task attempt, `sync_message_fail`, `dropped`, stuck `inprogress`, or canary 5xx/timeout.

## Verification Checklist

- Current source still excludes `line.register_webhook_at` from migration and restore payloads.
- Manifest, digest confirmation, lock, and exact snapshots are present before mutation.
- LINE-before-DB ordering and non-zero partial-failure behavior are verified from code/current tests.
- Both journals agree on the selected channel state before any rollback claim.
- Focused/full test results are reported separately from a real-message, queue, terminal-state, and rollback canary result.
- Historical-use claims exclude manual/operator test events.
