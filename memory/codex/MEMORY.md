# Task Group: /Users/tualek/ohochat / cross-repo unread-unresponded deploy-gate reviews
scope: Read-only cross-repo review memory for unread/unresponded fixes spanning `oho-api`, `oho-websocket`, and `oho-web-app`; use for deploy-gate audits, MR review follow-ups, or "is this actually fixed?" checks where write gates, realtime broadcasts, and frontend counters must align.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse for similar cross-repo review-only audits across these repos, but always re-check live `git status` / `git diff` in each repo and current commit semantics before treating any finding as still open.

## Task 1: Cross-repo deploy-gate review of round-2 unread/unresponded fixes, websocket looked clean but frontend and bulk-send risks remained

### rollout_summary_files

- rollout_summaries/2026-07-15T01-16-06-ttm9-cross_repo_unread_unresponded_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T08-16-06-019f6358-6a26-7531-ab13-b4360a1b5799.jsonl, updated_at=2026-07-15T01:29:28+00:00, thread_id=019f6358-6a26-7531-ab13-b4360a1b5799, round-2 deploy-gate pass verified live diffs in all three repos and found frontend pagination/rollback drift plus `oho-api` mixed-success timestamp collateral risk)

### keywords

- deploy gate, git diff, git status, unread, unresponded, bulk.class.js, getLastStreamMessageTimestamp, instagram parity, channel-eligible-members, single-flight, optimistic-flag-count-tracker, markRoomRead, last_read, pagination, Vue 2 reactivity

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 2: Cross-repo deploy-gate review of realtime badge fixes, improvements landed but security and rollback risks remained

### rollout_summary_files

- rollout_summaries/2026-07-14T18-31-25-OSyU-oho_unread_unresponded_cross_repo_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T01-31-25-019f61e5-e958-75d1-ae40-e7dc4ffd3d5c.jsonl, updated_at=2026-07-14T18:42:39+00:00, thread_id=019f61e5-e958-75d1-ae40-e7dc4ffd3d5c, stricter deploy-gate pass verified real repo state first and found bulk-send timestamp, websocket cache, and frontend rollback/counter edge cases)

### keywords

- deploy gate, git diff, git status, unread, unresponded, modifiedCount, channel-eligible-members, Firebase Remote Config, feature_flags_api_keys, checked_channels, Conversation.vue, optimistic-flag-count-tracker, bulk.class.js, get-last-stream-message-timestamp

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 3: Cross-repo review of MR !1285 unread/unresponded changes, websocket blocker plus frontend/backend drift risks

### rollout_summary_files

- rollout_summaries/2026-07-14T15-18-52-8PEC-mr1285_cross_repo_unread_unresponded_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T22-18-52-019f6135-9fb1-7b72-b968-52241fd501a2.jsonl, updated_at=2026-07-14T15:35:19+00:00, thread_id=019f6135-9fb1-7b72-b968-52241fd501a2, read-only review across `oho-api`, `oho-websocket`, and `oho-web-app` found a websocket `message.read` blocker and frontend Remote Config / optimistic-counter drift risks)

### keywords

- cross-repo review, unread, unresponded, mr-1285, message.read, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, emitEligibilityScopedUnrespondedUpdate, businessChannel, Remote Config, optimistic-flag-count-tracker, groupchat

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## User preferences

- when the user says `Do NOT trust the summary below as fact — run git diff / git status yourself in each repo and verify every claim against the actual diff.` -> pin the real repo/worktree state first and treat summaries as suspect until the live diff matches them. [Task 1][Task 2]
- when the user says `read plan.md` / prior review docs first and `do not re-flag findings already documented as fixed there` -> rebase on prior review history and avoid duplicate findings. [Task 3]
- when the user says `Do NOT edit, stage, commit, or run any command that mutates files or git state.` -> keep similar cross-repo reviews strictly read-only. [Task 1][Task 2][Task 3]
- when the user wants `structured findings report, ranked by severity` with exact `file:line` evidence and a one-line verdict -> stay compact, judgmental, and evidence-first instead of exploratory. [Task 1][Task 2][Task 3]
- when the user asks to check Instagram shape parity or whether a new test would still fail if the fix were reverted -> inspect both platform paths independently and mentally revert the fix before trusting a new regression test. [Task 1]
- when the user asks whether a websocket or frontend port is `actually faithful` -> compare semantics and state transitions, not just line similarity. [Task 1][Task 2]
- when the user asks for a complete flag/write/broadcast audit or to check pagination/performance implications -> trace UI mutations from socket events, authoritative fetch reconciliation, and append paths too, not just backend writes. [Task 1][Task 2][Task 3]

## Reusable knowledge

- The durable contract across these reviews is: SET writes are flag-gated, CLEAR writes are unconditional, and realtime broadcasts are flag-gated. Use that split when auditing each repo so a correct write-path change does not hide an incorrect broadcast-path gate. [Task 1][Task 2][Task 3]
- For this task family, the high-value trace is end to end: payload source -> guard -> DB write result -> broadcast audience/result -> frontend merge/filter logic. The reviews repeatedly found partially correct fixes that only became visible when the whole chain was traced. [Task 1][Task 2][Task 3]
- In `oho-api`, `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for `unread_by` and `is_unresponded:true`, while `buildClearUnreadUnrespondedPayload()` intentionally stays unconditional to avoid flag-toggle stuck state. [Task 3]
- The latest `oho-api` bulk-send review verified Facebook and Instagram reply services share the same `response.data` success / `GeneralError` failure contract, and the new mixed-success Facebook test calls `getLastStreamMessageTimestamp()` on both the merged payload and the successful-only payload. [Task 1]
- In `oho-websocket`, `message.read` is the websocket-side CLEAR site; newer code improved it by doing the `$pull` first, keeping `new:true` plus `.select('business_id updated_at').lean()`, and using `modifiedCount > 0` to suppress no-op broadcasts, but downstream consumers can still drop the emitted `updated_at` as stale. [Task 1][Task 2][Task 3]
- Group broadcast scoping moved from whole-business rooms toward eligible-member channels. The latest deploy-gate pass verified `channel-eligible-members.js` is now fresh-query plus single-flight dedup and fail-closed on unknown eligibility; older cache-TTL concerns are useful only when reviewing earlier rounds or regressions back toward cached behavior. [Task 1][Task 2]
- The frontend guidance changed across these rollouts: the earlier cross-repo review found browser Remote Config could overwrite API-authenticated flags, while the later deploy-gate review validated the fix via `feature_flags_api_keys` plus `plugins/firebase-remote-config.js:52-56` making browser updates non-authoritative for API-owned keys. [Task 2][Task 3]
- `utils/optimistic-flag-count-tracker.js` now records every increment in its Set and deletes on every decrement; round-2 fixed one known offscreen double-count path, but correctness still depends on seeding or reconciling those Sets from authoritative fetches on every full replacement and pagination append path. [Task 1][Task 2]
- `Conversation.vue` now uses a function-local `did_decrement_unread_count` flag, which removes one rollback leak, but `markRead()` still needs its optimistic `last_read` cursor unwound on failure or retries can skip the needed unread decrement. [Task 1]

## Failures and how to do differently

- Symptom: a review inherits wrong assumptions from a written summary. Cause: the claimed fix set and the live worktree diverge. Fix/pivot: always run `git status` and inspect the actual diff in every repo before trusting summary text or prior conclusions. [Task 1][Task 2]
- Symptom: a fix looks faithful because the ported code resembles another repo. Cause: semantic differences hide in guards, timestamps, payload fields, or audience selection. Fix/pivot: compare behavior contracts, not line similarity, especially for websocket ports and frontend consumers. [Task 1][Task 2][Task 3]
- Symptom: websocket audience scoping gets reviewed against stale assumptions. Cause: the helper changed across rounds from cache-sensitive logic to fresh-query single-flight logic. Fix/pivot: inspect the current `channel-eligible-members.js` implementation before reasoning about revocation risk or QPS/load tradeoffs, and state explicitly when telemetry is missing. [Task 1][Task 2]
- Symptom: bulk-send clear logic looks fixed once it skips the all-fail case. Cause: the clear guard is correct only partially if `lastMessageTimestamp` still comes from merged payloads that include failed deliveries, or if only one platform path is regression-tested. Fix/pivot: trace the timestamp source as carefully as the boolean success guard and check Facebook/Instagram parity separately. [Task 1][Task 2]
- Symptom: unread badge drift seems resolved after a Set-based tracker patch. Cause: reconciliation may only cover full-list replacement while append pagination and `last_read` rollback paths still drift. Fix/pivot: inspect `set*List` and `add*List` mutations together, and verify failure rollback unwinds both counters and cursor state. [Task 1][Task 2]
- Symptom: validation sounds stronger than it is because syntax checks passed. Cause: `git diff --check`, `node --check`, or wiring-only tests do not prove behavior; sandboxed read-only runs can also block Jest temp writes. Fix/pivot: report those checks as shallow confidence only and say explicitly when deeper behavioral proof could not run. [Task 1][Task 2][Task 3]

# Task Group: /Users/tualek/ohochat/oho-api / Thai code review of unread-unresponded changes
scope: Review-only memory for `oho-api` unread/unresponded diffs, especially query composition, flag-off contract checks, validation limits, and review reporting style; use when the user asks whether backend changes are okay, not when they ask for direct implementation.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar code reviews in this repo or nearby search-hook work, but re-verify exact query shape, failing tests, and worktree-specific files before treating any blocker as still open.

## Task 1: Review unread/unresponded flag-gated changes in `mr-1285-fixes`, flag-off contract regressions found

### rollout_summary_files

- rollout_summaries/2026-07-14T10-49-31-cVgx-thai_unread_unresponded_flag_off_review_mr_1285_fixes.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T17-49-31-019f603f-0763-7a32-9125-816c9dd5f2b5.jsonl, updated_at=2026-07-14T11:40:37+00:00, thread_id=019f603f-0763-7a32-9125-816c9dd5f2b5, corrected to the real `.claude/worktrees/mr-1285-fixes` diff and found flag-off contract / emitter-audience blockers)

### keywords

- unread, unresponded, flag-off, mr-1285-fixes, emitChatSessionStatusUpdatedEvent, emitContactUnrespondedStatusUpdatedEvent, buildClearUnreadUnrespondedPayload, convertUnreadUnrespondedQuery, channel-eligible-members, worktree verification, Thai review

## Task 2: Review `oho-api` unread/unresponded and bulk-send changes in `mr-1285-fixes`, blocker findings

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, worktree-specific review found blocker-level query-composition risks)

### keywords

- oho-api, code review, unread, unresponded, convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, cacheService, Redis, Jest, Mongo query composition

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 3: Verify unread/unresponded rollout coverage and remaining blockers, partial confidence

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, targeted Jest passed but Mongo-backed proof was unavailable)

### keywords

- MONGODB_URI, compute-badge-counts, Promise.allSettled, channel-eligible-members, cacheService, Redis timeout, bot-send-message.hooks.spec.js, quick-reply failures, updateContactProfile

## Task 4: Review earlier unread/unresponded diff, blocker findings

### rollout_summary_files

- rollout_summaries/2026-06-26T10-07-42-z14x-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl, updated_at=2026-06-26T10:19:09+00:00, thread_id=019f0366-4780-7b21-a9b4-c309436efcc5, earlier review established the same hook-chain failure pattern)

### keywords

- oho-api, unread, unresponded, search-query-converter, addVisibilityFilter, bulk send, convertUnreadUnrespondedQuery, Jest, type-check, Mongo query composition

## User preferences

- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged. [Task 1][Task 2][Task 4]
- when the user asked only whether the changes were okay -> stay review-first and findings-first; do not jump into fixing code unless asked. [Task 1][Task 2][Task 3][Task 4]
- when the user asked `ถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม` -> review against the contract `feature off = no behavior + no collateral impact`, not just whether the flag is referenced somewhere. [Task 1]
- when multiple worktrees exist, verify the real review target before making claims; the 2026-07-14 rollout had to discard an earlier wrong-worktree pass and re-anchor to `.claude/worktrees/mr-1285-fixes`. [Task 1]
- when the review flow is in Thai and the user is evaluating a local diff -> concise Thai blocker findings are the right default, not implementation-heavy prose. [Task 1][Task 2][Task 3]

## Reusable knowledge

- `convertUnreadUnrespondedQuery.ts` has a special both-flags path; the June and July reviews say this area must be traced through the full query lifecycle, not judged in isolation. `countBaseQuery`, `TYPED_FILTER_FIELDS`, parser coercion, and later visibility rewrites all affect whether the unread/unresponded shape survives. [Task 2][Task 4]
- `search-query-converter.ts` and related typed-filter handling explicitly preserve only `read_by`, `is_unresponded`, and `read_by.0`; any future query-shape change that introduces `$or` / `$and` needs matching parser and converter updates. [Task 2][Task 4]
- `buildClearUnreadUnrespondedPayload` is intentionally unconditional on the clear-write side and is used by multiple runtime paths; when flags toggle off and back on, unconditional clear logic prevents stuck `is_unresponded` / unread state. [Task 1]
- `convertUnreadUnrespondedQuery` plus its spec are the early gate for unread/unresponded query semantics, while `emit-chat-session-event.spec.ts` is the best focused proof for broadcast behavior including flag-off fan-out. [Task 1]
- `bulk.class.js` now updates contact state directly, and the rollout also touched cache and broadcast-adjacent utilities: `src/utils/compute-badge-counts.ts` uses `Promise.allSettled`, `src/utils/channel-eligible-members.ts` returns `null` on lookup failure or >2000 eligible members, and `src/utils/cache/index.js` wraps Redis commands with a 3s timeout. These affect how unread state propagates and fails. [Task 2][Task 3]
- `src/models/contact.model.spec.ts` and `src/models/chat-session.model.spec.ts` verify `unread_by` and `is_unresponded` are absent on bare documents when flags are off, which is a useful regression boundary when review touches defaults or rollout safety. [Task 3]

## Failures and how to do differently

- Symptom: unread/unresponded filter breaks or disappears when `search` or sale-visibility paths are involved. Cause: the new filter shape is vulnerable to typed-filter coercion and `addVisibilityFilter()` rebuilding `context.params.query` with its own `$or`. Fix/pivot: audit the full hook chain, including parser and visibility rewrite stages, not just the helper that first injected the condition. [Task 2][Task 4]
- Symptom: flag-off behavior still does work or leaks visibility. Cause: some hot paths still read/evaluate before deciding not to emit, and the new emitter audience follows channel eligibility rather than the stricter sale-owner/assignee/team visibility rules. Fix/pivot: review both zero-work and zero-side-effect expectations, then compare emitter audience to chat-search visibility semantics. [Task 1]
- Symptom: contact and group realtime behavior diverge across send paths. Cause: the new contact unresponded emitter was wired into `member-send-message` and `bot-send-message`, while `contact-send-message` still used the older emitter path. Fix/pivot: trace every send entrypoint before concluding the realtime contract is uniformly implemented. [Task 1]
- Symptom: review looks formatted clean but still has semantic bugs. Cause: `git diff --check` passed while the diff still contained blocker-level query-composition issues. Fix/pivot: do not treat formatting sanity as correctness; use focused tests and path tracing. [Task 2]
- Symptom: repo-wide validation gives noisy or misleading confidence. Cause: `npm run type-check` had unrelated TypeScript failures and `src/services/bot-send-message/bot-send-message.hooks.spec.js` still had 6 unrelated quick-reply failures. Fix/pivot: prefer targeted Jest suites and report exactly which failures are pre-existing versus relevant. [Task 2][Task 3][Task 4]
- Symptom: rollout verification stops short of DB proof. Cause: Mongo-backed tests could not run without `MONGODB_URI`. Fix/pivot: state the missing datasource explicitly and avoid claiming `explain()`-level or integration-level confidence when the DB-backed path was never exercised. [Task 3]

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

# Task Group: /Users/tualek/ohochat/oho-backoffice / external-message admin UI review
scope: Read-only UI/UX review memory for `oho-backoffice` external-message whitelist and app-catalog screens, especially Element UI behavior, repo-convention checks, and mock-data safety edges in the admin model.
applies_to: cwd=/Users/tualek/ohochat/oho-backoffice; reuse_rule=reuse for similar review-only admin UI checks in this checkout, but re-check the exact worktree and framework version because line numbers and component behavior assumptions can drift.

## Task 1: Read-only UI/UX review of external-message whitelist/app catalog screens, root cause and data-safety findings

### rollout_summary_files

- rollout_summaries/2026-07-14T07-38-59-v0i2-oho_backoffice_external_message_ui_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T14-38-59-019f5f90-99ef-79c1-9da8-c8468ab76236.jsonl, updated_at=2026-07-14T07:43:25+00:00, thread_id=019f5f90-99ef-79c1-9da8-c8468ab76236, line-cited review established Element UI arrow behavior and mock cascade/orphan risks)

### keywords

- vue2, nuxt2, element-ui, el-select, remote filterable, dropdown arrow, cascade delete, whitelist, app catalog, mock API, line-cited review

## User preferences

- when the user says `Do NOT edit any files -- this is review only` -> default to strictly read-only inspection for similar review tasks. [Task 1]
- when the user says `Every finding must cite a concrete file path and line number` -> gather exact line evidence first and avoid uncited judgments. [Task 1]
- when the user specifies `root-cause first` and then High/Medium/Low findings with concrete suggested fixes -> preserve that severity ordering and actionable output shape. [Task 1]
- when the user asks to grep the wider repo for other `filterable remote` usages -> check wider repo usage before claiming a pattern or divergence. [Task 1]

## Reusable knowledge

- Element UI `el-select` with `remote && filterable` intentionally omits the default arrow; the missing dropdown indicator was component behavior, not a repo CSS override, in the checked worktree. [Task 1]
- No CSS override suppressing the caret was found in the reviewed repo slice; the only related global selector was an unrelated dropdown-item hover tweak. [Task 1]
- The mock backend models two tables, `external_message_apps` and `business_external_app_whitelist`; deleting an app cascades into all whitelist rows. [Task 1]
- Editing `app_id` in the catalog does not propagate to existing whitelist rows, so existing whitelists can be orphaned if `app_id` stays mutable. [Task 1]

## Failures and how to do differently

- Symptom: a missing dropdown arrow looks like a CSS bug. Cause: Element UI hides the suffix icon for `remote && filterable`, and repo-wide CSS did not override it. Fix/pivot: inspect the component source directly before blaming local styling. [Task 1]
- Symptom: a review overstates a house convention. Cause: grep found only one `filterable remote` select instance in the repo. Fix/pivot: say explicitly when there is no comparable repo usage and compare against nearby search/select patterns instead. [Task 1]
- Symptom: whitelist/admin mockups appear safe because the UI has warning text. Cause: the data model still allows cascade delete and `app_id` rename orphaning. Fix/pivot: inspect the mock service or data layer, not just the page copy, when the user asks for admin-screen risk review. [Task 1]

# Task Group: /Users/tualek/ohochat/script-oho / migrate-unread.ts correctness review
scope: Read-only correctness-review memory for `unread-unresponded/migrate-unread.ts`, especially checkpoint semantics, cleanup-vs-backfill invariants, crash/resume safety, and operational cleanup guidance that must be proven from code lines rather than comments.
applies_to: cwd=/Users/tualek/ohochat/script-oho; reuse_rule=reuse for similar correctness reviews or operational questions in this checkout when the user wants evidence-first analysis of `migrate-unread.ts` or nearby migration-state logic, but re-check the live file because line numbers and safety guarantees can drift.

## Task 1: Explain how to remove legacy `read_by` after unread migration, cleanup is a separate gated mode

### rollout_summary_files

- rollout_summaries/2026-07-14T04-57-08-S8ep-script_oho_unread_migration_read_by_cleanup_mode.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T11-57-08-019f5efc-691c-7000-8729-9eceb1cc207d.jsonl, updated_at=2026-07-14T06:43:07+00:00, thread_id=019f5efc-691c-7000-8729-9eceb1cc207d, operational question answered by tracing the existing cleanup mode and its guards)

### keywords

- script-oho, migrate-unread.ts, cleanup-read-by, read_by, unread_by, checkpoint, MongoDB, $unset, migration, confirm-cleanup-read-by

## Task 2: Review checkpoint semantics versus cleanup-read-by assumptions, cleanup can trust incomplete proof

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed checkpoint membership is coarser than "Stream-verified" comments imply)

### keywords

- migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, INCLUDE_PARTIAL, runLegacyReadByReconcilePass, skippedNoChannel, partial, completed, loadCheckpoint, backfillCompleted, verified, checkpoint safety

## Task 3: Review cleanup cutoff parity, cleanup lacks the 90-day bound used elsewhere

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed cleanup query omits `last_active_at` cutoff even though backfill/reconcile apply it)

### keywords

- readByCutoffDate, DAYS, last_active_at, cleanup-read-by, runReadByToUnreadByPass, runLegacyReadByReconcilePass, resolveBusinessIds, MAX_DOCS_PER_BIZ, filter parity, HAS_LEGACY_READ_BY

## Task 4: Review crash/resume safety and totals refactor, buildTotals wiring confirmed with checkpoint caveats

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed `buildTotals()` coverage and exposed non-atomic checkpoint writes)

### keywords

- CHECKPOINT_SUFFIX, STATUS_FILE, saveCheckpoint, saveStatus, buildTotals, temp-file rename, crash-safety, loadCheckpoint, processedCount, cleanup mode, resume

## User preferences

- when the user says `ขอสรุปสั้นๆ` and then narrows to `ถ้างั้นถ้า run migration script ที่ script-oho แล้ว จะลบ read_byยังไง` -> switch to short, direct operational instructions once the concept is already established. [Task 1]
- when the user asks whether removing `read_by` closes the blockers -> separate `migrate unread_by` from `unset read_by` explicitly and state the safety boundary instead of answering as if they are the same step. [Task 1]
- when the user says `Trace the actual filter/gating logic, not the comments` and asks for line citations -> treat comments as non-binding, ground every behavioral claim in source lines/snippets, and do not smooth over gaps with intent-based reasoning. [Task 2][Task 3]
- when the user asks for `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` per item -> keep the review tightly structured and map each verdict to exact code lines. [Task 2]
- when the user asks whether one pass uses the `same DAYS/readByCutoffDate bound` as another -> compare the exact query objects across all relevant passes and surrounding guards, not just the obvious function or comment. [Task 3]
- when the user asks about shared `CHECKPOINT_FILE` / `STATUS_FILE` semantics or refactor sanity -> explicitly trace mode dispatch, suffix logic, write paths, and whether any hand-built state objects remain. [Task 4]

## Reusable knowledge

- `script-oho/unread-unresponded/migrate-unread.ts` already contains a dedicated cleanup path, `--mode=cleanup-read-by`; it is intentionally not auto-chained after backfill. [Task 1]
- Cleanup writes only when both `--execute` and `--confirm-cleanup-read-by` are present, and it unsets `read_by` on both `contacts` and `chat-sessions`. [Task 1]
- Cleanup is gated by the current checkpoint membership, so only businesses already marked complete in that env/gate checkpoint are eligible. The script comments describe `read_by` as the rollback path until `unread_by` has been spot-checked. [Task 1]
- `INCLUDE_PARTIAL` is opt-in only (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`), and `runLegacyReadByReconcilePass()` only runs inside that branch. A business can still become checkpoint-complete without legacy Stream verification because `partial` means budget exhaustion only and checkpointing checks only `!isDryRun && !result.partial`. [Task 2][Task 4]
- Cleanup trusts checkpoint membership directly via `loadCheckpoint()` and `backfillCompleted.has(id.toString())`; the checkpoint file stores only `{ completed: [...] }`, with no durable proof about reconcile coverage, skipped unresolved channels, or whether a business was verified under the current semantic config. [Task 2][Task 4]
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when a cutoff exists, but cleanup does not carry any date window. It filters only by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`. [Task 3]
- `resolveBusinessIds()` only narrows the business/channel universe; it does not encode doc freshness or backfill coverage. `MAX_DOCS_PER_BIZ` is `null`, so partial/budget limiting is not a protective invariant here. [Task 3]
- Cleanup mode reads checkpoint membership only and does not itself write checkpoint/status files, so it cannot overwrite backfill state by itself. `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but not cutoff/stream/partial semantics. [Task 4]
- `saveStatus()` uses a temp-file rename, but `saveCheckpoint()` writes directly to the checkpoint file. `loadCheckpoint()` swallows JSON parse/read errors and returns an empty set, so checkpoint corruption degrades into silent "start over" behavior. [Task 4]
- The 2026-07-14 review also found that cleanup resolves the current `connection_status: "complete"` channel set at runtime, so a business gaining new complete channels after backfill can make cleanup target docs outside the original backfill snapshot. [Task 3][Task 4]
- `buildTotals()` is the single totals builder now: both `saveStatus()` call sites use it, and no third hand-built totals literal remained. `processedCount++` happens before checkpoint eligibility is decided, so status can show business progress that has not been durably checkpointed. [Task 4]

## Failures and how to do differently

- Symptom: `read_by` cleanup is described as if it naturally follows migration. Cause: the script intentionally splits backfill and cleanup for rollback safety. Fix/pivot: keep the sequence explicit, `backfill/spot-check unread_by` first and `cleanup-read-by` second. [Task 1]
- Symptom: comments say a business is "verified" or cleanup is "safe to drop". Cause: the code does not persist any proof beyond membership in `completed`. Fix/pivot: inspect what the code actually stores and what cleanup consumes before accepting safety claims. [Task 2]
- Symptom: cleanup appears to mirror backfill/reconcile scope. Cause: the file comments suggest full-population behavior, but the actual queries diverge and cleanup omits the `last_active_at` cutoff. Fix/pivot: compare query objects and cutoff propagation across every related pass. [Task 3]
- Symptom: future resume logic assumes checkpoint files are durable and config-specific. Cause: checkpoint writes are non-atomic and the suffix key omits semantic dimensions such as cutoff/stream/partial choices. Fix/pivot: treat checkpoint correctness and resume safety as separate review items, not as implied by shared file names alone. [Task 4]
- Symptom: a review report sounds safe because the refactor is tidy. Cause: source-of-truth reasoning stopped at comments or naming instead of tracing state transitions and persisted artifacts. Fix/pivot: verify file-write paths, mode dispatch, and all remaining literal builders before concluding the refactor is safe. [Task 2][Task 4]

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
