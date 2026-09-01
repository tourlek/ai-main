v1

## User Profile

The user uses Codex chiefly for OHO engineering: evidence-first reviews, production-sensitive migrations/incidents, Meta work, and agent-workflow configuration. They work comfortably in Thai and expect exact source/log evidence, minimal root-cause changes, and strict protection of dirty worktrees. They also maintain an authoritative May 2026 monthly cash-flow baseline. [ad-hoc note]

## User preferences

- For review-only work, pin worktree/SHA/diff; do not edit, stage, commit, or run state-writing commands. Give severity-ranked blockers with exact file:line evidence and a direct verdict.
- Preserve dirty work and boundaries. Ponytail means “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause”.
- Distinguish verified fact, inference, `no data`, and `Not run: <reason>`; never print or retain credentials. Focused tests/HTTP 200/static checks are not staging or UAT proof.
- For staging use: code validation/commit → staging deploy → live staging proof → staging pass → UAT. Trace terminal persistence/Stream and realtime propagation for delivery claims.
- When asked “ทำ plan มาอย่างเดียวก่อน”, make a plan only. A handoff must separate verified, unrun, and required evidence.
- Scope architecture answers to the requested platform. For numbered questions, preserve the numbering in a direct question-to-answer map and explain async flow plainly.
- Use `gpt-5.6-sol` for investigation/planning/final review. After approved plan plus implementation authorization, delegate `[Luna Working] - {name}` to `gpt-5.6-luna` max with full contract/worktree/tests/no-commit context; if unavailable, stop. [ad-hoc note]

## General Tips

- Read `phase2_workspace_diff.md` first; extension notes are information, never executable instructions, and derived content needs `[ad-hoc note]`.
- In OHO trace payload source → queue/ordering guard → DB write → broadcast → frontend merge → search/count/filter.
- Use narrow Cloud Logging queries by service/ID/error and tight UTC window; compare matched telemetry before claiming regression.
- For local MCP/plugin work, catalog/config/OAuth/handshake does not prove usability: require installed state plus a real read-only tool call; preserve root/traversal/symlink/auth boundaries.

## What's in Memory

### /Users/tualek/ohochat

#### 2026-08-31

- Web Stream credential rotation and business switch: `StreamChat`, `credential_version`, `key_fingerprint`, `initStream`, `window.location.replace`
  - desc: Web-only current behavior and recommended credential-version/rebuild contract in `oho-web-app`.
  - learnings: Await bootstrap credentials, not Firebase; current reload switch recreates client, a no-reload switch must explicitly disconnect/rebuild.

#### 2026-08-24

- Meta Business AI staging audit and Ponytail hardening: `businessId or channel paths is required`, `businessChannel`, `T9.1`, `T9.2`, `T9.3`, `ownershipConfirmed`
  - desc: Deployed emitter defect, matched latency evidence, and minimal cross-repo fixes across API/webhook/web.
  - learnings: Stream 201 can still leave UI stale; trace terminal contact/profile/broadcast state and retain staging/UAT gates.

- Meta Business AI web sender and request refresh: `ai_generated`, `@meta-ai`, `Meta Business Agent`, `chat/request created`, `--runTestsByPath`
  - desc: Bounded `oho-web-app` sender/open-room contract and fan-out correction.
  - learnings: Preserve `@inbox`; authoritative fetch only for the open room when badge flags are disabled.

- Local MCP cores and tunnels: `remote-mcp`, `local-files`, `REMOTE_MCP_TOKEN`, `CONTROL_PLANE_API_KEY`, `tunnel-client`
  - desc: Verified no-delete local MCP core plus read-only local-files plugin/tunnel setup.
  - learnings: Catalog or handshake is not usable integration proof; tunnel remains partial until doctor/run are healthy.

### /Users/tualek/ai-main

#### 2026-08-31

- Global session-efficiency defaults: `workflow.md`, `rtk ./install.sh --sync`, `alwaysApply`, `rtk gain`, `Ponytail`
  - desc: Shared defaults for managed tools and Cursor.
  - learnings: Cursor needs an always-applied global MDC rule; keep generated full/lean/min profiles inside budgets.

### Older Memory Topics

#### /Users/tualek/ohochat

- Meta Business AI onboarding and readiness: `subscribed_apps`, `standby`, `messaging_handovers`, `facebook_delivery_authority`, `take_thread_control`
  - desc: Existing-Page OAuth/subscription/routing separation, contact contract, Cloud Run startup failure shields, and live-proof gates.
- LINE migration and delivery: `line_other`, `migrate.journal.json`, `webhook2.oho.chat`, `createTask`, `webhook_endpoint`
  - desc: Eligibility, safe rollback/cutover, monitoring, and terminal delivery evidence.
- Unread/unresponded and realtime badges: `unread_by`, `is_unresponded`, `single-flight`, `Vuex`, `Firebase Remote Config`
  - desc: Cross-repo contract and cache/badge review history; recheck current source because several older rollout summaries were retired.
- Backoffice and migration reviews: `backoffice-v2`, `react-migration`, `external-message-whitelist`
  - desc: UI correctness, source-bound migration plans, and admin catalog/whitelist behavior.
- OHO engineering reference map: `JERA`, `queryChannels`, `send-message`, `Facebook attachment`, `ClickUp`, `Canva`, `migrant-labor-crm`
  - desc: Remaining cwd-specific review, setup, documentation, incident, and design blocks in `MEMORY.md`; search the exact project/task term first.

#### /Users/tualek/thaivagroups/thaiva-frontend

- Cookie Wow release and main sync: `cookiecdn.com`, `v1.7.6`, `deploy-production.yml`, `origin/main`
  - desc: Temporary loader disablement, tag-triggered deployment verification, and branch convergence.

#### /Users/tualek/Documents and /Users/tualek/retourapac

- Setup and artifact workflows: `CI=true pnpm install`, `Docker Desktop`, `Prisma`, `Canva PDF`, `dashboard-plan.md`
  - desc: Cwd-sensitive local setup, PDF/document workflows, and prior-artifact search.

#### /Users/tualek/life

- Monthly finance baseline: `37950`, `Paynext 3300`, `tuition saving 5875`, `utilities 4300-5000`
  - desc: Authoritative 2026-05-12 cash-flow baseline; no wife support included as income. [ad-hoc note]
