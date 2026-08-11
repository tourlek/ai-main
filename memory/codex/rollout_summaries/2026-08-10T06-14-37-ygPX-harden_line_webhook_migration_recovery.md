thread_id: 019fea4f-0f09-7031-a11f-8b18c23fcf85
updated_at: 2026-08-10T07:28:25+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T13-14-37-019fea4f-0f09-7031-a11f-8b18c23fcf85.jsonl
cwd: /Users/tualek/ohochat

# Hardened LINE webhook migration and verified recovery behavior

Rollout context: In `/Users/tualek/ohochat/script-oho`, the user wanted the LINE webhook migration hardened for production, with `line.register_webhook_at` left unchanged. They first requested a plan-only pass, then requested implementation of remaining review issues.

## Task 1: Review and harden LINE webhook migration

Outcome: partial

Preference signals:
- The user explicitly said “plan มาอย่างเดียวก่อน” after delegation was unavailable, indicating they prefer a concrete implementation plan before code changes when scope is complex.
- The user clarified that `register_webhook_at` “อาจจะไม่ต้องอัปเดต” and accepted a plan that never changes it; future migration work should preserve this field unless explicitly requested.
- The user asked the agent to implement the remaining review issues after an evidence-based audit, indicating they value iterative review → fix → re-review rather than an unverified one-shot implementation.

Key steps:
- Audited the existing flow against the requirement: DB inventory → backup → LINE test → LINE PUT → verification → DB update → rollback.
- Identified and fixed three P0 issues: resume revalidation rejected already-migrated entries; concurrent applies could compensate each other; DB commit could occur before its journal marker was persisted.
- Added a further reconciliation path for Mongo write-response timeouts and completed-entry LINE/DB drift verification.
- Added helper regression tests and updated README/plan documentation.

Failures and how to do differently:
- The initial implementation wrote backup after mutation and treated dry-run entries as rollback candidates; future migrations must create an immutable manifest before any mutation and journal actual mutation phases.
- The initial revalidation rebuilt candidates from current DB hostname state, which removed already-migrated entries and re-added LINE-unavailable cases; revalidate each manifest entry against before-state or journal-backed target-state instead.
- A DB update marker written after `updateOne()` left a crash window; persist `db_update_requested` with planned `updated_at` before the write, then reconcile ambiguous responses from live DB state.
- No real DB, LINE API, or gateway integration run was performed, so production readiness remains unverified.

Reusable knowledge:
- The migration now uses explicit `--allowed-host`, immutable manifest files with digest and exact DB field-presence snapshots, manifest-bound confirmation tokens, atomic `0600` JSON writes, per-channel journals, bounded LINE request retries/timeouts, and an exclusive `<manifest>.lock`.
- Migration DB updates touch only `line.webhook_endpoint`, `line.is_webhook_endpoint_valid`, `line.is_webhook_active`, and `updated_at`; `line.register_webhook_at` is intentionally never written or restored.
- Apply order is test endpoint → PUT LINE → poll GET confirmation → journal DB intent → conditional Mongo update → final LINE/DB verification.
- Rollback is intended to restore exact values/presence with `$set`/`$unset`, skip untouched dry-run-only entries, detect conflicts, and exit non-zero on unresolved failures.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- `npm run test:line-webhook` → 11/11 passed
- `npm test` → 21/21 passed
- TypeScript check with Node16/ES2022 options → no errors
- `npm run migrate:line-webhook:help` → passed
- `git diff --check` → passed
- No DB query, LINE API call, gateway smoke, production canary, or commit was performed.
