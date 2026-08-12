thread_id: 019fea86-e89e-79c3-b1e3-68a6504098fc
updated_at: 2026-08-11T03:38:57+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration hardened and reviewed

Rollout context: In `/Users/tualek/ohochat/script-oho`, the user asked whether `migrate-line-webhook.ts` covered a production-safe migration: identify DB endpoints outside a whitelist, verify the new endpoint via LINE, update LINE first, then MongoDB, with complete backup and rollback.

## Task 1: Initial end-to-end audit

Outcome: partial

Preference signals:
- The user explicitly required DB whitelist checking, pre-verification through LINE, LINE API update before DB update, full backup, and rollback protection. Similar operational migrations should be reviewed against the complete failure/recovery flow, not only the happy path.

Key steps:
- Traced the script, `oho-api` LINE connection flow, webhook service route, and LINE API behavior.
- Confirmed URL construction matches first LINE connection: `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed LINE test API is appropriate for endpoint reachability, but real-message canary evidence is still needed.

Failures and how to do differently:
- Original implementation wrote backup after LINE/DB mutation, so a process crash could leave no rollback source.
- `--old-host` filtered hosts to migrate, which did not implement the requested “outside whitelist” semantics.
- Rollback could include dry-run-only entries and did not restore all modified DB fields.
- Confirmation was not bound to the exact candidate set.
- Partial failures did not reliably produce non-zero exit status.
- Verdict was rework before production.

Reusable knowledge:
- Existing `oho-api` flow at `oho-api/src/services/channel/line/line.hooks.js` constructs and registers the endpoint, while `oho-webhook/src/controllers/line/line.controller.ts` exposes `/line/webhook/:businessId` and returns `LINE Home` from `/line`.
- LINE `POST /v2/bot/channel/webhook/test` validates the endpoint and sends an empty-event request; it does not prove the full real-message processing path.

## Task 2: Plan-only hardening

Outcome: success

Preference signals:
- The user corrected the scope to “plan only” and specified that `line.register_webhook_at` should not be updated. Future work should respect plan-only requests and avoid editing implementation until explicitly authorized.

Key steps:
- Updated `migrate-line-webhook-endpoint/plan.md` with explicit whitelist classification, immutable manifest, atomic writes, manifest-bound apply, journaled state transitions, exact rollback, conflict detection, timeouts, exit semantics, tests, and canary rollout.
- Locked the decision that `line.register_webhook_at` is not read for migration logic, written, or restored.

## Task 3: Implementation review and fixes

Outcome: partial

Key steps:
- Implementation added `--allowed-host`, immutable manifest/digest, exact DB field-presence snapshots, atomic restricted files, LINE test → PUT → polling GET → DB update, rollback journals, and non-zero failure handling.
- Initial review found three P0 issues: candidate revalidation blocked resume, no exclusive run lock, and DB journal timestamp was recorded after DB commit.
- Follow-up implementation added state-aware revalidation, exclusive `<manifest>.lock`, `db_update_requested` before Mongo update, and DB commit reconciliation.

Reusable knowledge:
- Current implementation files: `migrate-line-webhook-endpoint/migrate-line-webhook.ts`, `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`, `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`.
- `register_webhook_at` is absent from migration and restore payloads.
- Apply/rollback are manifest-bound and use an exclusive lock; dry-run creates an immutable manifest before mutation.
- Focused tests passed 11/11 and full tests passed 21/21; CLI help also ran successfully.
- No DB, LINE API, gateway, or production canary was executed during review.

Failures and how to do differently:
- Orchestration tests with fake Mongo/LINE adapters remain incomplete; unit tests do not fully prove crash/resume, compensation, concurrent writes, or complete rollback behavior.
- Verdict: suitable for UAT canary, not fully production-approved without real canary evidence.

## Task 4: Production dry-run and execution guidance

Outcome: success

Preference signals:
- The user needed exact, copy-pasteable production commands and was frustrated by duplicated flags and shell placeholders. Provide one command per step, never duplicate `--execute`/`--confirm`, avoid `<placeholder>` in executable commands, and ensure multiline continuations have no trailing spaces.
- The user prefers canarying one channel/business, inspecting the manifest, then applying the exact manifest and testing real messages before broad rollout.

Key steps:
- Production dry-run uses `--env=prod --channel=<id> --allowed-host=api2.oho.chat` or `--all-channels`.
- Real execution must use the generated manifest with exactly one `--execute` and one confirmation token.
- Rollback requires a separate rollback dry-run token, then the same manifest with `--rollback --execute` and that token.
- Confirmed journal interpretation: `rollback_not_needed` can contain detail `would restore ...`; inspect the migration journal to distinguish untouched entries from entries that were actually migrated.

Failures and how to do differently:
- A command failed because `--execute` and `--confirm` were duplicated and `\ ` had a trailing space.
- A rollback command failed because `<rollback-token>` was used literally; zsh interpreted angle brackets as redirection. Use the actual token without angle brackets.

References:
- `npm run test:line-webhook` → 11 passing tests.
- `npm test` → 21 passing tests.
- Production dry-run shape: `npm run migrate:line-webhook -- --env=prod --all-channels --allowed-host=api2.oho.chat`.
- Apply shape: `npm run migrate:line-webhook -- --env=prod --manifest="$MANIFEST" --execute --confirm="$MIGRATE_TOKEN" --yes`.
- Rollback dry-run/apply use the same manifest with `--rollback`; tokens must be obtained from output and substituted literally.
