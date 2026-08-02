# Task Group: /Users/tualek/ohochat/backoffice-v2 / React migration architecture review
scope: Time-boxed, read-only architecture review of the migrated React admin app; use before scaling multi-person feature work, not as a legacy parity audit.
applies_to: cwd=/Users/tualek/ohochat/backoffice-v2; reuse_rule=reuse the sampling and boundary checks for this React checkout, but do not treat its snapshot findings as a current Git state and honor an explicit time-box or stated baseline results.

## Task 1: Review feature-based architecture and scale readiness; viable structure, fix boundary enforcement before multi-person development

### rollout_summary_files

- rollout_summaries/2026-08-01T15-20-59-jg2H-react_backoffice_architecture_review.md (cwd=/Users/tualek/ohochat/backoffice-v2, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T22-20-59-019fbdea-0a3f-7ed2-a3b3-fddd0046094f.jsonl, updated_at=2026-08-01T15:23:11+00:00, thread_id=019fbdea-0a3f-7ed2-a3b3-fddd0046094f, time-boxed sample; fix-then-ship)

### keywords

- backoffice-v2, react-migration, feature-based, ChannelTable, PaymentDialog, query-keys, shared/lib, shared/utils, barrels, circular-dependency, eslint.config.js

## User preferences

- when the user says “TIME-BOX ... อย่า audit ทุกไฟล์” and “ตอบ 5 ข้อ สั้นๆ ตรงประเด็น ห้ามเขียนยาว” -> use targeted sampling, preserve the five requested answers, and do not rerun stated baseline checks unless needed to answer the review. [Task 1]
- when legacy is reference only for design parity while backend/URL contracts “ห้ามเปลี่ยน” and old quirks may change only if recorded -> separate architectural findings from parity/contract assumptions. [Task 1]

## Reusable knowledge

- The feature-based structure is suitable for this admin CRUD app: routes are thin, pages use hooks, API I/O is separate, and pure domain logic lives in `lib`; it does not need a folder-level rewrite. [Task 1]
- Convention is clear: `shared/lib` is I/O/external-bound code, `shared/utils` is pure functions, and features use `lib/` rather than a second `utils/` directory. [Task 1]
- Sampled boundary violations: `ChannelTable.tsx:123-133` and `PaymentDialog.tsx:131-151` call `useQuery`/raw APIs from render components. Before the team scales, move that I/O into hooks, choose one query-key-factory location, reduce 258/232-line public barrels, and add CI checks for cycles plus relative cross-feature imports. [Task 1]
- Alias-path ESLint rules enforce barrel imports but miss `../../other-feature/...`; `business` composes JERA, payment, and sales-order, so reverse imports are a practical circular-dependency risk. [Task 1]

## Failures and how to do differently

- Symptom: layer enforcement looks complete because the folder layout and ESLint exist. Cause: the rules miss relative cross-feature imports and components can still import feature API directly. Fix/pivot: sample actual call paths and search components for direct `features/*/api` use before approving scale readiness. [Task 1]
- Symptom: Git status/log is used as architecture-review proof in this snapshot. Cause: the cwd is not a Git repository. Fix/pivot: rely on sampled source evidence and disclose that stated test/lint/typecheck/format/build results (696 tests) were not rerun within the time-box. [Task 1]

# Task Group: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing / JERA login feature-flag read-only review
scope: Read-only review of the uncommitted JERA login Remote Config feature-flag diff, including comments-only scope checks, cold-start semantics, Feathers hook behavior, and targeted Node 20 Jest validation.
applies_to: cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing; reuse_rule=reuse the review protocol for similar `oho-api` JERA login feature-flag changes, but treat the verified implementation, diff hash, test counts, and branch state as checkout-specific and re-inspect the live tracked and untracked diff.

## Task 1: Review comments-only cleanup then final JERA login feature-flag diff; final verdict no ship-blocking issues

### rollout_summary_files

- rollout_summaries/2026-07-30T09-25-01-qjNc-final_read_only_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-25-02-019fb257-6da8-7681-aa63-4c62263ee116.jsonl, updated_at=2026-07-30T09:33:14+00:00, thread_id=019fb257-6da8-7681-aa63-4c62263ee116, final live-diff review: 2 suites / 14 tests passed; no ship blockers)
- rollout_summaries/2026-07-30T09-13-25-kdFe-review_comment_cleanup_jera_tab.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-25-019fb24c-cc6f-7c03-b144-34394eac4620.jsonl, updated_at=2026-07-30T09:22:45+00:00, thread_id=019fb24c-cc6f-7c03-b144-34394eac4620, earlier review found comments-only scope drift and worktree movement)
- rollout_summaries/2026-07-30T09-05-06-mY16-oho_api_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-06-019fb245-30e8-7533-a6c3-ba67f1a607a4.jsonl, updated_at=2026-07-30T09:14:18+00:00, thread_id=019fb245-30e8-7533-a6c3-ba67f1a607a4, earlier live review: cold-start P1 was closed; 13 targeted tests passed)
- rollout_summaries/2026-07-30T08-42-56-lECv-oho_api_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-42-56-019fb230-e359-7f60-893d-3467569eb66b.jsonl, updated_at=2026-07-30T08:50:25+00:00, thread_id=019fb230-e359-7f60-893d-3467569eb66b, initial review found the cold-start authoritative-false blocker later fixed)

### keywords

- JERA, git diff, read-only-review, comments-only, firebase-remote-config, getLoginFeatureFlags, configLoaded, cold-start, TTL-boundary, addFeatureFlagsToResult, Feathers-hooks, isJeraFeatureEnabled, Jest, Node-20, EPERM, worktree-drift

## Task 2: Cross-repo JERA tab race-fix review; API hook wiring and fail-soft behavior initially blocked ship

### rollout_summary_files

- rollout_summaries/2026-07-30T06-47-30-iE0E-cross_repo_jera_tab_fix_review_ship_blockers.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T13-47-30-019fb1c7-36c8-7a02-92cc-6ab6c74fcc58.jsonl, updated_at=2026-07-30T06:56:14+00:00, thread_id=019fb1c7-36c8-7a02-92cc-6ab6c74fcc58, earlier live diff; API blockers were later fixed)

### keywords

- JERA, MaxPanel, feature_flags, Firebase Remote Config, service.hooks(hooks), addFeatureFlagsToResult, Promise.all, contact_id, immediate, Vuex, EPERM

## User preferences

- when the user says “Review-only (do not edit files, read-only)” or requires removal of any temporary symlink -> do not edit, stage, commit, or leave filesystem artifacts; confirm final `git status`. [Task 1]
- when the user says to run `git diff` yourself and not trust a prior-round summary -> independently inspect the live tracked and untracked diff, line-numbered final files, whole-repo dead references, and every claimed fix; pin final status/diff when the worktree is active. [Task 1]
- when the user asks for an explicit verdict, exact `file:line` evidence, and real pass/fail counts -> lead with ship blockers or `NONE FOUND`, keep numbered answers concise, and separate non-blocking nits and environment limits from code failures. [Task 1]
- when the user asks whether removed `e70f8a8a` contact-change refetch behavior was reintroduced -> trace the current watcher/call paths, not merely matching text; judge each watcher test by whether reverting production code would still pass. [Task 2]

## Reusable knowledge

- For the JERA login contract, presence of `feature_flags` is authoritative client-side. A cold start or Remote Config outage must omit unloaded keys, not return confidently false values: failed fetch leaves `cachedTemplate` null, `getBooleanWithState()` returns `configLoaded: false`, and `getLoginFeatureFlags()` excludes those entries. [Task 1]
- `getLoginFeatureFlags()` evaluates the four flags as `[key, usesBusinessSignal]` pairs and reuses the same key for Remote Config evaluation and returned object names (`src/firebase-remote-config.js:147-175`). `addFeatureFlagsToResult` is auxiliary/fail-soft: it catches/logs Remote Config errors, leaves `feature_flags` unset, and returns the login context. [Task 1]
- Independent `Date.now()` calls in `getCachedServerTemplate()` can straddle a TTL boundary; partial `configLoaded` output is possible. The regression test must control the relevant calls rather than assert all checks always resolve together. [Task 1]
- The final review found zero `isJeraFeatureEnabled` references; the hook module exports only Feathers lifecycle keys. Under Node `v20.20.2`, both targeted specs passed: 2 suites, 14 tests, 0 failures; `git diff --check` was clean. [Task 1]
- `service.hooks(hooks)` treats every enumerable top-level export as a hook namespace. A helper such as `addFeatureFlagsToResult` exported alongside `before/after/error` makes Feathers reject service registration; test the registration path, not just a directly imported helper. Feature-flag enrichment is auxiliary: per-flag rejection must fail soft rather than let `Promise.all` abort login. [Task 2]
- MaxPanel's reactive `immediate: true` flag watcher covers initial and late `false → true`; focus retry should require flag enabled, no active fetch, and prior error. Direct watcher-handler tests cover branches but not Vuex reactivity, visibility propagation, or concurrent triggers. [Task 2]

## Failures and how to do differently

- Symptom: a requested comments-only cleanup appears behaviorally equivalent. Cause: executable tuple/consumer changes or test behavior were bundled with comment edits. Fix/pivot: compare normalized code/AST as well as prose, flag executable scope drift, then stabilize the worktree and retest the exact final snapshot. [Task 1]
- Symptom: a TTL comment says all four checks “always resolve configLoaded together.” Cause: independent clock reads can cross the TTL boundary. Fix/pivot: retain partial-loading semantics and test them deterministically; use named timing constants and avoid depending on private array order. [Task 1]
- Symptom: Jest fails with `EPERM` before tests execute. Cause: the restricted sandbox blocks haste/transform cache writes. Fix/pivot: report an environment limitation rather than a code failure; use a narrowly isolated cache-write workaround only when necessary and disclose it. [Task 1]
- Symptom: server cold-start default false becomes API-authoritative and browser true is later filtered out. Cause: overwrite protection also suppresses recovery. Fix/pivot: omit unloaded flags rather than asserting false; verify both precedence and transient-failure recovery. [Task 2]

# Task Group: /Users/tualek/ohochat/oho-backoffice / Nuxt-to-React migration-plan review
scope: Evidence-first, read-only review of the Backoffice React v2 plan; use to verify parity, inventory, URL/state, navigation cutover, and execution-contract claims before migration work.
applies_to: cwd=/Users/tualek/ohochat/oho-backoffice with plan=/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md; reuse_rule=reuse the review checklist for revisions of this plan, but pin the live SHA and respect any explicit time/file limits before expanding the audit.

## Task 1: Round-2 audit of the revised plan; evidence gathering found stale inventory and unresolved contracts but did not complete the required verdict

### rollout_summary_files

- rollout_summaries/2026-07-31T17-56-21-UeF9-round_2_react_migration_plan_review_partial.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-56-21-019fb951-ea5f-7483-bc82-456377b2d2df.jsonl, updated_at=2026-07-31T18:07:44+00:00, thread_id=019fb951-ea5f-7483-bc82-456377b2d2df, incomplete requested 18-item audit)

### keywords

- react-migration, Nuxt2, React 19, sha-mismatch, 2f01fc94, 27d67415, active-menu, Zod passthrough, TanStack Router, MIGRATED_PATHS, Element UI, v-clipboard

## Task 2: Time-boxed plan review; no Phase 0 blocker, but resolve state/navigation, observability, and cutover contradictions before implementation

### rollout_summary_files

- rollout_summaries/2026-07-31T18-36-00-Lk1s-backoffice_react_v2_plan_time_boxed_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T01-36-00-019fb976-370c-7e03-b35f-7520e84e70a2.jsonl, updated_at=2026-07-31T18:37:38+00:00, thread_id=019fb976-370c-7e03-b35f-7520e84e70a2, scoped five-file review; NEEDS-FIX before implementation)

### keywords

- shadcn, Radix, visual parity, bizActiveTab, /business/$id?tab=API, Sentry, GCP Error Reporting, raw location.search, refetchOnWindowFocus, cutover

## Task 3: Round-2 revised-plan audit found a material baseline mismatch, unowned shared state, and omitted contracts; rollout ended without a verdict

### rollout_summary_files

- rollout_summaries/2026-07-31T17-45-44-dIut-round_2_backoffice_react_migration_plan_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-45-44-019fb948-34df-78c3-acf3-404943218769.jsonl, updated_at=2026-07-31T17:55:34+00:00, thread_id=019fb948-34df-78c3-acf3-404943218769, incomplete adversarial review; not an approval)

### keywords

- react-migration, 2f01fc94, v1.62.0, 27d6741, external-message-apps, store/modules/dashboard.js, x-jera-api-key, query-string serialization, jquery, export-to-csv

## User preferences

- when the user requires “SHA check result first,” all 18 pass/fail fixes, labeled scrutiny answers a-e, and a final verdict -> follow that exact order and finish synthesis; do not stop after evidence collection. [Task 1]
- when the user says “อ่านเฉพาะไฟล์ ... ห้าม re-audit repo ... ทั้งหมด” with an 8-minute limit -> honor the narrow scope, answer five numbered points concisely, and state `APPROVE`/`NEEDS-FIX`. [Task 2]
- when React migration is locked and “visual parity” plus a settled stack are non-negotiable -> test compliance and unresolved contracts rather than reopening the strategic choice. [Task 1][Task 2]
- when the user explicitly required a read-only review, full plan reading first, source-grounded `file:line` evidence, scrutiny answers, and a plain final verdict -> keep the review read-only, distinguish claims from verification, and put the verdict at both top and bottom. [Task 3]

## Reusable knowledge

- Pin the SHA before treating a plan inventory as verified: the live `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1` differed from the plan's `27d674...` baseline; live inventory was 35 components, not 34, and `v-clipboard` was stale because callers use `navigator.clipboard.writeText`. [Task 1]
- Raw query-string active-menu matching is not automatically preserved by Zod passthrough/TanStack Router normalization. Either retain raw `location.search` (removing only `page`) for legacy matching or use canonical order-independent comparison, with reordered/unknown-key tests. [Task 1][Task 2]
- `MIGRATED_PATHS` must cover every internal link and programmatic navigation, including child-path flips. Endpoint constants are not a request-contract inventory; audit method + path + query + body at call sites. [Task 1]
- shadcn copy-in source/Radix primitives can support visual parity, but Element UI's tables, date range/sidebar, upload, select, dialog, pagination, and loading behavior need bespoke wrappers plus screenshot/interaction gates. The 15–25 engineer-day design estimate was an unvalidated review estimate, not measured evidence. [Task 1][Task 2]
- Resolve the direct contracts before implementation: `bizActiveTab` URL contradiction, Sentry versus GCP Error Reporting, incomplete/dynamic navigation inventory, cookie/restricted-role/GCP validation, and the unsettled query refetch behavior. [Task 1][Task 2]
- The `27d6741` baseline predates the two external-message pages: regenerate the plan inventory at live `2f01fc94`/`v1.62.0` instead of accepting “12 routes verified @ baseline.” Current source had 12 page routes and 35 Vue components. [Task 3]
- State ownership is not settled while `store/modules/dashboard.js` values (`time_period`, `channels`, `checked_channels`) and cross-route `business`, `partners`, and `api_keys` caches have no final homes. Include `/external-message-apps` mutations and JERA full-sync POST with `x-jera-api-key` in the contract/E2E inventory. [Task 3]
- Element theme CSS is about 500 KB; shadcn/Radix visual parity is a substantive design-system effort. Treat the 2–4 engineer-week core re-skin estimate as approximate and make staffing/parallelism plus a design-system contingency explicit. [Task 3]

## Failures and how to do differently

- Symptom: a detailed review has strong findings but no usable decision. Cause: time was consumed collecting evidence and the requested pass/fail list, scrutiny answers, and verdict were not synthesized. Fix/pivot: reserve time for the exact deliverable and distinguish bounded review from a full audit. [Task 1]
- Symptom: an external recommendation or effort estimate is treated as a repository fact. Cause: exploratory research/proposal replaced source evidence. Fix/pivot: cite plan section plus live file:line for acceptance claims and label estimates approximate. [Task 1][Task 2]
- Symptom: a revision changelog or baseline claim is accepted as verification. Cause: live SHA/tree, imports, state consumers, and network calls were not compared. Fix/pivot: verify each against source; reserve enough time for the requested claim table and final APPROVE/rejection verdict. [Task 3]

# Task Group: /Users/tualek/ohochat/oho-web-app / Firebase Remote Config multi-tab and session-cache review
scope: Read-only design and live-diff review of web Firebase Remote Config business flags, shared SDK storage, session-cache isolation, and listener ordering; use for JERA/browser flag authority or per-tab cache changes.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app and /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing; reuse_rule=reuse the source-inspection and cache-safety rules for this SDK/version family, but re-check installed SDK behavior, the current worktree, and whether server login flags remain authoritative.

## Task 1: Analyze same-origin multi-tab Remote Config cache collision; browser fetch path was not safe to mirror from mobile

### rollout_summary_files

- rollout_summaries/2026-07-30T08-10-45-wXG9-firebase_remote_config_multitab_race_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-10-45-019fb213-6e6a-7ca2-9032-29a514b9a891.jsonl, updated_at=2026-07-30T08:16:29+00:00, thread_id=019fb213-6e6a-7ca2-9032-29a514b9a891, source-grounded multi-tab design verdict)

### keywords

- Firebase Remote Config, @firebase/remote-config@0.8.0, firebase_remote_config, IndexedDB, custom_signals, last_successful_fetch_response, minimumFetchIntervalMillis, onConfigUpdate, custom signals, multi-tab, feature_flags_api_keys, JERA

## Task 2: Iterate cache-hit signal ordering and comments-only review; final targeted browser test passed

### rollout_summary_files

- rollout_summaries/2026-07-30T09-13-04-OoVw-firebase_remote_config_comment_trimming_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-04-019fb24c-796b-7f70-87ac-e3cbecc0fb7e.jsonl, updated_at=2026-07-30T09:21:40+00:00, thread_id=019fb24c-796b-7f70-87ac-e3cbecc0fb7e, AST-identical comment trim; 1 suite / 9 tests passed)
- rollout_summaries/2026-07-30T09-07-45-YIjD-firebase_remote_config_cache_hit_rereview.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-07-45-019fb247-9cdc-76a3-a098-2b88906c3dc1.jsonl, updated_at=2026-07-30T09:16:07+00:00, thread_id=019fb247-9cdc-76a3-a098-2b88906c3dc1, final signal-ordering review; 9 tests passed)
- rollout_summaries/2026-07-30T09-05-32-HGYT-firebase_remote_config_review_partial_jest_blocked.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-32-019fb245-9645-7471-8e1c-d06b902e573f.jsonl, updated_at=2026-07-30T09:07:28+00:00, thread_id=019fb245-9645-7471-8e1c-d06b902e573f, partial re-review superseded by the successful final run)
- rollout_summaries/2026-07-30T08-47-57-M3ng-firebase_remote_config_tab_cache_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-47-57-019fb235-7d01-7910-8c06-037d382b4d1e.jsonl, updated_at=2026-07-30T08:56:35+00:00, thread_id=019fb235-7d01-7910-8c06-037d382b4d1e, earlier review found cross-tab blockers; signal-ordering fix later verified)

### keywords

- plugins/firebase-remote-config.js, sessionStorage, business_id, setCustomSignals, invocationCallOrder, onConfigUpdate, activate, degradedToSharedCache, Accepted residual risk, executable AST identical, Jest, NODE_PATH, EPERM

## User preferences

- when the user requires “Design consultation only. Do NOT modify any files” or “Review-only” -> keep the checkout strictly read-only and do not stage, commit, or leave dependency artifacts. [Task 1][Task 2]
- when the user demands every SDK claim be actual source/typings or documented-architecture reasoning, with a direct verdict in a fixed order -> inspect installed SDK paths/typings, label source versus documentation, and give the concrete recommendation rather than generic pros/cons. [Task 1]
- when the user says accepted risks are not to be re-litigated -> distinguish accepted residual risk from a regression; re-raise it only if current code worsens it or loses a mitigation. [Task 2]

## Reusable knowledge

- In installed `@firebase/remote-config@0.8.0`, IndexedDB `firebase_remote_config` records are keyed by app/name/namespace/record key, not custom-signal values. `active_config`, `last_successful_fetch_response`, and `custom_signals` are shared per app/namespace; timestamp-only freshness permits a tab for business A to use a recently evaluated business-B blob. [Task 1]
- API bootstrap is the primary authority: login supplies evaluated flags and Vuex records API keys as authoritative, filtering later browser Remote Config values via `feature_flags_api_keys`. The safer design recommendation was to remove automatic browser initialization/custom-signal/fetch/activate fallback after rollout verification, while retaining synchronous getters, E2E overrides, API bootstrap, and fail-closed defaults. [Task 1]
- Do not port Flutter's interval reset: `clearRemoteConfigCache()` sets `Duration.zero`, fetches, and never restores the initial 12-hour interval. `onConfigUpdate` exists in JS typings/runtime but uses cache age zero and still shares storage, so it does not create business isolation. [Task 1]
- For the reviewed per-tab session cache, await `setCustomSignals()` before every cache-hit return or listener registration; the final test asserts its `invocationCallOrder` before `onConfigUpdate`. `sessionStorage` is tab-scoped, but it cannot make a shared SDK response safe by itself. [Task 2]
- `fetchAndActivate()` / `activate()` are non-atomic against shared IndexedDB response writes, and SDK signal-storage failures are swallowed. Preserve the documented `degradedToSharedCache` boundary and never label a cache business-safe merely because activation returned successfully. [Task 2]
- A true comments-only check should compare executable AST/normalized code. The final cleanup had `executable AST identical=true`; inspect untracked tests with `git diff --no-index /dev/null test/plugins/firebase-remote-config.spec.js`. [Task 2]

## Failures and how to do differently

- Symptom: a cache hit or real-time callback stores wrong-business flags under the current `business_id`. Cause: listener registration/fetch used previously persisted shared custom signals, or `activate()` reread another tab's shared response. Fix/pivot: establish current signals before every listener/cache branch, treat successful fetch/activation as insufficient proof of business isolation, and prefer server-authoritative flags. [Task 1][Task 2]
- Symptom: direct Jest fails before collection with temp haste/transform `EPERM`. Cause: restricted sandbox cache/coverage writes. Fix/pivot: report infrastructure separately; when allowed, use main-checkout dependencies via `NODE_PATH` and suppress persistence only, then report the actual executed suite/test count. [Task 2]
- Symptom: a “comments-only” cleanup hides behavior changes or a requested `git diff` omits a new test. Cause: HEAD includes earlier implementation and untracked files are excluded. Fix/pivot: use AST comparison for the claimed cleanup and `git diff --no-index` for untracked files. [Task 2]

# Task Group: /Users/tualek/ohochat / unread-unresponded optimization report verification
scope: Read-only, source-first verification of an unread/unresponded performance report across `oho-api` and `oho-web-app`; use when a report proposes query, cache, socket, or Vuex optimization and every verdict must be independently line-cited.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app with /Users/tualek/ohochat/oho-api; reuse_rule=reuse the review protocol for similar cross-repo performance-report audits, but re-inspect the live files and exact revision before treating these source-only findings or proposal verdicts as current.

## Task 1: Verify unread/unresponded optimization report against live API and web code; partial claim confirmation, NO-SHIP as-is

### rollout_summary_files

- rollout_summaries/2026-07-29T11-58-23-dnwJ-unread_unresponded_report_verification_request.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-58-23-019fadbd-7acb-76b2-8d60-108475540831.jsonl, updated_at=2026-07-29T11:58:28+00:00, thread_id=019fadbd-7acb-76b2-8d60-108475540831, request only; no inspection results)
- rollout_summaries/2026-07-29T11-59-38-K1iF-unread_unresponded_optimization_report_verification.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-59-38-019fadbe-9f4b-7e81-955d-a4ab24c396a9.jsonl, updated_at=2026-07-29T12:13:38+00:00, thread_id=019fadbe-9f4b-7e81-955d-a4ab24c396a9, source-only verification; final NO-SHIP as-is)

### keywords

- unread-unresponded-optimize-review.md, O1-O14, countDocuments, maxTimeMS, emitChatSessionStatusUpdatedEvent, Redlock, Stream, badge-count-cache, channel-eligible-members, getContactChatById, contact_default, read-only, file:line

- Related skill: skills/oho-badge-cache-review/SKILL.md

## User preferences

- when verifying a report, the user required “Every claim you make must cite an actual file path and line number I read in this session” -> open and independently re-verify every cited source line; do not promote report assertions into facts. [Task 1]
- when the user said “Read-only review. Do not modify, stage, or commit” -> preserve repository state throughout the audit. [Task 1]
- when the user requested claim verdicts, missed findings, ranked `O1–O14` opinion, then an impact-column audit, and said “Be direct and concise” -> follow that exact output order without padding. [Task 1]

## Reusable knowledge

- The completed audit found group `countDocuments` and `$facet.metadata.$count` have no cardinality cap/cache but do have `maxTimeMS` and a 75s service timeout: say bounded-by-time, not literally unbounded. It also found `emitChatSessionStatusUpdatedEvent` performs a populated snapshot plus audience resolution before the feature-flag check, so flag-off still pays most emitter cost. [Task 1]
- Customer delivery happens before member after-hooks; clear writes/emitters precede Stream persistence inside Redlock. A clear-write error can therefore return an error after customer delivery while the message is absent from Stream. Bulk send also returns `{ok:true}` before detached platform handlers settle; both semantics blocked ship in the reviewed revision. [Task 1]
- Keep socket and fallback claims precise: Socket.IO emits once with `io.to(channelNames).emit()`, although room construction/delivery scale with eligible members; only qualifying fallback realtime events call heavyweight `getContactChatById`, which has no debounce/cancellation/in-flight coalescing. [Task 1]
- The stated API tree was effectively the target branch minus `bbe0ac735`, while the web app matched the target branch. No benchmark, explain, production cardinality, or latency telemetry was run; all findings are structural/source-only. [Task 1]

## Failures and how to do differently

- Symptom: `countDocuments` is called “unbounded,” every socket event is said to fetch, or Remote Config is said to block page open. Cause: result-cardinality, event qualification, and fire-and-forget behavior were conflated. Fix/pivot: distinguish time bounds from result caps, qualifying fallback events from in-list/stale events, and possible network activity from page-open blocking. [Task 1]
- Symptom: a proposal is approved as a quick optimization. Cause: it silently changes ordering, legacy field-absence semantics, or authoritative reconciliation. Fix/pivot: do not use raw fire-and-forget emits, a simple merged update removing `$exists`, off-list skip-fetch, or timestamp-only O12 optimization; treat O10/O14 as one Remote Config authority/refresh design. [Task 1]

# Task Group: /Users/tualek/Documents/Codex/2026-07-25/new-chat / Thai event planning and Google Docs export
scope: Create one ready-to-use Thai ceremony flow/script and export it as a native Google Docs document; use when the user wants a consolidated ceremonial program, short speaking script, and verified document import.
applies_to: cwd=/Users/tualek/Documents/Codex/2026-07-25/new-chat; reuse_rule=reuse the document-building and import verification workflow for similar Thai event documents, but treat the event sequence, royal names, file path, and document ID as task-specific.

## Task 1: จัดทำ flow และสคริปต์พิธีการ แล้วส่งออกเป็น Google Docs สำเร็จ

### rollout_summary_files

- rollout_summaries/2026-07-25T10-22-14-ZNOx-thai_event_flow_google_docs_export.md (cwd=/Users/tualek/Documents/Codex/2026-07-25/new-chat, rollout_path=/Users/tualek/.codex/sessions/2026/07/25/rollout-2026-07-25T17-22-14-019f98cc-014a-72d2-94c9-0a10127e2259.jsonl, updated_at=2026-07-25T10:38:58+00:00, thread_id=019f98cc-014a-72d2-94c9-0a10127e2259, native Google Docs import succeeded; text and 16×3 table structure were checked)

### keywords

- Thai, event-flow, ceremony-script, Google Docs, Google Drive, python-docx, google_docs_title_sanitize.py, native_google_docs, table-import, 16×3, สคริปต์พิธีการ, รวมทั้งหมดรวบเดียว

## User preferences

- เมื่อผู้ใช้ขอ “แทรกชื่อองค์ภาและพระพันปีชื่อเต็มพร้อมบทเข้าไว้อาลัย” -> งานพิธีการควรใช้พระนามเต็มและเขียนบทนำเข้าสู่ช่วงถวายความอาลัยโดยตรง. [Task 1]
- เมื่อผู้ใช้ขอ “บทพูดให้คุณแดนด้วยสั้นๆ” -> สคริปต์ของผู้กล่าวขอบคุณควรกระชับ ใช้เวลาประมาณ 1 นาที. [Task 1]
- เมื่อผู้ใช้ขอ “รวมทั้งหมดรวบเดียว” -> ส่งมอบเอกสาร/คำตอบฉบับรวมเดียวในตารางที่พร้อมใช้งาน ไม่แยกส่วนให้ผู้ใช้ประกอบเอง. [Task 1]
- เมื่อผู้ใช้ขอ “export เป็น googl docs ให้หน่อย” -> สร้าง Google Docs native ส่งลิงก์ และตรวจว่าข้อความกับตารางนำเข้าครบ. [Task 1]

## Reusable knowledge

- Workflow ที่ใช้ได้: สร้าง DOCX ด้วย `python-docx` → รัน `google_docs_title_sanitize.py` → import ผ่าน Google Drive ด้วย `upload_mode: "native_google_docs"` → ตรวจ `_get_document_text` และ `_get_document_tables`. [Task 1]
- ช่วงไว้อาลัยใน flow นี้ใช้ไฟนิ่งโทนสุภาพ ปิดเพลง งดเสียงปรบมือ; เพลงสนุกและไฟสีสันเริ่มหลังคำว่า “ณ บัดนี้”. [Task 1]
- Import ที่ยืนยันสำเร็จมี `converted:true`, `mimeType:application/vnd.google-apps.document`; ตรวจข้อความ พระนามเต็ม สคริปต์ ตารางเวลา และตาราง 16 แถว × 3 คอลัมน์แล้ว. [Task 1]

## Failures and how to do differently

- Symptom: local DOCX render ดูเหมือนตรวจแล้วแต่แสดงอักษรไทยไม่สมบูรณ์. Cause: ข้อจำกัดการ render ฟอนต์ไทยยังคงอยู่แม้เปลี่ยนฟอนต์และกำหนด `SAL_FONTPATH`. Fix/pivot: รายงาน visual QA ว่าจำกัด และอย่าอ้าง pixel-level verification หากยังไม่ได้ตรวจ glyph โดยอิสระ. [Task 1]
- Symptom: import สำเร็จแต่ถูกอ้างว่าเห็นหน้าตาใน Google Docs แล้ว. Cause: หลักฐานยืนยันได้เพียงข้อความและโครงสร้างผ่าน connector. Fix/pivot: แยก content/table verification ออกจาก visual QA โดยตรง. [Task 1]

# Task Group: /Users/tualek/ohochat / send-message and webhook source audits
scope: Read-only, source-first audit memory for outbound `oho-api` send paths and inbound `oho-webhook` receipt/worker chains; use for latency, locking, retry, duplicate, silent-drop, early-ack, or sibling-route divergence reviews.
applies_to: cwd=/Users/tualek/ohochat/oho-api + /Users/tualek/ohochat/oho-webhook; reuse_rule=reuse for similar static audits across these two repos, but pin the exact branch/SHA and retrace hooks, retries, and queue configuration before treating a finding as current.

## Task 1: Blind audit outbound sends, webhook receipt/workers, and sibling divergences; multiple latency and correctness risks found

### rollout_summary_files

- rollout_summaries/2026-07-22T15-59-56-ExfV-blind_audit_send_message_webhook_oho_api_webhook.md (cwd=/Users/tualek/ohochat/oho-webhook, rollout_path=/Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-59-56-019f8a8e-191c-7740-8373-583d8f41643f.jsonl, updated_at=2026-07-22T16:09:45+00:00, thread_id=019f8a8e-191c-7740-8373-583d8f41643f, source-only audit of outbound, receipt, worker, retry/dedup, and sibling send paths)

### keywords

- member-send-message, Facebook webhook, LINE webhook, Cloud Tasks, Redis dedup, retry-backoff, axios timeout, Stream Chat, bulk send, partner/send-message, contact-send-message, bot-send-message, inform-message, silent drop, duplicate message

## Task 2: Verify `member-send-message` locking/retries/timeouts/reference_id and early-ack redesign risks

### rollout_summary_files

- rollout_summaries/2026-07-22T15-15-41-t20F-oho_api_member_send_message_locking_retry_review.md (cwd=/Users/tualek/ohochat/oho-webhook, rollout_path=/Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-15-41-019f8a65-96f5-7a71-a99e-19040bdcad19.jsonl, updated_at=2026-07-22T15:22:38+00:00, thread_id=019f8a65-96f5-7a71-a99e-19040bdcad19, exact line-cited verification against pinned oho-api snapshot)

### keywords

- member-send-message, redlock, contact:$1:chat_session, LOCK_MS, LOCK_EXTEND_GAP_MS, retry-backoff, status 429, createAxiosApi, callWithStreamChatRetry, reference_id, early-ack, socket-reconcile

## User preferences

- when the user says `Independent BLIND audit` and `Do NOT read any *.md report/plan files` -> trace source only; do not let existing reports or plans contaminate the audit. [Task 1]
- when the user asks to `Exhaustively inventory` and `Before finalizing, grep for every awaited call` -> finish with an async-primitive completeness sweep, not a narrative-only review. [Task 1]
- when the user says `precision matters — every verdict must cite exact file:line evidence from the real code, not inference` and `Do not modify any code` -> keep the audit read-only and every verdict source-cited. [Task 2]
- when the user asks for an early-ack/socket-reconcile redesign review -> provide claim verdicts and a separate risk/mitigation section; trace correlation IDs end-to-end rather than assuming `reference_id` reaches Stream. [Task 2]
- when comparing sibling send paths, the user asked for `DIVERGENCE` and `concrete risk or benign` -> organize by route/file and emphasize sequencing/await placement over shared helper names. [Task 1]

## Reusable knowledge

- `member-send-message` takes `contact:$1:chat_session` before platform calls and releases it only in after/error hooks. Long platform or Stream work therefore occupies the same lock used by member/bot assignment, member response, and close-chat actions. [Task 1][Task 2]
- The lock is not extended every 200ms: the timer is 200ms but extension happens only near expiry (`LOCK_MS=3000`, `LOCK_EXTEND_GAP_MS=1000`). [Task 2]
- `createAxiosApi()` supplies a 60s default even when the LINE call site has no explicit timeout. `callWithStreamChatRetry()` makes six attempts with 5s/10s/20s/40s/80s delays (155s backoff); account for serial messages, not only per-message latency. [Task 1][Task 2]
- Facebook/Instagram/LINE 429 retry predicates contain dead later `else if (status === 429)` branches because the initial condition already returns false. [Task 1][Task 2]
- `reference_id` is validated and returned for API correlation but is not forwarded into the Stream payload in the reviewed snapshot. [Task 2]
- Facebook dedup is non-atomic Redis `get` then `setEx`; concurrent workers can both pass, while a retry that reuses its dedup key can be silently dropped. Facebook worker errors can become HTTP 200 to complete Cloud Tasks. [Task 1]
- `send-oho-webhook-events` is intentionally detached, 3s-timeout, observability-only work; separate it from awaited customer-visible path dependencies. [Task 1]
- Do not merge similarly named routes: `bulk` returns `{ok:true}` before all sends settle and lacks the main lock; `partner/send-message` does not re-check contact/business match; legacy `partner-send-message` only writes Stream; `contact-send-message` updates contact state before Stream and swallows Stream failures. [Task 1]

## Failures and how to do differently

- Symptom: retry behavior is inferred from helper names or a claimed 429 branch. Cause: predicate control flow makes the later 429 code unreachable. Fix/pivot: read the full predicate and calculate effective attempts, timeout, backoff, and serial accumulation. [Task 1][Task 2]
- Symptom: an early ACK or 200 response is assumed safe. Cause: queue completion, detached work, and swallowed errors have different durability/customer-visible semantics. Fix/pivot: trace ACK timing, awaits, error conversion, retry/dedup namespace, and commit order end to end. [Task 1]
- Symptom: a refactor reduces lock time by moving work to background. Cause: it may detach hard state/Stream dependencies or lose correlation/reconciliation correctness. Fix/pivot: classify each hook as hard dependency, safely backgroundable, or observability-only before changing hook order. [Task 2]
- Symptom: sibling send routes are treated as equivalent. Cause: route names and shared helpers hide different lock, validation, retry, and failure semantics. Fix/pivot: inventory each route/service and compare deltas against `member-send-message`. [Task 1]

# Task Group: /Users/tualek/ohochat/oho-backoffice / external-message admin UI review
scope: Read-only review memory for `oho-backoffice` external-message whitelist and app-catalog work, especially GitLab MR diffs, async-state/race correctness, Element UI behavior, and admin data-safety boundaries.
applies_to: cwd=/Users/tualek/ohochat/oho-backoffice; reuse_rule=reuse for similar review-only admin UI checks in this checkout, but re-check the exact worktree or MR head, framework behavior, and API contract before treating any finding as still open.

## Task 1: Review MR !32 external-message catalog/whitelist UI, two correctness blockers and two async-state risks found

### rollout_summary_files

- rollout_summaries/2026-07-20T02-21-10-WqUb-oho_backoffice_mr32_external_message_code_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/20/rollout-2026-07-20T09-21-10-019f7d53-c7cc-7ea2-9fb1-76d2f5ace193.jsonl, updated_at=2026-07-20T02:28:26+00:00, thread_id=019f7d53-c7cc-7ea2-9fb1-76d2f5ace193, GitLab MR review found late-save baseline corruption, page-reset stale rows, dialog-token drift, and debounced-search stale-response risk)

### keywords

- glab, merge request 32, code review, external-message, whitelist, pagination, request_seq, race condition, prettier, git diff --check, nuxt2, element-ui

## Task 2: Read-only OHO-1177 pagination/select-all review, four correctness risks found while cross-page model and recursion were safe

### rollout_summary_files

- rollout_summaries/2026-07-16T12-27-20-o4b5-oho_1177_pagination_select_all_read_only_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/16/rollout-2026-07-16T19-27-20-019f6ae5-4dea-7a62-b818-7b3d28db18df.jsonl, updated_at=2026-07-16T12:35:11+00:00, thread_id=019f6ae5-4dea-7a62-b818-7b3d28db18df, uncommitted OHO-1177 review found save/select-all, duplicate-validation, business-switch, and stale-page races)

### keywords

- OHO-1177, Vue2, Nuxt2, element-ui, pagination, select-all, checkbox-group, stale-response, whitelist_request_seq, duplicate-name, $limit, BadRequest

## Task 3: Read-only UI/UX review of external-message whitelist/app catalog screens, root cause and data-safety findings

### rollout_summary_files

- rollout_summaries/2026-07-14T07-38-59-v0i2-oho_backoffice_external_message_ui_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T14-38-59-019f5f90-99ef-79c1-9da8-c8468ab76236.jsonl, updated_at=2026-07-14T07:43:25+00:00, thread_id=019f5f90-99ef-79c1-9da8-c8468ab76236, line-cited review established Element UI arrow behavior and mock cascade/orphan risks)

### keywords

- vue2, nuxt2, element-ui, el-select, remote filterable, dropdown arrow, cascade delete, whitelist, app catalog, mock API, line-cited review

## User preferences

- when the user says `read-only, do NOT edit any files`, `Do NOT edit any files -- this is review only`, or asks `review mr นี้ให้หน่อย` -> inspect without editing, staging, committing, or drifting into implementation. [Task 1][Task 2][Task 3]
- when the user requires every correctness claim to cite actual lines and wants severity-ranked findings -> report evidence-first, blocker-oriented, and omit speculative issues. [Task 1][Task 2][Task 3]
- when the task is a GitLab MR review in this repo -> use the live MR metadata/diff, not a paraphrased summary, and keep the output merge-oriented with P1/P2-style findings. [Task 1]
- when the user supplies a checklist for cross-page state, select-all, async races, recursion, API contract adherence, and comments -> explicitly use that checklist rather than review only visible UI behavior. [Task 2]
- when the user specifies `root-cause first` and then High/Medium/Low findings with concrete suggested fixes -> preserve that severity ordering and actionable output shape. [Task 3]
- when the user asks to grep the wider repo for other `filterable remote` usages -> check wider repo usage before claiming a pattern or divergence. [Task 3]

## Reusable knowledge

- `glab mr view 32 -F json` and `glab mr diff 32` were reliable sources for `oho-backoffice` GitLab MR review, and `git diff --check` is a useful quick sanity check even when functional races remain. `prettier --check` can still catch formatting drift separately. [Task 1]
- This feature area is highly race-prone: business switching, save, page refresh, dialog open/close, and debounced search each need their own request-identity or snapshot guard. Do not treat one existing `request_seq` guard as blanket coverage. [Task 1][Task 2]
- Element UI checkbox-group keeps the full model, so toggling visible-page checkboxes preserves IDs from other pages. Deriving all/indeterminate from `selected_app_ids.length` versus catalog `total` is correct under the supplied cascade-delete contract. [Task 2]
- Last-page step-back recursion is bounded and refetches the corrected page without leaving loading stuck. [Task 2]
- `fetchAllExternalMessageApps()` walks every page because the API wrapper only supports paginated reads. It is used for whole-catalog validation and select-all behavior, so Save/dirty-baseline updates must be serialized against that async fetch and tied to the initiating business/request sequence. [Task 1][Task 2]
- In `pages/external-message-whitelist.vue`, changing business or resetting `app_page = 1` is not sufficient by itself; the visible page-1 list must be refetched or stale rows can remain on screen. [Task 1]
- The edit flow intentionally keeps `app_id` immutable to avoid orphaning existing whitelists, which matches the earlier mock-model data-integrity warning. [Task 1][Task 3]
- Page loaders need stale-response guards; duplicate-name validation must be loaded/gated before Save because the backend does not enforce unique names. The adapter's `_.clamp` of `$limit` hides the verified `BadRequest` contract for values above 50. [Task 2]
- Element UI `el-select` with `remote && filterable` intentionally omits the default arrow; no repo CSS override was found. The mock backend models `external_message_apps` and `business_external_app_whitelist`, cascades app deletion, and does not propagate mutable `app_id` edits to existing whitelist rows. [Task 3]

## Failures and how to do differently

- Symptom: a late whitelist save corrupts the newly selected business baseline. Cause: `saved_app_ids` from an older save overwrites `loaded_app_ids` after the user switches business. Fix/pivot: bind save completion to the business/dialog state that initiated it before mutating clean-baseline state. [Task 1]
- Symptom: the pager shows page 1 while stale rows from another page remain visible. Cause: code resets `app_page = 1` without refetching page 1 data. Fix/pivot: treat page reset as its own fetch boundary and verify the reload follows the state change. [Task 1]
- Symptom: Save persists old IDs then marks newly fetched select-all IDs clean. Cause: select-all fetches the whole catalog asynchronously while Save stays enabled. Fix/pivot: disable/serialize Save until the selection fetch resolves and only update dirty baseline after the matching PATCH succeeds. [Task 2]
- Symptom: business A select-all overwrites business B after a switch, or rapid paging/search shows old rows/loading state. Cause: responses are not tied to the initiating business/request sequence and page/search loaders lack stale-response guards. Fix/pivot: bind each request to current sequence/context and discard stale results. [Task 1][Task 2]
- Symptom: a fast create/update bypasses duplicate-name validation or a reopened dialog saves against the wrong form state. Cause: validation/save awaits before snapshotting dialog state and whole-catalog validation is not fully gated. Fix/pivot: snapshot dialog/form state before the first await and await/gate validation before Save. [Task 1][Task 2]
- Symptom: a missing dropdown arrow looks like a CSS bug. Cause: Element UI hides the suffix icon for `remote && filterable`. Fix/pivot: inspect component source before blaming styling. [Task 3]
- Symptom: whitelist/admin mockups appear safe because the UI has warning text. Cause: the data model still allows cascade delete and `app_id` rename orphaning. Fix/pivot: inspect the mock service/data layer, not only page copy. [Task 3]

# Task Group: /Users/tualek/ohochat / cross-repo unread-unresponded deploy-gate reviews
scope: Read-only cross-repo review memory for unread/unresponded fixes spanning `oho-api`, `oho-websocket`, and `oho-web-app`; use for deploy-gate audits, MR review follow-ups, or "is this actually fixed?" checks where write gates, realtime broadcasts, and frontend counters must align.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse for similar cross-repo review-only audits across these repos, but always re-check live `git status` / `git diff` in each repo and current commit semantics before treating any finding as still open.

## Task 1: Cross-repo review of MR !1285 unread/unresponded changes, exact MR head still had websocket blocker plus frontend/backend drift risks

### rollout_summary_files

- rollout_summaries/2026-07-15T10-24-15-fwAy-mr1285_unread_unresponded_cross_repo_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T17-24-15-019f654e-423f-7483-bdd6-494aba0e6b12.jsonl, updated_at=2026-07-15T10:56:47+00:00, thread_id=019f654e-423f-7483-bdd6-494aba0e6b12, exact-MR audit rebased on prior review docs; backend clear broadcasts looked improved but websocket `message.read` and frontend state sync were still not deploy-safe)

### keywords

- cross-repo review, unread, unresponded, mr-1285, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, emitEligibilityScopedUnrespondedUpdate, message.read, businessChannel, Remote Config, optimistic-flag-count-tracker, exact file:line

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 2: Cross-repo deploy-gate review of round-2 unread/unresponded fixes, websocket looked clean but frontend and bulk-send risks remained

### rollout_summary_files

- rollout_summaries/2026-07-15T01-16-06-ttm9-cross_repo_unread_unresponded_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T08-16-06-019f6358-6a26-7531-ab13-b4360a1b5799.jsonl, updated_at=2026-07-15T01:29:28+00:00, thread_id=019f6358-6a26-7531-ab13-b4360a1b5799, round-2 deploy-gate pass verified live diffs in all three repos and found frontend pagination/rollback drift plus `oho-api` mixed-success timestamp collateral risk)

### keywords

- deploy gate, git diff, git status, unread, unresponded, bulk.class.js, getLastStreamMessageTimestamp, instagram parity, channel-eligible-members, single-flight, optimistic-flag-count-tracker, markRoomRead, last_read, pagination, Vue 2 reactivity

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 3: Cross-repo deploy-gate review of realtime badge fixes, improvements landed but security and rollback risks remained

### rollout_summary_files

- rollout_summaries/2026-07-14T18-31-25-OSyU-oho_unread_unresponded_cross_repo_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T01-31-25-019f61e5-e958-75d1-ae40-e7dc4ffd3d5c.jsonl, updated_at=2026-07-14T18:42:39+00:00, thread_id=019f61e5-e958-75d1-ae40-e7dc4ffd3d5c, stricter deploy-gate pass verified real repo state first and found bulk-send timestamp, websocket cache, and frontend rollback/counter edge cases)

### keywords

- deploy gate, git diff, git status, unread, unresponded, modifiedCount, channel-eligible-members, Firebase Remote Config, feature_flags_api_keys, checked_channels, Conversation.vue, optimistic-flag-count-tracker, bulk.class.js, get-last-stream-message-timestamp

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 4: Cross-repo review of MR !1285 unread/unresponded changes, websocket blocker plus frontend/backend drift risks

### rollout_summary_files

- rollout_summaries/2026-07-14T15-18-52-8PEC-mr1285_cross_repo_unread_unresponded_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T22-18-52-019f6135-9fb1-7b72-b968-52241fd501a2.jsonl, updated_at=2026-07-14T15:35:19+00:00, thread_id=019f6135-9fb1-7b72-b968-52241fd501a2, read-only review across `oho-api`, `oho-websocket`, and `oho-web-app` found a websocket `message.read` blocker and frontend Remote Config / optimistic-counter drift risks)

### keywords

- cross-repo review, unread, unresponded, mr-1285, message.read, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, emitEligibilityScopedUnrespondedUpdate, businessChannel, Remote Config, optimistic-flag-count-tracker, groupchat

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## User preferences

- when the user says `Do NOT trust the summary below as fact — run git diff / git status yourself in each repo and verify every claim against the actual diff.` -> pin the real repo/worktree state first and treat summaries as suspect until the live diff matches them. [Task 2][Task 3]
- when the user says `read plan.md` / prior review docs first and `do not re-flag findings already documented as fixed there` -> rebase on prior review history and avoid duplicate findings. [Task 1][Task 4]
- when the user says `Do NOT edit, stage, commit, or run any command that mutates files or git state.` or `do not modify any files` -> keep similar cross-repo reviews strictly read-only. [Task 1][Task 2][Task 3][Task 4]
- when the user wants `structured findings report, ranked by severity` with exact `file:line` evidence and a one-line verdict -> stay compact, judgmental, and evidence-first instead of exploratory. [Task 1][Task 2][Task 3][Task 4]
- when the user asks to `cover all 3 repos` and separate findings by repo/axis -> keep repo boundaries explicit instead of collapsing backend, websocket, and frontend into one verdict. [Task 1]
- when the user asks to check Instagram shape parity or whether a new test would still fail if the fix were reverted -> inspect both platform paths independently and mentally revert the fix before trusting a new regression test. [Task 2]
- when the user asks whether a websocket or frontend port is `actually faithful` -> compare semantics and state transitions, not just line similarity. [Task 2][Task 3][Task 4]
- when the user asks for a complete flag/write/broadcast audit or to check pagination/performance implications -> trace UI mutations from socket events, authoritative fetch reconciliation, and append paths too, not just backend writes. [Task 1][Task 2][Task 3][Task 4]

## Reusable knowledge

- The durable contract across these reviews is: SET writes are flag-gated, CLEAR writes are unconditional, and realtime broadcasts are flag-gated. Use that split when auditing each repo so a correct write-path change does not hide an incorrect broadcast-path gate. [Task 1][Task 2][Task 3][Task 4]
- For this task family, the high-value trace is end to end: payload source -> guard -> DB write result -> broadcast audience/result -> frontend merge/filter logic. The reviews repeatedly found partially correct fixes that only became visible when the whole chain was traced. [Task 1][Task 2][Task 3][Task 4]
- In `oho-api`, `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for `unread_by` and `is_unresponded:true`, while `buildClearUnreadUnrespondedPayload()` intentionally stays unconditional to avoid flag-toggle stuck state. [Task 1][Task 4]
- The 2026-07-15 exact-MR review verified the four newly fixed contact clear broadcast call sites (`notify`, `inform-message`, `broadcast`, `bulk`) all route into `emitContactUnrespondedStatusUpdatedEvent()` / `emitEligibilityScopedUnrespondedUpdate()`. [Task 1]
- The latest `oho-api` bulk-send review verified Facebook and Instagram reply services share the same `response.data` success / `GeneralError` failure contract, and the new mixed-success Facebook test calls `getLastStreamMessageTimestamp()` on both the merged payload and the successful-only payload. [Task 2]
- In `oho-websocket`, `message.read` is the websocket-side CLEAR site. The exact-MR audit found it still flag-gated the `$pull unread_by` clear and missed the ordering guard; the later deploy-gate pass verified a newer version moved the `$pull` first, kept `new:true` plus `.select('business_id updated_at').lean()`, and used `modifiedCount > 0` to suppress no-op broadcasts, though downstream consumers can still drop emitted `updated_at` as stale. [Task 1][Task 2][Task 3][Task 4]
- Group broadcast scoping moved from whole-business rooms toward eligible-member channels. The latest deploy-gate pass verified `channel-eligible-members.js` is now fresh-query plus single-flight dedup and fail-closed on unknown eligibility; older whole-business-room findings are still relevant when auditing earlier MR revisions. [Task 1][Task 2][Task 3][Task 4]
- The frontend guidance changed across these rollouts: the earlier cross-repo reviews found browser Remote Config could overwrite API-authenticated flags, while the later deploy-gate review validated the fix via `feature_flags_api_keys` plus `plugins/firebase-remote-config.js:52-56` making browser updates non-authoritative for API-owned keys. [Task 1][Task 3][Task 4]
- `utils/optimistic-flag-count-tracker.js` now records every increment in its Set and deletes on every decrement; round-2 fixed one known offscreen double-count path, but correctness still depends on seeding or reconciling those Sets from authoritative fetches on every full replacement and pagination append path. [Task 1][Task 2][Task 3]
- `Conversation.vue` now uses a function-local `did_decrement_unread_count` flag, which removes one rollback leak, but `markRead()` still needs its optimistic `last_read` cursor unwound on failure or retries can skip the needed unread decrement. [Task 2]

## Failures and how to do differently

- Symptom: a review inherits wrong assumptions from a written summary. Cause: the claimed fix set and the live worktree or exact MR head diverge. Fix/pivot: always inspect the actual diff in every repo before trusting summary text or prior conclusions, and be explicit about which revision was reviewed. [Task 1][Task 2][Task 3][Task 4]
- Symptom: a fix looks faithful because the ported code resembles another repo. Cause: semantic differences hide in guards, timestamps, payload fields, or audience selection. Fix/pivot: compare behavior contracts, not line similarity, especially for websocket ports and frontend consumers. [Task 1][Task 2][Task 3][Task 4]
- Symptom: websocket audience scoping gets reviewed against stale assumptions. Cause: the helper changed across rounds from whole-business rooms to channel-eligible paths, then from cache-sensitive logic to fresh-query single-flight logic. Fix/pivot: inspect the current `channel-eligible-members.js` and broadcast target before reasoning about overreach, revocation risk, or QPS/load tradeoffs. [Task 1][Task 2][Task 3][Task 4]
- Symptom: bulk-send clear logic looks fixed once it skips the all-fail case. Cause: the clear guard is correct only partially if `lastMessageTimestamp` still comes from merged payloads that include failed deliveries, or if only one platform path is regression-tested. Fix/pivot: trace the timestamp source as carefully as the boolean success guard and check Facebook/Instagram parity separately. [Task 2][Task 3]
- Symptom: unread badge drift seems resolved after a Set-based tracker patch. Cause: reconciliation may only cover full-list replacement while append pagination and `last_read` rollback paths still drift. Fix/pivot: inspect `set*List` and `add*List` mutations together, and verify failure rollback unwinds both counters and cursor state. [Task 1][Task 2][Task 3]
- Symptom: validation sounds stronger than it is because syntax checks passed. Cause: `git diff --check`, `node --check`, or wiring-only tests do not prove behavior; sandboxed read-only runs can also block Jest temp writes. Fix/pivot: report those checks as shallow confidence only and say explicitly when deeper behavioral proof could not run. [Task 1][Task 2][Task 3][Task 4]

# Task Group: /Users/tualek/ohochat/oho-api / unread-unresponded code reviews
scope: Review-only memory for `oho-api` unread/unresponded diffs, especially query composition, flag-off contract checks, service boot safety, coverage-loss judgment, and review reporting style; use when the user asks whether backend changes are okay, not when they ask for direct implementation.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar code reviews in this repo or nearby search-hook work, but re-verify exact query shape, failing tests, and worktree-specific files before treating any blocker as still open.

## Task 8: Adversarial review of rev.2 unread/unresponded one-sprint refactor plan; NEEDS-CHANGES before dark state dual-write

### rollout_summary_files

- rollout_summaries/2026-07-31T08-15-01-Mjxm-rev2_unread_unresponded_refactor_plan_adversarial_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T15-15-01-019fb73d-b08e-7d42-947c-493c374ac7c0.jsonl, updated_at=2026-07-31T08:25:23+00:00, thread_id=019fb73d-b08e-7d42-947c-493c374ac7c0, production-enablement backlog and explicit Track B cut-line)

### keywords

- unread-unresponded, contact_chat_states, dark-write, dark-verify, buildCountBaseQuery, feature-flags, eligible-members, last_contact_date, OHO-1272, applyClearUnreadUnrespondedWrites, Atlas Search, production-canary, Track A, Track B

## Task 9: Audit direct one-sprint `contact_chat_states` cutover; NO-SHIP until ordering, search/count, and cross-repo writers are designed

### rollout_summary_files

- rollout_summaries/2026-07-31T07-43-22-cSLQ-no_ship_contact_chat_states_refactor_plan_audit.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-43-22-019fb720-b89a-7483-ad06-486d9c12dd1e.jsonl, updated_at=2026-07-31T07:53:55+00:00, thread_id=019fb720-b89a-7483-ad06-486d9c12dd1e, pinned `origin/develop` cross-repo audit; NO-SHIP)
- rollout_summaries/2026-07-31T07-42-00-B5iQ-read_only_review_contact_chat_states_refactor_plan.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-42-00-019fb71f-7572-71d1-b82a-670541b3921c.jsonl, updated_at=2026-07-31T07:51:34+00:00, thread_id=019fb71f-7572-71d1-b82a-670541b3921c, independent local-develop audit; NO-SHIP)

### keywords

- contact_chat_states, unread_by, is_unresponded, last_contact_date, last_active_at, Atlas Search, storedSource, buildCountBaseQuery, sale visibility, mark-read, oho-websocket, entity_type, NO-SHIP

## Task 7: Final OHO-1272 badge-cache single-flight timeout/write verification, ship in the reviewed worktree

### rollout_summary_files

- rollout_summaries/2026-07-29T17-36-04-EvVz-oho_1272_final_single_flight_timeout_verification.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T00-36-04-019faef2-a12e-78c2-b951-01d71a1deffd.jsonl, updated_at=2026-07-29T18:06:31+00:00, thread_id=019faef2-a12e-78c2-b951-01d71a1deffd, static/spec verification plus Promise probe; VERDICT: ship)

### keywords

- oho-1272, badge-count-cache, single-flight, staggered-GET, Promise.race, Bluebird, wall-clock-timeout, expired, stale-cache-write, Jest, getOrComputeBadgeCount

- Related skill: skills/oho-badge-cache-review/SKILL.md

## Task 1: Review an 8s Redis cache for unread/unresponded badge counts, key isolation checked but stale-write/stampede risks remained

### rollout_summary_files

- rollout_summaries/2026-07-15T07-12-24-BMSu-oho_api_badge_count_redis_cache_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T14-12-24-019f649e-9cc4-7813-bcca-a102cb1b4a2a.jsonl, updated_at=2026-07-15T07:21:36+00:00, thread_id=019f649e-9cc4-7813-bcca-a102cb1b4a2a, scope/key isolation and `0` hit semantics checked; Redis late-write and miss-stampede risks remained)

### keywords

- oho-api, unread, unresponded, badge-count-cache, computeBadgeCounts, cacheService, raceCommandTimeout, Redis, offline_queue, single-flight, stampede, Bluebird, ObjectId, EPERM, Jest haste map

## Task 2: Review uncommitted `oho-api` unread/unresponded diff, one boot-time regression plus coverage-loss risk

### rollout_summary_files

- rollout_summaries/2026-07-15T09-05-53-eBHL-oho_api_uncommitted_review_startup_blocker_and_behavior_pres.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-05-53-019f6506-8353-7c13-9dda-4d97fcfab9ad.jsonl, updated_at=2026-07-15T09:18:31+00:00, thread_id=019f6506-8353-7c13-9dda-4d97fcfab9ad, live-diff read-only review confirmed a Feathers startup blocker while the other targeted refactors preserved behavior)
- rollout_summaries/2026-07-15T09-09-58-II02-oho_api_uncommitted_unresponded_review_boot_regression_and_c.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-09-58-019f650a-4163-70e3-b3ce-6fa49d681272.jsonl, updated_at=2026-07-15T09:20:54+00:00, thread_id=019f650a-4163-70e3-b3ce-6fa49d681272, parallel live-diff review also found coverage-loss risk)

### keywords

- oho-api, unread, unresponded, read-only review, uncommitted diff, service.hooks(hooks), invalid hook type, contact-send-message, getContactSendMessagePreviewText, paginate.max, getMessagePreviewText, checkJs, deleted specs

## Task 3: Review unread/unresponded flag-gated changes in `mr-1285-fixes`, flag-off contract regressions found

### rollout_summary_files

- rollout_summaries/2026-07-14T10-49-31-cVgx-thai_unread_unresponded_flag_off_review_mr_1285_fixes.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T17-49-31-019f603f-0763-7a32-9125-816c9dd5f2b5.jsonl, updated_at=2026-07-14T11:40:37+00:00, thread_id=019f603f-0763-7a32-9125-816c9dd5f2b5, corrected to the real `.claude/worktrees/mr-1285-fixes` diff and found flag-off contract / emitter-audience blockers)

### keywords

- unread, unresponded, flag-off, mr-1285-fixes, emitChatSessionStatusUpdatedEvent, emitContactUnrespondedStatusUpdatedEvent, buildClearUnreadUnrespondedPayload, convertUnreadUnrespondedQuery, channel-eligible-members, worktree verification, Thai review

## Task 4: Review `oho-api` unread/unresponded and bulk-send changes in `mr-1285-fixes`, blocker findings

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, worktree-specific review found blocker-level query-composition risks)

### keywords

- oho-api, code review, unread, unresponded, convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, cacheService, Redis, Jest, Mongo query composition

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 5: Verify unread/unresponded rollout coverage and remaining blockers, partial confidence

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, targeted Jest passed but Mongo-backed proof was unavailable)

### keywords

- MONGODB_URI, compute-badge-counts, Promise.allSettled, channel-eligible-members, cacheService, Redis timeout, bot-send-message.hooks.spec.js, quick-reply failures, updateContactProfile

## Task 6: Review earlier unread/unresponded diff, blocker findings

### rollout_summary_files

- rollout_summaries/2026-06-26T10-07-42-z14x-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl, updated_at=2026-06-26T10:19:09+00:00, thread_id=019f0366-4780-7b21-a9b4-c309436efcc5, earlier review established the same hook-chain failure pattern)

### keywords

- oho-api, unread, unresponded, search-query-converter, addVisibilityFilter, bulk send, convertUnreadUnrespondedQuery, Jest, type-check, Mongo query composition

## User preferences

- when the user says `do NOT modify files` or `This is a REVIEW ONLY task. Do not edit any files.` -> keep similar `oho-api` reviews strictly read-only. [Task 1][Task 2]
- when the user asks for `findings ranked by severity with file:line references` and an `overall verdict` -> provide concise, judgmental, evidence-backed output with an explicit ship/needs-fix/block recommendation. [Task 1][Task 2]
- when a final concurrency re-review asks for `ship`/`no-ship`, event-loop ordering, Promise interop, and test timing -> inspect current files and regression tests directly; prove the claimed race rather than trusting the fix description. [Task 7]
- when the user says `run git status/git diff` and `verify with actual code inspection (not assumption)` -> inspect the live repo state first, not summaries or stale worktree assumptions. [Task 2][Task 3]
- when the user calls out pre-existing failing suites that must not be blamed on the diff -> separate environment/repo noise from a diff-caused regression. [Task 2]
- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged. [Task 3][Task 4][Task 6]
- when the user emphasized `correctness bugs (especially cross-member cache poisoning)` -> prioritize scope isolation, member identity, and stale-data correctness before style or minor test coverage. [Task 1]
- when the user asked `ถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม` -> review against the contract `feature off = no behavior + no collateral impact`, not just whether the flag is referenced somewhere. [Task 3]
- when the user asks for an “Adversarial review round 2” with “verdict ... numbered findings with file:line evidence ... prioritized 2-week backlog with explicit cut-line” -> challenge scope aggressively, pin revisions, and finish with a hard production-enablement boundary rather than rubber-stamping a revised plan. [Task 8]
- when the user asks for `SHIP / NEEDS-CHANGES / NO-SHIP`, all eight concerns, cross-repo writers, and omitted work -> trace SET -> ordering guard -> storage -> realtime -> search/count/filter and enumerate direct writers, rather than reviewing only the proposed schema. [Task 9]

## Reusable knowledge

- `computeBadgeCounts` is called by contact chat search and group search with `countBaseQuery`, `countMemberId`, and a label. `buildCountBaseQuery()` preserves business/tab/channel/sale-visibility scope while typed unread/unresponded fields are stripped, and `unread_by: countMemberId` makes member scope part of the cache filter. [Task 1]
- `getCachedBadgeCount()` treats numeric `0` as a hit and `undefined` as a miss; the reviewed TTL is numeric Redis seconds. `src/index.js` sets `global.Promise = require('bluebird')`, so production settlement inspection differs from native Jest promises. [Task 1]
- `service.hooks(hooks)` is only safe when the hooks module exports exactly lifecycle namespaces; any extra enumerable export becomes an invalid Feathers hook type, which is why `contact-send-message.service.js` booted incorrectly while `notify.service.js` stayed safe. [Task 2]
- `config/default.json` sets `paginate.max` to `50`; the reviewed dynamic max preserved that behavior. `getMessagePreviewText()` safely ignores non-string `data.label` from `qs.parse` and falls back to `message.text` / `กดปุ่ม`; `allowJs: true` with `checkJs: false` does not typecheck JS callers. [Task 2]
- `convertUnreadUnrespondedQuery.ts` has a special both-flags path; trace the full lifecycle through `countBaseQuery`, `TYPED_FILTER_FIELDS`, parser coercion, and later visibility rewrites. Any query shape that adds `$or` / `$and` needs matching parser/converter updates. [Task 4][Task 6]
- `buildClearUnreadUnrespondedPayload` is intentionally unconditional on the clear-write side so feature toggles do not leave stuck `is_unresponded` / unread state. [Task 3]
- `bulk.class.js`, `compute-badge-counts.ts`, `channel-eligible-members.ts`, and `cache/index.js` affect propagation and failure behavior; `cache/index.js` uses a 3s race timeout. [Task 4][Task 5]
- In the OHO-1272 worktree, `getOrComputeBadgeCount` synchronously registers the complete cache-read-plus-compute lifecycle before its first await. A local `expired` flag is set before timeout rejection and checked immediately before `setCachedBadgeCount`; `Promise.race(...).finally(...)` clears the timer and deletes the flight on every settlement path. This closes staggered-GET admission and late-success stale-write races. [Task 7]
- The reviewed specs cover concurrent one-read/one-compute, pending-GET joining, timeout then fresh retry, and a first computation resolving after timeout without overwriting the second flight's cached `7`. Production uses Bluebird as `global.Promise`; a focused probe confirmed native async promise assimilation and `.finally()`. [Task 7]
- `buildCountBaseQuery()` preserves tab/search filters such as status, assignment, starred, tags, and visibility after stripping pagination/meta and badge filters. A state collection containing only business/channel/spam/unread fields cannot reproduce present badge counts without a contract change or join/mirror design. [Task 8]
- Existing unread feature flags gate customer payload/eligible-member resolution, but CLEAR and mark-read stay unconditional by design. A dark write needs its own per-business kill switch, timeout/maxTimeMS, fail-soft behavior, metrics, repair path, and canary; it must not run simply because customer-facing flags are off. [Task 8]
- `last_contact_date` alone does not order cross-collection writes. Use a monotonic event timestamp/sequence plus conditional updates that reject older events; backfill must not overwrite newer live state. [Task 8]
- API-only badge endpoints do not improve performance until web stops requesting inline counts. Land/rebase OHO-1272 clear-write consolidation before Track B because the worktree overlaps current `origin/develop` in six relevant files. [Task 8]
- A direct state-collection cutover needs both `last_contact_date` (customer-message ordering) and `last_active_at` (activity ordering), explicit initialization, and conditional writes. State-first page-of-20 cannot preserve existing keyword, sale-visibility, permission, tag/assignment, and count contracts without joining/filtering before pagination or mirroring a deliberately complete state surface. [Task 9]
- Atlas Search applies typed unread filters against storedSource before lookup; `buildCountBaseQuery()` leaves contact-side filters for `countDocuments`. Group paths and `oho-api` plus `oho-websocket` mark-read writers are separate migration surfaces. Preserve the contract: SET is flag-gated, CLEAR is unconditional, broadcasts are flag-gated. [Task 9]

## Failures and how to do differently

- Symptom: a short-TTL Redis cache times out but a stale value appears later. Cause: `raceCommandTimeout()` does not cancel the command and Redis 3.x has `enable_offline_queue` on by default, so a timed-out `SETEX` may replay after reconnect. Fix/pivot: treat `timeout does not cancel command + offline queue enabled` as a serious bounded-staleness risk; distinguish it from key-isolation concerns. [Task 1]
- Symptom: cache mitigation still recreates DB load on concurrent misses. Cause: no single-flight/distributed lock around `computeBadgeCounts`. Fix/pivot: audit miss burst/stampede behavior separately from TTL and correctness. [Task 1]
- Symptom: a timeout rejects joiners but a late compute still writes stale cache state, or staggered callers each enter Redis/compute. Cause: lifecycle registration occurred after an await, or a wall-clock timeout was mistaken for cancellation. Fix/pivot: synchronously install the entire flight before Redis I/O, bound it independently of Mongo `maxTimeMS`, and gate every post-compute side effect on flight-local expiration. [Task 7]
- Symptom: cache specs look sufficient but hide boundary failures. Cause: `badge-count-cache` is mocked, so orchestration tests do not exercise serialization or Redis behavior. Fix/pivot: inspect the real helper boundary and use targeted runtime probes; `ObjectId` stringification was verified not to be the collision source. [Task 1]
- Symptom: removing a helper export looks like safe cleanup but the service fails at boot. Cause: whole-module hook registration sees an extra export as an invalid hook type. Fix/pivot: inspect `service.hooks(hooks)` bootstrap semantics before approving hook-module cleanup. [Task 2]
- Symptom: deleted tests look redundant by file name but real coverage drops. Cause: payload-helper specs do not replace service-boot assertions, hook-registration coverage, or exact write-shape / ordering assertions. Fix/pivot: compare deleted assertions against surviving tests branch by branch. [Task 2]
- Symptom: unread/unresponded filter breaks with `search` or sale visibility. Cause: typed-filter coercion and `addVisibilityFilter()` can rebuild `context.params.query`. Fix/pivot: audit the full hook chain, not only the injection helper. [Task 4][Task 6]
- Symptom: sandboxed Jest failures are misattributed to the diff. Cause: duplicate-worktree mocks and haste-map write `EPERM`; repo-wide typecheck may also contain unrelated errors. Fix/pivot: report the exact blocker and use static tracing/targeted probes rather than claim behavioral proof. [Task 1][Task 2][Task 4][Task 5]
- Symptom: a final review claims the full suite passed. Cause: known Node 24/config incompatibility and pre-existing TypeScript errors prevented independent Jest/tsc runs. Fix/pivot: describe the OHO-1272 result as static/spec verification plus focused Promise probe, not full-suite validation. [Task 7]
- Symptom: Track B dual-write is scheduled as a one-sprint default. Cause: no prerequisite measurement of eligible-member distribution, document/index size, or SET latency; its proposed state cannot satisfy the existing badge contract. Fix/pivot: first land OHO-1272, decide historical semantics, build dry-run-default/resumable migration tooling, verify Atlas indexes with `explain()`, then measure/canary existing storage before approving the design. [Task 8]
- Symptom: dark verification uses snapshot `diff = 0`, or Track A ships API-only. Cause: dual writes interleave/fail-soft and the web still triggers inline count work. Fix/pivot: compare normalized semantics with mismatch-age grace windows, repair and repeated scans; ship a minimal web consumer that disables inline counts or drop Track A. [Task 8]
- Symptom: the plan says writers are centralized or emitters receive the updated state. Cause: many paths use `updateOne`/discard results and emitters re-query. Fix/pivot: enumerate every direct model write and return-value contract; synchronize cross-repo mark-read, model/index, cleanup, and transaction behavior before canary. [Task 9]

# Task Group: /Users/tualek/ohochat/oho-web-app / realtime unread-unresponded badge review
scope: Read-only review memory for frontend unread/unresponded badge diffs in `oho-web-app`, especially contract checks against `oho-websocket`, Vue 2 reactivity boundaries, and merge-safety of optimistic/realtime counter updates.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app; reuse_rule=reuse for similar review-only work in this checkout when a frontend badge/count diff depends on sibling backend event payloads, but re-read the current frontend diff and backend commit before reusing any conclusion.

## Task 1: Review frontend increment/decrement badge logic for realtime unread/unresponded updates, not merge-safe

### rollout_summary_files

- rollout_summaries/2026-07-14T08-22-37-rN8j-oho_web_app_unread_unresponded_realtime_badge_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T15-22-37-019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df.jsonl, updated_at=2026-07-14T08:33:02+00:00, thread_id=019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df, review-only diff check against `oho-websocket@9141805` found sender-role and unread-state blockers)

### keywords

- code-review, smartchat, groupchat, unread_count, unresponded_count, is_read_by_me, is_unresponded, Vuex, realtime, websocket, oho-websocket@9141805, stale-event-guard, optimistic decrement, Vue 2 reactivity

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 2: Iterative adversarial review of OHO-1272 Vue 2/Vuex realtime badge fix, final re-review found four defects

### rollout_summary_files

- rollout_summaries/2026-07-24T07-49-15-1jYz-vue2_realtime_badge_recheck_four_issues.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T14-49-15-019f9319-959c-7630-8f42-e17b70c0d6ef.jsonl, updated_at=2026-07-24T07:53:27+00:00, thread_id=019f9319-959c-7630-8f42-e17b70c0d6ef, narrowly scoped re-review found synthetic-timestamp, pre-fetch aggregate, new-room, and stale-unresponded defects)
- rollout_summaries/2026-07-24T06-35-36-jLZD-oho_1272_realtime_badge_read_only_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-35-36-019f92d6-2878-7423-a00f-1e523deebd71.jsonl, updated_at=2026-07-24T06:40:00+00:00, thread_id=019f92d6-2878-7423-a00f-1e523deebd71, earlier narrow review found fetched-row badge overwrite and no-op dispatch distinction)
- rollout_summaries/2026-07-24T06-02-46-CTIY-realtime_badge_fix_adversarial_review_partial.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-02-46-019f92b8-19b7-75b3-bdd9-8d9231dfb910.jsonl, updated_at=2026-07-24T06:05:35+00:00, thread_id=019f92b8-19b7-75b3-bdd9-8d9231dfb910, partial review of the same worktree; branch mismatch and unfinished verdict limit confidence)

### keywords

- Vue2, Vuex, OHO-1272, smartchat.js, websocket.js, RoomList.vue, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, DEFAULT_UPDATE_FIELDS, optimistic-flag-count-tracker, unread_count, unresponded_count, last_contact_date, already_read_locally, triggerFilteredListRefetch, is_show_reload_chat_list_btn

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 3: Final GitLab MR !872 merge review; earlier raw-field blockers fixed and MR was mergeable

### rollout_summary_files

- rollout_summaries/2026-07-31T07-28-26-vltS-mr872_realtime_badge_final_merge_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-28-26-019fb713-0b24-7323-941a-c766d20f9d78.jsonl, updated_at=2026-07-31T07:56:34+00:00, thread_id=019fb713-0b24-7323-941a-c766d20f9d78, final head mergeable; 2 focused suites / 79 tests passed)

### keywords

- MR-872, 8150150f, smartchat, refreshChatRoomBadgeRealtime, DEFAULT_UPDATE_FIELDS, is_read_by_me, is_unresponded, feature-flags, open-room, markRoomRead, GitLab mergeable, websocket, Node-22, Jest

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 4: Second-round OHO-1272 verification; correctness fixes landed but formatting and a vacuous test required NO-SHIP

### rollout_summary_files

- rollout_summaries/2026-07-31T06-05-37-BMns-oho_1272_second_round_realtime_badge_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T13-05-37-019fb6c7-39c5-7110-9c61-b4878f375e66.jsonl, updated_at=2026-07-31T06:35:27+00:00, thread_id=019fb6c7-39c5-7110-9c61-b4878f375e66, earlier worktree state; NO-SHIP pending formatting and meaningful visibility test)
- rollout_summaries/2026-07-31T04-16-20-SFMO-cross_repo_review_mr872_mr1291_realtime_badge_blockers.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T11-16-20-019fb663-2d39-79b3-9364-4845f05664c6.jsonl, updated_at=2026-07-31T04:25:57+00:00, thread_id=019fb663-2d39-79b3-9364-4845f05664c6, earlier MR heads; !872 blocked, !1291 code-mergeable)

### keywords

- OHO-1272, MR-872, MR-1291, addRealtimeContactToList, equal-timestamp, is_unresponded, unread_count, unresponded_count, Prettier, visibility test, EPERM, oho_created_at

## User preferences

- when the user says `This is a review-only request. Do not fix anything, do not edit any files. Only report findings.` -> stay read-only and avoid proposing or applying patches unless explicitly asked. [Task 1]
- when the user says `Ground every claim in the actual diff content and the actual oho-websocket commit 9141805 content that you read yourself` -> cite exact file/line/field evidence and separate verified facts from inference. [Task 1]
- when the user wants findings grouped by severity and a one-line merge verdict -> preserve that compact review shape instead of drifting into a generic essay. [Task 1]
- when the user says `read ONLY these, do not explore the repo broadly` and asks for `yes/no verdict + file:line evidence` -> stay within the named files/line ranges, perform an adversarial defect search, and end with a compact, line-cited verdict. [Task 2]
- when the user says “Read the actual files, do not guess” and asks for “real defects, not style nits” -> inspect the live named worktree, focus on correctness, and do not substitute a summary for source evidence. [Task 2]
- when the user asks whether an MR can merge and asks for another check -> re-fetch GitLab metadata and re-review the latest exact head; use GitLab or an isolated clean worktree rather than touching a dirty main checkout. [Task 3]
- when the user requests a decisive UAT gate and test-by-test assessment -> report exact suite/test counts and causality; distinguish a direct branch test from component/integration proof and unrelated full-suite failures from changed-code failures. [Task 4]

## Reusable knowledge

- Backend commit `9141805` in `oho-websocket` emits `is_read_by_me:false` and `is_unresponded:true` on customer message events when the stale-event guard passes; `message.read` only `$pull`s `unread_by` and does not emit `is_read_by_me:true`. [Task 1]
- `store/modules/groupchat.js` already defines `unread_count` and `unresponded_count` in initial state, but `store/modules/smartchat.js` `contact_list` initial/reset shapes do not include those fields, so creating them later can hit a Vue 2 reactivity gap during reset/load windows. [Task 1]
- `components/Smartchat/Conversation.vue` already sets `room.is_unresponded = false` before decrementing in the optimistic unresponded flow, which is why that path avoids a duplicate decrement when the realtime event lands. [Task 1]
- `components/Smartchat/RoomList.vue` treats missing or legacy `is_read_by_me` as read in the list fallback, which explains the reviewed diff's asymmetry (`is_unresponded === true` vs `is_read_by_me !== false`) for already-known rows. [Task 1]
- `RoomList.room_list()` prioritizes the current-room false branch, then `state.read[my_id]` timestamp comparison, then presence of `state.read`, and only finally `is_read_by_me` fallback (`RoomList.vue:161-177`). A backend row with `state.read` therefore cannot reliably become unread merely by injecting `is_read_by_me:false`. [Task 2]
- `last_contact_date = new Date().toISOString()` is not valid realtime ordering metadata: a delayed inbound event can be newer than the local read cursor even when the real message was already read, producing false unread in `smartchat.js:730-733,836-860` and `RoomList.vue:163-165`. Use the real message timestamp/version or authoritative reconciliation. [Task 2]
- New-room aggregate transitions occur before the post-event API fetch (`smartchat.js:779,813-860` before `915-927`), so final fetched `is_read_by_me` / `is_unresponded` cannot correct the counters. Calculate deltas only after final data is known. [Task 2]
- New-room insertion can be skipped under `is_show_reload_chat_list_btn` or incomplete ascending pagination, while only active filtered lists refetch (`smartchat.js:966-994`); failed/empty fetches also leave incomplete socket-only rows (`904-931`). Queue/retry or authoritatively refetch rather than treating either path as a valid insertion. [Task 2]
- `is_unresponded:true` injection for existing rooms has no causal ordering; a stale inbound event can reassert it after a bot/member reply cleared it. Require event ordering/version metadata or authoritative reconciliation. Feature flags are independently gated, so this is shared-event handling rather than a flag-combination hole. [Task 2]
- `handleSmartchatRealtimeUpdate` finds rows by `_id` and then applies `_.pick(event_message, options.update_fields)`; `refreshChatRoomBadgeRealtime` must map `contact_id` to `_id` and pass `DEFAULT_UPDATE_FIELDS` so injected `is_unresponded` / `is_read_by_me` survive. The Set tracker makes repeated existing-room transitions idempotent, but it does not protect a later fetch merge. [Task 2]
- For a new room, `res.data[0]` can overwrite injected badge fields after counts and reconciliation Sets were already updated (`smartchat.js:927-940` in the earlier review). Preserve/reapply final badge fields, or compute both row state and aggregate transitions only after the authoritative fetch. [Task 2]
- `refreshChatRoomBadgeRealtime` spreads raw socket payloads before `handleSmartchatRealtimeUpdate` applies `DEFAULT_UPDATE_FIELDS`; feature gates must remove raw `is_unresponded` / `is_read_by_me`, not merely skip synthesized fields. For open rooms, remove `is_read_by_me` when `!is_unread_enabled || is_open_room`, because `Conversation.vue` `markRoomRead` owns open-room read state. [Task 3]
- MR !872's final reviewed state was `8150150f4fc9955cb7816288c90e511ff28a28b8` directly on `develop` `897245556ae6062ba6146996d527e212e5d334ce`: mergeable, conflict-free, zero divergence, discussions resolved; Node 22 focused smartchat/websocket suites passed 79 tests. This is snapshot-specific; no pipeline or manual QA was available. [Task 3]
- Equal-timestamp handling must strip raw `event_message.is_unresponded` after the payload spread while retaining `is_read_by_me:false` and `last_contact_date`; merely not synthesizing the field is insufficient. `addRealtimeContactToList` should synchronously dedupe, pop the capped tail, insert by sort direction, and reconcile its Set in one mutation. [Task 4]
- In the earlier !872 head, optimistic aggregate transitions preceded the authoritative fallback merge, equal timestamps were dropped by `<=` before unread injection, and concurrent missing-room fetches could blindly insert duplicates. Reconcile final fetched rows/counts, separate status freshness from message unread freshness, and single-flight/dedupe by contact. `oho_created_at` in !1291 was additive but also flowed into push payloads. [Task 4]

## Failures and how to do differently

- Symptom: the frontend diff looks symmetric but is not merge-safe. Cause: the backend `message.new` emission path in `oho-websocket@9141805` did not prove any sender-role guard, so the frontend cannot assume every emitted payload represents a customer-message increment case. Fix/pivot: verify producer-side contract fields before approving consumer-side counter logic. [Task 1]
- Symptom: unread counters still drift after local mark-read plus realtime updates. Cause: `markRoomRead()` decrements unread locally but does not synchronize `room.is_read_by_me`, so the later realtime transition logic can miss or double-handle unread state. Fix/pivot: trace optimistic local state and websocket transition state together, not as separate concerns. [Task 1]
- Symptom: counters are wrong when a room is not currently loaded. Cause: the increment path treats missing prior row state as already represented in the aggregate. Fix/pivot: require proof of previous aggregate membership before incrementing or skipping an adjustment. [Task 1]
- Symptom: a room falsely becomes unread after a delayed socket event. Cause: client `now` is substituted for the message's real timestamp and defeats the local-read comparison. Fix/pivot: preserve causal message ordering or discard/reconcile stale synthetic badge fields; do not equate synthetic time with socket ordering metadata. [Task 2]
- Symptom: aggregate counters and new-room visibility drift despite a successful fetch. Cause: deltas run before authoritative fetch, insertion can be blocked without a recovery path, and failed fetches insert incomplete data. Fix/pivot: fetch final row state before counting, and queue/retry/refetch every blocked or incomplete new-room path. [Task 2]
- Symptom: an optimized formatter wrapper says clean, or a negative visibility test passes. Cause: the wrapper is a proxy false positive, or another predicate already blocks insertion. Fix/pivot: run `./node_modules/.bin/prettier --check` directly and configure available menus (for example `['all']`) so the test actually isolates visibility. [Task 4]
- Symptom: unresponded returns after it was cleared. Cause: stale inbound events have no ordering guard. Fix/pivot: gate merges on version/order or reconcile against authoritative state. [Task 2]
- Symptom: a review is called an approval although the named branch was not checked out or the review ended before a verdict. Cause: the live worktree differed (`tk-sprint-2615/develop` rather than the requested branch) and the partial pass did not complete all six checks. Fix/pivot: verify branch/base before review and explicitly label conclusions as live-diff-only or incomplete. [Task 2]
- Symptom: disabled features or an open room receive false raw badge state even though synthetic-field gates look correct. Cause: raw socket fields were already in the spread payload; the first fix did not strip `is_read_by_me:false` for open rooms. Fix/pivot: test raw fields in optimistic and fallback paths, with flags disabled and open-room behavior, before approving. [Task 3]
- Symptom: passing focused tests are treated as full merge approval. Cause: GitLab conflicts/pipeline/manual QA were not checked. Fix/pivot: report exact MR merge metadata and disclose missing pipeline/manual QA separately from source/test evidence. [Task 3]

# Task Group: /Users/tualek/ohochat/script-oho / migrate-unread.ts correctness review
scope: Read-only correctness-review memory for `unread-unresponded/migrate-unread.ts`, especially whether `unread_by` / `is_unresponded` can be reconstructed safely, what checkpoint/cleanup guarantees actually exist, and what migration plan is honest enough to ship.
applies_to: cwd=/Users/tualek/ohochat/script-oho; reuse_rule=reuse for similar source-audit, production-readiness, or operational questions in this checkout when the user wants evidence-first analysis of `migrate-unread.ts` plus `oho-api@master`, but re-check the live file and master-branch source because line numbers, indexes, and invariants can drift.

## Task 1: Decide the final production plan, backfill `unread_by` only and leave `is_unresponded` absent

### rollout_summary_files

- rollout_summaries/2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl, updated_at=2026-07-21T10:51:30+00:00, thread_id=019f8442-2665-7082-a710-f24709dca055, final read-only pass converged to Option A and a single ordered rollout plan)

### keywords

- migrate-unread, unread_by, is_unresponded, option A, final plan, explain preflight, hint, checkpoint v3, residual IDs, fail-closed CLI, per-tenant rollout, oho-api@master

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 2: Review proposed `--mode=catchup`, exact reconstruction not safe from current live inputs

### rollout_summary_files

- rollout_summaries/2026-07-21T09-46-47-Fnuo-script_oho_catchup_adversarial_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl, updated_at=2026-07-21T09:58:39+00:00, thread_id=019f8412-1e0f-7e93-b5dd-807abd10d7d0, adversarial review rejected ship-ready exact-repair framing for catchup)

### keywords

- catchup, --mode=catchup, since watermark, classifyIsUnresponded, last_contact_date, last_active_at, Stream read state, eligible members, guardMisses, overCap, streamMissing, best effort, exact repair

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 3: Decide index and paging strategy, keep contact path minimal and fail closed on explain

### rollout_summary_files

- rollout_summaries/2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl, updated_at=2026-07-21T10:51:30+00:00, thread_id=019f8442-2665-7082-a710-f24709dca055, chose existing contact index plus one minimal group index with explain-based preflight)
- rollout_summaries/2026-07-21T09-46-47-Fnuo-script_oho_catchup_adversarial_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl, updated_at=2026-07-21T09:58:39+00:00, thread_id=019f8412-1e0f-7e93-b5dd-807abd10d7d0, earlier adversarial pass established that `_id` paging and `maxTimeMS` alone are not a scale guarantee)

### keywords

- pagedFind, _id sort, idx_business_id_v1, chat-session index, explain, hint, COLLSCAN, blocking sort, maxTimeMS, 5-6M, migration preflight

## Task 4: Adversarially verify flag ordering and migration hazards, flag-on-first refuted without write-prep gating

### rollout_summary_files

- rollout_summaries/2026-07-21T08-19-36-jN8a-unread_migration_flag_ordering_adversarial_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T15-19-37-019f83c2-4d93-7f91-b205-955f99879506.jsonl, updated_at=2026-07-21T08:28:49+00:00, thread_id=019f83c2-4d93-7f91-b205-955f99879506, adversarial source audit of 13 claims, safe ordering, missed hazards, and hardening priorities)

### keywords

- migrate-unread.ts, flag-on-first, flag || field-exists, read_by, unread_by, last_contact_date, secondaryPreferred, checkpoint, status file, analyze-business-size, monitor-migrate-unread, oho-api@master

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 5: Explain how to remove legacy `read_by` after unread migration, cleanup is a separate gated mode

### rollout_summary_files

- rollout_summaries/2026-07-14T04-57-08-S8ep-script_oho_unread_migration_read_by_cleanup_mode.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T11-57-08-019f5efc-691c-7000-8729-9eceb1cc207d.jsonl, updated_at=2026-07-14T06:43:07+00:00, thread_id=019f5efc-691c-7000-8729-9eceb1cc207d, operational question answered by tracing the existing cleanup mode and its guards)

### keywords

- script-oho, migrate-unread.ts, cleanup-read-by, read_by, unread_by, checkpoint, MongoDB, $unset, migration, confirm-cleanup-read-by

## Task 6: Review checkpoint semantics versus cleanup-read-by assumptions, cleanup can trust incomplete proof

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed checkpoint membership is coarser than "Stream-verified" comments imply)

### keywords

- migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, INCLUDE_PARTIAL, runLegacyReadByReconcilePass, skippedNoChannel, partial, completed, loadCheckpoint, backfillCompleted, verified, checkpoint safety

## Task 7: Review cleanup cutoff parity, cleanup lacks the 90-day bound used elsewhere

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed cleanup query omits `last_active_at` cutoff even though backfill/reconcile apply it)

### keywords

- readByCutoffDate, DAYS, last_active_at, cleanup-read-by, runReadByToUnreadByPass, runLegacyReadByReconcilePass, resolveBusinessIds, MAX_DOCS_PER_BIZ, filter parity, HAS_LEGACY_READ_BY

## Task 8: Review crash/resume safety and totals refactor, buildTotals wiring confirmed with checkpoint caveats

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed `buildTotals()` coverage and exposed non-atomic checkpoint writes)

### keywords

- CHECKPOINT_SUFFIX, STATUS_FILE, saveCheckpoint, saveStatus, buildTotals, temp-file rename, crash-safety, loadCheckpoint, processedCount, cleanup mode, resume

## User preferences

- when the user says `Design review, READ-ONLY, adversarial. Do NOT edit files. Do NOT run the migration or anything that connects to a database. Do NOT commit or switch branches.` -> keep similar migration reviews strictly non-invasive and evidence-first. [Task 2]
- when the user says `Adversarial code review, READ-ONLY` and `Do not trust the draft findings file's claims at face value` -> independently re-derive from source rather than agreeing with a draft. [Task 4]
- when the user asks for `file:line evidence` for every answer and says `If evidence is not in the repo, say "cannot verify from repo" rather than guessing` -> default to line-cited proof, and keep uncertainty explicit instead of smoothing it over. [Task 1][Task 2]
- when the user says `do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns` -> converge to one choice once the source audit is complete; do not hand back an open-ended concern list. [Task 1]
- when the central question is whether it is safe to run the migration before enabling flags -> answer with a concrete protocol and test proposed mitigations such as `flag || field-exists` against actual write and read/count paths. [Task 4]
- when the user says `If you must assume, name the assumption` -> separate evidence from assumptions explicitly in migration plans and rollout advice. [Task 1]
- when the user asks `ขอสรุปสั้นๆ` and then narrows to `ถ้างั้นถ้า run migration script ที่ script-oho แล้ว จะลบ read_byยังไง` -> switch to short, direct operational instructions once the concept is already established. [Task 5]
- when the user asks whether removing `read_by` closes the blockers -> separate `migrate unread_by` from `unset read_by` explicitly and state the safety boundary instead of answering as if they are the same step. [Task 5]
- when the user says `Trace the actual filter/gating logic, not the comments` and asks for line citations -> treat comments as non-binding, ground every behavioral claim in source lines/snippets, and do not smooth over gaps with intent-based reasoning. [Task 6][Task 7]
- when the user asks for `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` per item or `Answer EACH question below` -> keep the review tightly structured, question-by-question, and map each verdict to exact code lines. [Task 2][Task 6]

## Reusable knowledge

- The July 2026 source audits converged on Option A: `unread_by` is reconstructible from Stream read state plus current eligible-member lookup, but historical `is_unresponded` is not reconstructible honestly from Mongo state alone, so the safe plan is to leave `is_unresponded` absent rather than infer it. [Task 1][Task 2]
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` is the SET-side source of truth: `unread_by` is only written when unread is enabled and eligible members are known, and `is_unresponded` is only written when unresponded is enabled. Several CLEAR paths remain unconditional when the field exists. [Task 1][Task 2]
- Do not call clear writes unguarded: they are flag-ungated, but reviewed clear paths still use `last_contact_date` / event timestamp ordering and field-existence guards. The larger flag-order blocker is Step 0 legacy `read_by` conversion, which can rewrite `unread_by` from stale legacy state after live writes. [Task 4]
- Safer rollout framing is write-preparation first, then public unread/unresponded reads only after the tenant backfill is proven correct. `flag || field-exists` does not solve the ordering race once fields exist, and a long-running tenant pass is not an atomic “migrate then flip within minutes” boundary. [Task 4]
- `chat_status` is not a reliable historical reply classifier, and the inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that enables historical unresponded behavior must either accept that asymmetry or change API behavior first. [Task 1]
- The proposed catchup recomputes from current eligibility and Stream state rather than a historical event ledger. That means it can only be framed as best-effort rebaseline, not exact repair, especially when permissions changed during the window or some CLEAR paths did not move `last_contact_date` / `last_active_at`. [Task 2]
- Catchup’s current write guard checks only `_id`, `last_contact_date`, and `last_active_at`; group `is_unresponded` is not repaired there, and aggregate completion counters (`guardMisses`, `overCap`, `streamMissing`) are weaker than identity-based residual verification. [Task 2][Task 3]
- For migration execution, `pagedFind()` currently does `_id` keyset pagination without `hint()` / `explain()`. Contacts can reuse `idx_business_id_v1` for tenant-scoped `_id` scans, but group sessions need one minimal `_id`-ordered migration index, and execution should fail closed if explain shows `COLLSCAN` or blocking sort. [Task 1][Task 3]
- The CLI is already fail-closed: `.env.<env>` selection, matching `--confirm`, and explicit `--execute` are required. Production rollout should stay per-tenant, verify explain/index readiness first, then migrate and enable flags immediately after each tenant pass. [Task 1]
- `script-oho/unread-unresponded/migrate-unread.ts` already contains a dedicated cleanup path, `--mode=cleanup-read-by`; it is intentionally not auto-chained after backfill. Cleanup writes only when both `--execute` and `--confirm-cleanup-read-by` are present, and it unsets `read_by` on both `contacts` and `chat-sessions`. [Task 5]
- Cleanup is gated by current checkpoint membership only, and the checkpoint file stores only `{ completed: [...] }`, with no durable proof about reconcile coverage, skipped unresolved channels, or whether a business was verified under the current semantic config. [Task 5][Task 6][Task 8]
- `INCLUDE_PARTIAL` is opt-in only (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`), and `runLegacyReadByReconcilePass()` only runs inside that branch. A business can still become checkpoint-complete without legacy Stream verification because `partial` means budget exhaustion only and checkpointing checks only `!isDryRun && !result.partial`. [Task 6][Task 8]
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when a cutoff exists, but cleanup does not carry any date window. It filters only by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`. [Task 7]
- Cleanup mode reads checkpoint membership only and does not itself write checkpoint/status files, so it cannot overwrite backfill state by itself. `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but not cutoff/stream/partial semantics. `saveStatus()` uses a temp-file rename, while `saveCheckpoint()` writes directly and `loadCheckpoint()` degrades parse errors into an empty set. [Task 8]
- `buildTotals()` is the single totals builder now: both `saveStatus()` call sites use it, and no third hand-built totals literal remained. `processedCount++` happens before checkpoint eligibility is decided, so status can show business progress that has not been durably checkpointed. [Task 8]
- `secondaryPreferred` reads can make a guarded write appear not to have happened while the business is still checkpointed. Cleanup re-resolves current complete channels, analyzer coverage differs from migration (`mock_seed_key` exclusion), and monitor/report step schemas drift; treat these artifacts as separate, fallible signals. [Task 4]

## Failures and how to do differently

- Symptom: a migration plan keeps circling around heuristics for `is_unresponded`. Cause: the repo does not preserve a true historical reply ledger, and timestamp/classifier guesses overstate what can be reconstructed. Fix/pivot: leave `is_unresponded` absent and delete the migration paths rather than ship a heuristic classifier. [Task 1][Task 2]
- Symptom: a catchup proposal sounds exact because it uses current Stream read state plus guards. Cause: eligibility, timestamp changes, and CLEAR paths are not historically invertible from current live inputs. Fix/pivot: frame catchup as best effort or residual-repair only, not as ship-ready exact repair. [Task 2]
- Symptom: `maxTimeMS` or heartbeat logging is treated as proof the migration scales to 5-6M docs. Cause: timeouts and metrics are failure shields, not plan quality. Fix/pivot: inspect real index compatibility, require explain-based preflight, and fail closed on `COLLSCAN` / blocking sort. [Task 2][Task 3]
- Symptom: migration completion looks good because residual counts net to zero. Cause: aggregate counters can cancel unrelated documents and hide over-cap / skipped identities. Fix/pivot: use exact-ID residuals and retry tracking instead of numeric-only done criteria. [Task 1][Task 2][Task 3]
- Symptom: `read_by` cleanup is described as if it naturally follows migration. Cause: the script intentionally splits backfill and cleanup for rollback safety. Fix/pivot: keep the sequence explicit, `backfill/spot-check unread_by` first and `cleanup-read-by` second. [Task 5]
- Symptom: migration ordering is justified only by field decay or by “clear writes are ungated.” Cause: this ignores ordering guards, Step 0 stale legacy rewrites, live write races, and read/count exposure while a tenant is half-migrated. Fix/pivot: trace both write and read/count paths, separate write-prep from public rollout, and do not claim production facts such as index presence without an artifact. [Task 4]
- Symptom: comments say a business is "verified" or cleanup is "safe to drop". Cause: the code does not persist any proof beyond membership in `completed`. Fix/pivot: inspect what the code actually stores and what cleanup consumes before accepting safety claims. [Task 6]
- Symptom: cleanup appears to mirror backfill/reconcile scope. Cause: the file comments suggest full-population behavior, but the actual queries diverge and cleanup omits the `last_active_at` cutoff. Fix/pivot: compare query objects and cutoff propagation across every related pass. [Task 7]
- Symptom: future resume logic assumes checkpoint files are durable and config-specific. Cause: checkpoint writes are non-atomic and the suffix key omits semantic dimensions such as cutoff/stream/partial choices. Fix/pivot: treat checkpoint correctness and resume safety as separate review items, not as implied by shared file names alone. [Task 8]

# Task Group: /Users/tualek/ohochat/oho-api / unread-unresponded performance debugging
scope: Root-cause performance memory for unread/unresponded slowdowns in `oho-api`; use for attribution work that must separate expensive count paths from write-side stamping.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar unread/unresponded performance investigations in this repo, but re-check the current query shape, indexes, and incident evidence before assuming the same bottleneck still exists.

## Task 1: Diagnose unread/unresponded slowdown, root cause attributed to unread count query

### rollout_summary_files

- rollout_summaries/2026-07-11T15-21-15-jDcH-unread_unresponded_db_performance_root_cause.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T22-21-15-019f51c4-bc6d-7223-a93d-e4ee27e97fe7.jsonl, updated_at=2026-07-11T15:24:30+00:00, thread_id=019f51c4-bc6d-7223-a93d-e4ee27e97fe7, confirmed count-path root cause from incident evidence)

### keywords

- unread, unresponded, unread_by, is_unresponded, countDocuments, $nin, maxTimeMS, MongoDB, chat-search, message.read, performance regression

## User preferences

- when the user asked `ลองดูให้หน่อยว่า Feature unread/unrespone มีจุดไหนหรอที่ทำให้ Performance ของ databse slow` -> default to root-cause analysis with evidence, not a speculative fix. [Task 1]
- when the user narrowed it to `ตอน count unread unresponded หรอ ตอนที่ ส่ง message แล้วต้อง stamp is_unresponded กับ เอา id ออกจาก unread_by หรอ` -> compare read/query cost versus write/stamp cost explicitly and say which side dominates. [Task 1]

## Reusable knowledge

- The incident-backed bad path was unread `countDocuments` using `read_by: { $nin: [null, memberId] }`; on a multikey array this forced fetch-heavy counting across essentially the whole business and could dominate cluster CPU and connections. [Task 1]
- The mitigation pattern already present in the repo is: count unread with equality on `unread_by`, add `maxTimeMS(timeout || 30000)`, and fail soft with `null` so badge counts do not stall the main response. [Task 1]
- `message.read` in `src/webhook/stream.js` resolves the channel business before the feature-flag check, then `$pull`s the member id from `unread_by` on contact/chat-session; this is a real write path, but it is still targeted update-by-`_id`, not the main incident bottleneck described here. [Task 1]
- Write-side updates in `contact-send-message` and `member-send-message` mutate `unread_by` / `is_unresponded`, but this rollout validated they were secondary load compared with the old badge-count query shape. [Task 1]

## Failures and how to do differently

- Symptom: database slowdown around unread/unresponded polling. Cause: old unread count path used `$nin` on `read_by` without a timeout. Fix/pivot: treat `$nin` on an array count as an immediate red flag and inspect the count query before spending time on stamping writes. [Task 1]
- Symptom: performance debate gets stuck on whether stamping writes are expensive. Cause: read-path versus write-path costs were not separated. Fix/pivot: compare `countDocuments` path, write frequency, and targeted `_id` updates side by side and attribute the dominant cost explicitly. [Task 1]
- If a similar incident recurs, verify `docsExamined` / `keysExamined` or equivalent incident evidence on the count path first; do not rely on speculative code reading alone. [Task 1]

# Task Group: /Users/tualek/life / monthly finance baseline from ad-hoc notes
scope: Current personal-finance baseline figures and planning rules preserved only by authoritative ad-hoc notes after rollout-backed memory was pruned.
applies_to: cwd=/Users/tualek/life; reuse_rule=reuse for monthly cash-flow planning only when the user is still using the 2026-05-12 baseline, and treat older deleted rollout-derived finance guidance as stale unless the user reconfirms it.

## Task 1: Consolidate the latest monthly finance baseline from authoritative ad-hoc notes, success

### rollout_summary_files

- extensions/ad_hoc/notes/20260512-164155-finance-utilities-tuition-baseline.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-164155-finance-utilities-tuition-baseline.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)
- extensions/ad_hoc/notes/20260512-161531-finance-expense-baseline.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-161531-finance-expense-baseline.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)
- extensions/ad_hoc/notes/20260512-162222-paynext-usage-note.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-162222-paynext-usage-note.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)

### keywords

- finance baseline, net salary 37950, wife monthly support, tuition saving, water electric, utilities 4500, Paynext 3300, Promise, XU credit card, food transport, monthly shortfall

## User preferences

- when planning monthly cash flow, the user confirmed `Do not include wife monthly support as income` -> keep the baseline conservative and count only the user-controlled salary cash flow. [Task 1] [ad-hoc note]
- when planning monthly cash flow, the user confirmed `Include tuition saving in the monthly plan` and `Include water/electric as a monthly expense` -> do not treat tuition or utilities as optional side notes. [Task 1] [ad-hoc note]
- when cash is tight, the user wants `Paynext 3,300/month` treated as part of the expense baseline, but also remembered as a temporary bridge for fuel, food, and 7-Eleven purchases. [Task 1] [ad-hoc note]

## Reusable knowledge

- The latest confirmed probation-pay baseline is gross `40,000` (`38,500` salary + `1,500` WFH), with deductions `850` social security plus `3%` withholding tax, for net salary estimate `37,950/month`. [Task 1] [ad-hoc note]
- The confirmed monthly expense list currently includes: rent `11,000`; Promise `4,170`; phone `1,400`; XU/credit card `10,799`; Coway `399`; LG sub `3,300`; AIA `1,510`; Thunder `600`; Shopee Pay Later `310`; Finnix `600`; TikTok paylater `2,400`; Paynext `3,300`; food/transport `9,700`; tuition saving `5,875`. [Task 1] [ad-hoc note]
- Total monthly expenses are `51,664` with tuition saving and Paynext, or `45,789` without tuition saving but still with Paynext. [Task 1] [ad-hoc note]
- Water/electric should be budgeted around `4,300-4,500`, with an upper planning cap around `5,000/month`. [Task 1] [ad-hoc note]
- With utilities plus tuition saving included, the current monthly baseline becomes `55,964-56,664`, which implies a shortfall around `18,014-18,714/month` against the `37,950` net salary baseline. [Task 1] [ad-hoc note]

## Failures and how to do differently

- Do not reuse older finance memories that excluded utilities, counted wife support as income, or used stale salary math; the surviving authoritative baseline is the 2026-05-12 ad-hoc note set. [Task 1] [ad-hoc note]
- Do not treat Paynext only as debt repayment or only as spending flexibility. In this memory set it is both a recurring `3,300/month` obligation and a short-term cash substitute when fuel or food must still be covered. [Task 1] [ad-hoc note]
- Do not present a monthly plan as balanced unless utilities and tuition saving are included explicitly; the authoritative notes say the baseline remains materially short even before any new discretionary spending. [Task 1] [ad-hoc note]
