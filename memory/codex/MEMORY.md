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
- when the user says `run git status/git diff` and `verify with actual code inspection (not assumption)` -> inspect the live repo state first, not summaries or stale worktree assumptions. [Task 2][Task 3]
- when the user calls out pre-existing failing suites that must not be blamed on the diff -> separate environment/repo noise from a diff-caused regression. [Task 2]
- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged. [Task 3][Task 4][Task 6]
- when the user emphasized `correctness bugs (especially cross-member cache poisoning)` -> prioritize scope isolation, member identity, and stale-data correctness before style or minor test coverage. [Task 1]
- when the user asked `ถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม` -> review against the contract `feature off = no behavior + no collateral impact`, not just whether the flag is referenced somewhere. [Task 3]

## Reusable knowledge

- `computeBadgeCounts` is called by contact chat search and group search with `countBaseQuery`, `countMemberId`, and a label. `buildCountBaseQuery()` preserves business/tab/channel/sale-visibility scope while typed unread/unresponded fields are stripped, and `unread_by: countMemberId` makes member scope part of the cache filter. [Task 1]
- `getCachedBadgeCount()` treats numeric `0` as a hit and `undefined` as a miss; the reviewed TTL is numeric Redis seconds. `src/index.js` sets `global.Promise = require('bluebird')`, so production settlement inspection differs from native Jest promises. [Task 1]
- `service.hooks(hooks)` is only safe when the hooks module exports exactly lifecycle namespaces; any extra enumerable export becomes an invalid Feathers hook type, which is why `contact-send-message.service.js` booted incorrectly while `notify.service.js` stayed safe. [Task 2]
- `config/default.json` sets `paginate.max` to `50`; the reviewed dynamic max preserved that behavior. `getMessagePreviewText()` safely ignores non-string `data.label` from `qs.parse` and falls back to `message.text` / `กดปุ่ม`; `allowJs: true` with `checkJs: false` does not typecheck JS callers. [Task 2]
- `convertUnreadUnrespondedQuery.ts` has a special both-flags path; trace the full lifecycle through `countBaseQuery`, `TYPED_FILTER_FIELDS`, parser coercion, and later visibility rewrites. Any query shape that adds `$or` / `$and` needs matching parser/converter updates. [Task 4][Task 6]
- `buildClearUnreadUnrespondedPayload` is intentionally unconditional on the clear-write side so feature toggles do not leave stuck `is_unresponded` / unread state. [Task 3]
- `bulk.class.js`, `compute-badge-counts.ts`, `channel-eligible-members.ts`, and `cache/index.js` affect propagation and failure behavior; `cache/index.js` uses a 3s race timeout. [Task 4][Task 5]

## Failures and how to do differently

- Symptom: a short-TTL Redis cache times out but a stale value appears later. Cause: `raceCommandTimeout()` does not cancel the command and Redis 3.x has `enable_offline_queue` on by default, so a timed-out `SETEX` may replay after reconnect. Fix/pivot: treat `timeout does not cancel command + offline queue enabled` as a serious bounded-staleness risk; distinguish it from key-isolation concerns. [Task 1]
- Symptom: cache mitigation still recreates DB load on concurrent misses. Cause: no single-flight/distributed lock around `computeBadgeCounts`. Fix/pivot: audit miss burst/stampede behavior separately from TTL and correctness. [Task 1]
- Symptom: cache specs look sufficient but hide boundary failures. Cause: `badge-count-cache` is mocked, so orchestration tests do not exercise serialization or Redis behavior. Fix/pivot: inspect the real helper boundary and use targeted runtime probes; `ObjectId` stringification was verified not to be the collision source. [Task 1]
- Symptom: removing a helper export looks like safe cleanup but the service fails at boot. Cause: whole-module hook registration sees an extra export as an invalid hook type. Fix/pivot: inspect `service.hooks(hooks)` bootstrap semantics before approving hook-module cleanup. [Task 2]
- Symptom: deleted tests look redundant by file name but real coverage drops. Cause: payload-helper specs do not replace service-boot assertions, hook-registration coverage, or exact write-shape / ordering assertions. Fix/pivot: compare deleted assertions against surviving tests branch by branch. [Task 2]
- Symptom: unread/unresponded filter breaks with `search` or sale visibility. Cause: typed-filter coercion and `addVisibilityFilter()` can rebuild `context.params.query`. Fix/pivot: audit the full hook chain, not only the injection helper. [Task 4][Task 6]
- Symptom: sandboxed Jest failures are misattributed to the diff. Cause: duplicate-worktree mocks and haste-map write `EPERM`; repo-wide typecheck may also contain unrelated errors. Fix/pivot: report the exact blocker and use static tracing/targeted probes rather than claim behavioral proof. [Task 1][Task 2][Task 4][Task 5]

# Task Group: /Users/tualek/ohochat/oho-web-app / realtime unread-unresponded badge review
scope: Read-only review memory for frontend unread/unresponded badge diffs in `oho-web-app`, especially contract checks against `oho-websocket`, Vue 2 reactivity boundaries, and merge-safety of optimistic/realtime counter updates.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app; reuse_rule=reuse for similar review-only work in this checkout when a frontend badge/count diff depends on sibling backend event payloads, but re-read the current frontend diff and backend commit before reusing any conclusion.

## Task 1: Review frontend increment/decrement badge logic for realtime unread/unresponded updates, not merge-safe

### rollout_summary_files

- rollout_summaries/2026-07-14T08-22-37-rN8j-oho_web_app_unread_unresponded_realtime_badge_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T15-22-37-019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df.jsonl, updated_at=2026-07-14T08:33:02+00:00, thread_id=019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df, review-only diff check against `oho-websocket@9141805` found sender-role and unread-state blockers)

### keywords

- code-review, smartchat, groupchat, unread_count, unresponded_count, is_read_by_me, is_unresponded, Vuex, realtime, websocket, oho-websocket@9141805, stale-event-guard, optimistic decrement, Vue 2 reactivity

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## User preferences

- when the user says `This is a review-only request. Do not fix anything, do not edit any files. Only report findings.` -> stay read-only and avoid proposing or applying patches unless explicitly asked. [Task 1]
- when the user says `Ground every claim in the actual diff content and the actual oho-websocket commit 9141805 content that you read yourself` -> cite exact file/line/field evidence and separate verified facts from inference. [Task 1]
- when the user wants findings grouped by severity and a one-line merge verdict -> preserve that compact review shape instead of drifting into a generic essay. [Task 1]

## Reusable knowledge

- Backend commit `9141805` in `oho-websocket` emits `is_read_by_me:false` and `is_unresponded:true` on customer message events when the stale-event guard passes; `message.read` only `$pull`s `unread_by` and does not emit `is_read_by_me:true`. [Task 1]
- `store/modules/groupchat.js` already defines `unread_count` and `unresponded_count` in initial state, but `store/modules/smartchat.js` `contact_list` initial/reset shapes do not include those fields, so creating them later can hit a Vue 2 reactivity gap during reset/load windows. [Task 1]
- `components/Smartchat/Conversation.vue` already sets `room.is_unresponded = false` before decrementing in the optimistic unresponded flow, which is why that path avoids a duplicate decrement when the realtime event lands. [Task 1]
- `components/Smartchat/RoomList.vue` treats missing or legacy `is_read_by_me` as read in the list fallback, which explains the reviewed diff's asymmetry (`is_unresponded === true` vs `is_read_by_me !== false`) for already-known rows. [Task 1]

## Failures and how to do differently

- Symptom: the frontend diff looks symmetric but is not merge-safe. Cause: the backend `message.new` emission path in `oho-websocket@9141805` did not prove any sender-role guard, so the frontend cannot assume every emitted payload represents a customer-message increment case. Fix/pivot: verify producer-side contract fields before approving consumer-side counter logic. [Task 1]
- Symptom: unread counters still drift after local mark-read plus realtime updates. Cause: `markRoomRead()` decrements unread locally but does not synchronize `room.is_read_by_me`, so the later realtime transition logic can miss or double-handle unread state. Fix/pivot: trace optimistic local state and websocket transition state together, not as separate concerns. [Task 1]
- Symptom: counters are wrong when a room is not currently loaded. Cause: the increment path treats missing prior row state as already represented in the aggregate. Fix/pivot: require proof of previous aggregate membership before incrementing or skipping an adjustment. [Task 1]

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

## Task 4: Explain how to remove legacy `read_by` after unread migration, cleanup is a separate gated mode

### rollout_summary_files

- rollout_summaries/2026-07-14T04-57-08-S8ep-script_oho_unread_migration_read_by_cleanup_mode.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T11-57-08-019f5efc-691c-7000-8729-9eceb1cc207d.jsonl, updated_at=2026-07-14T06:43:07+00:00, thread_id=019f5efc-691c-7000-8729-9eceb1cc207d, operational question answered by tracing the existing cleanup mode and its guards)

### keywords

- script-oho, migrate-unread.ts, cleanup-read-by, read_by, unread_by, checkpoint, MongoDB, $unset, migration, confirm-cleanup-read-by

## Task 5: Review checkpoint semantics versus cleanup-read-by assumptions, cleanup can trust incomplete proof

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed checkpoint membership is coarser than "Stream-verified" comments imply)

### keywords

- migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, INCLUDE_PARTIAL, runLegacyReadByReconcilePass, skippedNoChannel, partial, completed, loadCheckpoint, backfillCompleted, verified, checkpoint safety

## Task 6: Review cleanup cutoff parity, cleanup lacks the 90-day bound used elsewhere

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed cleanup query omits `last_active_at` cutoff even though backfill/reconcile apply it)

### keywords

- readByCutoffDate, DAYS, last_active_at, cleanup-read-by, runReadByToUnreadByPass, runLegacyReadByReconcilePass, resolveBusinessIds, MAX_DOCS_PER_BIZ, filter parity, HAS_LEGACY_READ_BY

## Task 7: Review crash/resume safety and totals refactor, buildTotals wiring confirmed with checkpoint caveats

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed `buildTotals()` coverage and exposed non-atomic checkpoint writes)

### keywords

- CHECKPOINT_SUFFIX, STATUS_FILE, saveCheckpoint, saveStatus, buildTotals, temp-file rename, crash-safety, loadCheckpoint, processedCount, cleanup mode, resume

## User preferences

- when the user says `Design review, READ-ONLY, adversarial. Do NOT edit files. Do NOT run the migration or anything that connects to a database. Do NOT commit or switch branches.` -> keep similar migration reviews strictly non-invasive and evidence-first. [Task 2]
- when the user asks for `file:line evidence` for every answer and says `If evidence is not in the repo, say "cannot verify from repo" rather than guessing` -> default to line-cited proof, and keep uncertainty explicit instead of smoothing it over. [Task 1][Task 2]
- when the user says `do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns` -> converge to one choice once the source audit is complete; do not hand back an open-ended concern list. [Task 1]
- when the user says `If you must assume, name the assumption` -> separate evidence from assumptions explicitly in migration plans and rollout advice. [Task 1]
- when the user asks `ขอสรุปสั้นๆ` and then narrows to `ถ้างั้นถ้า run migration script ที่ script-oho แล้ว จะลบ read_byยังไง` -> switch to short, direct operational instructions once the concept is already established. [Task 4]
- when the user asks whether removing `read_by` closes the blockers -> separate `migrate unread_by` from `unset read_by` explicitly and state the safety boundary instead of answering as if they are the same step. [Task 4]
- when the user says `Trace the actual filter/gating logic, not the comments` and asks for line citations -> treat comments as non-binding, ground every behavioral claim in source lines/snippets, and do not smooth over gaps with intent-based reasoning. [Task 5][Task 6]
- when the user asks for `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` per item or `Answer EACH question below` -> keep the review tightly structured, question-by-question, and map each verdict to exact code lines. [Task 2][Task 5]

## Reusable knowledge

- The July 2026 source audits converged on Option A: `unread_by` is reconstructible from Stream read state plus current eligible-member lookup, but historical `is_unresponded` is not reconstructible honestly from Mongo state alone, so the safe plan is to leave `is_unresponded` absent rather than infer it. [Task 1][Task 2]
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` is the SET-side source of truth: `unread_by` is only written when unread is enabled and eligible members are known, and `is_unresponded` is only written when unresponded is enabled. Several CLEAR paths remain unconditional when the field exists. [Task 1][Task 2]
- `chat_status` is not a reliable historical reply classifier, and the inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that enables historical unresponded behavior must either accept that asymmetry or change API behavior first. [Task 1]
- The proposed catchup recomputes from current eligibility and Stream state rather than a historical event ledger. That means it can only be framed as best-effort rebaseline, not exact repair, especially when permissions changed during the window or some CLEAR paths did not move `last_contact_date` / `last_active_at`. [Task 2]
- Catchup’s current write guard checks only `_id`, `last_contact_date`, and `last_active_at`; group `is_unresponded` is not repaired there, and aggregate completion counters (`guardMisses`, `overCap`, `streamMissing`) are weaker than identity-based residual verification. [Task 2][Task 3]
- For migration execution, `pagedFind()` currently does `_id` keyset pagination without `hint()` / `explain()`. Contacts can reuse `idx_business_id_v1` for tenant-scoped `_id` scans, but group sessions need one minimal `_id`-ordered migration index, and execution should fail closed if explain shows `COLLSCAN` or blocking sort. [Task 1][Task 3]
- The CLI is already fail-closed: `.env.<env>` selection, matching `--confirm`, and explicit `--execute` are required. Production rollout should stay per-tenant, verify explain/index readiness first, then migrate and enable flags immediately after each tenant pass. [Task 1]
- `script-oho/unread-unresponded/migrate-unread.ts` already contains a dedicated cleanup path, `--mode=cleanup-read-by`; it is intentionally not auto-chained after backfill. Cleanup writes only when both `--execute` and `--confirm-cleanup-read-by` are present, and it unsets `read_by` on both `contacts` and `chat-sessions`. [Task 4]
- Cleanup is gated by current checkpoint membership only, and the checkpoint file stores only `{ completed: [...] }`, with no durable proof about reconcile coverage, skipped unresolved channels, or whether a business was verified under the current semantic config. [Task 4][Task 5][Task 7]
- `INCLUDE_PARTIAL` is opt-in only (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`), and `runLegacyReadByReconcilePass()` only runs inside that branch. A business can still become checkpoint-complete without legacy Stream verification because `partial` means budget exhaustion only and checkpointing checks only `!isDryRun && !result.partial`. [Task 5][Task 7]
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when a cutoff exists, but cleanup does not carry any date window. It filters only by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`. [Task 6]
- Cleanup mode reads checkpoint membership only and does not itself write checkpoint/status files, so it cannot overwrite backfill state by itself. `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but not cutoff/stream/partial semantics. `saveStatus()` uses a temp-file rename, while `saveCheckpoint()` writes directly and `loadCheckpoint()` degrades parse errors into an empty set. [Task 7]
- `buildTotals()` is the single totals builder now: both `saveStatus()` call sites use it, and no third hand-built totals literal remained. `processedCount++` happens before checkpoint eligibility is decided, so status can show business progress that has not been durably checkpointed. [Task 7]

## Failures and how to do differently

- Symptom: a migration plan keeps circling around heuristics for `is_unresponded`. Cause: the repo does not preserve a true historical reply ledger, and timestamp/classifier guesses overstate what can be reconstructed. Fix/pivot: leave `is_unresponded` absent and delete the migration paths rather than ship a heuristic classifier. [Task 1][Task 2]
- Symptom: a catchup proposal sounds exact because it uses current Stream read state plus guards. Cause: eligibility, timestamp changes, and CLEAR paths are not historically invertible from current live inputs. Fix/pivot: frame catchup as best effort or residual-repair only, not as ship-ready exact repair. [Task 2]
- Symptom: `maxTimeMS` or heartbeat logging is treated as proof the migration scales to 5-6M docs. Cause: timeouts and metrics are failure shields, not plan quality. Fix/pivot: inspect real index compatibility, require explain-based preflight, and fail closed on `COLLSCAN` / blocking sort. [Task 2][Task 3]
- Symptom: migration completion looks good because residual counts net to zero. Cause: aggregate counters can cancel unrelated documents and hide over-cap / skipped identities. Fix/pivot: use exact-ID residuals and retry tracking instead of numeric-only done criteria. [Task 1][Task 2][Task 3]
- Symptom: `read_by` cleanup is described as if it naturally follows migration. Cause: the script intentionally splits backfill and cleanup for rollback safety. Fix/pivot: keep the sequence explicit, `backfill/spot-check unread_by` first and `cleanup-read-by` second. [Task 4]
- Symptom: comments say a business is "verified" or cleanup is "safe to drop". Cause: the code does not persist any proof beyond membership in `completed`. Fix/pivot: inspect what the code actually stores and what cleanup consumes before accepting safety claims. [Task 5]
- Symptom: cleanup appears to mirror backfill/reconcile scope. Cause: the file comments suggest full-population behavior, but the actual queries diverge and cleanup omits the `last_active_at` cutoff. Fix/pivot: compare query objects and cutoff propagation across every related pass. [Task 6]
- Symptom: future resume logic assumes checkpoint files are durable and config-specific. Cause: checkpoint writes are non-atomic and the suffix key omits semantic dimensions such as cutoff/stream/partial choices. Fix/pivot: treat checkpoint correctness and resume safety as separate review items, not as implied by shared file names alone. [Task 7]

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
