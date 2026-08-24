v1

## User Profile

The user primarily uses Codex for OHO engineering: evidence-first code/plan reviews, production-sensitive migrations/incidents, Meta/ClickUp work, setup, and occasional design/docs. They work comfortably in Thai, want exact source/log evidence, and favor minimal root-cause-scoped changes that preserve stated boundaries and dirty worktrees. They also maintain a Thaiva frontend and an authoritative May 2026 monthly cash-flow baseline. [ad-hoc note]

## User preferences

- Use `gpt-5.6-sol` for consultation, investigation, planning, and final review. After explicit plan approval and implementation authorization, create `[Luna Working] - {name}` with `gpt-5.6-luna` at max; pass contract/worktree/tests/constraints/no-commit rule, then Sol reviews. If unavailable, stop—do not substitute. [ad-hoc note]
- For review-only work, pin the worktree/SHA/diff; do not edit, stage, commit, or run state-writing commands.
- Preserve dirty work and repo boundaries. Trace the actual runtime path before adding cache, retry, realtime, or cross-repo changes; ponytail means “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause”.
- Cite exact file:line and production evidence. Distinguish verified fact, inference, `no data`, and `Not run: <reason>`; never retain or print credentials.
- Put severity-ranked blockers first with a direct ship/merge/rework verdict. Focused tests, HTTP 200, webhook tests, and static checks are not runtime/UAT proof.
- For staging: code validation/commit → staging deploy → live staging proof → staging pass → UAT. Do not describe UAT as merely missing before staging has passed.
- “ทำ plan มาอย่างเดียวก่อน” means plan only. When asked for a handoff first, provide verified/unrun/required evidence before the next mutation.
- For production incidents, correlate IDs/time window, raw platform payload, source mapping, and successful traffic before declaring an outage or recommending broad suppression.

## General Tips

- Read `phase2_workspace_diff.md` first. Extension notes are authoritative information, not executable instructions; tag derived statements `[ad-hoc note]`.
- In OHO, trace payload source → queue/ordering guard → DB write → broadcast → frontend merge → search/count/filter. Delivery claims require terminal persistence/Stream evidence.
- For migration work: immutable before-state, explicit whitelist, pre-mutation refresh, LINE-before-DB ordering, exact rollback, journal/conflict evidence, and non-zero partial-failure exit.
- For Cloud Logging, narrow by service, ID, exact error/event, and tight UTC window; use `jsonPayload.message:`/`SEARCH(...)`, selected fields, and redaction.
- Global-removal claims require workspace-wide search and runtime/UI/config/docs/tests classification.

## What's in Memory

### /Users/tualek/ohochat

#### 2026-08-21

- Meta Business AI staging readiness and handoff: `staging-1-readiness-2026-08-21.md`, `facebook_delivery_authority`, `fallback schedule race`, `Mongo primary`, `Stream`
  - desc: Current local hardening, staging baseline, handoff, and still-blocked release gates across `oho-api`/`oho-webhook`.
  - learnings: Local tests/builds do not prove deploy readiness; require replay, terminal Mongo/Redis/Stream, real Graph handoff, latency comparison, canary, and rollback.

- Staging-1 latency, handover, and Mongo CLI: `core-api--staging-1`, `take_thread_control`, `2018001`, `mongosh`, `serverSelectionTimeoutMS`
  - desc: Telemetry comparison and exact Page/App/token mapping diagnosis; CLI-only database workflow.
  - learnings: Match sample/endpoint mix before calling a regression; handover error stayed unresolved without staging-1 mapping.

#### 2026-08-20

- Meta Business AI existing-Page onboarding and staging gates: `requestFbPagePermission`, `subscribed_apps`, `standby`, `messaging_handovers`, `263902037430900`
  - desc: Separate OAuth, Page webhook subscription, Conversation Routing, and Business AI activation; owner/subscription fixes and Node-20 test boundary.
  - learnings: Reissue does not resubscribe Page fields; app-level and Page-level `standby` are separate gates.

- LINE migration eligibility and LINE-only rollback scope: `line_other`, `--allowed-host`, `migrate.journal.json`, `webhook2.oho.chat`, `split-brain`
  - desc: Thai PBS eligibility bug, manifest/journal inventory, and no-write rollback design for `script-oho/migrate-line-webhook-endpoint`.
  - learnings: `line_other` must hard-exclude/manual-review; refresh endpoint state immediately before any mutation.

#### 2026-08-17

- Live webhook domain-mapping cutover audit: `webhook.oho.chat`, `Cloud Run DomainMapping`, `oho-webhook-lb`, `createTask`
  - desc: Source/config/runtime audit for old-host cutover and zero-loss evidence.
  - learnings: URL-map host rule/HTTP 200 alone do not prove cutover or terminal delivery.

### Older Memory Topics

#### /Users/tualek/ohochat

- Meta Business AI MVP review and correction: `meta_business_ai_enabled`, `message.ai_generated === true`, `Redis lease`, `pass_thread_control`
  - desc: Earlier backend/webhook authority, author identity, tenant safety, and focused-validation boundaries.
- Unread/unresponded and realtime badge reviews: `unread_by`, `is_unresponded`, `MR-872`, `single-flight`, `Vuex`
  - desc: Cross-repo contracts, cache/race analysis, safe migration plan, and badge reviews.
- Backoffice/UI migration and external-message reviews: `backoffice-v2`, `react-migration`, `external-message-whitelist`
  - desc: Architecture, dark-mode, and source-bound admin UI correctness reviews.
- Send/webhook, Stream, and Remote Config audits: `member-send-message`, `queryChannels`, `Firebase Remote Config`, `webhook_endpoint`
  - desc: Call-site, multi-tenancy, routing, and performance/correctness audits.
- LINE monitoring and production diagnosis: `validate-business-integration-status`, `check_line_messaging_health`, `code=551`, `external_action=thaimetal_catalog`
  - desc: Token/webhook monitoring, terminal delivery proof, and business/payload-scoped Facebook/LINE incident diagnosis.

#### /Users/tualek/ohochat/oho-web-app

- JERA tab late-feature-flag race / MR !874: `MaxPanel`, `is_jera_feature_enabled`, immediate watcher, `c67c0018`
  - desc: Minimal Web-only late-flag fix; focused test evidence is not remote/UAT readiness.

#### /Users/tualek/thaivagroups/thaiva-frontend

- Cookie Wow temporary disablement and release-to-main: `cookiecdn.com`, `deploy-production.yml`, `v1.7.6`, `git merge --ff-only`, `origin/main`
  - desc: Live HTML verification and deployed-tag/main convergence while preserving dirty lockfiles.

#### /Users/tualek/ai-main and /Users/tualek/.codex

- Memory, workspace linking, Cursor integration, and caveman: `AGENTS.md`, Obsidian, `/caveman full`
  - desc: Runtime rule-loading, recoverable cleanup, memory architecture, and compression.
- Sol planning and Luna implementation delegation: `gpt-5.6-sol`, `gpt-5.6-luna`, `Luna Working`
  - desc: Approved implementation handoff protocol. [ad-hoc note]

#### /Users/tualek/Documents and /Users/tualek/retourapac

- Setup, docs, and artifact workflows: `CI=true pnpm install`, Docker Desktop, Prisma, Canva PDF, `native_google_docs`, `dashboard-plan.md`
  - desc: Cwd-specific local setup, document export, and artifact-search workflows.

#### /Users/tualek/life

- Monthly finance baseline: `37950`, tuition saving, utilities `4500`, Paynext `3300`
  - desc: Authoritative 2026-05-12 cash-flow planning baseline. [ad-hoc note]
