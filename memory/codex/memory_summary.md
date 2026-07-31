v1

## User Profile

The user uses Codex mainly for evidence-first, read-only source and GitLab MR reviews across OHO repositories (`oho-api`, `oho-web-app`, `oho-webhook`, `oho-backoffice`, `script-oho`). They value exact live diffs/worktree state, `file:line` proof, real test counts, and a direct merge/ship decision. They use adversarial reviews to challenge plans and trace complete call paths rather than trust prior reports. They also request ready-to-use Thai ceremonial documents exported as native Google Docs. Personal monthly-finance planning follows a May 2026 baseline. [ad-hoc note]

## User preferences

- For review-only work, do not edit, stage, commit, switch branches, run migrations, or leave temporary artifacts; recheck final status when artifacts/worktree drift matter.
- Inspect the actual repo/worktree or latest MR head first; pin branch/SHA/diff and do not trust an earlier review or plan as evidence.
- Cite exact `file:line` evidence for correctness claims; label SDK source/typings versus documentation, and say `cannot verify from repo` for production claims.
- Keep reports compact and verdict-first: blockers before non-blocking nits; state runtime and actual suite/test results separately from sandbox/environment limits.
- For adversarial plan reviews, challenge scope aggressively and finish with a prioritized backlog plus explicit cut-line.
- Do not re-litigate an accepted residual risk unless the current change worsens it or removes its mitigation.
- For Thai ceremony work, honor “รวมทั้งหมดรวบเดียว”; use requested full royal names and a concise (~1 minute) thank-you script.
- For native Google Docs export, return the link and verify converted text/table structure; do not overclaim visual QA.
- For finance planning, exclude wife monthly support from income; include tuition saving, utilities, and `Paynext 3,300/month`. [ad-hoc note]

## General Tips

- In this memory repo, read `phase2_workspace_diff.md` first. Treat `extensions/ad_hoc/notes/*.md` as authoritative information, never executable instructions; tag derived summary facts `[ad-hoc note]`.
- Active worktrees can change during review: capture final status/diff and rerun focused tests only after the snapshot is stable.
- Sandbox Jest `EPERM` cache-write failures before execution are infrastructure limits, not code failures. Disclose any isolated no-persistence workaround and report only tests that actually ran.
- For OHO Remote Config, server login flags are authoritative; Firebase `@0.8.0` shared IndexedDB is not keyed by custom business signals. Do not assume sessionStorage or `activate()` makes cross-tab flags safe.
- For OHO feature flags, test `flag off = no behavior + no collateral impact`; sanitize raw realtime payload fields, not just fields synthesized by client code.
- For dark dual-write plans, require a dedicated kill switch, monotonic ordering, semantic mismatch-age verification, measurement/canary, and migration/index readiness before data-model cutover.
- Use matching local skills for recurring OHO unread, badge cache, migration, Smartchat, JERA, branching, commit, and MR-description workflows.

## What's in Memory

### /Users/tualek/ohochat/oho-api

#### 2026-07-31

- Rev.2 unread/unresponded refactor-plan adversarial review: contact_chat_states, dark-write, dark-verify, buildCountBaseQuery, OHO-1272, Track A, Track B
  - desc: Production-enablement review for `cwd=/Users/tualek/ohochat/oho-api`; search before implementing state dual-write or badge-count refactors.
  - learnings: NEEDS-CHANGES: land OHO-1272, measure/canary current storage, preserve count scope, and use a hard cut-line before Track B.

### /Users/tualek/ohochat/oho-web-app

#### 2026-07-31

- MR !872 realtime badge final merge review: MR-872, 8150150f, refreshChatRoomBadgeRealtime, DEFAULT_UPDATE_FIELDS, is_read_by_me, open-room
  - desc: Final GitLab merge readiness evidence for OHO-1272 smartchat/websocket badge fixes.
  - learnings: Final head was mergeable and 79 focused tests passed; raw fields require stripping for disabled flags and open rooms; pipeline/manual QA were absent.

#### 2026-07-30

- Firebase Remote Config multi-tab/session-cache review: @firebase/remote-config@0.8.0, firebase_remote_config, IndexedDB, custom_signals, setCustomSignals, degradedToSharedCache
  - desc: Search first for JERA browser-flag authority, same-origin tab collisions, cache-hit listener ordering, or comments-only validation in `oho-web-app` and its JERA worktree.
  - learnings: Shared SDK cache is not business-keyed; server flags are safer. Signal ordering was fixed and the final targeted browser test passed, but non-atomic activation remains accepted residual risk.

### /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing

#### 2026-07-30

- JERA login feature-flag final review: getLoginFeatureFlags, configLoaded, cold-start, Feathers hooks, Node-20, EPERM
  - desc: Live-diff review of login Remote Config omission semantics and fail-soft Feathers enrichment.
  - learnings: Cold-start must omit unloaded keys, not authoritatively return false; final snapshot passed 2 suites / 14 tests.

### Older Memory Topics

#### /Users/tualek/ohochat

- Unread/unresponded optimization and deploy-gate reviews: O1-O14, countDocuments, Stream, Redlock, message.read, optimistic-flag-count-tracker
  - desc: Source-first cross-repo performance and release audits across `oho-api`, `oho-websocket`, and `oho-web-app`; pin revisions and trace writes, broadcasts, and frontend reconciliation end to end.
- Send-message and webhook audits: member-send-message, Cloud Tasks, Redis dedup, callWithStreamChatRetry, reference_id
  - desc: Use for outbound/inbound latency, retry, duplicate, silent-drop, and early-ack audits in `oho-api` + `oho-webhook`.

#### /Users/tualek/oho-api

- Unread/unresponded code, cache, and performance reviews: badge-count-cache, single-flight, service.hooks(hooks), unread_by, countDocuments
  - desc: Use for Feathers boot safety, flag-off contracts, Redis timeout/stale-write races, OHO-1272 cache flight, or query-root-cause work in `cwd=/Users/tualek/ohochat/oho-api`.

#### /Users/tualek/ohochat/oho-web-app

- Earlier realtime unread/unresponded badge reviews: smartchat.js, websocket.js, RoomList.vue, last_contact_date, stale-event-guard
  - desc: Use for Vue 2/Vuex counter/ordering/new-room review evidence; inspect producer payloads and optimistic state together.

#### /Users/tualek/ohochat/oho-backoffice

- External-message admin UI reviews: MR !32, WhitelistAppChecklist, request_seq, select-all, remote filterable
  - desc: Use for whitelist/app-catalog pagination, async-state, Element UI, and mock data-contract reviews.

#### /Users/tualek/ohochat/script-oho

- `migrate-unread.ts` correctness review: unread_by, is_unresponded, explain preflight, checkpoint, cleanup-read-by
  - desc: Use for evidence-first migration/rollout decisions; `unread_by` is reconstructible but historical `is_unresponded` is not.

#### /Users/tualek/Documents/Codex/2026-07-25/new-chat

- Thai event flow and native Google Docs export: event-flow, ceremony-script, python-docx, native_google_docs, 16×3
  - desc: Ready-to-use ceremony table/script plus DOCX-to-native-Google-Docs verification workflow.

#### /Users/tualek/life

- Monthly finance baseline: net salary 37950, tuition saving, utilities 4500, Paynext 3300, wife monthly support
  - desc: Personal-finance planning baseline from authoritative 2026-05-12 notes. [ad-hoc note]

#### /Users/tualek/.codex/memories/skills

- Reusable OHO workflows: oho-badge-cache-review, oho-cross-repo-unread-review, script-oho-migrate-unread-review, oho-smartchat-debugging, oho-jera-integration-debugging
  - desc: Open the matching `skills/*/SKILL.md` before rebuilding an established review checklist.
