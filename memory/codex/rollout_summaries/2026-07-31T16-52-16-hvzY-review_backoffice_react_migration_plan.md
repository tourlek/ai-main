thread_id: 019fb917-4170-7273-a018-fe437807752a
updated_at: 2026-07-31T16:57:58+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T23-52-16-019fb917-4170-7273-a018-fe437807752a.jsonl
cwd: /Users/tualek/ohochat/docs/react-migration

# Read-only review of the oho-backoffice React migration plan

Rollout context: Reviewed `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` in read-only mode, then compared it with the actual `oho-backoffice` repository at `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1`. Scope stayed limited to `oho-backoffice`; other migration documents were consulted only where the backoffice plan explicitly referenced shared cutover assumptions.

## Task 1: Review migration plan against the existing backoffice repo

Outcome: success

Preference signals:
- The user explicitly required “Scope is strictly oho-backoffice only” and “do not edit the plan file or any other files” -> future reviews should remain repository-scoped and read-only.
- The user required findings organized by plan section/phase, with specific references, concrete adjustments, and a prioritized top 3–5 list -> preserve this evidence-first, phase-ordered reporting format.
- The user required critiques grounded in verifiable files and asked not to guess repo structure/tooling -> inspect the actual route, dependency, auth, API, and deployment sources before making claims.

Key findings:
- The plan omitted two production routes present in the real menu and pages: `/external-message-apps` and `/external-message-whitelist` (`store/modules/menu.js:92-103`, corresponding page files). These must be added to route inventory, feature structure, tests, smoke tests, and cutover order.
- The plan’s API examples are not the real contract: it uses `/businesses`, `id`, and simplified `status`, while the repo uses `/backoffice/business`, `_id`, `is_disabled`, `is_deleted`, and many Feathers-style query parameters (`api/endpoint.js`, `pages/business/index.vue`, `pages/business/_id.vue`). Auth similarly uses `/backoffice/authentication-user`, not the plan’s `/authentication`; `auth_created_token_at` is also omitted.
- The auth/cookie migration needs an explicit contract table. Existing cookies are host-only with `{ maxAge }`; the plan proposes `.oho.chat`, `Secure`, and deletion on any bootstrap error. This could broaden token exposure and log users out on transient failures. Preserve cookie names/codec/attributes and remove cookies only for confirmed invalid-session responses such as 401/403.
- The plan introduces `sidebarCollapsed` and `commandPaletteOpen` Zustand state, but repo inspection found no existing command palette or collapsible sidebar. This conflicts with behavior/UI parity and adds unnecessary scope; defer Zustand unless a real shared-state inventory justifies it.
- Route search parameters are incompatible with the legacy URL contract. The plan proposes `q`, `page`, and `status=active|inactive`, while existing menu URLs use `is_disabled`, `is_deleted`, payment status values, and other query fields. Preserve legacy query compatibility during gradual migration.
- Path-based LB routing alone is insufficient because Nuxt links and `$router.push()` perform client-side navigation without a new LB request. A cross-app navigation contract is needed: hard navigation across ownership boundaries, a React/Nuxt route ownership manifest, and forward/back E2E coverage.
- Build/deploy decisions are unresolved too late. Cloud Run is locked while build-per-environment versus build-once runtime configuration is deferred to Phase 5. Decide hosting and runtime configuration in Phase 0 because they affect Dockerfile, nginx, CI, artifact promotion, and rollback.
- Testing is locked conceptually but not operationally. Phase 1 lacks Vitest/RTL/Playwright setup, fixtures, coverage, typecheck/lint/test CI gates, and controlled staging data. Screenshot diffs alone do not verify payment approval, uploads, destructive actions, validation, or error recovery.
- The plan’s `Intl.NumberFormat` replacement lacks parity rules. Existing `numeral` behavior includes integers, fixed two decimals, percentages, compact numbers, currency prefixes, Decimal128 strings, and null handling (`plugins/numeral-format.js`). Define a formatting matrix and golden tests.
- Several cross-cutting items may be inactive in the current app: socket, window-focus, mobile detection, and widget lifecycle calls are commented out in `layouts/default.vue`. Perform an active/dead/removed runtime-liveness audit before porting them.
- The page migration definition of done should use per-route parity matrices covering URL params, reads, writes, validation, uploads/downloads, confirmations, error states, and cross-links—not only generic hooks/forms/manual QA/screenshots.
- Phase 5’s 5–7 day estimate is inconsistent with waiting 2–3 days per path. Concrete exact/nested LB matchers, calendar duration, IaC, rollback drills, and exit criteria are required.
- Monitoring needs browser-side observability: frontend error reporting, release/version/environment tags, source maps, and React-vs-Nuxt dashboards. Cloud/LB metrics and an error boundary alone will miss runtime render, fetch, and chunk-loop failures.
- Cleanup should be gated by explicit evidence: route completeness, SLO/client-error thresholds, rollback drill success, retention window, and preserved legacy artifacts before disabling the Nuxt rollback path.

Failures and how to do differently:
- The plan initially relied on a hand-written route list and missed active external-message pages. Future migration reviews should generate route/menu/page inventories from the repo and compare them with the plan.
- The plan’s generic React examples drifted from the actual API and auth contracts. Future plans should derive examples and DTOs from `api/endpoint.js`, auth actions, and representative page calls before presenting them as blueprints.
- A path-based cutover assumption ignored client-side navigation. Future designs must test navigation from both legacy and React apps and explicitly handle cross-boundary links.

Reusable knowledge:
- Existing backoffice deployment is PM2/Nuxt with six environment configs; production uses Node 14 and PM2, while the plan proposes Node 24 React deployment. Relevant files include `ecosystem*.config.yml`, `package.json`, and `nginx.staging.conf`.
- Actual active dependency usage includes `d3` in `components/Business/Dashboard/LineChartMultipleAxis.vue` and `export-to-csv` in business/deleted-business pages; many listed dependencies require usage audits rather than package.json-only replacement decisions.
- Actual API endpoint registry is in `oho-backoffice/api/endpoint.js`; auth request/token behavior is in `store/index.js` and request authorization is attached in `plugins/axios.js`.

References:
- [1] Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` (611 lines); key sections: locked decisions 14–34, Phase 0 427–435, Phase 1 437–462, Phase 2 464–476, Phase 4 490–522, Phase 5 524–556, risk register 568–581.
- [2] Actual route evidence: `oho-backoffice/store/modules/menu.js:92-103`; `pages/external-message-apps.vue`; `pages/external-message-whitelist.vue`.
- [3] Actual auth/API evidence: `oho-backoffice/api/endpoint.js:3-15,63-74`; `plugins/axios.js:3-45`; `store/index.js:96-166`.
- [4] Actual navigation evidence: `layouts/default.vue:1-18`; `components/Sidenav.vue`; `components/SubMenu.vue:117-131`.
- [5] Final verdict: rework the plan before implementation. Top priorities were complete route/behavior/API inventory, correct auth/cookie contracts, executable cross-app navigation and LB matchers, early hosting/build decisions, and parity testing/observability.
