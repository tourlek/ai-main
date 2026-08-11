thread_id: 019fea86-e89e-79c3-b1e3-68a6504098fc
updated_at: 2026-08-10T11:07:05+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration hardening and production canary review

Rollout context: In `/Users/tualek/ohochat/script-oho`, the user asked whether `migrate-line-webhook.ts` safely migrates LINE webhook domains based on a DB whitelist, verifies the new endpoint through LINE, updates LINE then MongoDB, and supports complete backup/rollback. The work evolved through review, an implementation-ready plan, subsequent fixes, production dry-run, one-channel apply/rollback operations, and command troubleshooting.

## Task 1: Audit the original migration script

Outcome: fail

Preference signals:

- The user explicitly required: check DB domains against a whitelist, verify the new endpoint before changing LINE, update LINE before DB, and “backup ไว้ทั้งหมด” so rollback is possible. Similar migrations should be reviewed against the complete operational sequence, not just whether the happy-path API calls exist.
- The user expects evidence-first review with concrete file/line findings and no premature edits.

Key steps:

- Traced the script and the real `oho-api` LINE connection flow. URL construction matches `${webhook_endpoint}/line/webhook/${businessId}`.
- Confirmed the original flow had test → PUT LINE → DB update, but backup was persisted only after `processChannel()` completed.
- Identified that `--old-host` filtered hosts to migrate, while the requirement was to migrate DB endpoints whose domains are outside an explicit whitelist.

Failures and how to do differently:

- Original backup could be absent if the process died after LINE/DB mutation, and failed/partial entries could be omitted from rollback data.
- Rollback could act on dry-run-only entries and did not restore all mutated DB fields exactly.
- Confirmation was not bound to the exact candidate set.
- Original script reported failures but could still exit successfully.
- Verdict was rework before production.

Reusable knowledge:

- `oho-api/src/services/channel/line/line.hooks.js:237-286` performs the existing LINE PUT then GET verification and builds the expected URL.
- `oho-webhook/src/controllers/line/line.controller.ts:30-45` exposes `/webhook/:businessId` and returns HTTP 200 for empty LINE verification events.
- LINE’s `POST /v2/bot/channel/webhook/test` validates the endpoint and sends a test webhook, but does not prove full real-message processing.

## Task 2: Plan and harden the implementation

Outcome: partial

Preference signals:

- The user corrected the scope to plan-only: “ไม่ต้องงั้นนายทำ plan มาอย่างเดียวก่อน” -> when asked for a plan, do not implement until explicitly authorized.
- The user specified that `line.register_webhook_at` should not be updated -> preserve that field unchanged in both migration and rollback.
- The user asked for sub-agent delegation, but accepted the available-model limitation and then chose plan-only. Do not silently substitute an unavailable model.

Key steps:

- Replaced `plan.md` with a fail-closed implementation plan covering explicit `--allowed-host`, immutable manifest, atomic writes, manifest-bound apply, per-channel journal, exact rollback, conflict detection, timeouts, exit semantics, tests, and canary rollout.
- Later implementation added `migrate-line-webhook.helpers.ts`, helper tests, manifest-first flow, lock file, state-aware revalidation, and `db_update_requested` journal intent before Mongo commit.
- `register_webhook_at` is absent from migration/restore payloads.

Reusable knowledge:

- CLI now uses `--allowed-host=<hostname>` rather than the old reversed-semantics `--old-host`.
- Production apply must use the reviewed manifest: `--manifest=<path> --execute --confirm=<token> --yes`; apply does not rebuild the candidate set.
- Manifest stores exact field presence for endpoint, validity, active state, and `updated_at`; rollback uses `$set`/`$unset` to restore presence exactly.
- Apply/rollback use an exclusive `<manifest>.lock` and journal phases including `line_put_requested`, `db_update_requested`, `db_updated`, `migrated`, and compensation/conflict states.
- Focused tests passed 11/11; full repository tests passed 21/21; CLI help ran successfully. No real DB/LINE/gateway integration test was performed before the canary.

Failures and how to do differently:

- The implementation initially had three P0 issues: revalidation rejected resumed candidates, no concurrent-run lock, and a crash window after DB commit but before journaling. These were subsequently addressed in source and verified statically/unit-wise.
- Remaining limitation: orchestration tests with fake Mongo/LINE adapters are still missing, so production readiness was not fully proven. Verdict was suitable for UAT canary, not blanket production rollout.

References:

- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/plan.md`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- Verification: `npm run test:line-webhook` → 11 passed; `npm test` → 21 passed.

## Task 3: Production dry-run, one-channel apply, and rollback operations

Outcome: partial

Preference signals:

- The user wants copy-pasteable commands and became frustrated when a command duplicated flags. Future production commands should be emitted as one clean command, with no placeholders or repeated flags.
- Do not use angle-bracket placeholders in shell commands when the user asks for an exact command; zsh interprets `<token>` as redirection.
- After a canary, the user wants a concrete rollback command and confirmation of what the journal means.

Key steps:

- Production dry-run was correctly proposed with `--env=prod`, a channel selector, and `--allowed-host=api2.oho.chat`; dry-run reads Mongo/LINE and writes only local manifest/journal files.
- A one-channel manifest was applied using the manifest-bound confirmation token.
- The migrate journal recorded channel `6a794f77fc9340171589accf` as `migrated` with a durable `dbUpdatedAt` marker.
- Rollback dry-run output misleadingly labeled the entry `rollback_not_needed` while its detail said `would restore ...`; inspection of the migrate journal established that the channel had in fact migrated and required rollback.
- A later one-channel manifest was created for `6a794f77fc9340171589accf`, with apply command generated from the provided manifest and token.

Failures and how to do differently:

- The user’s failed command duplicated `--execute` and `--confirm`, and used `\ ` with a trailing space, breaking shell continuation. Always validate command text for duplicate flags and avoid multiline continuation unless necessary.
- Rollback summary semantics are confusing: `rollback_not_needed` can mean “dry-run would restore” rather than untouched. Inspect the rollback and migrate journals before claiming no rollback is needed; this should be fixed in future implementation.
- The rollout contains real production identifiers and URLs; do not repeat secrets/tokens in memory.

References:

- Dry-run pattern: `npm run migrate:line-webhook -- --env=prod --channel=<id> --allowed-host=api2.oho.chat`
- Apply pattern: `npm run migrate:line-webhook -- --env=prod --manifest=<manifest-path> --execute --confirm=<token> --yes`
- Rollback pattern: `npm run migrate:line-webhook -- --env=prod --manifest=<manifest-path> --rollback --execute --confirm=<rollback-token> --yes`
- Journal evidence: migrate phase was `migrated`; rollback dry-run detail was `would restore https://webhook.oho.chat/...` despite summary phase `rollback_not_needed`.

## Task 4: Final review status

Outcome: uncertain

Reusable knowledge:

- Static review confirmed the three prior P0 fixes and all tests passed, but no final user confirmation of the last production command’s result appears in the rollout.
- Safe status at the end: source fixes reviewed; UAT/one-channel canary workflow available; production-wide rollout should wait for real-message, queue, terminal-processing, and rollback verification.
