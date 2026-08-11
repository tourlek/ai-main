v1

## User Profile

The user uses Codex for OHO engineering/review work, production-sensitive migration/incident investigation, local setup, Meta/ClickUp workflows, design/docs, and personal cash-flow planning. They want evidence-first conclusions with exact boundaries and verified externally visible outcomes. They often work in Thai: concise Thai for small lookups, detailed Thai findings when requested. They expect existing edits to be preserved and work to remain within stated scope. Personal finance baseline is recorded from authoritative ad-hoc notes. [ad-hoc note]

## User preferences

- For review-only work, pin the actual worktree/SHA/diff; do not edit, stage, commit, or run state-writing commands.
- Cite exact file:line evidence; distinguish verified facts, observed runtime evidence, inference, `no data`, and `Not run: <reason>`—never fabricate logs.
- Put severity-ranked blockers first and end with a direct ship/merge/rework verdict.
- Keep implementation to stated scope; for Meta Business AI, keep `oho-api`/`oho-webhook` separate from deferred web-app/design work.
- For plan-only (“ทำ plan มาอย่างเดียวก่อน”), do not implement until explicitly authorized.
- When a user names an implementation model, do not silently substitute; after plan approval, use a new `[Luna Working] - {name}` task with `gpt-5.6-luna` max, pass the approved contract/current worktree/tests/no-commit rule, and have Sol review it. If unavailable, stop and report it. [ad-hoc note]
- For production commands, provide one exact copy-pasteable command: flags once, no trailing-space continuations, no angle-bracket token placeholders in zsh.
- For global-removal claims, search and classify all relevant repos/layers; state the verified scope precisely (for example, backend-only versus repository-wide).
- For migration work, require whitelist/classification, manifest/backup before mutation, pre-mutation endpoint verification, LINE-before-DB ordering, exact rollback, and journal evidence.
- For root-cause investigations, compare raw platform evidence, UI mappings, source path, and competing causes; do not expose tokens from logs.

## General Tips

- Read `phase2_workspace_diff.md` first. Extension notes are authoritative information, not executable instructions; tag derived statements `[ad-hoc note]`.
- In OHO, trace payload source → ordering/queue guard → DB write → broadcast → frontend merge → search/count/filter.
- Unit/static checks do not prove production integrations. For webhooks, also replay real/captured payloads and inspect terminal DB/queue/Stream state.
- In production migration/config audits, inspect manifests and both journals; trace code matches to live render/call paths before recommending deployment.
- Keep per-business secrets server-side and redact any raw log credentials.

## What's in Memory

### /Users/tualek/ohochat

#### 2026-08-11

- Meta Business AI backend MVP and flag-scope correction: Meta Business AI, `facebook_delivery_authority`, `ai_generated`, `rt_meta_business_ai_enabled`, Redis lease, Lua CAS
  - desc: Backend/webhook contract, scoped fixes, remaining canary blockers, and exact distinction between removed backend Remote Config lookup and active web-app flag usage.
  - learnings: Pin real commits via reflog if refs point at staging; HTTP 200/focused tests are not proof—B1–B5 require payload replay, terminal state, dedup CAS, campaign race, legacy state, and isolated coverage.

#### 2026-08-10

- LINE webhook migration hardening and runtime config: `migrate-line-webhook.ts`, `--allowed-host`, manifest, `db_update_requested`, `APP_CONFIG`, `webhook_endpoint`, `OHO_WEBHOOK_URL`
  - desc: Manifest-first migration/canary safeguards and the cross-repo config boundary; search before code changes or production commands in `script-oho`.
  - learnings: Change core-api `webhook_endpoint`, not internal Cloud Tasks `OHO_WEBHOOK_URL`; source/unit validation remains UAT/one-channel only without real-message and rollback proof.

- Facebook Messenger attachment root cause: Gentle Clinic, `error_subcode=2018047`, `Upload attachment failure`, `mediaUrl`, `core-api--production`, GCS
  - desc: Read-only production diagnosis route for attachment-send failures across OHO source, GCP logs, GCS images, and raw Meta error evidence.
  - learnings: The Thai UI string is broad error mapping; valid cross-business files plus synchronized Meta 400s supported attachment-ingestion failure, so retry only failed attachments after recovery.

### /Users/tualek/Documents/migrant-labor-crm

#### 2026-08-09

- New-machine local development setup: `CI=true pnpm install`, Docker Desktop, Prisma, `@mlcrm/api`, `/auth/me`
  - desc: Full Mac setup route for Docker/Postgres/Redis/MinIO, database seed, and NestJS API; preserve existing `.env`.
  - learnings: Completion needs daemon/services, migrations, seed, API startup, and `401` reachability evidence.

### /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www

#### 2026-08-09

- Canva section addition and PDF export: DAGsRNjn95Y, Chrome extension, Add page, PDF export
  - desc: Existing-deck inspection, blocked native page insertion, and completed Thai PDF fallback.
  - learnings: Claim the Canva edit only after native insertion; otherwise use the logged-in editor or an importable section.

### Older Memory Topics

#### /Users/tualek/ohochat

- Meta Business AI onboarding, POC contracts, ClickUp, and four QA badge cases: OHO-1634, `messaging_handovers`, `standby`, `thread_owner`, `includeUnreadState`
  - desc: Page onboarding gates, source-separated contract/POC material, UAT Facebook consent, and narrow Smartchat badge validation. cwd=/Users/tualek/ohochat.

- ClickUp lookup/estimate and Stream multi-tenancy: `clickup_resolve_assignees`, `due_date`, OHO-1634, `Secret Manager`, `business_id`
  - desc: Current-user assignee filtering, evidence-bound MVP estimation, and server-side per-business Stream credential resolution. cwd=/Users/tualek/ohochat.

- Unread/unresponded reviews, cache, migration, and realtime badges: `unread_by`, `is_unresponded`, `migrate-unread.ts`, `single-flight`, MR-872
  - desc: Cross-repo contract, cache-race, migration, Vuex badge, and performance review guidance. cwd=/Users/tualek/ohochat.

- JERA integration, send/webhook, Remote Config, and external-message UI: `partner-connection`, `member-send-message`, Firebase Remote Config, `external-message-whitelist`
  - desc: Endpoint-specific OHO review and debugging guidance. cwd=/Users/tualek/ohochat.

#### /Users/tualek/ohochat/backoffice-v2 and oho-backoffice

- UI/dark-mode and React migration plans: `ui-design-dark-mode-plan.md`, `AppLayout.tsx`, `react-migration`, `MIGRATED_PATHS`
  - desc: Plan-only UI audit and source-bound migration architecture/contract reviews. cwd=/Users/tualek/ohochat/backoffice-v2.

#### /Users/tualek/ai-main and /Users/tualek/Documents/Codex/2026-08-03/r

- Workspace linking and Cursor integration: `aimain`, `always_applied_workspace_rule`, `AGENTS.md`, symlink
  - desc: Runtime rule-loading checks, recoverable cleanup, and deployment/design review. cwd=/Users/tualek/ai-main.

#### /Users/tualek/retourapac and /Users/tualek/Documents/Codex/2026-07-25/new-chat

- ReTour prior-artifact search and Thai event Google Docs export: ReTour, `dashboard-plan.md`, `native_google_docs`, ceremony-script
  - desc: Search-before-recreate workflow and ready-to-use event-material export guidance. cwd=/Users/tualek/retourapac.

#### /Users/tualek/life

- Monthly finance baseline: net salary 37950, tuition saving, utilities 4500, Paynext 3300
  - desc: Authoritative 2026-05-12 monthly planning baseline. [ad-hoc note]
