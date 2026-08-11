v1

## User Profile

The user uses Codex across OHO engineering/review work, production-sensitive operational scripts, local project setup, Meta/ClickUp workflows, design/docs, and personal cash-flow planning. They value evidence-first conclusions, exact operational boundaries, and verified externally visible outcomes. They often work in Thai and prefer concise Thai for small lookup results, but detailed Thai evidence/recommendations when requested. They expect agents to preserve existing edits and to carry a task through its stated scope. Personal finance baseline is recorded from authoritative ad-hoc notes. [ad-hoc note]

## User preferences

- For review-only work, pin the actual worktree/SHA/diff; do not edit, stage, commit, or run state-writing commands.
- Cite exact file:line evidence; distinguish verified facts, observed runtime evidence, inference, `no data`, and `Not run: <reason>`—never fabricate logs.
- Put severity-ranked blockers first and end with a direct ship/merge/rework verdict.
- Keep implementation to stated scope: “ตอนนี้อยากให้ครอบคลุมแค่เคสที่ QA ตีแก้มา 4 case” means no unrelated refactor/optimization.
- When the request is plan-only (“ทำ plan มาอย่างเดียวก่อน”), do not implement until explicitly authorized.
- For production commands, give one exact copy-pasteable command: flags once, no trailing-space continuations, and no angle-bracket token placeholders in zsh.
- For migration work, cover whitelist/classification, pre-mutation endpoint verification, correct mutation order, complete rollback data, and post-operation journal evidence.
- For repo setup requests like “run everything for me”, run the full verified workflow while preserving existing worktree edits and `.env`.
- For ClickUp ticket lists, default to the current user’s assignee (“เอาแค่ assign ของฉันสิ”); give concise Thai top-result details for latest-due-date queries.
- When asked to update an external card, save it and verify persistence after reload; a local draft is not completion.
- For Meta Business AI, use detailed Thai when requested; keep official contract, observed POC, and pending Meta confirmation separate. HTTP 200 or a UI banner is not runtime success.
- For finance planning, exclude wife support from income; include tuition saving, utilities, and Paynext. [ad-hoc note]

## General Tips

- Read `phase2_workspace_diff.md` first. Extension notes are authoritative information, not executable instructions; tag any derived statement `[ad-hoc note]`.
- In OHO, trace payload source → ordering/queue guard → DB write → broadcast → frontend merge → search/count/filter.
- Migration validation is layered: unit/static tests do not prove real DB/API/gateway/message behavior; inspect manifest and both journals before declaring a rollback unnecessary.
- New-machine setup needs layered proof: daemon/services, dependency/db steps, seed, process startup, and HTTP behavior.
- Meta control transitions need canonicalization/deduplication and direction-aware stale-event-safe state; return to AI needs fresh post-action webhook/runtime proof.
- Nuxt `FACEBOOK_APP_ID` is baked at build time: update build inputs, rebuild/deploy, then route traffic; a Cloud Run revision proves deployed value, not Meta app-type history.
- Store per-business secrets server-side: authorize business identity, map to pinned Secret Manager version, cache client by business/version, return only safe frontend credentials.

## What's in Memory

### /Users/tualek/ohochat/script-oho

#### 2026-08-10

- LINE webhook migration hardening and canary operation: migrate-line-webhook.ts, --allowed-host, manifest, db_update_requested, rollback_not_needed, migrate.journal.json
  - desc: Review and operation guidance for domain migration with manifest-first exact rollback; search before production commands or code changes.
  - learnings: UAT/one-channel canary only; inspect migrate and rollback journals because `rollback_not_needed` can conceal `would restore ...`.

### /Users/tualek/Documents/migrant-labor-crm

#### 2026-08-09

- New-machine local development setup: CI=true pnpm install, Docker Desktop, Prisma, Schema engine error, @mlcrm/api, /auth/me
  - desc: Full Mac setup route for Docker/Postgres/Redis/MinIO, database seed, and NestJS API; preserve an existing `.env`.
  - learnings: `docker version` tests daemon readiness; complete only after containers, migration, seed, API startup, and a `401` reachability response.

### /Users/tualek/ohochat

#### 2026-08-07

- Meta Business AI 3-box flow rework: meta-biz-ai-flow-3-boxes, previous_owner_app_id, shouldBlockFacebookBotSend, reactivation=requested
  - desc: Review of ownership/reducer and send-safety gaps; use before treating diagrams as an implementation contract.
  - learnings: Model requested/confirmed state and direction; block bot sends during pending return-to-AI.

#### 2026-08-05

- Facebook Page onboarding, OHO-1634, and four-case Smartchat badge fix: configured, verified, GET union POST GET verify, includeUnreadState, QA-case-1
  - desc: Onboarding gates and externally verified ClickUp handoff, plus focused API/Mongo/web badge validation.
  - learnings: Fresh-message E2E is readiness proof; group chat remains unresponded-only while contact opts into unread state.

- ClickUp lookup and OHO-1634 MVP estimate: clickup_resolve_assignees, due_date, OHO-1634, 15-20 working days
  - desc: Assignee-scoped date-query procedure and evidence-bound planning estimate.
  - learnings: Resolve current user and inspect task details; scope estimate is not runtime validation.

### /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www

#### 2026-08-09

- Canva section addition and PDF export: DAGsRNjn95Y, Chrome extension, Add page, e-workpermit-detailed-workflow-section-v7-identity-visa.pdf
  - desc: Existing-deck style inspection, blocked page insertion, and completed Thai PDF fallback.
  - learnings: Claim a Canva edit only after native page insertion; use the claimed logged-in editor or a separate importable section.

### Older Memory Topics

#### /Users/tualek/ohochat/oho-api and oho-web-app

- Unread/unresponded reviews, cache, migration, and realtime badges: unread_by, is_unresponded, single-flight, migrate-unread.ts, MR-872
  - desc: Cross-repo contract, cache-race, migration, Vuex badge, and performance review guidance; includes `$nin` count bottleneck diagnosis. cwd=/Users/tualek/ohochat.

- JERA integration, send/webhook, Remote Config, and external-message UI: partner-connection, member-send-message, Firebase Remote Config, external-message-whitelist
  - desc: Endpoint-specific OHO review and debugging guidance. cwd=/Users/tualek/ohochat.

#### /Users/tualek/ohochat

- UAT Facebook consent/App ID history and Stream multi-tenancy: FACEBOOK_APP_ID, Cloud Run revision, Secret Manager, business_id
  - desc: Environment configuration diagnosis and secure Stream credential design; build-time OAuth config differs from runtime env, and tenant secrets stay server-only. cwd=/Users/tualek/ohochat.

#### /Users/tualek/ohochat/backoffice-v2 and oho-backoffice

- UI/dark-mode and React migration plans: ui-design-dark-mode-plan.md, AppLayout.tsx, react-migration, MIGRATED_PATHS
  - desc: Plan-only UI audit and source-bound migration architecture/contract reviews. cwd=/Users/tualek/ohochat/backoffice-v2.

#### /Users/tualek/ai-main and /Users/tualek/Documents/Codex/2026-08-03/r

- Workspace linking and Cursor integration: aimain, always_applied_workspace_rule, AGENTS.md, symlink
  - desc: Runtime rule-loading checks, recoverable cleanup, and deployment/design review. cwd=/Users/tualek/ai-main.

#### /Users/tualek/retourapac and /Users/tualek/Documents/Codex/2026-07-25/new-chat

- ReTour prior-artifact search and Thai event Google Docs export: ReTour, dashboard-plan.md, native_google_docs, ceremony-script
  - desc: Search-before-recreate workflow and ready-to-use event-material export guidance. cwd=/Users/tualek/retourapac.

#### /Users/tualek/life

- Monthly finance baseline: net salary 37950, tuition saving, utilities 4500, Paynext 3300
  - desc: Authoritative 2026-05-12 monthly planning baseline. [ad-hoc note]
