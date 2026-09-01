# Raw Memories

Merged stage-1 raw memories (stable ascending thread-id order):

## Thread `019f5f90-99ef-79c1-9da8-c8468ab76236`
updated_at: 2026-07-14T07:43:25+00:00
cwd: /Users/tualek/ohochat/oho-backoffice
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T14-38-59-019f5f90-99ef-79c1-9da8-c8468ab76236.jsonl
rollout_summary_file: 2026-07-14T07-38-59-v0i2-oho_backoffice_external_message_ui_review.md

---
description: Read-only UI/UX review of external-message whitelist and app-catalog screens; key durable takeaway is that Element UI remote filterable selects intentionally hide the dropdown arrow, and this repo had no CSS override suppressing it. Also captured data-safety issues in the mock two-table model (cascade delete, app_id rename orphan risk).
task: read-only ui/ux design review of external-message whitelist/admin screens with line-cited findings
task_group: oho-backoffice vue2/nuxt2 admin ui review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-backoffice
keywords: vue2, nuxt2, element-ui, el-select, remote filterable, dropdown arrow, cascade delete, whitelist, app catalog, mock API, line-cited review
---

### Task 1: Read-only UI/UX review of external-message whitelist/app catalog screens

task: read-only ui/ux design review of external-message whitelist/admin screens with line-cited findings
task_group: oho-backoffice vue2/nuxt2 admin ui review
task_outcome: success

Preference signals:
- when the user said "Do NOT edit any files -- this is review only" -> future similar tasks should default to strictly read-only inspection and avoid edits.
- when the user said "Every finding must cite a concrete file path and line number" -> future similar reviews should gather exact line evidence first and avoid uncited judgments.
- when the user specified the output shape/order (root-cause first, then High/Medium/Low) -> preserve severity ordering and actionable fix language in future review output.
- when the user asked to grep the wider repo for other `filterable remote` usages -> check wider repo usage before claiming a pattern or divergence.

Reusable knowledge:
- Element UI `el-select` with `remote && filterable` intentionally omits the default arrow; the missing dropdown indicator is component behavior, not a repo CSS override, when no local CSS rule targets the suffix.
- In the checked worktree, no CSS override was found that suppresses the caret; the only related global rule was an unrelated dropdown-item hover tweak.
- The mock backend models two tables: `external_message_apps` and `business_external_app_whitelist`; deleting an app cascades into all whitelist rows.
- Changing `app_id` in the catalog does not propagate to existing whitelist entries, so whitelists can become orphaned if `app_id` is mutable.

Failures and how to do differently:
- Do not overclaim a repo-wide convention when grep finds only a single `remote filterable` select; explicitly note when no comparable instance exists.
- For framework-behavior questions, inspect the component source directly rather than inferring from screenshots or broad CSS searches.

References:
- `pages/external-message-whitelist.vue:14-34` — `el-select` with `filterable remote clearable` and no explicit icon.
- `pages/external-message-whitelist.vue:37-55` — main checklist/save layout.
- `pages/external-message-whitelist.vue:91-115` — remote business search and error handling.
- `pages/external-message-apps.vue:55-85` — create/edit dialog.
- `pages/external-message-apps.vue:162-183` — delete confirmation and cascade warning.
- `components/ExternalMessage/WhitelistAppChecklist.vue:12-14` — empty state.
- `api/mockExternalMessageApps.js:127-147` — delete cascade logic.
- `api/mockExternalMessageApps.js:97-125` — app_id edit logic that can orphan existing whitelist data.
- `node_modules/element-ui/packages/select/src/select.vue:196-198` — `iconClass()` returns `''` for `remote && filterable`.

## Thread `019f654e-423f-7483-bdd6-494aba0e6b12`
updated_at: 2026-07-15T10:56:47+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T17-24-15-019f654e-423f-7483-bdd6-494aba0e6b12.jsonl
rollout_summary_file: 2026-07-15T10-24-15-fwAy-mr1285_unread_unresponded_cross_repo_review.md

---
description: Read-only cross-repo review of MR !1285 unread/unresponded changes; core backend path improved, but websocket/frontend drift risks and rollout/migration concerns remained.
task: code-review MR !1285 unread/unresponded across oho-api, oho-websocket, oho-web-app
task_group: /Users/tualek/ohochat
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api
keywords: mr-1285, unread, unresponded, code-review, read-only, exact file:line, emitContactUnrespondedStatusUpdatedEvent, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, message.read, Remote Config, optimistic-flag-count-tracker
---

### Task 1: Backend review in oho-api

task: code-review MR !1285 unread/unresponded backend changes
task_group: oho-api review
task_outcome: partial

Preference signals:
- The user said to read prior review docs first and “do not re-flag findings already documented as fixed there” -> rebase on prior review history and avoid duplicate findings.
- The user asked for “structured findings report, ranked by severity” and “every finding must cite an exact file:line” -> keep reviews line-precise, severity-ranked, and evidence-first.
- The user said “do not modify any files” -> keep review flows read-only.

Reusable knowledge:
- `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for both `unread_by` and `is_unresponded:true`.
- `buildClearUnreadUnrespondedPayload()` intentionally builds unconditional CLEAR payloads to avoid flag-toggle stuck-state bugs.
- `emitEligibilityScopedUnrespondedUpdate()` is the actual gate for the contact clear broadcasts; notify/inform/broadcast/bulk all reach it.

Failures and how to do differently:
- Contact-side scoped broadcast is correct for unresponded but only covers channel-eligible members; sale-visibility audience mismatches are a separate issue.
- Bulk-send still needs success-aware review because it can clear state even when platform delivery fails.

References:
- `src/services/contact-send-message/contact-send-message.hooks.js:227-259`
- `src/services/chat-session/group/contact-user/send-message/send-message.class.js:40-50`
- `src/services/member-send-message/member-send-message.hooks.js:690-728`
- `src/services/member-send-message/bulk/bulk.class.js:218-285`
- `src/services/chat-session/hooks/emit-chat-session-event.js:271-372`

### Task 2: oho-websocket review

task: code-review websocket unread/unresponded behavior in MR !1285
task_group: websocket review
task_outcome: fail

Preference signals:
- The user wanted the review to “cover all 3 repos” and keep findings separated by repo/axis -> keep repo boundaries explicit.
- The user called out the rule that realtime broadcasts of these fields must be flag-gated, not the writes.

Reusable knowledge:
- `src/webhook/stream.js` has a `message.read` branch that directly `$pull`s from `unread_by`; this is the websocket-side CLEAR site to scrutinize for unconditional behavior.
- The Stream webhook handler’s customer-message broadcasts are split into single-chat and group-chat paths, with group broadcasts using the broader `businessChannel(businessId, 'member')` audience.

Failures and how to do differently:
- `message.read` clear is currently flag-gated and lacks the backend ordering guard.
- Group customer-message broadcasts go to the whole business member room, not a channel-eligibility-scoped audience.

References:
- `src/webhook/stream.js:149-160`
- `src/handlers/stream-webhook.handler.js:361-449`
- `src/webhook/stream.spec.js:93-108`

### Task 3: oho-web-app review

task: code-review frontend unread/unresponded behavior in MR !1285
task_group: frontend review
task_outcome: partial

Preference signals:
- The user wanted a careful senior review before production rollout, not implementation suggestions.
- The user explicitly asked for complete flag/write/broadcast inventory behavior in the audit -> include UI state mutation paths from sockets and optimistic logic.

Reusable knowledge:
- `store/index.js` bootstraps feature flags from backend auth, but `plugins/firebase-remote-config.js` later fetches client config and commits to the same state again.
- `store/modules/smartchat.js` and `store/modules/groupchat.js` both use the shared optimistic flag tracker; validate offscreen increment/decrement behavior, not just visible-room updates.

Failures and how to do differently:
- Client Remote Config can race backend-authenticated flags.
- Optimistic count tracking can drift without authoritative reconciliation.
- Groupchat badge/list behavior is not fully aligned with Smartchat.

References:
- `plugins/firebase-remote-config.js:8-52,81-85`
- `store/index.js:476-485`
- `store/modules/smartchat.js:692-749`
- `store/modules/groupchat.js:215-321`
- `pages/business/_biz_id/groupchat/index.vue:26-31,449-567`
- `utils/optimistic-flag-count-tracker.js:1-27`

## Thread `019f8442-2665-7082-a710-f24709dca055`
updated_at: 2026-07-21T10:51:30+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl
rollout_summary_file: 2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md

---
description: third-pass read-only review of unread/unresponded migration; decided Option A (backfill unread_by only, leave is_unresponded absent), with follow-on plan to remove unresponded migration paths and use explain-based preflight plus minimal indexing
task: third-and-final-review-pass-on-mongodb-migration
task_group: /Users/tualek/ohochat/script-oho / migrate-unread correctness review
task_outcome: success
cwd: /Users/tualek/ohochat/script-oho
keywords: migrate-unread, unread_by, is_unresponded, option A, explain preflight, hint, checkpoint v3, residual IDs, group index, chat-sessions, fail-closed CLI, read-only review
---

### Task 1: Decide whether to backfill `is_unresponded`

task: third-pass source audit of `oho-api@master` and `script-oho/unread-unresponded` for whether `is_unresponded` can be reconstructed

task_group: /Users/tualek/ohochat/oho-api + /Users/tualek/ohochat/script-oho migration review
task_outcome: success

Preference signals:
- when the user said “do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns” -> future similar reviews should converge to one choice and avoid handing back a concern list
- when the user required “Verify every factual claim in the brief against source before relying on it” and “cite file:line for each load-bearing claim” -> future similar work should default to line-cited proof and explicitly say “cannot verify from repo” when proof is missing
- when the user said “If you must assume, name the assumption” -> future plans should separate evidence from assumptions instead of blending them into conclusions

Reusable knowledge:
- Contact customer-message handling writes `last_active_at` and `last_contact_date` via separate guarded updates; same-timestamp behavior is normal but not an invariant.
- `chat_status` is not a reliable historical reply classifier because it conflates customer-message fallback and bot fallback cases.
- The inbox send path is a known asymmetry: it advances `last_active_at` but does not clear `is_unresponded`.
- The safest migration policy from the audited source is to leave historical `is_unresponded` absent rather than infer it.

Failures and how to do differently:
- The brief’s timestamp-classifier draft relied on insufficient provenance; future runs should reject heuristics unless the repo exposes a true reply ledger.
- Do not assume the migration is the only actor affecting user-visible state; clear paths remain unconditional when the field exists.

References:
- `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:164-167, 230-237`
- `oho-api/src/services/chat-session/group/contact-user/send-message/send-message.class.js:19-36`
- `oho-api/src/utils/update-contact-last-active-at.js:12-19`
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:634-686`
- `oho-api/src/services/bot-send-message/bot-send-message.hooks.js:540-576`
- `oho-api/src/utils/build-customer-message-unread-payload.ts:24-38`
- `oho-api/src/models/contact.model.js:211-219`
- `oho-api/src/models/chat-session.model.js:78-86`

### Task 2: Decide classifier / filter shape

task: determine whether a pure classifier or Mongo filter should be used for `is_unresponded`

task_group: migration design review
task_outcome: success

Preference signals:
- when the user asked for “the final classifier rule, as a pure function and as a Mongo filter” but the audit concluded the honest answer was that the classifier should not exist -> future similar reviews should answer “not applicable” when the evidence says the feature should be omitted
- when the user asked to “Attack the draft above” -> future similar work should actively reject unsafe heuristics rather than merely weakening them

Reusable knowledge:
- `first_chat_at` can exclude contacts that never messaged, but it does not prove whether later activity was a reply.
- `assigned_at` was unsafe because the contact schema uses `assign_at`, not a top-level `assigned_at`; whether historical documents persisted an undeclared top-level `assigned_at` could not be verified from the repo.
- Timestamp tolerance increases false matches rather than fixing the ambiguity.

Failures and how to do differently:
- A timestamp-based heuristic can misclassify assignment/status/comment/spam actions as replies.
- The migration CLI still exposes unresponded passes unless the operator explicitly skips them; relying only on an opt-out flag is weaker than deleting the path.

References:
- `script-oho/unread-unresponded/helpers/migration-cli.ts:479-485`
- `oho-api/src/models/contact.model.js:154-164, 185-188`

### Task 3: Decide index and paging strategy

task: adjudicate contact vs group indexing and paging preflight for the migration
task_group: migration execution hardening
task_outcome: success

Preference signals:
- when the user asked to “Adjudicate the index/paging disagreement” and “Give one answer” -> future similar decisions should pick one side and tie it to a concrete preflight rule
- when the user insisted the checked-out tree is stale and `oho-api@master` is the source of truth -> future similar repo decisions should trust branch `master` evidence, not the working tree

Reusable knowledge:
- `pagedFind()` currently does keyset pagination on `_id` but does not use `hint()` or `explain()`.
- Contacts already have a `business_id + _id` index on `master`; group sessions do not have the needed `_id`-ordered index for this migration path.
- The explain-based preflight should refuse execution if the plan is a collection scan or blocking sort.

Failures and how to do differently:
- It is not enough to say a plan is “probably fine”; the rollout only accepted the plan after tying it to concrete index declarations and a fail-closed explain check.
- The residual-count logic can numerically cancel unrelated documents, so “done” must be exact-ID based rather than aggregate-count based.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:177-190, 238-250`
- `oho-api/src/models/contact.model.js:621-624`
- `oho-api/src/models/chat-session.model.js:109-137`

### Task 4: Produce an ordered production plan

task: write one ordered plan from current state to production rollout completion
task_group: migration runbook / production readiness
task_outcome: success

Preference signals:
- when the user required “one ordered plan” including dependencies, parallelism, and explicit human decisions -> future similar plans should be sequenced, not freeform
- when the user’s rollout shape already agreed on per-tenant migration followed by immediate tenant flag-on -> future plans should preserve that operational sequencing unless the user changes it

Reusable knowledge:
- The current code already has a separate `cleanup-read-by` mode that is gated by checkpoint membership and dedicated confirmation.
- The CLI is fail-closed: `.env.<env>` selection, a matching `--confirm`, and explicit `--execute` are required.
- Production rollout should only proceed after explicit database authorization and explain/index verification.

Failures and how to do differently:
- Current checkpoint/residual logic is count-based in places where exact identity is safer; exact ID tracking should be a prerequisite, not an optional enhancement.
- The old status file’s cumulative counters cannot be trusted as per-tenant proof; treat them as advisory until exact IDs are reconciled.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:2084-2112, 2126-2134`
- `script-oho/unread-unresponded/helpers/migration-cli.ts:321-334, 401-412`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69`

### Task 5: Identify incorrect or missing claims

task: final pass over the brief for overstated claims and missing constraints
task_group: evidence audit / postmortem
task_outcome: success

Preference signals:
- when the user asked for “Anything in the above you believe is still wrong or missing” -> future similar reports should explicitly enumerate corrections and not just provide the main answer
- when the user demanded evidence-dense language and “cannot verify from repo” rather than guessing -> future similar reports should keep uncertainty visible

Reusable knowledge:
- The inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that turns on the unresponded flag must either accept that false-positive path or defer the feature until API behavior changes.
- The old status file proves a prior run happened, but not that the named three tenants each received the cumulative `s0a` total.
- External operational facts, production state, and retention assumptions should not be encoded as repo facts.

Failures and how to do differently:
- Do not treat cumulative counts as proof of per-tenant effect unless the artifact explicitly preserves per-tenant attribution.
- Do not convert assumptions about production state into assertions about the codebase.

References:
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:143-159`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:2-14, 26-69`

### Task 6: Final plan synthesis

task: synthesize final production plan from source audit and migration code review
task_group: migration readiness / final recommendation
task_outcome: success

Preference signals:
- the user required the final output to be machine-consumed and terse, so future similar syntheses should remain compact, decision-oriented, and citation-heavy
- the user wanted the rollout shaped as a per-tenant migration with immediate tenant flag enablement, not a catchup mode

Reusable knowledge:
- Keep `is_unresponded` absent; do not backfill it.
- Use explain-based preflight and a minimal group index rather than broad new contact indexes.
- Treat guard misses, Stream-missing docs, over-cap docs, and residual counts as exact-ID reconciliation problems, not just counters.
- `read_by` cleanup remains a separate gated mode to run after the main rollout.

Failures and how to do differently:
- The old status file could not cleanly attribute its cumulative numbers to the named tenants, so future rollouts should not use it as proof of tenant-specific writes.
- There is a known inbox-send asymmetry that may require product-owner acceptance before enabling `is_unresponded`-related behavior.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:730-735, 884-888, 1024-1057, 1406-1469, 1729-1734`
- `oho-api/src/utils/channel-eligible-members.ts:28-35, 78-92`
- `oho-api/src/models/chat-session.model.js:109-137`
- `oho-api/src/models/contact.model.js:621-624`
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:143-159`

## Thread `019f8a8e-191c-7740-8373-583d8f41643f`
updated_at: 2026-07-22T16:09:45+00:00
cwd: /Users/tualek/ohochat/oho-webhook
rollout_path: /Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-59-56-019f8a8e-191c-7740-8373-583d8f41643f.jsonl
rollout_summary_file: 2026-07-22T15-59-56-ExfV-blind_audit_send_message_webhook_oho_api_webhook.md

---
description: Blind source-code audit of oho-api and oho-webhook send-message/webhook flows; captured exhaustive call-chain tracing, retry/timeout arithmetic, sibling-path deltas, and several correctness risks (dedup/retry, swallowed Cloud Tasks failures, unreachable retry branches, ack-before-work patterns).
task: blind audit of send-message flows and webhook receipt/worker paths across oho-api and oho-webhook
task_group: source-code-audit / send-message-webhook-flows
task_outcome: success
cwd: /Users/tualek/ohochat/oho-webhook
keywords: oho-api, oho-webhook, member-send-message, Facebook webhook, LINE webhook, Cloud Tasks, Redlock, Redis dedup, retry-backoff, axios timeout, Stream Chat, bulk send, partner send-message, contact-send-message, bot-send-message, inform-message, tiktok, correctness bugs, silent drop, duplicate message
---

### Task 1: oho-api outbound send-message flows

task: blind audit of /member-send-message plus sibling send paths in oho-api
task_group: oho-api send-message audit
task_outcome: success

Preference signals:
- when the user said "Independent BLIND audit" and "Do NOT read any *.md report/plan files", treat the audit as source-only and avoid any documentation or prior-plan contamination.
- when the user said "Exhaustively inventory" and "Before finalizing, grep for every awaited call", run a completeness sweep over async primitives before closing out.
- when the user required file:line citations for every claim, keep evidence anchored to exact lines in the source tree.

Reusable knowledge:
- `/member-send-message` validates `messages.max(25)` and acquires a Redlock on `contact:$1:chat_session` via `data.contact_id`.
- Lock TTL is 3s and the extension gap is 1s; the same lock serializes member assignment, bot assignment, accept/reject/cancel, close-chat, and `/member-send-message`.
- Facebook/Instagram integration services use `axios.create({ timeout: 60000 })` and the shared retry wrappers, but the 429 retry branches are unreachable; effectively the outer service gets one 60s attempt plus wrapper overhead.
- LINE outbound in the main member-send path is chunked by 5, processed serially, and retries only ECONNRESET via the shared wrapper; worst-case per chunk is `4*60 + 7 = 247s`.
- TikTok send path uploads image media first (timeout 60s, concurrency 5), then sends messages serially; failed uploads fall back to sending without `tiktok_media_id`.
- Stream Chat send calls use `callWithStreamChatRetry` (`maxRetry: 5`, exponential starting at 5s), so a single Stream call can contribute `6*60 + 155 = 515s` worst-case.

Failures and how to do differently:
- Some helper code swallows errors and returns partial success objects; future audits should check whether downstream hooks ever see the error or only `{ok:false}`.
- The repo contains several overlapping send paths with similar names; future retrieval should key off route file + service file, not just the service name.

References:
- `src/services/member-send-message/member-send-message.hooks.js:1243-1317` — before/after/error hook chain.
- `src/services/member-send-message/member-send-message.class.js:37-339` — platform dispatch and helpers.
- `src/utils/retry-backoff.js:296-360`, `src/utils/axios.js:6-16` — retry and Axios defaults.
- `src/hooks/lock-resource.js:43-105`, `src/utils/resource-lock.js:7-13` — lock key pattern and TTL.
- `src/services/integration/facebook/reply-message/reply-message.class.js:20-50`, `src/services/integration/instagram/reply-message/reply-message.class.js:20-50`, `src/utils/api/tiktok.js:68-72`, `src/services/channel/utils/tiktok.js:131-217` — platform-specific integrations.

### Task 2: oho-webhook inbound receipt, worker chains, and retry/dedup paths

task: blind audit of Facebook/LINE webhook receipt and worker chain in oho-webhook
task_group: webhook audit
task_outcome: success

Preference signals:
- when the user asked for "platform webhook receipt -> ack" and Cloud Tasks worker tracing, start from controller ACK timing and follow through the worker chain.
- when the user said to "state the ambiguity explicitly", treat dynamic config/feature-flag branches as open questions only if they cannot be resolved from code.
- when the user required completeness, end with a final async-primitive sweep to make sure every implementation file is represented.

Reusable knowledge:
- Facebook controller writes source-message metrics, resolves external-app whitelist caches, optionally inserts Cloud Tasks, and can bypass queueing when `USE_QUEUE !== 1`.
- Facebook worker `handleWebhook` processes entries in `Promise.all`, and errors are turned into HTTP 200 to force Cloud Tasks completion.
- Facebook dedup is Redis-based and non-atomic (`get` then `setEx`), so concurrent workers can both pass the check; retry tasks can also be dropped as duplicates if they reuse the same key.
- LINE controller can route through Cloud Tasks or direct worker mode depending on `USE_QUEUE` and `isThrottled`; worker verification and event processing are parallelized over `events[]`.
- LINE manual retry scheduling composes RMQ and DLQ delays into `330,125s` total scheduled delay (about `91h 42m 5s`) based on the inspected arrays.
- `send-oho-webhook-events` is intentionally detached, uses a 3s Axios timeout, and is observability-only.

Failures and how to do differently:
- Some helper failures are swallowed and replaced by 200 responses; future audits should distinguish intended "force completion" from accidental loss of durability.
- Webhook worker chains contain detached helpers (e.g. forwarding, some state updates); future audits should explicitly mark whether a helper is awaited and whether its failure is user-visible.

References:
- `src/controllers/facebook/facebook.controller.ts:47-245`, `:247-413` — Facebook receipt + worker.
- `src/controllers/line/line.controller.ts:38-346`, `src/controllers/line/handler.ts:1146-1347` — LINE receipt + worker.
- `src/controllers/facebook/block.ts:53-83`, `src/services/redis.service.ts:73-176` — Redis dedup implementation.
- `src/helpers/external-app-whitelist.ts:17-94`, `src/helpers/cached-channel-profile.ts:31-77` — whitelist cache path.
- `src/helpers/retry-message.ts:21-455` — retry queue scheduling.
- `src/helpers/send-oho-webhook-events.js:71-108` — detached outgoing webhook delivery.

### Task 3: sibling send-path divergence audit

task: compare bulk, bot-send-message, partner/send-message, partner-send-message, inform-message, and contact-send-message against main member-send-message
task_group: sibling send-path audit
task_outcome: success

Preference signals:
- when the user asked for "PART C" deltas only, compare against the main path and do not restate identical calls.
- when the user asked to tag deltas as "concrete risk or benign", separate correctness risk from harmless implementation differences.
- when the user asked for "one subsection per sibling flow", preserve route-by-route organization.

Reusable knowledge:
- `bulk` returns `{ok:true}` before all sends settle and does not use the main contact lock.
- `bot-send-message` and `inform-message` update contact state and log after/around sends, but LINE in `inform-message` does not use the main retry wrapper and Instagram/TikTok are unsupported there.
- `partner/send-message` is API-key authenticated, validates platform/messages, but does not re-check that the provided `business_id` matches the loaded contact business; it reuses the same platform integration helpers.
- `partner-send-message` is a separate legacy route that only writes to Stream Chat and does not call platform send helpers.
- `contact-send-message` updates contact state before Stream writes and swallows Stream failures; it also expands long texts into 5000-character chunks.

Failures and how to do differently:
- Legacy and new routes have similar names but very different semantics; future audits should identify them by file and route path to avoid mixing them up.
- Some sibling flows share helpers but differ in sequencing; future comparisons should focus on commit order and await placement, not just helper reuse.

References:
- `src/services/member-send-message/bulk/bulk.class.js:35-109`, `bulk.hooks.js:636-669` — bulk.
- `src/services/bot-send-message/bot-send-message.class.js:15-190`, `src/services/bot-send-message/bot-send-message.hooks.js:504-688` — bot-send-message.
- `src/services/partner/send-message/send-message.hooks.ts:39-480`, `send-message.class.ts:18-161` — partner/send-message.
- `src/services/partner-send-message/partner-send-message.class.js:1-69`, `partner-send-message.hooks.js:1-163` — legacy partner-send-message.
- `src/services/bot-send-message/inform-message/inform-message.class.js:18-133`, `inform-message.hooks.js:1-171` — inform-message.
- `src/services/contact-send-message/contact-send-message.class.js:20-67`, `contact-send-message.hooks.js:242-556` — contact-send-message.

## Thread `019f92b8-19b7-75b3-bdd9-8d9231dfb910`
updated_at: 2026-07-24T06:05:35+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-02-46-019f92b8-19b7-75b3-bdd9-8d9231dfb910.jsonl
rollout_summary_file: 2026-07-24T06-02-46-CTIY-realtime_badge_fix_adversarial_review_partial.md

description: Partial read-only review of OHO-1272 realtime unread/unresponded badge fix; live diff inspected but no final verdict was produced. Highest-value takeaways are strict evidence/read-only requirements, branch mismatch, and a possible count-state reset edge case.
task: adversarial code review of smartchat/websocket realtime badge diff
task_group: /Users/tualek/ohochat/oho-web-app realtime unread-unresponded badge review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
keywords: code-review, OHO-1272, smartchat, websocket, unread_count, unresponded_count, is_read_by_me, is_unresponded, DEFAULT_UPDATE_FIELDS, optimistic-flag-count-tracker, Vuex, Vue 2

### Task 1: Review realtime badge fix

task: trace realtime unread/unresponded badge update diff and identify confirmed defects
 task_group: frontend realtime badge review
 task_outcome: partial

Preference signals:
- The user said “Read the actual files, do not guess” and required file:line grounding -> future reviews should inspect the live worktree and cite exact evidence.
- The user requested a “read-only critical review” and prohibited edits, commits, and checkout -> do not modify the worktree during similar reviews.
- The user required a one-line verdict, issue headings, and a concise “Checked, no issue” section -> preserve that exact output shape.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` is at `store/modules/smartchat.js:719-760`; it gates `rt_unread_feature_enabled` and `rt_unresponded_feature_enabled`, maps `contact_id` to `_id`, injects badge fields, and dispatches `handleSmartchatRealtimeUpdate` with `DEFAULT_UPDATE_FIELDS` and `is_fetch_contact: !in_list`.
- `handleSmartchatRealtimeUpdate` matches by `_id` at `smartchat.js:779-783` and picks only requested fields at `:792`; `DEFAULT_UPDATE_FIELDS` contains `_id`, `is_unresponded`, and `is_read_by_me` (`constants/contact.js:3-28`).
- Count transitions use `resolveOptimisticFlagTransition` (`smartchat.js:826-873`; tracker `utils/optimistic-flag-count-tracker.js:25-40`) and list replacement/pagination reconcile the tracking Sets (`smartchat.js:70-147`).
- The four socket handlers preserve existing notifications and add badge dispatches at `store/modules/websocket.js:255-313`.

Failures and how to do differently:
- The requested branch was not active: live worktree branch was `tk-sprint-2615/develop`, while the user named `fix/oho-1272-unread-unresponded-realtime-badge`; `HEAD` and `origin/master` were both `619b6182`. Disclose this scope mismatch or stop before approval.
- The rollout ended without a final verdict, so the six review points were not fully verified. Do not treat the implementation as approved.
- Investigate `store/modules/smartchat.js:175-181`: `resetContactList` replaces `contact_list` with only `total`, `limit`, `skip`, and `data`, omitting `unread_count` and `unresponded_count` that exist in initial state at `:22-29`. This may create a Vue 2 reactivity/count reset edge case; it was not conclusively classified in this rollout.

References:
- `git -C /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge diff`
- `store/modules/smartchat.js:719-760, 779-873, 175-181`
- `store/modules/websocket.js:255-313`
- `constants/contact.js:3-28`
- `utils/optimistic-flag-count-tracker.js:25-40, 42-76`

## Thread `019f92d6-2878-7423-a00f-1e523deebd71`
updated_at: 2026-07-24T06:40:00+00:00
cwd: /Users/tualek/ohochat/oho-api
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-35-36-019f92d6-2878-7423-a00f-1e523deebd71.jsonl
rollout_summary_file: 2026-07-24T06-35-36-jLZD-oho_1272_realtime_badge_read_only_review.md

---
description: Read-only adversarial review of Vue 2/Vuex realtime unread/unresponded badge fix; found fetch-merge badge/count desync and unconditional no-op dispatches
task: review OHO-1272 realtime chat-list badge diff
 task_group: frontend realtime badge code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
keywords: Vue 2, Vuex, smartchat, realtime, unread_count, unresponded_count, reconcile Set, DEFAULT_UPDATE_FIELDS, feature flags, code review
---

### Task 1: Review OHO-1272 realtime badge fix

task: adversarial read-only review of realtime unread/unresponded badge patch
task_group: frontend realtime badge code review
task_outcome: success

Preference signals:
- The user said “do not modify any files — review only” and requested “real defects, not style nits” -> similar reviews should stay read-only and focus on correctness defects.
- The user requested six yes/no verdicts with `file:line` evidence and a final `VERDICT: LGTM` or issue count under ~400 words -> use a compact evidence-first review format.

Reusable knowledge:
- Existing-room repeated events do not double-count because `resolveOptimisticFlagTransition` consults the reconciliation Sets and prior row state (`store/modules/smartchat.js:826-873`).
- New-room processing updates aggregate counts/Set before fetching complete contact data; merging `res.data[0]` afterward can overwrite the injected `is_unresponded`/`is_read_by_me` values, leaving the row inconsistent with counters (`store/modules/smartchat.js:927-940`). Fix by reapplying injected badge fields after the fetch merge or otherwise preserving them.
- Both feature flags independently gate badge injection (`store/modules/smartchat.js:723-739`), but all four websocket handlers still dispatch the helper (`store/modules/websocket.js:267,282,296,311`). The helper returns before nested work when no badge is enabled, so external state is unchanged, but this is not literal byte-for-byte behavior; an outer feature-flag guard would eliminate the no-op dispatches.
- `DEFAULT_UPDATE_FIELDS` excludes documented raw socket keys such as `business_id`, `contact_id`, `preview_message`, `platform`, `contact_name`, `channel_id`, `channel_name`, `contact_image_url`, and `is_team_notification`; only selected fields plus injected `_id` and badge fields are merged (`constants/contact.js:3-28`, `smartchat.js:744-757,792`).
- `_id: contact_id` matches the existing row key and is used consistently for fetch, route/current-contact, and removal paths (`smartchat.js:779-783,930-933,947-963,1018-1023`).
- Missing `updated_at` was not shown to cause a material defect for deterministic badge assertions; exact `skipUpdateChatRoom` behavior was outside the permitted source scope.
- For a new room under an active filter, the action refetches the filtered list rather than directly inserting; nonmatching rooms are omitted (`smartchat.js:965-1007`).

Failures and how to do differently:
- Do not assume that “counts are updated through the shared action” guarantees row/count consistency: inspect later fetch merges for overwrites.
- Distinguish semantic no-op behavior from literal byte-for-byte behavior: an unconditional Vuex dispatch still differs even if the helper immediately returns.

References:
- Diff path: `/private/tmp/claude-501/-Users-tualek-ohochat/e09208f3-facf-4303-8b26-c1c18904dc1b/scratchpad/oho1272.diff`
- Worktree: `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge`
- Key evidence: `smartchat.js:826-873`, `927-940`, `965-1007`; `websocket.js:267,282,296,311`; `constants/contact.js:3-28`

## Thread `019f9319-959c-7630-8f42-e17b70c0d6ef`
updated_at: 2026-07-24T07:53:27+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T14-49-15-019f9319-959c-7630-8f42-e17b70c0d6ef.jsonl
rollout_summary_file: 2026-07-24T07-49-15-1jYz-vue2_realtime_badge_recheck_four_issues.md

description: Read-only adversarial re-review of Vue 2/Vuex realtime unread/unresponded badge fix; found synthetic-timestamp false unread, pre-fetch aggregate drift, incomplete/blocked new-room handling, and stale unresponded reassertion.
task: review realtime unread and unresponded badge fix
task_group: /Users/tualek/ohochat/oho-web-app frontend review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Vue2, Vuex, smartchat.js, RoomList.vue, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, unread, unresponded, last_contact_date, already_read_locally, triggerFilteredListRefetch

### Task 1: Realtime badge fix re-review

task: determine whether realtime unread/unresponded badges work across in-list and new-room paths
 task_group: Vue2 frontend realtime badge review
 task_outcome: partial

Preference signals:
- The user said “read ONLY these, do not explore the repo broadly” -> constrain future reviews to explicitly named files/line ranges.
- The user said “Review only, do not modify files” -> do not edit, stage, commit, or run mutating commands.
- The user required “yes/no verdict + file:line evidence” and an adversarial search for real defects -> provide compact, line-cited verdicts and avoid speculative findings.

Reusable knowledge:
- `RoomList.room_list()` prioritizes current-room false, then `state.read[my_id]` timestamp comparison, then presence of `state.read`, and only finally `is_read_by_me` fallback (`RoomList.vue:161-177`). Because backend rows may contain `state.read`, injecting only `is_read_by_me:false` is insufficient; a timestamp is needed for the `my_read` branch.
- Injecting a client “now” timestamp is unsafe. `smartchat.js:730-733` creates `last_contact_date`, while `smartchat.js:836-845` compares it with the local read cursor. A delayed event after the real message was read can make the cursor appear older and falsely mark the room unread; `RoomList.vue:163-165` repeats the same comparison. Use the real message timestamp/version or authoritative fetch, and discard synthetic badge fields when stale.
- Aggregate transitions run before new-room API reconciliation (`smartchat.js:779,813-860` before `915-927`), so authoritative `is_read_by_me`/`is_unresponded` values fetched for a new room do not update aggregate counts. Calculate deltas after fetch using final data.
- New-room insertion is skipped when `is_show_reload_chat_list_btn` is true or ascending pagination is incomplete (`smartchat.js:966-994`). Only active filtered lists refetch, so legitimate rooms can be absent until a later poll. Refetch or queue insertion in the blocked path.
- Failed/empty new-room fetches leave socket-only payloads (`smartchat.js:904-931`); missing badge fields then render as read/not-unresponded under `RoomList.vue:169-180`, and incomplete data may fail visibility/filter checks (`smartchat.js:952-965`). Avoid inserting incomplete rows or retry/refetch authoritatively.
- `is_unresponded:true` is injected independently for in-list rooms (`smartchat.js:725-738`) and can be counted/merged (`smartchat.js:813-825,869-880`), but stale inbound events lack causal ordering and can reassert true after a bot/member reply clears it. Add event ordering metadata or authoritative reconciliation.
- No direct flag-combination hole was identified: unread and unresponded feature flags are checked independently (`smartchat.js:710-715,727-733`); shared new-room defects affect either combination.

Failures and how to do differently:
- Do not treat a synthetic timestamp as equivalent to the socket message’s real ordering metadata; it breaks both the stale-read guard and RoomList derivation.
- Do not evaluate aggregate badge deltas before the authoritative new-room fetch completes.
- Do not silently skip blocked new-room insertion without a refetch path.

References:
- `/private/tmp/claude-501/-Users-tualek-ohochat/e09208f3-facf-4303-8b26-c1c18904dc1b/scratchpad/oho1272-recheck.diff`
- `store/modules/smartchat.js:730-733,772-779,813-860,904-931,952-994`
- `components/Smartchat/RoomList.vue:149-177,191-205`
- Final verdict from the review: `VERDICT: 4 issues`.

## Thread `019fadbe-9f4b-7e81-955d-a4ab24c396a9`
updated_at: 2026-07-29T12:13:38+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-59-38-019fadbe-9f4b-7e81-955d-a4ab24c396a9.jsonl
rollout_summary_file: 2026-07-29T11-59-38-K1iF-unread_unresponded_optimization_report_verification.md

description: Read-only cross-repo audit of unread/unresponded performance report; found bounded-but-uncapped group totals, inline populate/audience fan-out, a customer-delivered/Stream-missing failure window, frontend fallback fetch amplification, and unsafe optimization proposals.
task: verify unread/unresponded optimization report claims and O1-O14 against live oho-api/oho-web-app code
task_group: cross-repo unread-unresponded performance review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: unread, unresponded, countDocuments, maxTimeMS, populate, sendMessage, Stream, Redlock, badge-count-cache, channel-eligible-members, Remote Config, refreshChatRoomBadgeRealtime, bulk-send, Vuex

### Task 1: Verify performance claims and deploy safety
task: audit report claims (a)-(g), missed query/fan-out risks, and optimization proposals O1-O14
task_group: cross-repo unread-unresponded deploy-gate review
task_outcome: partial

Preference signals:
- when the user says “READ-ONLY review” and “Do not modify any files” -> inspect live repositories and report findings only; do not patch, stage, or commit.
- when the user requires “Cite file:line for every claim” and an exact section contract -> produce structured, judgmental, evidence-first verdicts with explicit CONFIRMED/WRONG/PARTIAL labels.
- when the task spans API and web, the user expects the full chain: query/write cost, socket audience, frontend merge/fetch cost, and behavior preservation—not isolated file review.

Reusable knowledge:
- `group/search/search.class.js:110-114` runs unbounded `countDocuments(findQueryPayload)` but applies `maxTimeMS`; service timeout is 75s. It is frequently refetched by UI watchers, not proven to be timer-polled.
- `emit-chat-session-event.js:47-128` has one `findOne`, nine top-level populates, nested team populates, and no query-level maxTimeMS. Audience resolution can add team/member reads at `socket.io.js:359-417`. Contact inbound awaits emit hooks through `promiseAll`; member reply awaits full and narrow emitters sequentially.
- `contact-send-message.hooks.js:220-243` split one update into two sequential writes. The writes are error-unguarded, but the second has an ordering guard on `last_contact_date`.
- Critical failure window: platform delivery completes before after-hooks (`member-send-message.class.js:26-64`); clear writes at `member-send-message.hooks.js:667-686` run before `sendMessagesToChatStream()` at `:1289`, all inside Redlock `:1250-1310`. A clear-write failure can return an error after customer delivery while skipping Stream persistence.
- `badge-count-cache.ts:18-25` lacks environment/service prefix, but `channel-eligible-members.ts:8-9` also lacks one. Do not claim cross-environment collision without shared-Redis evidence.
- Web Remote Config `minimumFetchIntervalMillis=0` is configured at `plugins/firebase-remote-config.js:16-17`; plugin fetch is fire-and-forget at `:85-89`, so “network on every page load” is possible but not proven to block page open.
- `smartchat.js:706-763,927-948` only fetches contact details for qualifying fallback realtime events; there is no debounce, cancellation, or in-flight coalescing in `services/contact-api-service.js:54-66`.
- Bulk send starts platform handlers without awaiting and returns `{ok:true}` at `member-send-message/bulk/bulk.class.js:31-68`; serial contact loops and awaited per-contact writes/emits can fail-stop after the HTTP response succeeds.
- Flag-off does not avoid emitter cost: flag evaluation occurs after read/populate/audience work at `emit-chat-session-event.js:47-200`; only the payload field is removed at `:201-203`.
- Eligible-member cache misses have no single-flight (`channel-eligible-members.ts:50-76`) and accepted writes can carry up to 2,000 IDs into `unread_by` (`:10-18,74-78`).
- Socket.IO uses one `io.to(channelNames).emit()` call (`socket.io.js:420-440`), but recipient fan-out and room construction scale with eligible members; inbound bubbles add B message emits plus status emits.
- Web fallback uses the heavyweight `query_params.contact_default` population set (`smartchat.js:927-936`, `api/query-params.js:2-68`); realtime list/store paths perform multiple O(n) scans and rendering passes.

Failures and how to do differently:
- Do not describe `countDocuments` as literally unbounded when a timeout exists; distinguish work/cardinality bound from time bound.
- Do not label every socket event as causing a fallback fetch; separate qualifying fallback events from timestamped in-list and stale events.
- Do not approve raw fire-and-forget emits: it changes ordering, permits cross-request state races, and can lose events on shutdown.
- Do not merge clear writes by simply removing the `$exists` guard; legacy documents without `is_unresponded` require preserving field-absence semantics.
- Do not skip off-list fallback fetches without an authoritative polling/reconciliation path; this can leave rooms absent or counters stale.
- Treat O10/O14 as one Remote Config authority/refresh design, not independent quick fixes.
- Label conclusions as structural/source-only when no benchmark, explain, or production telemetry was run.

References:
- `/Users/tualek/ohochat/unread-unresponded-optimize-review.md`
- API revision: `5971ebf5673a838010ac5c9ca810e6d76163f555`; web revision: `5fc4ef224814aec240b55891ef36664e0abce5cd`; timestamp commit: `bbe0ac735`.
- `oho-api/src/services/member-send-message/member-send-message.hooks.js:667-686,1281-1289`
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:47-128,239-289`
- `oho-api/src/utils/badge-count-cache.ts:18-25`
- `oho-api/src/utils/channel-eligible-members.ts:50-76`
- `oho-api/src/services/member-send-message/bulk/bulk.class.js:31-68`
- `oho-web-app/store/modules/smartchat.js:706-763,927-948`
- `oho-web-app/plugins/firebase-remote-config.js:16-17,85-89`
- No tests or benchmarks were run; review was read-only/source-only.

## Thread `019fb1c7-36c8-7a02-92cc-6ab6c74fcc58`
updated_at: 2026-07-30T06:56:14+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T13-47-30-019fb1c7-36c8-7a02-92cc-6ab6c74fcc58.jsonl
rollout_summary_file: 2026-07-30T06-47-30-iE0E-cross_repo_jera_tab_fix_review_ship_blockers.md

description: Read-only cross-repo review of JERA tab race fix found a Feathers hook-registration startup blocker, fail-open login failure semantics, and weak direct-unit-test coverage; frontend contact-change regression was not reintroduced.
task: review uncommitted JERA tab race fix across oho-web-app and oho-api
task_group: cross-repo code review
task_outcome: fail
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: JERA, MaxPanel, feature_flags, Firebase Remote Config, Feathers hooks, service.hooks, Promise.all, contact_id, EPERM, Jest

### Task 1: Review oho-api login feature-flag hook

task: inspect login hook wiring, security, failure semantics, DRY, and tests
task_group: oho-api login feature flags
task_outcome: fail

Preference signals:
- The user requested a strictly review-only task across two separate worktrees and required every claim to cite actual file lines -> future reviews should inspect live diffs and avoid edits or unsupported speculation.
- The user explicitly required checking whether `e70f8a8a` contact-change refetch behavior was reintroduced -> always compare current watcher/call paths against the removed behavior, not just search for matching text.

Reusable knowledge:
- `login.service.js:16` calls `service.hooks(hooks)`, and Feathers treats every enumerable top-level export as a hook namespace. Exporting `addFeatureFlagsToResult` alongside `before/after/error` causes an invalid hook type and blocks service registration.
- `addFeatureFlagsToResult` reads `context.params.member.business_id` only after authentication, membership lookup, and member refresh (`login.hooks.js:36-70,146-150`), so the business ID is database-derived at that point rather than freely attacker-supplied.
- `Promise.all` at `login.hooks.js:121-126` rejects the entire after-hook when any flag helper rejects; `error.create` has no recovery. Remote Config fetch errors are caught, but `template.evaluate()` is outside that catch (`firebase-remote-config.js:35-52,79-85`).
- The helper reuses `businessSignal()` and `getBoolean()`; the semantic wrappers for unread, unresponded, and JERA do not require another abstraction.
- New login tests mock all Remote Config functions and directly invoke the exported helper. They therefore do not validate Feathers registration, production after-chain wiring, rejection handling, or the real JERA implementation. The handcrafted business ID/context also conflicts with the repo’s fixture-derived test standard.

Failures and how to do differently:
- Do not export helper functions as enumerable properties from a Feathers hook module passed wholesale to `service.hooks()`. Keep helpers non-exported, attach them safely for tests, or test through service registration.
- Do not let auxiliary feature-flag evaluation abort authentication. Use per-flag fail-soft defaults/logging or an explicitly validated fallback policy.
- Add a service-registration test and a rejected-helper test; direct helper tests alone miss the startup blocker and login availability regression.

References:
- `src/services/authentication-member/login/login.hooks.js:121-145,164-180,186-193`
- `src/services/authentication-member/login/login.service.js:3,16`
- `node_modules/@feathersjs/commons/lib/hooks.js:142-147`
- `src/firebase-remote-config.js:35-52,79-85,198-229`
- `src/services/authentication-member/login/login.hooks.spec.js:24-32,42-48,55-127`

### Task 2: Review oho-web-app MaxPanel fix

task: inspect race closure, retry behavior, and contact-change regression
task_group: oho-web-app JERA MaxPanel
task_outcome: partial

Preference signals:
- The user asked for test-by-test assessment, including whether a test would still pass if the fix were reverted -> future reviews should mentally revert each relevant production change and distinguish branch tests from integration proof.

Reusable knowledge:
- `MaxPanel.vue:361-374` watches the reactive feature flag with `immediate: true`; this covers both initial true state and a late browser/API flag transition.
- `MaxPanel.vue:375-383` retries only on focus when the flag is enabled, no fetch is active, and the previous attempt errored. `fetchJeraPartnerConnections()` sets the in-flight guard before awaiting and records errors at `:725-753`.
- The hotfix behavior from `e70f8a8a` remains removed: `contact_id` watcher only sets `active_profile_source` (`:402-406`). Fetch triggers are flag/focus watchers and explicit connect/disconnect methods (`:361-383,754-760`).
- MaxPanel tests directly invoke watcher handlers. They cover branches but not actual Vuex reactivity, watcher scheduling, `immediate: true`, visibility-change propagation, or simultaneous triggers.

Failures and how to do differently:
- Treat direct watcher-handler tests as partial coverage, not proof of the race fix. Add a mounted/component test that changes Vuex state from false to true and verifies the API fetch, plus an in-flight concurrency test.
- The “flag re-evaluates true” test is artificial because a Vue boolean watcher does not naturally rerun for `true → true`; focus retry is the realistic retry path.

References:
- `components/MaxPanel.vue:361-383,402-412,447-449,725-753,754-760`
- `test/components/MaxPanel.spec.js:251-340`
- `layouts/default.vue:468-480`
- `e70f8a8a` removed the old contact-change fetch from the `contact_id` watcher.

### Task 3: Assess frontend/backend interaction

task: trace login flags, browser Remote Config precedence, and double-fetch risk
task_group: cross-repo feature-flag integration
task_outcome: partial

Reusable knowledge:
- `nuxtServerInit` awaits `authOhoMember`, which commits `res.feature_flags` into Vuex (`store/index.js:300-302,502-512`); MaxPanel reads `state.feature_flags.rt_jera_feature_enabled` (`MaxPanel.vue:447-448`).
- `setFeatureFlags` records API-authoritative keys and `setRemoteConfigFeatureFlags` filters those keys (`store/index.js:103-128`), so normal API/browser resolution ordering should not overwrite server decisions.
- MaxPanel’s nonempty-result and in-flight guards prevent ordinary duplicate JERA fetches (`MaxPanel.vue:363-370,725-735`).
- If server Remote Config cold-start evaluation returns default false (`firebase-remote-config.js:35-52,119-129`), that false becomes authoritative and later browser true is discarded, leaving a possible session-level hidden-tab failure.

Failures and how to do differently:
- Review API-authoritative flag systems for both overwrite safety and recovery semantics. Preventing browser overwrite can also suppress recovery from a transient server-side flag-evaluation failure.
- Targeted tests were not executable in this sandbox: both Jest commands failed with `EPERM` writing haste-map files. Record this as unverified rather than claiming tests passed.

References:
- `store/index.js:103-128,300-302,502-512`
- `plugins/firebase-remote-config.js:43-56,85-89`
- `src/firebase-remote-config.js:35-52,119-129`
- Test error: `EPERM: operation not permitted, open .../jest_dx/haste-map-...`

## Thread `019fb213-6e6a-7ca2-9032-29a514b9a891`
updated_at: 2026-07-30T08:16:29+00:00
cwd: /Users/tualek/ohochat/oho-web-app
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-10-45-019fb213-6e6a-7ca2-9032-29a514b9a891.jsonl
rollout_summary_file: 2026-07-30T08-10-45-wXG9-firebase_remote_config_multitab_race_review.md

---
description: Read-only cross-repo review found a real same-origin multi-tab Firebase Remote Config cache collision; recommend removing the browser fetch path after server flags are verified.
task: analyze web Firebase Remote Config caching, multi-tab business-signal race, and mobile-pattern port
 task_group: oho-web-app/firebase-remote-config-design
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Firebase Remote Config, minimumFetchIntervalMillis, onConfigUpdate, onConfigUpdated, IndexedDB, custom signals, multi-tab, feature_flags_api_keys, JERA
---

### Task 1: Evaluate multi-tab cache race and web implementation strategy

task: determine whether a large web minimum fetch interval can reuse another tab’s business-evaluated config, inspect Flutter cache reset behavior, verify JS real-time support, and recommend whether to port mobile behavior.
task_group: Firebase Remote Config design review
task_outcome: success

Preference signals:
- When the user required “Design consultation only. Do NOT modify any files” -> keep future reviews read-only and do not edit, stage, or commit.
- When the user required every SDK claim to be tagged as actual source/typings or documented-architecture reasoning -> cite exact local SDK paths/lines and label external documentation separately.
- When the user specified a fixed six-part output order and asked for a direct verdict -> preserve that structure and provide a concrete recommendation rather than a generic pros/cons list.

Reusable knowledge:
- Installed `@firebase/remote-config@0.8.0` uses IndexedDB database `firebase_remote_config`. Its composite key is app ID, app name, namespace, and record key; custom-signal values are not part of the key (`node_modules/@firebase/remote-config/dist/index.cjs.js:1024-1040,1253-1256`).
- `active_config`, `last_successful_fetch_response`, fetch timestamp, and `custom_signals` are single records per app/namespace (`:1081-1121`). Cache freshness checks timestamp only (`:586-610`), so a Tab A for business X can consume Tab B’s recently evaluated business-Y blob. This makes the multi-tab race real.
- Flutter starts with a 12-hour interval (`oho-flutter-mobile/lib/core/services/remote_config_service.dart:21-23`), but `clearRemoteConfigCache()` sets `Duration.zero`, fetches, and never restores 12 hours (`:62-75`). The first signal update therefore leaves that instance permanently unthrottled.
- The JS SDK supports `onConfigUpdate`, documented in installed typings (`node_modules/@firebase/remote-config/dist/remote-config-public.d.ts:289-304`) and implemented at `index.cjs.js:523-545`. Real-time fetches use cache age zero (`:1788-1805`) and callbacks require explicit `activate()` (`:1820-1830`). Real-time does not isolate per-business cached values.
- Server-side correctness is already primary: login adds four evaluated flags (`oho-api/.claude-worktrees/jera-tab-is-missing/src/services/authentication-member/login/login.hooks.js:119-140,175-187`), while Vuex marks API-set keys authoritative and filters later browser values (`oho-web-app/store/index.js:103-128,502-512`).
- Recommended strategy is the simpler safer variant: after verifying rollout, remove automatic browser initialization/custom-signal setting/fetch/activate fallback from `plugins/firebase-remote-config.js`; retain synchronous Vuex getters, E2E overrides, API bootstrap, and fail-closed defaults. Do not port interval bypass or real-time listeners.

Failures and how to do differently:
- Do not assume Firebase cache entries are keyed by custom-signal combinations; local SDK source shows they are not.
- Do not claim the exact behavior is always “reactivation”: a fresh tab may load the shared active config, and `activate()` can return false when the shared ETag is already active (`index.cjs.js:290-315`).
- Do not infer OHO fetch volume. The review found no repository measurement; inspect Firebase usage dashboards before prioritizing cleanup.

References:
- `oho-web-app/plugins/firebase-remote-config.js:16-17,36-41,52-57,85-89`
- `oho-web-app/components/SwitchBusiness.vue:202-215`
- `node_modules/@firebase/remote-config/package.json` reports `@firebase/remote-config` version `0.8.0`.
- Firebase pricing/quota documentation reviewed: 100,000 fetches/day free under announced September 1, 2026 model; real-time connection itself is not a continuous series of fetches, but invalidation-triggered downloads count.
- Suggested validation: two same-origin tabs on different businesses, alternating hard reloads, verify each tab’s flags against its own login response; simulate server Remote Config failure and ensure authentication succeeds with false defaults.

## Thread `019fb247-9cdc-76a3-a098-2b88906c3dc1`
updated_at: 2026-07-30T09:16:07+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-07-45-019fb247-9cdc-76a3-a098-2b88906c3dc1.jsonl
rollout_summary_file: 2026-07-30T09-07-45-YIjD-firebase_remote_config_cache_hit_rereview.md

description: Read-only re-review confirmed the Firebase Remote Config cache-hit signal-ordering fix and 9 passing Jest tests; no new blockers found.
task: review firebase-remote-config cache-hit signal ordering
task_group: oho-web-app frontend code review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
keywords: firebase-remote-config, setCustomSignals, invocationCallOrder, Jest, sessionStorage, degradedToSharedCache, EPERM, read-only review

### Task 1: Verify cache-hit signal ordering

task: review firebase-remote-config cache-hit signal ordering
task_group: oho-web-app frontend code review
task_outcome: success

Preference signals:
- When the user says “review-only” and “Do NOT edit any files,” keep the review strictly read-only and verify every claim against the live worktree.
- When the user requests a verdict up front, exact `file:line` evidence, separate nice-to-haves, and actual test counts, use a compact structured, evidence-first report.
- When the user says accepted risks are not to be re-litigated, do not re-flag them unless the current code makes them worse or reveals a genuinely new mitigation.

Reusable knowledge:
- In the final snapshot, `setCustomSignals()` is awaited at `plugins/firebase-remote-config.js:115-121`, before all listener registrations: cache hit `:123-128`, fetch-failure cache fallback `:141-145`, and normal/shared-cache completion `:137-163`.
- The regression assertion at `test/plugins/firebase-remote-config.spec.js:96-101` checks the correct `business_id` and `mockSetCustomSignals` invocation before `mockOnConfigUpdate`; Jest 27 supports `mock.invocationCallOrder`, and the assertion would fail against the old cache-hit bug.
- Accepted SDK risks are documented at `plugins/firebase-remote-config.js:7-17`; the code still uses `fetchAndActivate()` and `activate()`, so the risk characterization remains applicable.
- Verified invariants remain at `:98` (minimum fetch interval 0), `:173-178` (test override), `:180-190` (missing API key return), `:192-196` (fire-and-forget), and `:132-160` (`degradedToSharedCache`).
- Final test result was 1 suite passed, 9 tests passed, 0 failures, 0 snapshots. The successful run used repository Jest dependencies with `NODE_ENV=test`, `NODE_PATH`, `--runInBand --cache=false --coverage=false`, while suppressing sandbox-rejected cache/coverage filesystem writes in memory.

Failures and how to do differently:
- Direct Jest attempts initially failed before test collection due to sandbox `EPERM` writes to temp haste/transform caches. Distinguish these infrastructure failures from actual test failures and use a controlled in-memory cache-write workaround when permitted.
- The worktree changed concurrently during review. Re-read the latest files, re-run tests, and capture final hashes before issuing a verdict.
- `test/plugins/firebase-remote-config.spec.js` was untracked, so the requested `git diff` did not include it; ensure it is added before commit/MR.

References:
- Worktree: `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing`
- Final plugin SHA-256: `0274d13dc3b82cf6a46cdf9628a9ba6a25c27f9fb3d70c00046ed564335f4a4f`
- Final test SHA-256: `b99dafda71d6a067848e11a5a9bf96594da162572a8810bdeddef8fb3c752419`
- No `node_modules` symlink remained in the worktree.

## Thread `019fb257-6da8-7681-aa63-4c62263ee116`
updated_at: 2026-07-30T09:33:14+00:00
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-25-02-019fb257-6da8-7681-aa63-4c62263ee116.jsonl
rollout_summary_file: 2026-07-30T09-25-01-qjNc-final_read_only_jera_login_feature_flags_review.md

description: Final read-only review of oho-api JERA login feature-flag diff; implementation passed behavioral checks and all 14 tests, with only non-blocking test-quality/style nits.
task: review-uncommitted-login-feature-flags-diff
task_group: oho-api-read-only-code-review
task_outcome: success
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
keywords: git-diff, read-only-review, firebase-remote-config, getLoginFeatureFlags, configLoaded, cold-start, TTL-boundary, Feathers-hooks, isJeraFeatureEnabled, Jest, Node-20, EPERM

### Task 1: Review JERA login feature flags

task: verify-final-uncommitted-diff-and-run-specs
task_group: oho-api-read-only-code-review
task_outcome: success

Preference signals:
- when the user said to run `git diff` yourself and not trust the prior-round summary -> independently verify the live worktree, line-numbered final files, and all claimed fixes before reporting.
- when the user required read-only review and removal of any temporary symlink -> do not edit, stage, commit, or leave filesystem artifacts; confirm final git status.
- when the user requested an explicit verdict, exact file:line evidence, and real pass/fail counts -> give a compact evidence-first report with separate ship blockers and non-blocking nits.

Reusable knowledge:
- `getLoginFeatureFlags()` evaluates the four flags using `[key, usesBusinessSignal]` pairs and uses the same key for Remote Config evaluation and returned object keys (`src/firebase-remote-config.js:147-175`). The constants are identical to their Remote Config/result names.
- Cold-start failure is fail-safe: fetch failure leaves `cachedTemplate` null (`src/firebase-remote-config.js:35-52`), `getBooleanWithState()` returns `{ value: false, configLoaded: false }` (`:119-130`), and the reducer excludes unloaded keys (`:172-175`).
- Login feature-flag enrichment is auxiliary and fail-soft: the after-hook catches errors, logs with `warnWithOptions`, leaves `feature_flags` unset, and returns the login context (`src/services/authentication-member/login/login.hooks.js:102-118`).
- Whole-repo searches found zero `isJeraFeatureEnabled` references. The hook module exports only Feathers lifecycle keys, verified by the new spec.
- Under Node `v20.20.2`, both specs passed: 2 suites and 14 tests, 0 failures. The sandbox blocked Jest cache writes with `EPERM`; an in-process filesystem shim suppressed only Jest cache persistence so actual transforms/tests ran.

Failures and how to do differently:
- Standard Jest invocation could not write its haste/transform cache in the restricted sandbox and failed before tests ran. Report this as an environment limitation, not a test failure; if using a cache-write workaround, disclose it.
- Non-blocking cleanup opportunities: prefer TypeScript for `login.hooks.spec.js`; derive the repeated four-flag fixture from one named object; name remaining timing margins; rename `mod` to a meaningful module variable; remove the remaining WHAT-only comment.

References:
- `src/firebase-remote-config.js:35-52,119-130,147-175`
- `src/firebase-remote-config.spec.ts:274-317`
- `src/services/authentication-member/login/login.hooks.js:102-118,121-172`
- `src/services/authentication-member/login/login.hooks.spec.js:48-118`
- Exact validation result: `Test Suites: 2 passed, 2 total; Tests: 14 passed, 14 total`.
- Final status: intended modified files only; no `node_modules` symlink; `git diff --check` clean.

## Thread `019fb6c7-39c5-7110-9c61-b4878f375e66`
updated_at: 2026-07-31T06:35:27+00:00
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T13-05-37-019fb6c7-39c5-7110-9c61-b4878f375e66.jsonl
rollout_summary_file: 2026-07-31T06-05-37-BMns-oho_1272_second_round_realtime_badge_review.md

---
description: Second-round read-only verification of OHO-1272 realtime badge fixes; correctness blockers fixed, but formatting and a vacuous visibility test caused NO-SHIP
 task: review-uncommitted-smartchat-realtime-badge-fixes
 task_group: oho-web-app-smartchat-code-review
 task_outcome: partial
 cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
 keywords: OHO-1272, smartchat.js, addRealtimeContactToList, is_unresponded, equal-timestamp, dedupe, Jest, Prettier, EPERM, UAT
---

### Task 1: Equal-timestamp raw badge contract

task: verify equal-timestamp realtime event handling
task_group: smartchat realtime badge review
task_outcome: success

Preference signals:
- The user required a read-only review with actual file:line citations and specifically asked to verify raw `is_unresponded` stripping; future reviews should inspect the live diff and prove the raw-payload contract, not rely on synthesized-field reasoning.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` now deletes `event_message.is_unresponded` only when `is_equal_timestamp` is true (`store/modules/smartchat.js:775-805`). Newer events still synthesize `is_unresponded:true` (`:791-797`).
- Equal events retain `is_read_by_me:false` and `last_contact_date`, allowing the downstream local-read cursor guard to run.

Failures and how to do differently:
- The earlier version only avoided synthesizing `is_unresponded`; raw payload fields could still survive. The corrected implementation strips the raw field after the spread.

References:
- `store/modules/smartchat.js:775-805`
- `test/store/modules/smartchat.spec.js:1394-1420`

### Task 2: Atomic realtime dedupe and cap handling

task: verify duplicate-row fix and capped-list behavior
task_group: smartchat realtime insertion
 task_outcome: success

Reusable knowledge:
- `addRealtimeContactToList` performs dedupe first, then optional tail pop, then head/tail insertion and Set reconciliation in one synchronous mutation (`store/modules/smartchat.js:172-201`). This prevents the prior await-separated pop/insert race that could lose an unrelated tail row.
- Realtime insertion maps `from_head: sort_chat_list !== 1` (`store/modules/smartchat.js:1048-1055`), preserving normal unshift behavior and oldest-sort push behavior.
- Repo-wide grep found no executable `handleLimitContactList` or `removeLastContact` references; only the explanatory comment at `smartchat.js:174` remains.
- Pagination still uses `addContactListData`/`addContactListDataFromHead`, which retain dedupe but intentionally do not add cap-pop behavior.

References:
- `store/modules/smartchat.js:178-201`
- `store/modules/smartchat.js:1048-1055`
- `test/store/modules/smartchat.spec.js:1434-1488`

### Task 3: Test and formatting validation

task: validate store/full test results and formatting
task_group: smartchat verification and UAT gate
task_outcome: partial

Preference signals:
- The user asked for decisive UAT gating and explicit separation of unrelated full-suite failures from changed-code failures; future reviews should report exact suite/test counts and causality.

Reusable knowledge:
- Store scope passed 61/61 (`smartchat.spec.js` + `websocket.spec.js`) under a narrowly scoped Jest cache-write workaround. Direct Jest execution otherwise failed before tests due sandbox `EPERM` writes under `/private/var/folders/.../jest_dx`.
- Full test run: 53 suites passed, 4 failed; failures were in unchanged JERA/media suites: `MaxPanel`, `IntegrationExternal`, `MaxPanelJeraProfilePanel`, and media-library `_type`. Changed files were only the Smartchat store/test files.
- Direct installed `./node_modules/.bin/prettier --check` (Prettier 2.8.8) flagged both changed files. An earlier `rtk npx prettier --check` clean result was a proxy false positive; use the repository binary for formatting verification.
- The visibility-negative test is weak/vacuous: it mocks visibility false but leaves `getAvailableMenusForChatRoom` returning `[]` while the active menu is `all`, so insertion is blocked regardless (`test/store/modules/smartchat.spec.js:492-515`; `__mocks__/mock-plugin.js:53-57`; `__mocks__/mock-store.js:41-43`). Set available menus to `['all']` to genuinely exercise visibility.
- No direct test covers `from_head:false` at the cap; implementation was statically verified but this remains a non-blocking coverage gap.

Failures and how to do differently:
- Do not accept formatter validation from optimized wrapper output when it conflicts with the installed binary. Run `./node_modules/.bin/prettier --check` directly.
- Do not treat a negative assertion as meaningful unless other branch predicates are configured to allow the behavior under test.

References:
- Store validation: `smartchat.spec.js` + `websocket.spec.js`, 61 passed.
- Full validation: 53 passed, 4 failed; 702 passed, 25 failed, 2 skipped.
- Formatting command: `./node_modules/.bin/prettier --check store/modules/smartchat.js test/store/modules/smartchat.spec.js`
- Final verdict: `NO-SHIP` until formatting is clean and the visibility test is non-vacuous.

## Thread `019fb713-0b24-7323-941a-c766d20f9d78`
updated_at: 2026-07-31T07:56:34+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-28-26-019fb713-0b24-7323-941a-c766d20f9d78.jsonl
rollout_summary_file: 2026-07-31T07-28-26-vltS-mr872_realtime_badge_final_merge_review.md

---
description: Final read-only review of oho-web-app MR !872; prior raw badge-field and open-room blockers were fixed, and the MR was verified mergeable with focused tests passing.
task: review GitLab MR !872 merge readiness
 task_group: /Users/tualek/ohochat/oho-web-app / realtime smartchat badge reviews
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: MR-872, 8150150f, smartchat, refreshChatRoomBadgeRealtime, is_read_by_me, is_unresponded, feature-flags, open-room, Vuex, websocket, mergeable, Jest
---

### Task 1: Final MR !872 merge review

task: determine whether MR !872 can merge after iterative fixes
task_group: oho-web-app realtime unread/unresponded badge review
task_outcome: success

Preference signals:
- The user asked whether the MR could merge and repeatedly requested another check -> future reviews should re-fetch current GitLab metadata and re-review the latest exact head, not rely on prior conclusions.
- The review was explicitly read-only and avoided a dirty main checkout -> preserve user worktrees and inspect the MR via GitLab or an isolated clean worktree.

Reusable knowledge:
- `refreshChatRoomBadgeRealtime` spreads raw socket payloads before `handleSmartchatRealtimeUpdate` picks `DEFAULT_UPDATE_FIELDS`; feature flags must strip raw `is_unresponded` and `is_read_by_me`, not only gate synthesized fields.
- Final fix computes `is_open_room` before the optimistic/fallback split and strips `is_read_by_me` when `!is_unread_enabled || is_open_room`; this protects the contract that open-room read state is owned by `markRoomRead`.
- Final MR head `8150150f4fc9955cb7816288c90e511ff28a28b8` is based directly on `develop` `897245556ae6062ba6146996d527e212e5d334ce`; GitLab reported mergeable, conflict-free, zero divergence, and resolved discussions.
- Focused validation passed on Node `22.23.1`: `test/store/modules/smartchat.spec.js` and `test/store/modules/websocket.spec.js`, 2 suites and 79 tests.

Failures and how to do differently:
- Earlier heads had two real blockers: raw badge fields bypassed disabled flags; then raw `is_read_by_me:false` bypassed the open-room guard. Always test raw payload fields for both optimistic and fallback paths, including open-room behavior.
- No GitLab pipeline or manual QA was available; merge approval should state those limitations explicitly.

References:
- Final MR state: `sha=8150150f4fc9955cb7816288c90e511ff28a28b8`, `detailed_merge_status=mergeable`, `has_conflicts=false`, `diverged_commits_count=0`, `head_pipeline=null`.
- Test command: `rtk /Users/tualek/.nvm/versions/node/v22.23.1/bin/node /Users/tualek/.nvm/versions/node/v22.23.1/lib/node_modules/npm/bin/npm-cli.js test -- --runInBand --no-cache test/store/modules/smartchat.spec.js test/store/modules/websocket.spec.js`
- Result: `Test Suites: 2 passed, Tests: 79 passed`.
- Code: `store/modules/smartchat.js:798,815,837-848`.
- Tests: `test/store/modules/smartchat.spec.js:1832-1896`.

## Thread `019fb917-4170-7273-a018-fe437807752a`
updated_at: 2026-07-31T16:57:58+00:00
cwd: /Users/tualek/ohochat/docs/react-migration
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T23-52-16-019fb917-4170-7273-a018-fe437807752a.jsonl
rollout_summary_file: 2026-07-31T16-52-16-hvzY-review_backoffice_react_migration_plan.md

description: Read-only, evidence-based review of the oho-backoffice React migration plan against the actual Nuxt/Vue repository; found route inventory, API/auth contract, cross-app navigation, testing, deployment, and observability gaps requiring rework before implementation
task: review oho-backoffice React migration plan against repository source
 task_group: migration-plan-review
 task_outcome: success
cwd: /Users/tualek/ohochat/docs/react-migration
keywords: oho-backoffice, react-migration, Nuxt2, Vue2, TanStack Router, Cloud Run, path-based-cutover, auth-cookie-contract, external-message, API-inventory, read-only-review

### Task 1: Review migration plan against actual oho-backoffice repo

task: compare backoffice-react-v2-plan.md with live oho-backoffice source without editing
 task_group: migration-plan-review
 task_outcome: success

Preference signals:
- When the user specified “Scope is strictly oho-backoffice only” and “do not edit the plan file or any other files” -> keep future reviews scoped to that repo and strictly read-only.
- When the user required organization by plan section/phase, quoted references, concrete adjustments, and a prioritized top 3–5 -> report findings phase-by-phase, evidence-first, with actionable fixes and a short priority list.
- When the user required grounding in verifiable files and said not to guess repo structure/tooling -> inspect route, API, auth, dependency, and deployment sources before asserting a gap.

Reusable knowledge:
- The v2 plan omitted active production routes `/external-message-apps` and `/external-message-whitelist`, present in `oho-backoffice/store/modules/menu.js:92-103` and implemented by `pages/external-message-apps.vue` and `pages/external-message-whitelist.vue`. Add them to route inventory, feature structure, tests, smoke tests, and cutover sequence.
- The plan’s sample API contract is inaccurate: real endpoints are in `oho-backoffice/api/endpoint.js`, including `/backoffice/business` and `/backoffice/authentication-user`; business data uses `_id`, `is_disabled`, and `is_deleted`, not the simplified `/businesses`, `id`, and `status` example.
- Existing auth behavior is in `store/index.js:96-166`: cookies include `auth_user_token`, `auth_user_id`, and `auth_created_token_at`; token exchange uses the backoffice authentication endpoint. `plugins/axios.js:3-45` attaches the current cookie token to requests.
- Existing cookie writes are host-only with `maxAge`; the plan’s proposed `.oho.chat` domain and deletion on every bootstrap failure require explicit review. Preserve codec, domain/path, SameSite/Secure, expiry, removal attributes, and distinguish 401/403 from transient network/5xx failures.
- The plan introduces Zustand state (`sidebarCollapsed`, `commandPaletteOpen`) without evidence that either behavior exists in the current backoffice. For a 1:1 migration, defer these unless a parity inventory proves they are required.
- Legacy URL state is not equivalent to the proposed React schema. Existing business menu links use `is_disabled` and `is_deleted` (`store/modules/menu.js:19-31`), while payment and list pages use additional legacy query parameters. Preserve compatibility during gradual cutover.
- URL-map path routing can be bypassed by client-side navigation: Nuxt uses `<nuxt-link>` and `$router.push()` (`components/Sidenav.vue`, `components/SubMenu.vue:117-131`). Define a hard-navigation rule at React/Nuxt ownership boundaries, maintain a route ownership manifest, and test navigation in both directions plus browser history.
- Cloud Run and build strategy are coupled decisions. The plan locks Cloud Run but defers build-per-env versus build-once runtime config to Phase 5; decide hosting/runtime config in Phase 0 because it changes Dockerfile, nginx, CI, artifact promotion, and rollback.
- Testing needs implementation gates, not only a locked stack: configure Vitest/RTL/Playwright, controlled staging fixtures, lint/typecheck/unit/build CI gates, and per-route E2E assertions for mutations, uploads, destructive actions, validation, and recovery.
- `Intl.NumberFormat` needs a parity contract before replacing numeral. `plugins/numeral-format.js` supports integer, fixed-decimal, percentage, compact, currency-prefix, and null/Decimal-like formatting. Create separate helpers and golden tests.
- Runtime-liveness audit is required before porting cross-cutting behavior. Socket, window-focus, mobile detection, and widget lifecycle calls are commented out in `layouts/default.vue`; classify active, dead, or intentionally removed behavior.
- Phase 5 needs concrete LB exact/nested matchers, calendar-duration re-estimation, IaC, staging rollback drills, and explicit rollback/decommission exit criteria. A 5–7 day phase conflicts with 2–3 day observation windows per path.
- Cloud/LB metrics and an error boundary do not provide browser observability. Add frontend error reporting, source maps, release/environment tags, and separate React/Nuxt dashboards before production cutover.

Failures and how to do differently:
- A hand-written route list missed active external-message pages. Generate route/menu/page inventories from the repository and compare them with the plan.
- Generic React examples drifted from the real API and auth contract. Derive DTOs, endpoint wrappers, and examples from `api/endpoint.js`, auth actions, and representative page calls.
- Path-based cutover was underspecified for SPA client navigation. Test legacy→React and React→legacy transitions and enforce hard navigation across ownership boundaries.

References:
- `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`
- `/Users/tualek/ohochat/oho-backoffice/api/endpoint.js`
- `/Users/tualek/ohochat/oho-backoffice/store/index.js`
- `/Users/tualek/ohochat/oho-backoffice/plugins/axios.js`
- `/Users/tualek/ohochat/oho-backoffice/store/modules/menu.js`
- `/Users/tualek/ohochat/oho-backoffice/components/Sidenav.vue`
- `/Users/tualek/ohochat/oho-backoffice/components/SubMenu.vue`
- `/Users/tualek/ohochat/oho-backoffice/layouts/default.vue`
- Verified repo baseline: `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1`.

## Thread `019fbdea-0a3f-7ed2-a3b3-fddd0046094f`
updated_at: 2026-08-01T15:23:11+00:00
cwd: /Users/tualek/ohochat/backoffice-v2
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T22-20-59-019fbdea-0a3f-7ed2-a3b3-fddd0046094f.jsonl
rollout_summary_file: 2026-08-01T15-20-59-jg2H-react_backoffice_architecture_review.md

---
description: Time-boxed architecture review of migrated React admin app; structure is viable but needs boundary and scaling fixes before multi-person development
 task: review-react-migration-architecture
 task_group: /Users/tualek/ohochat/backoffice-v2
 task_outcome: success
 cwd: /Users/tualek/ohochat/backoffice-v2
 keywords: react-migration, feature-based, layering, payment, business, barrels, query-keys, circular-dependency, eslint
---

### Task 1: Review React migration architecture

task: assess feature-based React structure, layer enforcement, sampled payment/business implementation, and scale risks
task_group: React architecture review
 task_outcome: success

Preference signals:
- เมื่อผู้ใช้กำหนด “TIME-BOX ... อย่า audit ทุกไฟล์” และ “ตอบ 5 ข้อ สั้นๆ ตรงประเด็น ห้ามเขียนยาว” -> รีวิวลักษณะนี้ควรใช้ targeted sampling และสรุป actionable findings โดยไม่ rerun baseline checks เว้นแต่จำเป็น
- ผู้ใช้ล็อกว่า backend contract และ URL contract ห้ามเปลี่ยน ส่วน legacy quirk แก้ได้แต่ต้องจด -> แยก architectural review จาก parity/contract audit ให้ชัด

Reusable knowledge:
- Feature-based architecture เหมาะกับ admin CRUD ขนาดนี้; ไม่จำเป็นต้องรวมโฟลเดอร์หรือรื้อสถาปัตยกรรม
- Layer separation มีจริงในเส้นหลัก: route composer บาง, page ใช้ hooks, API แยก raw I/O, `lib` มี domain/pure logic
- กฎ “components render อย่างเดียว” ยังไม่ตรง implementation: `src/features/business/components/ChannelTable.tsx:123-133` ใช้ `useQuery` และเรียก `getLineWebhook`; `src/features/payment/components/PaymentDialog.tsx:131-151` ใช้ `useQuery` และเรียก API โดยตรง; `PaymentDetailPage` ยังรวม validation/orchestration ได้ในฐานะ feature container
- `shared/lib` หมายถึง I/O/external-bound code; `shared/utils` หมายถึง pure function; feature-level ใช้ `lib/` เดียว ไม่มี `utils/` ถือว่าเป็น convention ที่ชัด
- Query-key convention กระจายหลายตำแหน่ง: payment `hooks/query-keys.ts`, business `lib/query-keys.ts` และ `api/*`, JERA/external-message `api/query-keys.ts`; sample ไม่พบ namespace collision แต่การกระจายนี้เสี่ยง convention เสื่อมเมื่อทีมโต
- Public barrels ใหญ่: `src/features/business/index.ts` 258 lines และ `src/features/payment/index.ts` 232 lines; ควรลดให้เหลือ public API ที่ถูกใช้ข้าม feature/โดย routes จริง
- ESLint feature isolation ตรวจ alias deep imports แต่ config ระบุเองว่า relative imports ที่ไต่ข้าม feature (`../../other-feature/...`) ตรวจไม่ได้; ยังไม่มี circular dependency/dependency-direction gate
- `business` เป็น composition hub ที่ import JERA, payment และ sales-order; ต้องเฝ้าระวัง reverse dependency ที่ทำให้เกิด cycle

Failures and how to do differently:
- ห้ามสรุปว่า layer enforcement ครบเพียงเพราะมีโฟลเดอร์และ ESLint: ต้อง sample call path และค้นหา component ที่ import `features/*/api` โดยตรง
- ก่อนให้ทีมเพิ่มหน้าแบบเต็มสปีด ควรย้าย I/O จาก `ChannelTable` และ `PaymentDialog` เข้า hooks, กำหนดตำแหน่ง query-key factory เดียว, ลด barrels, และเพิ่ม CI ตรวจ circular dependencies กับ relative cross-feature imports
- ใน snapshot นี้ git commands ใช้ไม่ได้เพราะ cwd ไม่ใช่ git repository; อย่าใช้ git status/log เป็นหลักฐานหลักของ review

References:
- Plan: `/Users/tualek/docs/react-migration/backoffice-react-v2-plan.md`, sections 6, 8, 9
- `src/features/business/components/ChannelTable.tsx:123-133`
- `src/features/payment/components/PaymentDialog.tsx:131-151`
- `src/features/payment/components/PaymentDetailPage.tsx:157-184`
- `src/app/routes/_authenticated/business.tsx:26-50`
- `src/features/business/components/BusinessPage.tsx:98-138`
- `eslint.config.js:235-238`
- Component sizes: `PaymentDialog.tsx` 659 lines, `PaymentDetailPage.tsx` 664 lines, `BusinessDetailPage.tsx` 632 lines

## Thread `019fc38b-2163-7081-8ab6-b42248952f08`
updated_at: 2026-08-02T20:11:49+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T00-35-03-019fc38b-2163-7081-8ab6-b42248952f08.jsonl
rollout_summary_file: 2026-08-02T17-35-03-puSA-meta_business_ai_poc_second_opinion_review.md

---
description: Evidence-first Thai second-opinion review of Meta Business AI POC OHO-1215; docs and code reviewed successfully, prod log recheck only partially completed due sandbox credential refresh failure; main takeaway is to rework owner/state model before implementation
task: review_meta_business_ai_poc_oho1215
task_group: meta-business-ai-messenger-handover
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: OHO-1215, Meta Business AI, standby, messaging, ai_generated, hop_context, pass_thread_control, take_thread_control, thread_owner, bot gate, gcloud logging, queue ordering, HUMAN_AGENT
---

### Task 1: Meta Business AI POC second-opinion review

task: review six POC answers against findings, payloads, official guide, code paths, and prod logs
 task_group: meta-business-ai-messenger-handover
 task_outcome: success

Preference signals:
- ผู้ใช้ขอรายงานภาษาไทยแบบละเอียด และกำหนดโครงสร้างปัญหา/หลักฐาน/ความรุนแรง/ข้อเสนอแนะ -> งาน review คล้ายกันควรตอบไทยและ cite หลักฐานละเอียด
- ผู้ใช้กำชับ “Do not fabricate log output” และให้แยก verified/not verified -> ห้ามเปลี่ยน timeout หรือ credential failure เป็น no data; ใช้ `Not run: <reason>` ตามจริง
- ผู้ใช้กำหนด read-only, ห้ามแก้ไฟล์และ commit -> ควรตรวจโดยไม่แก้ repo และ pin สถานะ worktree/commit ก่อน trace

Reusable knowledge:
- คำตอบ POC ทั้งหกไม่ควรถูกใช้เป็น implementation contract โดยตรง: Q1 replay ยังเป็น hypothesis; Q2 observational flag คือ recently observed ไม่ใช่ enabled state; Q3 channel ไม่พอระบุว่า AI/OHO/Business Suite เป็น owner; Q4 เป็น eventual/best-effort detection; Q5 structured reason ไม่มีใน payload; Q6 standby gate ถูกหลักแต่ต้องมี send-time guard
- `meta-biz-ai-payload-samples.md:33–39` มี AI echo ทาง `messaging` พร้อม `hop_context.app_id=388207815496149`; ห้ามตีความ `messaging=OhoChat` หรือ `standby=Meta AI` แบบ binary
- `meta-biz-ai-payload-samples.md:71–77` แสดง `take_thread_control` metadata `axon_take_thread_control`, previous owner `388207815496149`, new owner `928891643393937`, timestamp เป็นวินาที และส่งซ้ำ 4 ครั้ง; ต้อง deduplicate logical transition
- `meta-biz-ai-payload-samples.md:53–69` แสดง read-channel switch หลัง AI farewell; arrival `entry.time` ประมาณ 3.69s แต่ embedded event timestamp ประมาณ 2.13s; ต้องเก็บทั้ง clocks และไม่ใช้ “~4s” เป็น universal SLA
- `meta-biz-ai-queue-routing-design.md:68–72` ระบุ hop_context พบเพียง 113/796 requests และ AI echoes 25 รายการไม่มี hop; finding เก่าที่บอก `is_ai_thread_owner` มาทุกข้อความขัดกับหลักฐานใหม่
- `handler.ts:857–875` ทิ้ง channel หลังเลือก `messaging[0] || standby[0]`; `handler.ts:945–992` จัดการ read แล้ว return ก่อน bot path; `handler.ts:1612–1632` schedule fallback bot; ดังนั้น standby ingress gate อย่างเดียวไม่กัน scheduled/in-flight send และไม่ implement read-based ownership flip
- `helper.ts:1465–1541` และ `facebook.controller.ts:124–168` เลือก queue จาก entry/event แรกและ enqueue request ทั้งก้อน; ต้องแตก canonical event envelope ต่อ page/PSID/event ก่อนจัด queueเพื่อกัน mixed-entry misrouting
- control event อย่าง `take_thread_control` ไม่มี `message` แต่เข้า handler เดียวกัน; `helper.ts:1294–1304` fallback เป็น unsupported text ได้ จึงควร branch control event ก่อน transform และห้ามสร้าง chat bubble/bot trigger
- Official PDF local (15 หน้า, extract ด้วย `pypdf`) ระบุ Business AI App ID `622851382610562`, `ai_generated:true`, standby, `HUMAN_AGENT`, และ reactivation ผ่าน `pass_thread_control`; ต้องแยก official expected behavior จาก observed Axon rollout

Failures and how to do differently:
- gcloud month-wide query hung; ใช้รายวัน/รายสัปดาห์ + `--limit` + shell alarm/timeout 90s เสมอ
- gcloud continuation ล้มก่อน query เพราะ sandbox ปฏิเสธเขียน `~/.config/gcloud/credentials.db`; รายงาน slice เหล่านั้นเป็น `Not run: gcloud credential refresh ถูก sandbox ปฏิเสธ` ไม่ใช่ “ไม่พบข้อมูล”
- direct public Meta docs fetch ล้ม (`Failed to fetch`/URL unsafe); cite local PDF และระบุ live comparison not verified
- adoption scan ที่ค้นเฉพาะ `ai_generated:true` ไม่สามารถพิสูจน์ coverage 100% ได้เพราะไม่มี independent denominator; Instagram “ไม่เคยเก็บ payload” ไม่เท่ากับ “ไม่มี payload”

References:
- `docs/meta-business-ai/meta-biz-ai-poc-6-answers.md:7–121`
- `docs/meta-business-ai/meta-biz-ai-poc-result.md:93–105, 163–177, 187–229, 235–254, 308–331`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:53–93`
- `docs/meta-business-ai/meta-biz-ai-queue-routing-design.md:48–85`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/handler.ts:857–875,945–992,1242–1274,1612–1632,1940–1960`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/helper.ts:1294–1304,1317–1343,1465–1541`
- `oho-webhook/.claude-worktrees/meta-business-ai/src/controllers/facebook/facebook.controller.ts:124–168`
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:7–25`
- Direct completed query: `resource.type="cloud_run_revision" AND resource.labels.service_name="webhook--production" AND jsonPayload.message:"pass_thread_control" --freshness=24h --limit=100` -> empty output/no data found for available 24h window

## Thread `019fc64c-3291-73a0-9abc-8400c6838b3d`
updated_at: 2026-08-03T06:38:46+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-03/r
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T13-25-10-019fc64c-3291-73a0-9abc-8400c6838b3d.jsonl
rollout_summary_file: 2026-08-03T06-25-10-otHf-audit_and_fix_cursor_ai_main_rules_symlinks.md

description: Verified Cursor still loads ai-main-managed skills, commands, and workspace rules; removed a conflicting stale home-level AGENTS.md while preserving a backup.
task: audit_and_fix_cursor_ai_main_rules
task_group: ai-main-cursor-integration
task_outcome: success
cwd: /Users/tualek/Documents/Codex/2026-08-03/r
keywords: Cursor, ai-main, symlink, AGENTS.md, CLAUDE.md, skills, commands, aimain, workspace rules

### Task 1: Audit Cursor integration

task: verify_cursor_rules_and_symlinks
task_group: ai-main-cursor-integration
task_outcome: success

Preference signals:
- The user asked whether Cursor still used the rules and symlinks configured in ai-main -> similar audits should verify actual runtime loading, not only filesystem presence.

Reusable knowledge:
- `~/.cursor/skills/` contained 22 valid symlinks to `/Users/tualek/ai-main`, with no broken links.
- `~/.cursor/commands/worklog.md` points to `/Users/tualek/ai-main/commands/worklog.md`.
- Cursor 3.14.7 loaded workspace `AGENTS.md`/`CLAUDE.md` as `always_applied_workspace_rule`; absence of `~/.cursor/rules/` did not prevent ai-main workspace rules from loading.
- `/Users/tualek/ai-main/bin/aimain list` showed all 11 registered workspaces as `ok`.

Failures and how to do differently:
- Use native `find` rather than `rtk find` for compound predicates/actions.
- `cursor-agent` was unavailable and network installation failed; use Cursor runtime state/logs when CLI testing is impossible.

References:
- `/Users/tualek/ai-main/install.sh`
- `/Users/tualek/ai-main/bin/aimain list`
- Cursor version: `3.14.7`

### Task 2: Remove stale conflicting rule

task: remove_conflicting_home_agents_rule
task_group: ai-main-cursor-integration
task_outcome: success

Preference signals:
- The user said “จัดการให้หน่อย” -> make the corrective change, preserve a recoverable backup, and avoid touching unrelated dirty work in `ai-main`.

Reusable knowledge:
- `/Users/tualek/AGENTS.md` was an old generic rule source loaded in addition to ai-main workspace rules and could conflict with repo-specific conventions.
- It was moved, not deleted, to `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`.
- After removal, workspace files remained intact and `aimain list` still reported every workspace `ok`.
- Existing Cursor sessions may cache rules; reload the window or start a new chat after changing rule files.

Failures and how to do differently:
- Do not edit or clean unrelated changes in `/Users/tualek/ai-main`; preserve the user’s dirty worktree.

References:
- Removed: `/Users/tualek/AGENTS.md`
- Backup: `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`
- Verification: `ls -la /Users/tualek/AGENTS.md` returned no such file; `aimain list` returned all workspaces `ok`.

## Thread `019fc66d-6db1-7253-a396-dfde3105523c`
updated_at: 2026-08-05T03:30:55+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T14-01-28-019fc66d-6db1-7253-a396-dfde3105523c.jsonl
rollout_summary_file: 2026-08-03T07-01-28-EQdm-meta_business_ai_facebook_page_onboarding_clickup_handoff.md

---
description: Created and externally verified a Meta Business AI Facebook Page onboarding runbook, added onboarding readiness gates/T0 to MVP docs, and synchronized the canonical artifacts to ClickUp OHO-1634.
task: onboard Facebook Page for Meta Business AI MVP and sync ClickUp documentation
task_group: /Users/tualek/ohochat / Meta Business AI onboarding and stakeholder handoff
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, Facebook Page onboarding, Conversation Routing, default app, messaging_handovers, standby, thread_owner, pass_thread_control, take_thread_control, HUMAN_AGENT, ClickUp, OHO-1634, fresh-message E2E
---

### Task 1: Facebook Page onboarding runbook

task: define prerequisites and verification gates for Meta Business AI Facebook Page onboarding
task_group: Meta Business AI onboarding

task_outcome: success

Preference signals:
- when asked what Facebook Page onboarding is necessary, the rollout separated Oho-controlled setup from Page-admin Meta setup -> future onboarding responses should cover both sides proactively.
- the rollout required fresh-message E2E evidence before calling a Page ready -> distinguish `configured` from `verified`; do not treat OAuth/API 200/banner as readiness.
- the user’s established evidence boundary was preserved: separate official Meta documentation, Oho-observed POC, and pending Meta confirmation.

Reusable knowledge:
- Runbook created at `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`.
- Required gates: identity mapping; Page access token and permissions; HTTPS webhook/signature verification; union-safe Page subscriptions; standby ingress and send-time bot guards; Page-admin Business AI activation; Conversation Routing/default app; takeover setting; fresh-message E2E for AI active, standby suppression, human takeover, and return-to-AI.
- Required webhook fields documented: `messages`, `message_echoes`, `message_deliveries`, `message_reads`, `messaging_postbacks`, `messaging_referrals`, `messaging_handovers`, `standby`.
- Subscription migration procedure is `GET → union required fields → POST → GET verify`; never replace existing Page fields.
- Onboarding states are `not_started | blocked | configured | verified | rolled_back`; `configured` must not be presented as `verified`.
- Business AI eligibility/status API and complete Unified Onboarding contract were not available in the reviewed public/partner documentation; keep these as manual/interim steps and pending Meta confirmation.
- Silent `take_thread_control` requires Conversation Routing/default-app readiness in the tested setup; retain a `send_first` + `HUMAN_AGENT` fallback for human takeover.
- Return-to-AI requires a positive fresh runtime signal after `pass_thread_control`; HTTP 200, banner, `standby`, or one owner snapshot alone is insufficient.
- Rollback: stop Oho outbound but retain webhook ingestion, stop automated take/pass/release calls, restore routing/default-app baseline, and unsubscribe only as an approved final step.

Failures and how to do differently:
- Meta documentation conflicts on `messaging_handovers` vs singular naming, generic vs Business AI-specific take control, `ai_generated` guarantees, App IDs, and endpoint forms. Preserve these as explicit clarification questions rather than assuming a universal contract.
- Research agent timeouts occurred, but the completed runbook contains the verified source boundary; do not claim broader verification than the document supports.

References:
- `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `docs/meta-business-ai/04-mvp-implementation-solutions-2026-08-04.md:407`
- `docs/meta-business-ai/05-mvp-implementation-task-plan-2026-08-04.md:43` (`T0 — Onboard Facebook Page and establish readiness baseline`)

### Task 2: ClickUp documentation synchronization

task: upload canonical onboarding/MVP documents and update ClickUp OHO-1634
 task_group: ClickUp external handoff
 task_outcome: success

Preference signals:
- when updating a card, the rollout verified the persisted card after reload -> future external handoffs should treat reload verification as part of completion, not optional.

Reusable knowledge:
- Successful ClickUp task lookup used `task_id: "OHO-1634"`; an incorrect workspace/task combination returned `{"error":"Team not authorized"}`.
- Uploaded canonical artifacts: `04-mvp-implementation-solutions-2026-08-04.md`, `05-mvp-implementation-task-plan-2026-08-04.md`, `06-facebook-page-onboarding-2026-08-05.md`.
- Card description now includes Canonical 6 files, the Facebook Page onboarding gate, the onboarding runbook link, and T0-T10 planning.
- Old duplicate attachment IDs were removed; reload verification showed old `04` and `05` links absent and canonical files present.
- Local and downloaded ClickUp attachment SHA-256 values matched for all three files.

Failures and how to do differently:
- Long ClickUp descriptions can be truncated by connector reads. Restore from the full local source and verify key tail sections (MVP plan, Definition of Done, Related documents) after reload.

References:
- ClickUp: `https://app.clickup.com/t/86eyce35p`
- Verification signals: `canonical6=true`, `onboardingGate=true`, `mvpPlan=true`, `taskT0=true`, `definitionDone=true`, `relatedDocuments=true`, `old04=false`, `old05=false`.

## Thread `019fc8d3-33e3-7132-b93a-a21e3685223b`
updated_at: 2026-08-03T18:11:52+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T01-11-52-019fc8d3-33e3-7132-b93a-a21e3685223b.jsonl
rollout_summary_file: 2026-08-03T18-11-52-TXSz-meta_business_ai_doc_split_clickup_update_blocked.md

description: แยก Meta Business AI official/current, coming soon/planned, observed POC และ communication pack สำเร็จ; เตรียม ClickUp OHO-1634 description แต่บันทึกการ์ดจริงไม่ได้เพราะไม่มี ClickUp connector และ browser ยังไม่ล็อกอิน
task: meta-business-ai-doc-split-and-clickup-card-update
task_group: /Users/tualek/ohochat
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, OHO-1634, OHO-1215, ClickUp, Conversation Routing, standby, ai_generated, thread_owner, pass_thread_control, HUMAN_AGENT, source-matrix

### Task 1: แยกเอกสาร Meta และผล POC

task: split Meta documented capabilities from coming soon/planned items and Oho observed behavior
task_group: Meta Business AI documentation
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ขอ “แยก document ที่เกี่ยวกับ docs จาก meta” และ “แยก docs ที่เป็น coming soon” พร้อมเอกสารที่ส่งคุย Meta ได้ -> ควรสร้าง source-separated documents และ communication pack โดยไม่ปน official contract กับ local observation
- ผู้ใช้ต้องการหลักฐานตรงและไม่ fabricate logs -> ระบุ observed, not verified และขอบเขตของ POC อย่างชัดเจน

Reusable knowledge:
- สร้าง source matrix จาก official partner PDF 15 หน้าและ public Meta docs พร้อมข้อขัดแย้ง 10 จุด; ใช้เป็นจุดเริ่มต้นก่อน implementation
- เอกสารใหม่อยู่ใน `docs/meta-business-ai/`: `meta-official-source-matrix-2026-08-04.md`, `meta-official-available-2026-08-04.md`, `meta-official-coming-soon-2026-08-04.md`, `oho-poc-observed-behavior-2026-08-04.md`, `meta-partner-communication-pack-2026-08-04.md`, `meta-business-ai-dev-questions-2026-08-04.md`
- POC evidence: test page `104613548045675`, 13 subscribed fields, live self-handoff 4/4 รอบไม่พบ `pass_thread_control`, `thread_owner` 8 threads บน v20/v25 ไม่คืน `app_id`, `pass_thread_control` ไป `622851382610562` ทำงาน, control event เคย duplicate 4 ครั้ง
- Implementation ต้องแยก delivery authority, agent identity และ latest event; ใช้ send-time guard/cancel scheduled sends และ canonicalize/dedupe events

Failures and how to do differently:
- อย่าใช้ `standby`, `messaging`, `app_id` หรือ `ai_generated` เพียงค่าเดียวเป็น universal owner contract; current evidence จำกัดตาม Page/rollout

References:
- `docs/meta-business-ai/meta-official-source-matrix-2026-08-04.md`
- `docs/meta-business-ai/meta-official-coming-soon-2026-08-04.md`
- `docs/meta-business-ai/oho-poc-observed-behavior-2026-08-04.md`

### Task 2: เตรียม ClickUp description และ cross-reference

task: update ClickUp OHO-1634 description and related documentation
task_group: ClickUp card update
 task_outcome: partial

Preference signals:
- ผู้ใช้ขอ “update description ในการ์ด” และรวมไฟล์ที่เกี่ยวข้อง -> ต้องทำ external update จริงและตรวจผลหลัง save ไม่ควรนับ draft เป็น completion

Reusable knowledge:
- Draft พร้อมวางอยู่ที่ `docs/meta-business-ai/clickup-OHO-1634-description-2026-08-04.md`
- Related files ถูกอัปเดตให้ชี้ไปยัง draft/source split: `clickup-OHO-1634-poc-results.md`, `meta-biz-ai-card-review-2026-08-03.md`, `meta-biz-ai-summary-solutions-2026-08-03.md`, `HANDOFF.md`
- ClickUp browser เปิดได้แต่ redirect ไป `https://app.clickup.com/login`; active tool search ไม่พบ ClickUp connector/plugin

Failures and how to do differently:
- Card ยังไม่ได้แก้จริง; รอ authenticated ClickUp browser session แล้ววาง draft ลง OHO-1634 และ verify saved description/toast

References:
- `https://app.clickup.com/t/90182460598/OHO-1634`
- `docs/meta-business-ai/clickup-OHO-1634-description-2026-08-04.md`
- Exact blocker: browser resolved to `https://app.clickup.com/login`; no ClickUp tool available

## Thread `019fca5a-c19e-7761-966a-95f4e7276aae`
updated_at: 2026-08-04T01:21:08+00:00
cwd: /Users/tualek/retourapac
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T08-19-33-019fca5a-c19e-7761-966a-95f4e7276aae.jsonl
rollout_summary_file: 2026-08-04T01-19-33-sccm-find_retour_form_dashboard_slides.md

description: Search for ReTour APAC slides explaining form access and dashboard usage; no matching deck was found, but authoritative replacement documentation and the prior Claude session were identified
 task: locate existing ReTour form-opening and dashboard-usage slides
 task_group: retourapac-documentation
 task_outcome: partial
 cwd: /Users/tualek/retourapac
 keywords: ReTour, slides, dashboard, submission-form, Claude-session, Google-Drive, apps-script

### Task 1: Locate existing form/dashboard slides

task: locate previously created slides for opening the submission form and using the dashboard
task_group: retourapac-documentation
task_outcome: partial

Preference signals:
- The user asked: “ฉันน่าจะเคยมีทำ slide ของ step การเปิดปุ่ม form และการใช้ dashboard ช่วยหา slide ให่หน่อยเคยทำไว้ใน claude” -> when asked to find a prior artifact, search both Claude history and the workspace/Drive before proposing to recreate it.

Reusable knowledge:
- No ReTour-specific `.pptx`, `.ppt`, or Google Slides deck was found in the repository or the searched Google Drive presentation results.
- The practical substitute is `/Users/tualek/retourapac/apps-script/README.md`, covering setup, form webhook flow, dashboard roles, and daily use.
- `/Users/tualek/retourapac/dashboard-plan.md` contains the form test-access and dashboard implementation details.
- The prior Claude session is `/Users/tualek/.claude/projects/-Users-tualek-retourapac/f39934f0-c004-4206-853a-18ffda63f30b.jsonl`, titled “สร้าง dashboard สำหรับ review และ approve forms”.
- Master dashboard sheet: `https://docs.google.com/spreadsheets/d/1ktQ8F00uR4rLJiawR964bSYcNILl7pb0O8NhMwCA4u4/edit`.

Failures and how to do differently:
- Broad `rg` searches across Claude JSONL files generated massive truncated output. Narrow searches to the relevant Claude project directory, metadata fields such as `ai-title`/`last-prompt`, and exact artifact extensions.
- The search ended without direct user confirmation or a recovered deck; treat the result as partial and offer to create a new slide deck from the identified documentation.

References:
- `/Users/tualek/retourapac/apps-script/README.md`
- `/Users/tualek/retourapac/dashboard-plan.md`
- `/Users/tualek/.claude/projects/-Users-tualek-retourapac/f39934f0-c004-4206-853a-18ffda63f30b.jsonl`
- `https://docs.google.com/spreadsheets/d/1ktQ8F00uR4rLJiawR964bSYcNILl7pb0O8NhMwCA4u4/edit`

## Thread `019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd`
updated_at: 2026-08-04T05:01:22+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T11-50-48-019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd.jsonl
rollout_summary_file: 2026-08-04T04-50-48-0WTj-backoffice_v2_ui_design_dark_mode_plan.md

description: สร้างแผน audit UI และ dark mode สำหรับ backoffice-v2 สำเร็จ โดยตรวจ source + rendered UI และยืนยัน Markdown formatting
 task: backoffice-v2 UI/UX audit and detailed dark-mode implementation plan
 task_group: /Users/tualek/ohochat/backoffice-v2 UI design workflow
 task_outcome: success
 cwd: /Users/tualek/ohochat/backoffice-v2
 keywords: backoffice-v2, ui-audit, dark-mode, responsive-layout, spacing, padding, margin, Playwright, jwt-malformed, prettier

### Task 1: UI audit and dark-mode plan

task: inspect backoffice-v2 UI and create a detailed Markdown implementation plan
task_group: UI design and frontend planning
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ขอ “ทำเป็น plan อย่างละเอียด” และ “สร้าง md plan มาเลย” พร้อม “รวมถึงทำโหมด dark” -> ควรสร้างเอกสาร implementation-ready ที่มี design specs, file references, rollout phases, tests และ acceptance criteria ไม่ใช่แค่สรุปปัญหา
- ผู้ใช้ขอวิเคราะห์ padding/margin/ความสวยงามจาก UI จริง -> ควรตรวจ source ควบคู่กับ rendered screenshots/viewport checks
- งานรอบนี้เป็น plan-only -> ต้องไม่แก้ implementation หรือ commit โดยไม่ได้รับคำสั่งเพิ่ม

Reusable knowledge:
- แผนที่สร้างแล้วอยู่ที่ `ui-design-dark-mode-plan.md` และครอบคลุม spacing scale 4px, typography roles, responsive shell, shared page patterns, semantic dark tokens, page-by-page work, implementation phases, visual matrix, accessibility และ acceptance criteria
- Source baseline ที่สำคัญ: `src/styles/globals.css` มี light tokens แต่ไม่มี `.dark`, `color-scheme`, `theme-color` หรือ pre-paint bootstrap; มี global heading sizes และ `div:focus { outline: none }`
- `src/shared/components/layout/AppLayout.tsx` ใช้ `p-10`; `SubMenu.tsx` ใช้ `w-60`; ที่ 1024px โครงสร้าง rail 64px + submenu 240px + main padding ทำให้ content/table ถูกบีบ
- พบ light-only coupling จำนวนมาก เช่น `bg-white`, `text-black-*`, `border-black-*`, hardcoded hex/rgba และ `transition-all` ใน business, payment, external-message, JERA และ dashboard; dark-mode migration ควรเริ่มจาก theme foundation และ shared primitives ก่อน feature pages
- Visual smoke check ใช้ Playwright ผ่าน `bash /Users/tualek/.codex/skills/playwright/scripts/playwright_cli.sh`; เรียก script ตรง ๆ ทำให้ `Permission denied`

Failures and how to do differently:
- Authenticated visual review ใช้ dummy cookies และ API ตอบ `jwt malformed`; ให้รายงานเป็นข้อจำกัดและอย่าอ้างว่าหน้า data จริงหรือ feature behavior ผ่าน
- ระหว่าง dev server มี process/session อื่นแก้ source หลายไฟล์; ก่อนสรุปควรตรวจ timestamps และ re-check line references เสมอ
- Full validation ยังไม่ได้รันใน rollout นี้; ห้ามอ้าง lint/typecheck/test/build ผ่านจากงานนี้

References:
- `ui-design-dark-mode-plan.md`
- `output/playwright/login-desktop.png`
- `output/playwright/login-mobile.png`
- `output/playwright/business-desktop.png`
- `output/playwright/business-1024.png`
- `pnpm exec prettier --check ui-design-dark-mode-plan.md` -> `All matched files use Prettier code style!`
- Local API limitation: `jwt malformed`

## Thread `019fcc18-966f-75c1-8bb6-3c8b98c927f4`
updated_at: 2026-08-05T03:16:07+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T16-26-31-019fcc18-966f-75c1-8bb6-3c8b98c927f4.jsonl
rollout_summary_file: 2026-08-04T09-26-31-tqzG-smartchat_four_qa_badge_fix_scoped_validation.md

---
description: Implemented a narrowly scoped Smartchat unread/unresponded badge fix for four QA cases, preserving group behavior and validating API/Mongo/frontend contracts.
task: smartchat-realtime-badge-fix-four-qa-cases
task_group: /Users/tualek/ohochat/oho-api
 task_outcome: success
cwd: /Users/tualek/ohochat/oho-api
keywords: smartchat, unread_by, is_unresponded, is_read_by_me, feature-flags, group-chat, contact, emit-chat-session-event, TDD, QA-case-1, QA-case-2, QA-case-3, QA-case-4
---

### Task 1: Scope and implement four-case Smartchat badge fix

task: constrain realtime badge behavior to the four reported QA cases
 task_group: cross-repo Smartchat badge workflow
 task_outcome: success

Preference signals:
- when the user said “ตอนนี้อยากให้ครอบคลุมแค่เคสที่ QA ตีแก้มา 4 case” -> keep the patch focused on those QA cases and defer broad refactor/optimization.
- when the user said “ได้ทำ plan แล้วแก้ไขได้เลย” -> edits were authorized after the scope discussion.

Reusable knowledge:
- `oho-api/src/services/chat-session/hooks/emit-chat-session-event.js` preserves group-chat’s existing unresponded-only contract. Contact/Smartchat alone opts into unread state via `includeUnreadState: true`.
- `buildAttentionEventUnreadPayload` independently gates `unread_by` and `is_unresponded`; both flags off returns `{}` and does not call `getEligibleMemberIds`.
- Contact socket recipients are partitioned into unread/read groups, producing at most two `emitMessages` calls; group emits remain one shared payload.
- Focused verification passed: API `46/46`, Mongo-backed integration `28/28`, web focused tests `135/135`; Prettier and `git diff --check` passed.

Failures and how to do differently:
- Initial TDD run correctly exposed group scope expansion and an over-broad Jest mock that loaded `models/index.js`; restore group expectations and mock only boundary exports.
- Flag-off user-visible behavior is disabled, but the request after-hook still performs one contact `findOne()` and flag lookup before returning. Treat this as deferred optimization, not as proof that the feature is entirely absent at runtime.
- No browser E2E was run; distinguish focused/unit/Mongo contract proof from real UI proof.

References:
- `/Users/tualek/ohochat/oho-api/src/services/chat-session/hooks/emit-chat-session-event.js:220-400`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.ts:7-45`
- `/Users/tualek/ohochat/oho-api/src/utils/build-customer-message-unread-payload.spec.ts`
- `/Users/tualek/ohochat/oho-api/src/services/contact/bot-assign/request/request-attention-badge.spec.ts:83-128`
- Key test command: `node ./node_modules/jest/bin/jest.js --runTestsByPath src/services/chat-session/hooks/emit-chat-session-event.spec.ts src/services/contact/bot-assign/request/request-attention-badge.spec.ts src/utils/build-customer-message-unread-payload.spec.ts src/utils/channel-eligible-members.spec.ts --runInBand --forceExit --detectOpenHandles`
- Final status: changes remained uncommitted/unpushed; browser E2E was not run.

## Thread `019fcc78-6964-7c40-b51c-34e9b65b8d10`
updated_at: 2026-08-04T11:26:49+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-11-11-019fcc78-6964-7c40-b51c-34e9b65b8d10.jsonl
rollout_summary_file: 2026-08-04T11-11-11-39xm-uat_facebook_login_consent_meta_app_change_history.md

description: Diagnosed UAT Facebook consent discrepancy and dated the UAT App ID change; source code is shared, but UAT uses a different Meta app and Meta app-type history remains unverified.
task: diagnose-uat-facebook-login-consent-and-app-id-history
task_group: oho-web-app/deployment-debugging
task_outcome: partial
cwd: /Users/tualek/ohochat
authentication: Facebook OAuth, Meta Login for Business, Cloud Run, Nuxt build-time config
keywords: facebook-login, consent, login-for-business, FACEBOOK_APP_ID, Cloud-Run, UAT, staging-4, production, gcloud-logging, meta-dashboard

### Task 1: Diagnose UAT Facebook consent difference

task: compare Facebook login and consent behavior across UAT, staging-4, and production
task_group: oho-web-app/deployment-debugging
task_outcome: partial

Preference signals:
- The user asked to compare `prod`, `staging-4`, and `uat` and explain why only UAT differs -> future debugging should compare deployed environment configuration and browser requests before editing code.
- The user requested read-only history checking when asking when the change occurred -> preserve the distinction between verified deployment facts and unverified Meta-side history.

Reusable knowledge:
- `components/LoginCard.vue` calls `this.$auth.loginWith("facebook")`; `plugins/fb-auth.js` configures the strategy with `clientId: process.env.FACEBOOK_APP_ID` and `scope: ["public_profile", "email"]`.
- The frontend source path is shared across environments; no consent-specific endpoint or divergent Facebook code path was found in the searched web/API repositories.
- UAT bundle used App ID `1092549003000749`; production used `388207815496149`; staging-4 OAuth used `1121209881887696`. UAT OAuth was observed as standard flow without `config_id` / `is_business_login=1`.
- Facebook App ID is baked into the Nuxt client at build time. Updating only Cloud Run runtime env vars is insufficient; update GitLab `DOTENV`, rebuild, deploy, and route traffic to the new revision.
- UAT traffic was 100% on `web-app--uat--26a0dd06--v1-115-0`; revision `web-app--uat--9d797cbb--v1-115-1` was ready but not routed.

Failures and how to do differently:
- Post-login consent could not be verified because the browser had no authenticated Facebook session. Do not claim the exact Meta consent request without an authenticated repro or captured request.
- Staging-4 had a configuration inconsistency: Cloud Run runtime metadata showed App ID `906298295642485`, while the served OAuth bundle used `1121209881887696`; always inspect both baked bundle config and runtime env.

References:
- `/Users/tualek/ohochat/oho-web-app/components/LoginCard.vue:259-264`
- `/Users/tualek/ohochat/oho-web-app/plugins/fb-auth.js:19-25`
- `/Users/tualek/ohochat/oho-web-app/nuxt.config.js:44-51`
- `web-app--uat--26a0dd06--v1-115-0`

### Task 2: Date UAT App ID change

task: identify when UAT changed from the previous Facebook App ID
task_group: Cloud-Run-audit-history
task_outcome: success

Preference signals:
- The user asked whether the change could be dated because the rollback button was unavailable -> future responses should provide exact timestamps and clearly state what the evidence does and does not prove.

Reusable knowledge:
- UAT revisions used App ID `265344702138419` through 2026-03-06.
- First revision using `1092549003000749` was `web-app--uat-00082-8tn`, created `2026-03-17T16:56:06.462906Z` (2026-03-17 23:56 Thailand time).
- Cloud Logging recorded `google.cloud.run.v1.Services.ReplaceService` at `2026-03-17T16:56:05.742293Z`, principal `rapee@oho.chat`, client `cloud-console`.
- This proves when UAT began using the new App ID, not when the Meta app was created or switched to Facebook Login for Business.
- Meta documentation says rollback is available only for an existing app within 30 days of switching; newly created Business Type apps cannot switch back.

Failures and how to do differently:
- Meta dashboard inspection was blocked by a login page. The Meta app type/switch date remains unverified; continue from the preserved Meta dashboard tab after the user signs in.
- GitLab audit API returned 404; Cloud Run audit logs and revision metadata were the reliable evidence.

References:
- Revision: `web-app--uat-00082-8tn`
- Timestamp: `2026-03-17T16:56:06.462906Z`
- Principal: `rapee@oho.chat`
- Audit method: `google.cloud.run.v1.Services.ReplaceService`
- Meta docs: `https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business`

## Thread `019fcc97-697a-70b0-a137-64ad27e07903`
updated_at: 2026-08-04T11:48:17+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-45-02-019fcc97-697a-70b0-a137-64ad27e07903.jsonl
rollout_summary_file: 2026-08-04T11-45-02-h9iX-clickup_latest_due_date_assigned_ticket.md

---
description: ตรวจสอบ ClickUp tickets ที่ assign ให้ผู้ใช้ปัจจุบันและหา ticket ที่มี due date ล่าสุด สำเร็จ โดยพบ OHO-1215 เป็นรายการล่าสุด
 task: find-latest-due-date-for-current-clickup-assignee
 task_group: clickup-task-search
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: ClickUp, clickup_search, clickup_get_task, clickup_resolve_assignees, due_date, assignee, OHO-1215
---

### Task 1: Find latest due date among assigned ClickUp tickets

task: find-latest-due-date-for-current-clickup-assignee
task_group: ClickUp task search
task_outcome: success

Preference signals:
- ผู้ใช้ถามภาษาไทยแบบสั้นว่า “ticket ไหนที่ มี duedate ล่าสุด ที่ assign ฉัน” -> งานลักษณะนี้ควรตอบเฉพาะรายการล่าสุดอย่างกระชับ พร้อม ticket ID, ชื่อ, due date, status และลิงก์

Reusable knowledge:
- Resolve current ClickUp user first with `clickup_resolve_assignees({assignees:["me"]})`; this returned user ID `113526352`.
- Search with `clickup_search({count:100, filters:{asset_types:["task"], assignees:["113526352"]}})` found 39 assigned tasks.
- Search results do not reliably include due dates; call `clickup_get_task` for each result, read `due_date`, sort numerically descending, and format timestamps in `Asia/Bangkok`.
- 24 of the 39 assigned tasks had due dates. The latest was `OHO-1215`, `[MS-PD-0170] นำ Meta Business AI (BizAI) มาใช้กับ OHO Chat ผ่าน Messenger (PAF Pilot)`, due 31 October 2026, status `to do`, URL `https://app.clickup.com/t/86ey96htu`.

Failures and how to do differently:
- Initial broad tool-description/search output was truncated, so inspect structured tool results rather than copying rendered text.
- Do not sort by `dateUpdated`; it is different from `due_date`. Fetch task details before ranking.

References:
- `clickup_resolve_assignees({assignees:["me"]})` -> `{"userIds":["113526352"]}`
- `clickup_search` filter: `asset_types:["task"]`, `assignees:["113526352"]`
- Latest task URL: `https://app.clickup.com/t/86ey96htu`
- Latest due date raw timestamp: `1793394000000`

## Thread `019fcca5-2c2f-7bb1-ad67-039a286e19da`
updated_at: 2026-08-05T04:00:09+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-00-04-019fcca5-2c2f-7bb1-ad67-039a286e19da.jsonl
rollout_summary_file: 2026-08-04T12-00-04-U5UC-clickup_assignee_filter_and_meta_business_ai_estimate.md

description: ClickUp ticket filtering was corrected to use the user's assignee; OHO-1634 Meta Business AI MVP was estimated at 15–20 working days, with important verification limits.
task: ClickUp ticket lookup and OHO-1634 implementation estimation
task_group: /Users/tualek/ohochat
 task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: ClickUp, assignee, OHO-1634, Meta Business AI, BizAI, standby, messaging, Cloud Tasks, HUMAN_AGENT, messaging_handovers

### Task 1: Filter tickets by current assignee

task: Find ClickUp tickets due 14 Aug 2026 and assigned to the user
task_group: ClickUp ticket lookup
task_outcome: success

Preference signals:
- When the user said “เอาแค่ assign ของฉันสิ” after a broad result -> future date-based ticket lists should default to the current user's assigned tickets, not all tickets.

Reusable knowledge:
- User identity verified in ClickUp: `Tualek[Full Stack]`, `sitthiporn@oho.chat`, user ID `113526352`.
- Five verified tickets due 14 Aug 2026: OHO-1811, OHO-1824, OHO-1820, OHO-1828, OHO-1804.

Failures and how to do differently:
- Numeric `assignees: [113526352]` failed validation (`expected string, received number`); retrying with a string caused a ClickUp server error. If search filtering fails, inspect candidate tasks individually with `clickup_get_task`.

References:
- ClickUp search date filter: `due_date_from: "2026-08-14", due_date_to: "2026-08-15"`.
- Candidate verification used `clickup_get_task({task_id, detail_level:"summary"})`.

### Task 2: Estimate OHO-1634 MVP

task: Estimate implementation effort for ClickUp ticket OHO-1634
 task_group: Meta Business AI Messenger integration
 task_outcome: partial

Preference signals:
- The assistant interpreted “MCP” as likely “MVP” because the ticket had no MCP requirement; preserve this ambiguity warning and ask for clarification when needed.

Reusable knowledge:
- Planning estimate: 15–20 working days for one developer; 20 days recommended for ticket planning. Limited POC demo: 5–7 days.
- Scope includes webhook/event canonicalization, dedicated AI queue, ownership state, dedupe, subscription changes, bot/scheduled-send guards, Smartchat UI, takeover/return-to-AI, QA, observability, and canary rollout.
- Current inspected code routes `messaging`/`standby` together in `oho-webhook/src/controllers/facebook/helper.ts`; `oho-webhook/src/helpers/cloud_tasks.api.ts` has no `meta-ai` queue; `oho-api/src/utils/facebook/request-page-subscribed-app.js` lacks `messaging_handovers`; `HUMAN_AGENT` already exists in member send hooks.

Failures and how to do differently:
- Numeric ClickUp task ID `90182460598` returned `Team not authorized`; custom ID `OHO-1634` succeeded.
- No Meta runtime/integration test or Cloud Tasks canary was run, so do not state the estimate as verified delivery capacity.

References:
- Ticket: `OHO-1634`, `[DEV] POC BizAI take control`.
- Relevant paths: `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/helper.ts`, `/Users/tualek/ohochat/oho-webhook/src/helpers/cloud_tasks.api.ts`, `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js`, `/Users/tualek/ohochat/oho-api/src/services/member-send-message/member-send-message.hooks.js`.
- Verification rule: HTTP/API success is insufficient for return-to-AI; require fresh runtime evidence such as `ai_generated`, `hop_context`, control/ownership events, and an actual post-action AI response.

## Thread `019fcca9-5c19-7c82-9846-631245488d38`
updated_at: 2026-08-04T12:07:11+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-04-39-019fcca9-5c19-7c82-9846-631245488d38.jsonl
rollout_summary_file: 2026-08-04T12-04-39-FePe-dynamic_stream_credentials_cloud_run_multitenancy.md

---
description: Secure multi-business Stream Chat credential architecture without duplicating Cloud Run
 task: design dynamic secret-backed Stream Chat configuration per business
 task_group: /Users/tualek/ohochat backend architecture
 task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Stream Chat, business_id, Secret Manager, Cloud Run, multi-account, credential mapping, user token, secret rotation
---

### Task 1: Per-business Stream Chat secrets

task: Store and resolve separate Stream Chat credentials for each business.
task_group: backend secret management and multi-tenancy
task_outcome: success

Preference signals:
- The user clarified: “มันเป็น secreat เลยเพราะต้องทำ multi account streamchat แยกตาม business” -> similar designs should keep Stream `api_secret` server-only and avoid frontend or Remote Config delivery.

Reusable knowledge:
- Store a mapping in MongoDB containing `business_id`, Stream API key, Secret Manager resource, pinned secret version, and enabled state; store the actual `api_secret` only in Secret Manager.
- Resolve `business_id` from the authenticated session and authorize it; never trust an unvalidated request-body business identifier.
- Backend flow: resolve business → load mapping → access the pinned secret version → create/select the Stream server client → generate an expiring user token → return only API key and user token to frontend.
- Cache clients per `connectionId:secretVersion` (with TTL/LRU and invalidation on version change); do not use one global Stream singleton across businesses.
- Rotate by adding a new Secret Manager version and updating the mapping. Pinning a numeric version makes rollback explicit.

Failures and how to do differently:
- Do not put Stream secrets in Firebase Remote Config, frontend runtime config, or one global Cloud Run env var.
- Do not expose the Stream API secret to the browser.

References:
- `/Users/tualek/ohochat`
- `business_id → MongoDB mapping → Secret Manager → backend Stream client → frontend apiKey + userToken`

### Task 2: Cloud Run deployment topology

task: Determine whether each Stream account requires a separate Cloud Run service.
task_group: Cloud Run deployment architecture
task_outcome: success

Reusable knowledge:
- A single Cloud Run service can support multiple Stream accounts by selecting the correct per-business client at request time.
- Duplicate Cloud Run only when infrastructure-level isolation is required, such as separate service accounts, networks, scaling, deployments, or compliance boundaries.
- Cloud Run environment variables are revision-bound; changing them creates a new revision, so they are unsuitable for per-request dynamic secrets.

Failures and how to do differently:
- Do not model each business as a separate Cloud Run service merely because Stream credentials differ.

References:
- Cloud Run environment-variable behavior: configuration changes create a new revision.
- Suggested cache key example: `${config.connectionId}:${config.secretVersion}`

## Thread `019fdb04-3fd5-7162-baaf-6899542d9a88`
updated_at: 2026-08-07T07:05:16+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-07/referenced-chatgpt-conversation-this-is-an
rollout_path: /Users/tualek/.codex/sessions/2026/08/07/rollout-2026-08-07T13-58-36-019fdb04-3fd5-7162-baaf-6899542d9a88.jsonl
rollout_summary_file: 2026-08-07T06-58-36-zLcc-meta_business_ai_3_boxes_documentation_review.md

---
description: Read-only review of Meta Business AI 3-box flow found P0 contract and safety gaps; keep diagrams conceptual until runtime state contract and reducer semantics are fixed
task: review-meta-business-ai-3-boxes-flow
task_group: /Users/tualek/ohochat Meta Business AI documentation and architecture review
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, 3-boxes, take_thread_control, pass_thread_control, return-to-AI, observed_authority, reducer, monotonic, bot guard, dedup, out-of-order, oho-webhook, oho-api
---

### Task 1: Review Meta Business AI 3-box flow documentation

task: assess completeness, inconsistencies, architectural gaps, unclear assumptions, and concrete improvements for `meta-biz-ai-flow-3-boxes-2026-08-07.md`
task_group: Meta Business AI documentation/source-contract review
task_outcome: success

Preference signals:
- when reviewing this work, the user asked for completeness, missing sections, inconsistencies, architectural gaps, and concrete recommendations -> provide severity-ranked findings with file/line evidence rather than a generic summary
- prior user constraints require read-only review and no fabricated logs -> distinguish verified source facts, observed POC, proposed behavior, and `Not verified`
- prior Meta reviews were requested entirely in Thai and detailed -> similar reviews should default to Thai with source-cited rationale

Reusable knowledge:
- The 3-boxes file is suitable as a conceptual communication diagram but must not be treated as the runtime implementation contract until it represents uncertainty and lifecycle states.
- Control direction is not preserved end-to-end: `oho-webhook/src/controllers/facebook/handler.ts:898-914` sends control type but not `previous_owner_app_id` or `new_owner_app_id`. The reducer at `oho-api/src/utils/meta-business-ai.js:250-265` treats every `take_thread_control` as human takeover, so an Axon take can be misclassified.
- Return-to-AI confirmation is too broad: `oho-api/src/utils/meta-business-ai.js:284-297` accepts `meta_human` and `external_app` as confirmation. Confirmation should require a fresh positive Business AI signal, not merely Meta-side authority.
- Bot safety has a pending-state gap. `shouldBlockFacebookBotSend` at `oho-api/src/utils/meta-business-ai.js:318-326` blocks `meta_or_other` and page kill switch, but `return-to-ai.class.js:48-69` can set `reactivation_state=requested` while authority remains `oho`; scheduled/direct bot sends may then pass. The canonical safety rule should block bot outbound during `requested`, `confirmed`, and `unconfirmed` reactivation, plus known Meta authority and page kill switch.
- The task plan requires monotonic state, but `runtime-event.class.js:17-46` performs load/reduce/full-object write and `reduceMetaRuntimeEvent` at `meta-business-ai.js:191-205` does not reject stale events. Cross-queue reordering and concurrent read-modify-write can regress state or lose updates. Define normalized event time, tie-breaker, stable event ID, stale-event rejection, and conditional atomic update.
- The 3-boxes diagram overstates deterministic behavior: `meta-biz-ai-flow-3-boxes-2026-08-07.md:51-59,71-73` skips requested/confirmed/unconfirmed/failed states; `:110` says `ai_generated:true` is always present although POC only verifies captured samples; `:98` presents idle-to-AI takeover as a contract although TTL remains open.
- POC evidence shows self-handoff is not deterministic, `standby` versus `messaging` is not a binary owner test, `thread_owner` is not a universal passive owner oracle, and control events can be duplicated/out-of-order. Preserve these limitations in all diagrams and docs.
- Documentation navigation is stale: `HANDOFF.md` still frames MVP as future work and omits the 7 Aug flow docs, while source repos contain Meta Business AI commits from 6 Aug. Add a single index/status matrix separating official contract, observed POC, proposed design, implemented, verified E2E, and stale archive.
- Data handling and operations need explicit sections for preview retention, redaction/access/deletion, metric thresholds, dashboard/alert owners, kill-switch authority, and canary evidence.

Failures and how to do differently:
- Do not use a diagram arrow as proof of runtime success. Mark edges as verified contract, observed/best-effort, or requested/pending confirmation, and show `unknown`, `requested`, `unconfirmed`, and `failed`.
- Do not equate `take_thread_control` with OHO ownership without inspecting owner direction and target app IDs.
- Do not treat HTTP success, a banner, farewell text, or a generic Meta human/external signal as Return-to-AI confirmation.
- Do not claim monotonic behavior from a reducer design unless stale-event rejection and atomic persistence are verified in source/tests.
- Live official Meta comparison was not verified because URLs returned `429 Too Many Requests` or `Cache miss`; use local official PDF and stored POC evidence while labeling live comparison unavailable.

References:
- `docs/meta-business-ai/meta-biz-ai-flow-3-boxes-2026-08-07.md:51-59,71-73,98,110,117,158-160`
- `docs/meta-business-ai/oho-poc-observed-behavior-2026-08-04.md:35-46,86-142`
- `docs/meta-business-ai/01-meta-docs-vs-oho-poc-2026-08-04.md:20-35,108-120`
- `oho-webhook/src/controllers/facebook/handler.ts:898-914,939-962`
- `oho-api/src/utils/meta-business-ai.js:191-205,250-326`
- `oho-api/src/services/contact/meta-business-ai/runtime-event/runtime-event.class.js:17-46`
- `oho-api/src/services/contact/meta-business-ai/return-to-ai/return-to-ai.class.js:48-69`
- `docs/meta-business-ai/05-mvp-implementation-task-plan-2026-08-04.md:95-113,143-162,273-317`

## Thread `019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc`
updated_at: 2026-08-09T07:19:28+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www
rollout_path: /Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T11-06-11-019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc.jsonl
rollout_summary_file: 2026-08-09T04-06-11-vKu8-canva_section_addition_and_pdf_export.md

---
description: Canva section-addition attempt for foreign-worker presentation; direct page insertion was not completed, but a 13-page Thai PDF export succeeded. Key takeaway: use the logged-in Chrome extension/editor for page insertion or provide a separate importable section.
task: add foreign-worker information as a new section after an existing Canva presentation section and export deliverable
task_group: canva-presentation-editing
 task_outcome: partial
cwd: /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www
keywords: Canva, Chrome extension, Canva editing transaction, page insertion, blank login page, foreign workers, e-WorkPermit, PDF export
---

### Task 1: Add section to existing Canva design

task: append a new section after the existing Canva presentation content
task_group: Canva presentation editing
task_outcome: partial

Preference signals:
- The user asked to add it “ใน section ใหม่ต่อจากอันเดิม” -> append after existing pages and preserve prior content.
- The user accepted making a separate file and importing/copying it later -> offer a standalone importable section when direct insertion is blocked.
- The user wanted the original section/style inspected before editing -> inspect final pages and match the existing visual style.

Reusable knowledge:
- Canva design: `DAGsRNjn95Y`; URL: `https://www.canva.com/design/DAGsRNjn95Y/A0WvLzG-4q4jOq7e0rHRsw/edit`.
- Existing design has 60 editable 1920×1080 presentation pages.
- Canva API transaction `6728889961075207786` was opened for inspection but cancelled; it did not add pages.
- The Chrome extension later exposed the logged-in editor tab titled `สามัคคีทีม จำกัด - Presentation` with “All changes saved.”

Failures and how to do differently:
- The in-app browser reached Canva login but became a blank page after login; use Chrome extension instead when available.
- Do not report the Canva edit as saved or complete unless a page is visibly added and the editor confirms saving.
- The editing API path did not establish a working page-insertion operation; use native Canva Add page/copy-page UI or create a separate section file.

References:
- Source research partially succeeded: Passport article on Cabinet resolution 28 Sep 2021; DOE object 2444 on four-nationality electronic work permits; Chiang Mai DOE object 87182 on Cabinet resolution 24 Sep 2024.

### Task 2: Export section as PDF

task: export the prepared Thai section as a PDF
task_group: document export
 task_outcome: success

Reusable knowledge:
- PDF created with 13 pages, with Thai text and layout reported as matching the PowerPoint.

References:
- `/Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www/outputs/pdf/e-workpermit-detailed-workflow-section-v7-identity-visa.pdf`

## Thread `019fe533-6a13-7ce1-b33a-be843748c46b`
updated_at: 2026-08-09T06:58:19+00:00
cwd: /Users/tualek/Documents/migrant-labor-crm
rollout_path: /Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T13-26-19-019fe533-6a13-7ce1-b33a-be843748c46b.jsonl
rollout_summary_file: 2026-08-09T06-26-19-LLdx-migrant_labor_crm_new_machine_local_setup.md

description: Completed new-machine local setup for Migrant Labor CRM; Docker services, Prisma database, seed, and NestJS API were verified, with an optional sample PDF omitted.
task: setup migrant-labor-crm local environment on new Mac
task_group: local development setup
 task_outcome: success
cwd: /Users/tualek/Documents/migrant-labor-crm
keywords: pnpm, docker-compose, Docker Desktop, Prisma, PostgreSQL, Redis, MinIO, NestJS, CI=true, EPERM, ENOTFOUND, schema engine error

### Task 1: New-machine local stack setup

task: configure env, dependencies, Docker services, database, seed, and API for migrant-labor-crm
task_group: local development setup
task_outcome: success

Preference signals:
- The user asked “นาย run ทั้งหมดให้หน่อย” (“run everything for me”) -> for similar repo setup requests, inspect and execute the complete workflow instead of only providing instructions.
- The agent preserved existing worktree edits and avoided overwriting `.env` contents -> protect user changes during setup.

Reusable knowledge:
- Repo README setup sequence: `pnpm install`, `.env`, `docker compose up -d`, `pnpm db:generate`, `pnpm db:migrate`, `pnpm db:seed`, `pnpm dev`.
- If frontend is already running, start only the API with `pnpm --filter @mlcrm/api dev`.
- `.env` is ignored by Git. Frontend defaults to `http://localhost:3000`; `apps/web/.env.local` with `VITE_API_URL` is only needed for a non-default API URL.
- Docker services expose PostgreSQL `5432`, Redis `6379`, MinIO API `9000`, and MinIO console `9001`.
- Use `CI=true pnpm install` in non-TTY sessions; plain install failed with `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`.
- Prisma generate may require unsandboxed access to `~/.cache/prisma`; sandboxed run failed with `EPERM` on the Prisma query engine cache.
- Migration may require unsandboxed local Docker/network access; sandboxed run produced only `Schema engine error`.
- Docker Desktop installation was blocked by stale broken symlinks; `brew install --cask docker --no-binaries` successfully installed the app without trying to replace privileged helper binaries.
- Migration applied three existing migrations: `20260503135306_init_mvp`, `20260503141100_init_mvp`, and `20260504032732_init_mvp`.
- Seed completed but skipped `/Users/tualek/Downloads/power_of_attorney.pdf`; the PDF can be uploaded later through the UI.
- API verification succeeded: `GET http://localhost:3000/auth/me` returned `401`, and NestJS reported successful startup.

Failures and how to do differently:
- Before running Compose, verify Docker daemon readiness with `docker version`; a valid CLI alone is insufficient if the Docker socket is unavailable.
- If Docker Desktop needs privileged setup, the user must run `sudo /Applications/Docker.app/Contents/MacOS/install --user=tualek` and accept any macOS/Docker prompts themselves.
- Do not treat `pnpm db:migrate` success as sufficient; also verify container status, seed output, API logs, and an HTTP response.

References:
- `CI=true pnpm install`
- `docker compose up -d`
- `pnpm db:generate`
- `pnpm db:migrate`
- `pnpm db:seed`
- `pnpm --filter @mlcrm/api dev`
- `curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/auth/me` -> `401`
- `/Users/tualek/Documents/migrant-labor-crm/.env.example`
- `/Users/tualek/Documents/migrant-labor-crm/docker-compose.yml`

## Thread `019fe9f1-4dfe-7963-a2c9-f930bfbf93e7`
updated_at: 2026-08-10T06:55:37+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T11-32-13-019fe9f1-4dfe-7963-a2c9-f930bfbf93e7.jsonl
rollout_summary_file: 2026-08-10T04-32-13-Idz9-line_webhook_migration_hardening_scoped_dry_run.md

description: Hardened LINE webhook migration with manifest-first backup/rollback and validated a single production channel in read-only mode; production apply remains blocked by unresolved recovery/final-verification review findings.
task: line webhook migration safety review and implementation
task_group: /Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint
task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, whitelist, allowed-host, manifest, rollback, journal, register_webhook_at, dry-run, channel scope, MongoDB, compensation

### Task 1: Harden LINE webhook migration

task: implement safe manifest-first LINE webhook migration and rollback
 task_group: script-oho/migrate-line-webhook-endpoint
 task_outcome: partial

Preference signals:
- The user required explicit DB whitelist checking and full backup before mutation -> future implementations should use manifest-first, fail-closed workflows rather than old-host filtering or post-mutation backups.
- The user explicitly said `register_webhook_at` should not be updated -> never include `line.register_webhook_at` in migration or rollback payloads.
- The user later narrowed live testing to exactly channel `6a794f77fc9340171589accf` -> preserve exact scope and never broaden to `--all-channels` without approval.

Reusable knowledge:
- Implemented files: `migrate-line-webhook-endpoint/migrate-line-webhook.ts`, `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, `README.md`, `plan.md`.
- Flow is manifest-first: DB inventory → LINE inventory → immutable atomic manifest → drift revalidation → LINE test → PUT → poll GET → conditional Mongo update → final checks → journal/rollback.
- Manifest stores DB fields with presence markers, LINE endpoint/active state, candidate IDs/count, whitelist, environment/Mongo target, and digest; it excludes credentials and `register_webhook_at`.
- Production dry-run command used: `npm run migrate:line-webhook -- --env=prod --channel=6a794f77fc9340171589accf --allowed-host=api2.oho.chat --delay-ms=0 --concurrency=1`.
- Dry-run result: one channel, `testabc`; classification `line_db_match`; DB and LINE both pointed to `https://webhook.oho.chat/line/webhook/604ee3c35c2d9e573e8e9873`; target was `https://api2.oho.chat/webhook/line/webhook/604ee3c35c2d9e573e8e9873`.

Failures and how to do differently:
- Do not execute production yet. Review identified missing/unsafe final LINE verification after DB update, incomplete crash/recovery guarantees around `updated_at`, and insufficient explicit live `business_id` validation.
- Add orchestration tests for final LINE drift, crash after DB write before journal persistence, rollback conflict detection, and exact business ID checks before enabling `--execute`.
- Keep unrelated dirty repository changes separate from migration work.

References:
- Focused tests: `npm run test:line-webhook` → 9/9 passed.
- Full tests: `npm test` → 19/19 passed.
- Targeted TypeScript check passed with `npx tsc --noEmit --target ES2022 --module Node16 --moduleResolution Node16 --esModuleInterop --skipLibCheck --types node --ignoreDeprecations 6.0 ...`.
- Main live artifact: `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-20260810065326-230ce054.json`.
- No `--execute`, LINE PUT, or Mongo update was performed.

## Thread `019fea4f-0f09-7031-a11f-8b18c23fcf85`
updated_at: 2026-08-10T07:28:25+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T13-14-37-019fea4f-0f09-7031-a11f-8b18c23fcf85.jsonl
rollout_summary_file: 2026-08-10T06-14-37-ygPX-harden_line_webhook_migration_recovery.md

---
description: Hardened and reviewed a LINE webhook migration script with manifest-first safety, exact rollback, resumability, and explicit preservation of register_webhook_at; tests pass but real integrations remain unverified
task: line-webhook-migration-hardening-and-review
task_group: /Users/tualek/ohochat/script-oho/script-oho/migrate-line-webhook-endpoint
 task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, manifest, rollback, journal, db_update_requested, exclusive lock, register_webhook_at, MongoDB, LINE API
---

### Task 1: Harden LINE webhook migration

task: implement and review production-safety fixes for LINE webhook endpoint migration
task_group: script-oho/migrate-line-webhook-endpoint
task_outcome: partial

Preference signals:
- The user said “plan มาอย่างเดียวก่อน” after the requested sub-agent model was unavailable -> for complex migrations, produce and validate an implementation-ready plan before editing when the user requests it.
- The user said `register_webhook_at` may not need updating -> do not include `line.register_webhook_at` in migration or rollback payloads unless explicitly requested.
- The user asked to “แก้ตาม issue ที่เหลือเลย” after the audit -> use review findings as an explicit implementation checklist, then rerun focused and full verification.

Reusable knowledge:
- Migration now requires explicit `--allowed-host`; the old `--old-host` semantics were replaced to avoid reversing the whitelist requirement.
- Dry-run creates an immutable manifest before mutations, containing DB/LINE before-state, candidate IDs, environment/target metadata, and digest. Apply/rollback require the reviewed manifest and manifest-bound confirmation token.
- Manifest revalidation accepts DB before-state or target-state only when a durable journal marker proves a prior DB mutation; it no longer rebuilds candidates solely from current DB hostname classification.
- Apply/rollback acquire an exclusive `<manifest>.lock` using `open(..., "wx")`, preventing two processes from compensating LINE against each other.
- Journal phase `db_update_requested` is persisted with a planned `updated_at` before Mongo `updateOne()`. Ambiguous Mongo responses are reconciled against target DB state and the planned timestamp; if state cannot be proven, the run records `compensation_failed` and leaves LINE target state for manual recovery.
- Completed `migrated`/`db_synced` entries are re-read from both LINE and Mongo on rerun to detect external drift rather than blindly skipping them.
- `migrationUpdate()` and `restoreUpdate()` do not contain `register_webhook_at`; exact rollback uses field-presence-aware `$set`/`$unset` for the fields migration changes.

Failures and how to do differently:
- Original backup was written after LINE/DB mutation and excluded some failed states; always persist immutable before-state before the first external mutation.
- Original rollback could act on dry-run-only entries; select rollback candidates from mutation journal phases or verified live target state only.
- Original partial failure could exit successfully; treat failed test/PUT/verify/DB, compensation failure, and rollback conflicts as non-zero outcomes.
- Tests are unit/helper and orchestration-oriented only; do not claim production readiness without real-cluster, LINE API, gateway smoke, canary message, and terminal-processing evidence.

References:
- `migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.ts`
- `migrate-line-webhook-endpoint/migrate-line-webhook.helpers.spec.ts`
- `migrate-line-webhook-endpoint/README.md`
- `migrate-line-webhook-endpoint/plan.md`
- `npm run test:line-webhook` output: 11 tests passed
- `npm test` output: 21 tests passed
- `npx tsc --noEmit --target ES2022 --module Node16 --moduleResolution Node16 ...` output: `TypeScript: No errors found`
- `npm run migrate:line-webhook:help` completed successfully
- `git diff --check` completed successfully
- No secrets, DB credentials, LINE tokens, or production endpoints were stored; no real DB/LINE/gateway calls were made.

## Thread `019fea86-e89e-79c3-b1e3-68a6504098fc`
updated_at: 2026-08-17T04:40:27+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl
rollout_summary_file: 2026-08-10T07-15-37-7oWo-line_webhook_migration_hardening_and_routing_diagnosis.md

description: Reviewed and hardened OHO LINE webhook migration; identified unsafe backup/rollback ordering, added manifest-first requirements, and diagnosed 69 stale-token channels plus orphaned deleted-business traffic.
task: LINE webhook endpoint migration production-safety review and incident diagnosis
task_group: /Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: LINE webhook, migrate-line-webhook, manifest, rollback, allowed-host, 401 Authentication failed, connection_status, is_access_token_valid, Cloud Run domain mapping, URL map, webhook.oho.chat, webhook2.oho.chat

### Task 1: Audit original migration

task: Review migration flow against DB whitelist, LINE verification, mutation ordering, backup, and rollback requirements
task_group: script-oho/migrate-line-webhook-endpoint
task_outcome: partial

Preference signals:
- User required backup before any change and rollback protection against lost messages; treat this as a hard acceptance criterion.

Reusable knowledge:
- Original flow was test → LINE PUT → GET verify → MongoDB update, but backup was written after `processChannel()` completed.
- Original `--old-host` filtered hosts to migrate; it did not implement “DB hostname outside explicit whitelist.”
- Original rollback could include dry-run-only/already-new entries and did not restore all mutated DB fields.

Failures and how to do differently:
- Persist immutable before-state for every actionable candidate before the first LINE mutation; bind apply to that manifest and journal actual mutation phases.
- Force non-zero exit for unresolved `failed_test`, `failed_put`, or `failed_db` states.

References:
- `migrate-line-webhook.ts:916`, `:1373`, `:762`, `:1442`.
- OHO connect construction: `oho-api/src/services/channel/line/line.hooks.js:237-286`.

### Task 2: Plan and hardening implementation

task: Define fail-closed implementation while leaving `line.register_webhook_at` untouched
task_group: script-oho/migrate-line-webhook-endpoint
task_outcome: partial

Preference signals:
- User explicitly said not to update `line.register_webhook_at`; never include it in migrate or rollback payloads.
- User changed scope to plan-only; when asked for a plan only, do not implement.
- Requested model `5.6luna` was unavailable; do not silently substitute another model.

Reusable knowledge:
- Plan requires `--allowed-host`, immutable atomic manifest, digest-bound apply, candidate revalidation, journal phases, exact DB field-presence restore, timeouts, compensation, and canary evidence.
- Hardened files included `migrate-line-webhook.helpers.ts`, `.spec.ts`, expanded `migrate-line-webhook.ts`, README, and `plan.md`.

Failures and how to do differently:
- Sub-agent spawn failed: `Unknown model gpt-5.6-luna`. Stop and report unavailable model rather than using a near substitute.

References:
- `plan.md`; helpers/spec files.
- Journal phases: `backed_up → tested → line_put_requested → line_verified → db_updated → migrated`.

### Task 3: Production diagnosis

task: Explain skipped channels, orphaned traffic, and correct ingress cutover strategy
task_group: production LINE/GCP operations
 task_outcome: partial

Preference signals:
- User expects DNS, certificate, route, logs, and DB evidence before routing conclusions.
- User wants old domain retired without losing messages.

Reusable knowledge:
- Latest manifest: 69 channels, 62 businesses, all `unmigratable_invalid_token`; LINE GET webhook returned HTTP 401, so migration correctly stopped before POST/PUT/DB update.
- Inbound webhook can work while access-token API calls fail; `connection_status` and `is_access_token_valid` are not reliable live authorities.
- Deleted business `652f64468e7d21abc6e62235` still sent traffic; Core API returned 400 `Channel doesn't exists!` after ingress/Cloud Tasks acknowledged 200.
- `webhook.oho.chat` is a Cloud Run domain mapping and bypasses `oho-webhook-lb`; adding an LB host rule does not reroute it. `webhook2.oho.chat` is the LB-backed domain.
- To stop deleted-business webhook traffic, disable `Use webhook` in LINE Developers Console; revoking token alone does not stop inbound webhooks. There is no DELETE webhook endpoint API.

Failures and how to do differently:
- Never infer topology from LB names. Verify DNS → IP → target proxy/cert → URL map → backend → logs.
- Do not remap/delete the old domain before all LINE channels are migrated or disabled at the source.
- Do not treat ingress HTTP 200 as successful processing; verify downstream terminal state.

References:
- Error: `LINE GET webhook failed (401): {"message":"Authentication failed. Confirm that the access token in the authorization header is valid."}`.
- `oho-api/src/services/channel/line/line.hooks.js` contains duplicate `is_access_token_valid: true`.
- Validation cron uses `.limit(2000)` without pagination.
- DNS: `webhook.oho.chat → CNAME ghs.googlehosted.com`; LB IP `34.149.183.186` serves `webhook2.oho.chat`.

## Thread `019fea91-cc0c-72a0-a973-d5bc782a9d01`
updated_at: 2026-08-10T07:33:25+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-27-31-019fea91-cc0c-72a0-a973-d5bc782a9d01.jsonl
rollout_summary_file: 2026-08-10T07-27-31-raWB-facebook_attachment_ingestion_root_cause_gentle_clinic.md

---
description: Diagnosed recurring Facebook attachment send failures for Gentle Clinic; evidence points to Meta attachment ingestion failure rather than corrupt OHO files or OHO re-upload logic.
task: Diagnose Facebook Messenger attachment failures using GCP logs and source tracing
task_group: /Users/tualek/ohochat Facebook send-path production investigation
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Gentle Clinic, 67121be026ec0ed85e1d9208, Facebook, Meta, Messenger Send API, error_subcode 2018047, Upload attachment failure, GCP Cloud Logging, GCS, mediaUrl, youpin-to-facebook
---

### Task 1: Facebook attachment root-cause investigation

task: Correlate Gentle Clinic Facebook attachment failures across raw Meta errors, GCP logs, GCS file validity, and OHO source code.
task_group: production Facebook send-path diagnosis
task_outcome: success

Preference signals:
- When the user asked for the “rootcause” and whether it was the file, OHO metadata/upload, or Meta -> future debugging should separate raw platform evidence from UI error mappings and explicitly compare competing causes.
- When the user provided a business ID and sample file URL -> search production logs using business ID, page ID, file ID/URL, error code/subcode, and timestamps; preserve read-only investigation unless edits are requested.

Reusable knowledge:
- OHO’s Facebook image path sends the existing public GCS `mediaUrl` in `{ attachment: { type: 'image', payload: { url } } }`; it does not re-encode or re-upload the file to Meta before the Send API request.
- Source locations: `oho-api/src/utils/message-converter/youpin-to-facebook.js:42-52` and `oho-api/src/services/integration/facebook/reply-message/reply-message.class.js:30-35`.
- UI text `ส่งข้อความไม่สำเร็จ เนื่องจาก Facebook ไม่รองรับไฟล์ดังกล่าว` is a mapping for Facebook/Instagram `code=100` + `error_subcode=2018047`, not a precise diagnosis (`oho-api/src/utils/get-error-message-send-message-fail.js:123-126`).
- Production logs repeatedly showed Meta HTTP 400 responses with `(#100) Upload attachment failure`, `type: OAuthException`, `code: 100`, `error_subcode: 2018047`, and different `fbtrace_id` values for Gentle Clinic. The same subcode appeared across unrelated Facebook Pages/businesses, supporting a Meta-side attachment ingestion/fetch incident rather than a business-specific defect.
- The supplied/sample and Gentle-related GCS files returned HTTP 200 and decoded as valid JPEGs. Tested properties included RGB/sRGB, no alpha, standard JPEG encoding, and ordinary dimensions/sizes. Older reused images and a newly uploaded image failed in the same time window, weakening hypotheses involving one corrupt file, new-upload race, or OHO metadata.
- The original sample JSON’s business ID (`604e2c63...`) is not Gentle Clinic’s business ID (`67121be...`); correlate actual send logs before attributing it to Gentle.

Failures and how to do differently:
- Broad `gcloud logging read` searches generated truncated output. Use tight filters for `resource.labels.service_name`, exact `2018047`, business/page identifiers, and narrow UTC time ranges; format only timestamp, severity, text payload, and relevant labels.
- A local gcloud warning reported that `/Users/tualek/.config/gcloud/logs` was not writable; logging access through the proxy still worked. Do not confuse that local warning with an application failure.
- Do not store or repeat access tokens found in raw Axios log lines; redact them as `[REDACTED_SECRET]`.
- Meta’s public status page showed “No known issues,” but that is weaker evidence than synchronized cross-business production failures and does not rule out a partial attachment-ingestion incident.

References:
- Raw Meta error shape: `HTTP 400`; `(#100) อัพโหลดไฟล์แนบไม่สำเร็จ` / `(#100) Upload attachment failure`; `code=100`; `error_subcode=2018047`.
- Gentle Clinic Facebook Page ID: `1626745224287212`.
- Representative Gentle `fbtrace_id` values: `A3afHY6EcLdo3J09SOyuUV8`, `AqGswMbobZ-r0fkNQ6vyAtZ`, `AS4Ixcoke0f2L-ISRYhGG_l`.
- Production service/project: `core-api--production` in GCP project `oho-platform`.
- Operational conclusion from the rollout: retry only failed attachments after failures cease for roughly 10–15 minutes; do not resend a whole saved reply because successful messages may duplicate.

## Thread `019feaaa-5edf-7453-8fdb-0bf9b642ca0c`
updated_at: 2026-08-10T10:38:39+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-54-21-019feaaa-5edf-7453-8fdb-0bf9b642ca0c.jsonl
rollout_summary_file: 2026-08-10T07-54-21-Wlnm-line_webhook_migration_review_config_audit.md

---
description: Reviewed and hardened a production LINE webhook domain migration; established fail-closed manifest/rollback requirements and identified the only required runtime config change.
task: LINE webhook migration safety review and cross-repo config audit
task_group: /Users/tualek/ohochat/script-oho / production migration workflow
task_outcome: partial
cwd: /Users/tualek/ohochat/script-oho
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, whitelist, manifest, rollback, register_webhook_at, APP_CONFIG, core-api, OHO_WEBHOOK_URL, Cloud Run
---

### Task 1: Review migration safety

task: Audit `migrate-line-webhook-endpoint/migrate-line-webhook.ts` against DB whitelist, LINE verification, mutation ordering, backup, and rollback requirements.
task_group: script-oho production migration review
task_outcome: partial

Preference signals:
- The user required: check DB for LINE webhook domains outside the whitelist; verify the new endpoint with LINE before PUT; update LINE first and MongoDB afterward; back up everything before mutation for rollback.
- The user initially requested a read-only, evidence-based review with file/line citations.

Reusable knowledge:
- Canonical endpoint shape is `${webhook_endpoint}/line/webhook/${businessId}`, matching `oho-api/src/services/channel/line/line.hooks.js`.
- The original flow had test → PUT LINE → GET verify → DB update, but backup persistence occurred after `processChannel`, leaving a crash window.
- Original `--old-host` filtered hosts to migrate, which did not implement the requirement “migrate domains not in whitelist.”
- LINE `success: true` proves the endpoint accepted LINE’s test event, not full message ingestion/queue processing; real-message canary evidence is still required.

Failures and how to do differently:
- Never approve production migration when backup is written after external mutations.
- Rollback must select only entries that actually reached a mutation phase, not every dry-run entry.
- Bind apply confirmation to an immutable manifest/candidate set and return non-zero on unresolved partial failures.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- `oho-api/src/services/channel/line/line.hooks.js:237-285`
- `oho-webhook/src/controllers/line/line.controller.ts:38-76`

### Task 2: Plan-only hardening

task: Produce an implementation-ready plan without modifying implementation code.
task_group: script-oho migration planning
task_outcome: success

Preference signals:
- The user explicitly said `register_webhook_at` need not be updated.
- The user explicitly narrowed the task to “plan only”; do not implement or delegate until explicitly requested.
- Requested model `gpt-5.6-luna` was unavailable; the user chose plan-only instead of silently substituting another model.

Reusable knowledge:
- `script-oho/migrate-line-webhook-endpoint/plan.md` specifies explicit `--allowed-host`, immutable manifest before mutation, manifest-bound apply, durable per-channel journal, exact DB field-presence restore, timeout/polling, compensating rollback, conflict detection, and non-zero exit semantics.
- `line.register_webhook_at` must not appear in migration or rollback `$set`/`$unset` payloads.

Failures and how to do differently:
- Respect plan-only scope; do not edit implementation or run DB/LINE/gateway operations during planning.

References:
- `script-oho/migrate-line-webhook-endpoint/plan.md`
- Required flow: `DB inventory → LINE inventory → immutable manifest → revalidate → test → PUT → GET verify → DB update → final verify`

### Task 3: Cross-repo runtime configuration audit

task: Determine which repos/env/secrets must change for the new public LINE webhook domain.
task_group: cross-repo deployment/config audit
task_outcome: partial

Preference signals:
- When a search result appears in UI code, inspect enclosing comments and reachability before recommending a deployment; the user corrected an overclaim about `oho-web-app`.

Reusable knowledge:
- `oho-api` runtime config is loaded from `APP_CONFIG` (`oho-api/config/local.js`), backed by Secret Manager `core-api-config--json--<env>` and sourced from GitLab config project `294` via `load-config.sh`/`prepare-app-config.sh`.
- The required runtime update is the environment config field `webhook_endpoint`, e.g. production `https://api2.oho.chat/webhook`, followed by deploying `core-api` with the new secret version.
- `oho-webhook`’s `OHO_WEBHOOK_URL` is an internal Cloud Run callback base used by Cloud Tasks to call `/line/message/...`; it is a separate contract and does not need changing for this public LINE endpoint migration.
- The stale `https://webhook.oho.chat/...` string in `oho-web-app/pages/business/_biz_id/setting/integration.vue` is inside a commented `<el-table>` block (`~824-1140`) and is not rendered; no web-app deployment is needed for it.
- A production Secret Manager read that would retrieve the entire JSON secret was refused to avoid exposing unrelated credentials; source/deployment mapping was sufficient to identify the config path.

Failures and how to do differently:
- Do not infer runtime impact from `rg` matches alone. Verify comments, feature gates, route registration, and call/render path.
- Do not retrieve an entire production secret merely to inspect one field; use a safe narrow inspection or source/deployment mapping.

References:
- `oho-api/load-config.sh`
- `oho-api/prepare-app-config.sh`
- `oho-api/deploy.sh`
- `oho-api/config/local.js`
- `oho-api/src/services/channel/line/line.hooks.js`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99`
- `oho-web-app/pages/business/_biz_id/setting/integration.vue:824-1140`
- Live Cloud Run: `webhook--production` had `OHO_WEBHOOK_URL=https://webhook--production-...run.app`.

## Thread `019fead6-e1dd-77a1-84ca-e7b90cfc6323`
updated_at: 2026-08-10T17:19:20+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T15-42-58-019fead6-e1dd-77a1-84ca-e7b90cfc6323.jsonl
rollout_summary_file: 2026-08-10T08-42-58-K9az-meta_business_ai_scoped_review_and_luna_fixes.md

---
description: Scoped review and partial implementation of Facebook Meta Business AI MVP; corrected identity contract, authority transitions, tenant safety, dedup lease races, and send guards, with focused validation but remaining rollout risks.
task: review-and-fix-facebook-meta-business-ai-mvp
task_group: ohochat-meta-business-ai
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, ai_generated, standby, facebook_delivery_authority, oho-webhook, oho-api, Redis lease, Lua CAS, tenant scope, Graph API, primary read, performance, Luna max
---

### Task 1: Review Meta Business AI MVP

task: review-facebook-meta-business-ai-branch
 task_group: ohochat-meta-business-ai-review
 task_outcome: success

Preference signals:
- when reviewing this feature, the user asked for a detailed plan focused on worst cases such as “ข้อความไม่เข้าหรอ ? หรือ performance drop” -> future reviews should separate message delivery, authority correctness, security/tenant scope, and performance with concrete evidence.
- the user explicitly constrained the work to `oho-api` and `oho-webhook` first and asked not to expand into web-app/design -> keep implementation scope limited to backend/webhook seams.

Reusable knowledge:
- The intended branch refs initially pointed at staging, so pin the actual feature commits via reflog/topology: `oho-api afccdd74e`, `oho-webhook c3dbadd`.
- Prior implementation had high-risk paths: messaging did not restore authority, Take/Pass persisted state before Graph success, contact lookup lacked business scoping, Redis dedup completion/release lacked ownership tokens, and AI identity incorrectly required `app_id`.
- Canonical Facebook events are flattened from `entry.messaging[]` and `entry.standby[]` and tagged with `__ohoChannel`; `message.ai_generated` is nested inside each canonical event.

Failures and how to do differently:
- GitLab MR lookup failed due sandbox DNS; rely on local refs/reflog/source evidence and label remote verification unavailable.
- Do not treat POC diagrams or prior plans as runtime contracts without tracing parser → persistence → bot/send paths.

References:
- `/Users/tualek/ohochat/oho-api` commit `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`
- `/Users/tualek/ohochat/oho-webhook` commit `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`
- Error: `dial tcp: lookup gitlab.boonmeelab.com: no such host`

### Task 2: Implement scoped fixes

task: implement-facebook-meta-business-ai-safety-fixes
 task_group: ohochat-meta-business-ai-implementation
 task_outcome: partial

Preference signals:
- when the user requested `5.6 Luna max`, the assistant initially selected `gpt-5.6-sol` and the user corrected: “ฉันบอกให้ใช้ 5.6 Luna max” -> never substitute a nearby model without explicit approval; stop and report model availability.
- the user said to fix “แค่ scope ที่เป็น feature meta business ai ก่อน” -> preserve dirty worktree and avoid unrelated cleanup or channel changes.
- the user clarified: `ai_generated === true` on a Facebook `standby` event is sufficient Meta Business AI identity even when `app_id` is absent -> implement `entry.__ohoChannel === 'standby' && entry.message.ai_generated === true`; do not require `app_id`.

Reusable knowledge:
- Authority is represented by `facebook_delivery_authority` (`oho|other`) plus observation timestamp. `standby` customer events observe `other`; customer `messaging` observes `oho` only as recovery from prior `other`, avoiding a Mongo write on normal OHO traffic.
- Take/Return services now query by `_id + business_id`, validate Facebook, call Graph first, and persist authority only after Graph success. Graph failure leaves prior authority unchanged.
- Authority persistence uses conditional primary updates and avoids writes when the authority is unchanged or the event is stale.
- Webhook dedup now uses a pending lease and ownership token. `completeWithTtl` and `releaseWithToken` use Lua/CAS token checks so an expired worker cannot mutate a newer worker’s lease.
- Automated Facebook send guard performs a primary read and should fail closed if the authoritative contact cannot be found; this adds primary-read cost that must be measured.
- Stream identity for AI messages is `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox`.

Failures and how to do differently:
- Campaign broadcast still filters recipients once before the batch; authority changes during the batch can create a TOCTOU send window. Either accept/document this risk or add a carefully measured per-recipient/send-time check.
- Focused tests/builds passed, but full suite, production E2E, load testing, and production logs were not run. Do not call the change merge/canary-ready until those gates are completed.
- Redis tests pass with warning because no local Redis was available: `EPERM 127.0.0.1:6379`; distinguish this environment warning from a test failure.
- Worktrees remain dirty with pre-existing and newly added files. Before commit, capture baseline status and review only the intended Meta Business AI delta.

References:
- Identity: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:20-24`
- Authority observation: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:42-95`
- Canonical event extraction: `oho-webhook/src/controllers/facebook/helper.ts:1532-1561`
- Webhook handling and dedup completion: `oho-webhook/src/controllers/facebook/handler.ts:966-989,1230-1415`
- Redis lease/CAS: `oho-webhook/src/services/redis.service.ts:1-20,230-305`
- API tenant-scoped loader/update: `oho-api/src/services/contact/meta-business-ai/shared.js:5-75`
- Automation guard: `oho-api/src/utils/meta-business-ai-automation-guard.js`
- Validation: API focused `4 suites/17 tests`; webhook focused `3 suites/17 tests`; both builds passed; `git diff --check` passed.

## Thread `019febf6-d717-7103-a1de-872be9834c91`
updated_at: 2026-08-11T03:33:02+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T20-57-30-019febf6-d717-7103-a1de-872be9834c91.jsonl
rollout_summary_file: 2026-08-10T13-57-30-8fJv-meta_business_ai_minimal_integration_flag_scope_correction.md

---
description: Meta Business AI MVP was simplified to Facebook-only authority observation, but the claim that the feature flag was fully removed was incorrect because web-app and legacy references remain.
task: review-and-simplify-meta-business-ai-mvp-and-verify-feature-flag-removal
task_group: /Users/tualek/ohochat cross-repo Meta Business AI workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, rt_meta_business_ai_enabled, oho-api, oho-webhook, oho-web-app, standby, facebook_delivery_authority, Redis lease, campaign race, primary Mongo, feature flag
---

### Task 1: Simplify and review Meta Business AI MVP

task: review branch MVP across oho-api/oho-webhook for performance, webhook safety, and worst-case failures; reduce scope before implementation.
task_group: Meta Business AI backend/webhook review
task_outcome: partial

Preference signals:
- The user asked to recheck existing MVP work, worried that new fields could hurt performance, and explicitly asked about worst cases such as messages not arriving or performance dropping -> future reviews should trace webhook throughput, DB writes/queries, queue/dedup behavior, and delivery failure modes.
- The user asked to prioritize `oho-api` and `oho-webhook` while waiting for web-app design -> keep backend/webhook scope separate from UI work.
- The user prefers detailed Thai, source-cited findings with clear evidence/severity/recommendation structure, and no fabricated logs or verification.

Reusable knowledge:
- Original feature commits were `oho-api afccdd74e` and `oho-webhook c3dbadd`; the branch refs later pointed at staging, so review required reflog/commit inspection rather than assuming a normal branch diff.
- The minimal direction removed backend Remote Config gating and large runtime-state writes, using Facebook-only `standby` authority observation, durable customer-message persistence before automation suppression, primary Mongo reads, timestamp-conditional authority updates, and a 5-second query bound.
- `standby` means another app may own delivery; it is not proof of Meta Business AI. `ai_generated` identifies an echo author, not ownership.
- Validation completed: both builds passed, focused tests passed, and `git diff --check` passed. Full captured-payload replay, terminal Mongo/Stream verification, load testing, and canary were not completed.

Failures and how to do differently:
- Redis dedup leases use no owner token/CAS; a worker running beyond the 300-second lease can race a reclaimed worker. Fix before canary.
- Broadcast authority filtering is batch-snapshot-only; add send-time per-recipient authority checks or gate campaigns.
- Legacy `meta_business_ai.observed_authority` remains as compatibility state; measure/backfill/expire it before removal.
- Do not treat HTTP 200 or unit tests as webhook delivery proof; replay captured payloads and inspect terminal Mongo/Stream state.

References:
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md` (remaining blockers B1–B5)
- `oho-api/src/services/contact/upsert/upsert.hooks.js`
- `oho-api/src/services/contact/meta-business-ai/shared.js`
- `oho-webhook/src/controllers/facebook/handler.ts`
- `oho-webhook/src/controllers/facebook/helper.ts`

### Task 2: Correct feature-flag removal scope

task: investigate why `rt_meta_business_ai_enabled` still exists after the assistant claimed no feature flag remained.
task_group: cross-repo flag/config verification
task_outcome: fail

Preference signals:
- The user challenged the contradiction directly: “บอกว่าไม่มี feature flag แล้วทำไมยังมี ใน firebase config” -> acknowledge the overclaim and distinguish backend removal from repository-wide removal.

Reusable knowledge:
- A workspace-wide search found active web-app flag usage:
  - `oho-web-app/store/index.js:52` initializes `rt_meta_business_ai_enabled: false`.
  - `oho-web-app/plugins/firebase-remote-config.js:23` defines the flag.
  - `oho-web-app/components/Smartchat/Conversation.vue`, `RoomHeader.vue`, and `SendMessageDisabled.vue` read the flag to gate UI/badges/actions.
  - `oho-web-app/utils/meta-business-ai.js` contains feature-enabled checks.
- Backend RC lookup was removed from `oho-api`/`oho-webhook`, but Meta Business AI backend domain code remains for Stream labeling and takeover/return endpoints. Thus the accurate claim is “no backend RC lookup remains,” not “no feature flag exists anywhere.”
- Use a workspace-wide search before claiming global removal: `rg -n -i "meta[_-]?business[_-]?ai|rt_meta_business_ai|business_ai" . --glob '!node_modules/**' --glob '!dist/**' --glob '!coverage/**' --glob '!.claude-worktrees/**' --glob '!*.lock'`.

Failures and how to do differently:
- The assistant searched backend/runtime scope but failed to account for web-app, docs, and legacy/config references. Future agents must classify all hits as active runtime, UI, config, docs, tests, or compatibility before making removal claims.

References:
- `oho-web-app/store/index.js:52`
- `oho-web-app/plugins/firebase-remote-config.js:23`
- `oho-web-app/components/Smartchat/Conversation.vue:1000-1006,3789-3839`
- `oho-web-app/components/Smartchat/RoomHeader.vue:118-130`
- `oho-web-app/components/Smartchat/SendMessageDisabled.vue:263-273`
- Search output also showed `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`, `oho-api/config/default.json`, takeover/return services, and compatibility references.

## Thread `019fef13-d776-7dc0-b2b5-fce38b9ab737`
updated_at: 2026-08-11T04:28:15+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-28-02-019fef13-d776-7dc0-b2b5-fce38b9ab737.jsonl
rollout_summary_file: 2026-08-11T04-28-02-vw3l-meta_ai_plan_review_aborted.md

---
description: User requested a detailed, prioritized review of a Meta AI profile-fix plan, but the rollout was aborted before any file inspection or analysis.
task: review-meta-ai-profile-plan
task_group: plan-review
task_outcome: uncertain
cwd: /Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an
keywords: Meta AI, plan review, assumptions, risks, edge cases, validation, rollback, testing, observability, dependencies, migration, security, acceptance criteria
---

### Task 1: Review Meta AI profile plan

task: review `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md` in detail
task_group: Meta AI implementation planning
 task_outcome: uncertain

Preference signals:
- The user explicitly requested a comprehensive review covering "assumption/risk/edge case/validation/rollback/testing/observability/dependency/migration/security หรือ acceptance criteria" -> future reviews should proactively inspect each of these categories.
- The user asked for "การแก้ไขที่ actionable และจัดลำดับความสำคัญ" -> provide concrete proposed changes and prioritize them rather than only listing omissions.

Reusable knowledge:
- The requested plan file is `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`.

Failures and how to do differently:
- The user aborted before the file was opened, so there are no validated findings, edits, tests, or implementation facts to preserve.

References:
- Prior conversation ID: `6a7aa49b-df20-83ec-a0b6-c5704cce2124`
- Exact requested review dimensions: assumptions, risks, edge cases, validation, rollback, testing, observability, dependencies, migration, security, and acceptance criteria.

## Thread `019fef19-a05e-7773-9301-06b8ab7c9e37`
updated_at: 2026-08-14T06:34:08+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-34-21-019fef19-a05e-7773-9301-06b8ab7c9e37.jsonl
rollout_summary_file: 2026-08-11T04-34-21-HTzp-meta_business_ai_plan_review_correction_and_implementation_r.md

---
description: Meta Business AI plan was narrowed from an oversized profile/state-machine migration to a Facebook-only MVP, but implementation still needs rework on disabled-channel writes, duplicated authority persistence, Redis lease expiry, and bulk-send scope.
task: review-and-correct-meta-business-ai-mvp-plan
task_group: /Users/tualek/ohochat / Meta Business AI backend and webhook workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, ai_generated, standby, meta_business_ai_enabled, facebook_delivery_authority, Stream, @meta-ai, inbox fallback, Redis lease, Graph API, oho-api, oho-webhook
---

### Task 1: Narrow Meta Business AI plan and implementation scope

task: review-and-correct-meta-business-ai-mvp-plan
task_group: Meta Business AI Facebook MVP

task_outcome: partial

Preference signals:
- when the assistant treated `ai_generated` as something OHO creates, the user corrected: “`ai_generated` คือ field ที่ webhook จาก meta ส่งมานะถ้า meta ai เป็นคนตอบ” -> preserve strict incoming `message.ai_generated === true`; never infer it from app ID, metadata, channel, or standby.
- when the plan combined schema migration, state machine, Redis/Cloud Tasks, provisioning, and cleanup, the user asked to update it to be ready for work -> prefer smallest implementation contract with explicit non-goals and phase exit criteria.
- user expects Thai, evidence-first, source-cited reviews and explicit separation of verified local tests versus unverified runtime/UAT.

Reusable knowledge:
- `message.ai_generated === true` identifies the author of an individual Meta AI message, not thread ownership or delivery authority.
- `standby` means another app may own delivery; it is not proof that the app is Meta Business AI.
- AI Stream identity is `${businessId}@meta-ai`; lazy provisioning failure falls back to `${businessId}@inbox` while preserving `ai_generated: true`.
- Existing authority guard should remain primary Mongo, tenant-scoped, and fail closed on read failure.
- Canonical Facebook events flatten both `messaging[]` and `standby[]`; AI detection must work on both.

Failures and how to do differently:
- Do not remove `isMetaBusinessAiGeneratedEvent`; Stream membership does not identify webhook author.
- Do not introduce `meta_ai_profile`, Redis authority cache, Cloud Tasks writes, send-first/HUMAN_AGENT state machine, or broad TypeScript conversion into this MVP unless separately approved.
- Standards review found remaining P1 issues after implementation: disabled channels can still cause activation snapshot writes; authority persistence is duplicated in `upsert.hooks.js` and `upsert.class.js`; Redis claim lease is fixed at 300 seconds with no renewal; raw bulk Facebook broadcast has no per-recipient authority guard and should be explicitly out of scope or fixed.

References:
- `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19`
- `oho-webhook/src/controllers/facebook/meta-business-ai.ts`
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js`
- `oho-api/src/utils/meta-business-ai-stream.js`
- `oho-api/src/services/contact/upsert/upsert.hooks.js`
- `oho-api/src/services/contact/upsert/upsert.class.js`
- `oho-api/src/utils/meta-business-ai-automation-guard.js`
- `oho-webhook/src/controllers/facebook/block.ts`
- Focused validation evidence: webhook tests passed in focused runs; API `upsert.class.spec.js` had a Node 24/config compatibility failure (`Utils.isRegExp is not a function`); `git diff --check` passed.

### Task 2: Workflow constraint

task: apply-ponytail-full

task_group: coding workflow

task_outcome: success

Preference signals:
- user invoked `ponytail full` -> future edits should “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause” and avoid premature abstraction or broad refactors.

Reusable knowledge:
- Keep subsequent Meta Business AI changes minimal and preserve existing dirty worktrees/user changes unless explicitly authorized otherwise.

## Thread `019ff026-fc80-7881-8a12-5ba2c15991bb`
updated_at: 2026-08-11T10:24:33+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T16-28-34-019ff026-fc80-7881-8a12-5ba2c15991bb.jsonl
rollout_summary_file: 2026-08-11T09-28-34-wXtp-meta_business_ai_plan_review_and_scope_correction.md

description: Reviewed and reworked Meta Business AI implementation plan; corrected ai_generated semantics, narrowed MVP, and blocked unsupported authority/control side effects pending activation evidence
 task: review-and-update-meta-business-ai-plan
 task_group: /Users/tualek/ohochat / Meta Business AI Messenger
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, ai_generated, standby, activation source, delivery authority, Stream @meta-ai, take_thread_control, pass_thread_control, oho-api, oho-webhook, focused tests
---

### Task 1: Review Meta Business AI plan

task: review-and-update-meta-business-ai-plan
task_group: Meta Business AI Messenger architecture
task_outcome: success

Preference signals:
- ผู้ใช้ยืนยันว่า `ai_generated` คือ field ที่ Meta webhook ส่งมาเมื่อ Meta AI เป็นผู้ตอบ -> ในงานต่อไปต้อง preserve incoming field และแยก message author identity ออกจาก thread/delivery authority
- ผู้ใช้ต้องการแผนที่พร้อมทำงาน ไม่ใช่ migration ขนาดใหญ่ที่รวมหลาย concern -> เริ่มจาก scope และ contract ที่พิสูจน์ได้จริง
- งาน Meta ควรตอบภาษาไทย พร้อม evidence/path และระบุข้อจำกัดอย่างตรงไปตรงมา

Reusable knowledge:
- `message.ai_generated === true` เป็น per-message author signal สำหรับ Meta AI; ไม่ใช่ Page activation, contact eligibility หรือ delivery ownership
- `app_id`, `metadata`, `hop_context`, `standby`, `thread_owner` และ `subscribed_apps` ไม่ใช่ activation source ที่เชื่อถือได้โดยลำพังจากหลักฐานใน rollout
- ไม่มี supported Page/contact activation source ใน repo ณ rollout นี้; Meta Eligibility API ถูกระบุเป็น coming soon ในเอกสารที่เก็บไว้
- Existing legacy `meta_business_ai` state/schema ต้องไม่ถูกลบโดยไม่มี backfill และ volume verification

Failures and how to do differently:
- แผนเดิมรวม `meta_ai_profile`, state machine, Redis/Cloud Tasks, provisioning, webhook cleanup และ TypeScript conversion ไว้ด้วยกัน -> แยก concerns และเริ่มจาก sender identity/author labeling ที่เล็กที่สุด
- ห้ามเปลี่ยน `ai_generated` ให้กลายเป็น authority observation หรือใช้ `standby` เป็นหลักฐานว่าเป็น Meta Business AI โดยอัตโนมัติ
- Exact handoff text ใช้ได้เฉพาะ handoff-to-queue contract; ห้ามใช้เป็น Page activation หรือปลดล็อก Graph take/return

References:
- `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19`
- `docs/meta-business-ai/meta-official-coming-soon-2026-08-04.md:9-15,29-31`

### Task 2: Update plan and implementation safeguards

task: narrow-meta-business-ai-mvp-and-validate
 task_group: oho-api/oho-webhook Meta Business AI MVP
 task_outcome: partial

Preference signals:
- เมื่อผู้ใช้แก้ว่า `ai_generated` มาจาก Meta webhook -> ใช้ strict boolean จาก payload เท่านั้น; ห้ามสร้างจาก `app_id`, metadata หรือ channel

Reusable knowledge:
- Updated plan path: `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `hasMetaBusinessAiActivation()` intentionally returns `false` until an explicit activation source exists; this prevents unsupported Meta take/return and Meta-specific send blocking
- AI echoes from Facebook `messaging`/`standby` can route to `${businessId}@meta-ai`; provisioning failure should fall back to `${businessId}@inbox` while preserving `ai_generated:true`
- Generic standby and non-Meta external app behavior should remain unchanged until activation is confirmed
- API focused validation passed 5 suites / 31 tests; webhook focused validation passed 1 suite / 17 tests; both builds and `git diff --check` passed

Failures and how to do differently:
- Do not call the implementation ready to ship: no real UAT or terminal Mongo/Stream replay was performed, and type-check still has unrelated existing failures
- Worktrees contained many pre-existing uncommitted changes and deleted canonical/dedup tests; isolate the intended diff before commit/review
- Verify terminal datastore/Stream state, not HTTP 200 or unit-test success alone

References:
- API test command: `npm test -- --runInBand --coverage=false src/services/contact/meta-business-ai/control-hooks.spec.js src/utils/meta-business-ai.spec.js src/utils/meta-business-ai-automation-guard.spec.js src/services/member-send-message/inbox/inbox.hooks.spec.js src/utils/meta-business-ai-stream.spec.js`
- Webhook test command: `npm test -- --runInBand --forceExit --coverage=false __tests__/facebook-meta-business-ai.test.ts`
- Activation seam: `oho-api/src/utils/meta-business-ai.js:42-50`
- Author detection: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:34-39`
- Final status: blocked pending explicit Meta activation/eligibility source and real replay verification

## Thread `019ff083-0ff1-7601-a36c-8514dad1e62b`
updated_at: 2026-08-11T13:57:23+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-09-08-019ff083-0ff1-7601-a36c-8514dad1e62b.jsonl
rollout_summary_file: 2026-08-11T11-09-08-rVYn-meta_business_ai_mvp_correction_pass.md

---
description: Implemented and locally validated a narrowly scoped Facebook Meta Business AI MVP correction pass; runtime/UAT remains unverified.
task: facebook-meta-business-ai-mvp-corrections
task_group: /Users/tualek/ohochat backend-webhook workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, meta_business_ai_enabled, ai_generated, Facebook standby, external-app whitelist, handoff, take_thread_control, pass_thread_control, Stream meta-ai, Redis lease, duplicate-create race, git diff check
---

### Task 1: Facebook Meta Business AI MVP corrections

task: implement approved Meta Business AI corrections in oho-api/oho-webhook without disturbing dirty work
 task_group: backend/webhook Meta Business AI
 task_outcome: partial

Preference signals:
- The user required preserving dirty work and explicitly forbade commit, push, reset, revert, delete, or stage -> future agents should inspect and report worktree state first and never perform destructive Git actions.
- The user required Facebook Messenger-only scope, no web-app changes, and no unrelated refactors -> keep similar work narrowly bounded.
- The user required exact validation results and remaining UAT gaps -> distinguish local test success from runtime readiness.

Reusable knowledge:
- Activation is persisted `channel.meta_business_ai_enabled`, default `false`, manually configured, and not Firebase Remote Config. It is propagated through webhook channel context, contact upsert, persisted contact snapshot, automation guards, and control services.
- `message.ai_generated === true` is strict per-message author evidence only. It must not be used as activation, thread ownership, or app identity evidence; unknown extra fields including `meta_business_ai.identity` are ignored.
- External-app whitelist handling must occur after Facebook/page/contact validation. Strict AI evidence is a narrow exception; unknown non-AI external apps remain fail-closed, and mixed batches must not be dropped wholesale.
- Enabled Facebook standby customer messages are persisted before OHO chatbot/ARP/greeting/fallback/referral/scheduled automation is blocked.
- Existing Accept/Close hooks invoke Graph takeover/return only under activation/source checks, with tenant scoping and authority persistence only after Graph success. Graph failure leaves prior state unchanged.
- Lazy Stream identity is `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox` while retaining `ai_generated:true`. No cold provisioning/backfill/repair.
- Focused validation passed: API 10 suites/50 tests; webhook 5 suites/46 tests; webhook TypeScript reported no errors; `git diff --check` clean in both repos; nothing staged.

Failures and how to do differently:
- A duplicate-create race initially lacked activation snapshot coverage. The fallback now persists the channel activation snapshot before applying standby authority, and `src/services/contact/upsert/upsert.class.spec.js` covers it.
- Local tests showed pre-existing duplicate Jest mock warnings, missing `OHO_FB_APP_ID`, and unavailable localhost Redis. Treat these as environment warnings, not runtime proof.
- Full suites, live Meta payload replay, Graph calls, terminal Mongo/Redis/Stream checks, canary/rollback, and target app configuration were not verified. Do not label this production-ready without those gates.

References:
- API HEAD: `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`
- Webhook HEAD: `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`
- Exact handoff text: `เอเจนต์ AI ของคุณโอนแชทนี้ให้คุณ`
- Plan: `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- Core files: `oho-api/src/models/channel.model.js`, `oho-api/src/services/contact/upsert/upsert.class.js`, `oho-api/src/services/contact/meta-business-ai/control-hooks.js`, `oho-api/src/utils/meta-business-ai-stream.js`, `oho-webhook/src/controllers/facebook/meta-business-ai.ts`, `oho-webhook/src/controllers/facebook/helper.ts`, `oho-webhook/src/controllers/facebook/handler.ts`

## Thread `019ff094-bfe0-7330-b67d-5c37089d39fe`
updated_at: 2026-08-14T09:31:07+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-28-28-019ff094-bfe0-7330-b67d-5c37089d39fe.jsonl
rollout_summary_file: 2026-08-11T11-28-28-MoHA-stream_querychannels_best_practices_review.md

description: Traced OHO Stream Chat queryChannels usage, corrected an incomplete frontend analysis, and created an official best-practices review Markdown report
 task: trace-and-review-stream-querychannels
 task_group: ohochat-stream-chat
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: queryChannels, Stream Chat, chat-proxy-singapore, recoverStateOnReconnect, CID, GetStream best practices, oho-api, oho-web-app, Flutter

### Task 1: Locate queryChannels call sites

task: identify active Stream Chat queryChannels callers
 task_group: ohochat-stream-chat
 task_outcome: success

Preference signals:
- The user asked where `queryChannel`/`queryChannels` is used and wanted docs updated based on the complete scope -> future searches should distinguish active production code, SDK-generated calls, scripts, tests, docs, and commented-out code.

Reusable knowledge:
- Active backend calls are `oho-api/src/services/contact/chat-search/chat-search.class.js:46` (`/contact/chat/search`) and `oho-api/src/services/chat-session/group/search/search.class.js:28` (`/chat-session/group/search`).
- Flutter production call is `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:331`, invoked by `oho-flutter-mobile/lib/modules/home/controllers/chat_list_controller.dart:915`.
- Script/CLI calls: `script-oho/unread-unresponded/migrate-unread.ts:716`, `probe-stream-authority.ts:355`, `oho-cli/lib/fix/fix-chat-room-attachment.js:307`, `oho-cli/lib/fix/fix-contact.js:74`.
- `oho-api/src/services/conversations/facebook/facebook.hooks.js:372` is within a comment block and is not active runtime code.

Failures and how to do differently:
- Plain text search can include unrelated `queryChannel` variables, tests, docs, and dead code; inspect enclosing comments and call paths before counting a finding.

References:
- `rtk rg -n --hidden --glob '!**/.git/**' --glob '!**/node_modules/**' "queryChannels\\(" .`

### Task 2: Trace web SDK network behavior

task: determine whether browser-side Stream calls bypass application-level queryChannels
 task_group: ohochat-web-stream-sdk
 task_outcome: success

Preference signals:
- The user corrected: "แต่หน้าบ้านมีเรียก https://chat-proxy-singapore.stream-io-api.com/ ด้วยนะ" -> future agents must inspect SDK integration and browser network paths before claiming the frontend does not call a third-party API directly.

Reusable knowledge:
- `oho-web-app/components/Smartchat/Conversation.vue:1517-1525` creates `StreamChat`, sets base URL `https://chat-proxy-singapore.stream-io-api.com`, and calls `connectUser`.
- `Conversation.vue:1595` calls `channel.watch()`; `:2460` calls `channel.query()`.
- The installed SDK defaults `recoverStateOnReconnect: true` and recovery calls `queryChannels` over `POST {baseURL}/channels` with active CIDs, `last_message_at` sort, and limit 30.
- Distinguish paths: `POST /channels` indicates `queryChannels`; `POST /channels/{type}/{id}/query` indicates `channel.watch()`/`channel.query()`.

Failures and how to do differently:
- Initial “webapp has no direct Stream call” conclusion was wrong because it relied on searching for application-level `queryChannels` only. Trace SDK source and network endpoint paths instead.

References:
- `oho-web-app/components/Smartchat/Conversation.vue:1516-1597,2458-2465`
- `oho-web-app/node_modules/stream-chat/src/client.ts:1242-1255,1402-1437`
- `oho-web-app/node_modules/stream-chat/src/channel.ts:1008-1047,1223-1245`

### Task 3: Produce GetStream best-practices review Markdown

task: compare OHO queryChannels implementations with official GetStream guidance and save report
 task_group: ohochat-stream-chat-review
 task_outcome: success

Preference signals:
- The user asked “ทำเป็น .md ไฟล์ให้หน่อย” -> research findings should be saved as a reviewable Markdown artifact in the repo, not only summarized in chat.
- The user requested comparison against the official GetStream best-practices URL -> cite primary documentation and separate verified facts from inference and unrun validation.

Reusable knowledge:
- Created `/Users/tualek/ohochat/queryChannels-best-practices-review.md`.
- Report findings: backend allows/pass-through limits up to 50 while Stream max is 30; Smartchat uses CID but omits sort; Groupchat uses `type + id` rather than CID; Flutter batches 10 and avoids duplicate watch but uses `id` only, ignores `type`, omits sort, and requests `messageLimit: 100`; web reconnect uses CID/sort/limit 30 but may retain stopped channels in SDK `activeChannels`.
- Official baseline captured from `https://getstream.io/chat/docs/react-native/query-channels.md`: selective filters, CID preferred, explicit sort, max 30 channels, avoid redundant watch calls, and use `state:false`/`watch:false` where state/realtime is unnecessary.
- No application code was modified, tests were not run, and no commit was made. Dashboard performance, production `$limit=31..50` replay, Flutter payload measurement, and browser reconnect reproduction remain unverified.

Failures and how to do differently:
- Treat the Groupchat CID recommendation and web active-channel accumulation as source-backed inferences unless confirmed with Stream Dashboard or runtime reproduction.
- Do not reduce Flutter `messageLimit: 100` blindly; measure first-render/state consumption first.

References:
- Artifact: `queryChannels-best-practices-review.md`
- Official docs: `https://getstream.io/chat/docs/react-native/query-channels.md`
- Backend: `oho-api/src/services/contact/chat-search/chat-search.class.js:46-50`; `oho-api/src/services/chat-session/group/search/search.class.js:28-32`; limits in `oho-api/src/services/contact/chat-search/shared-hooks.js` and `oho-api/src/services/chat-session/group/search/search.hooks.js`; `oho-api/config/default.json:6-9`
- Flutter: `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:317-350`

## Thread `019ff11b-e580-7052-b2d7-ee32d28d724d`
updated_at: 2026-08-11T14:09:31+00:00
cwd: /Users/tualek/ai-main
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T20-56-05-019ff11b-e580-7052-b2d7-ee32d28d724d.jsonl
rollout_summary_file: 2026-08-11T13-56-05-3WLH-ai_main_obsidian_caveman_token_context_analysis.md

---
description: Compared Obsidian cold memory, ai-main memory, and caveman token savings; verified ai-main is sufficient and enabled caveman full.
task: compare-memory-and-output-token-efficiency
task_group: ai-main-memory-workflow
 task_outcome: success
cwd: /Users/tualek/ai-main
keywords: ai-main, Obsidian, caveman, AGENTS.md, context, tokens, cold-memory, prompt-profiles
---

### Task 1: Memory architecture and Obsidian viability

task: compare Obsidian memory with ai-main/Codex memory
task_group: ai-main-memory-workflow
task_outcome: success

Preference signals:
- User asked for an evidence-based check of what is installed and whether it truly saves tokens/context -> inspect configured paths and repository structure before recommending a change.

Reusable knowledge:
- ai-main already has per-repo knowledge, shared cross-tool memory, `full`/`lean`/`min` prompt profiles, and guard scripts that reduce reliance on prompt rules.
- `/Users/tualek/.codex/AGENTS.md` measured 12,897 bytes and 1,836 words; README documents a 4,000-token ceiling for the full profile.
- Obsidian should be treated as cold memory: retrieve only relevant notes/excerpts, never load the whole vault. It adds organization and multi-AI portability more than direct token savings.
- Obsidian skill expects `/mnt/d/Obsidian Vault/AI Research/`, but filesystem verification on this macOS setup found that path absent.

Failures and how to do differently:
- Verify configured vault paths on the current OS; do not infer availability from an installed skill.
- Avoid storing the same knowledge in Obsidian and ai-main memory; duplication increases context and can create stale/conflicting facts.

References:
- `/Users/tualek/.agents/skills/obsidian-vault/SKILL.md`
- `/Users/tualek/ai-main/README.md`
- Configured but missing path: `/mnt/d/Obsidian Vault/AI Research/`
- ai-main memory locations: `memory/SHARED.md`, `memory/codex/`, `memory/lessons/`, and `knowledge/<repo>.md`

### Task 2: Caveman behavior

task: verify caveman operation and select response compression level
task_group: response-style-and-token-efficiency
task_outcome: success

Preference signals:
- User explicitly said `/caveman full` -> keep responses compressed at full level until `/caveman off`, `normal mode`, or session end.

Reusable knowledge:
- Caveman compresses generated responses and may reduce later conversation-history size, but does not reduce system prompt, `AGENTS.md`, source code, or tool-output context.
- It is a formatting/prompt skill, not an automatic context-retrieval mechanism.
- Available controls: `/caveman lite`, `/caveman full`, `/caveman ultra`, `/caveman off`.

Failures and how to do differently:
- Do not claim the skill's stated “65%” reduction is a verified reduction for Thai or this workflow; it was only a claim in the skill documentation.

References:
- `/Users/tualek/.agents/skills/caveman/SKILL.md`
- Exact user command: `/caveman full`

## Thread `019ff914-9f48-7db3-aec9-3c772585e8f1`
updated_at: 2026-08-13T06:57:27+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-05-06-019ff914-9f48-7db3-aec9-3c772585e8f1.jsonl
rollout_summary_file: 2026-08-13T03-05-06-BsgF-jera_tab_minimal_watcher_fix_and_mr_squash.md

---
description: Minimal JERA tab race fix completed in Web MR; over-engineered API/Remote Config changes were excluded, Web commits squashed and force-pushed.
task: fix JERA tab missing after late feature-flag resolution and clean up MR scope
task_group: /Users/tualek/ohochat/oho-web-app JERA feature-flag workflow
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: JERA, MaxPanel, rt_jera_feature_enabled, immediate watcher, partner connections, MR 874, c67c0018, Luna, force-with-lease, over-engineering
---

### Task 1: Minimal Web-only JERA fix

task: replace mount-only JERA partner fetch with late-flag watcher and remove unrelated complexity
task_group: JERA tab race / GitLab MR cleanup
task_outcome: success

Preference signals:
- when the user clarified the bug, they said `completeClaimedDedup()` was unrelated and asked whether the tab disappears because it renders before the flag arrives -> keep future fixes on the actual JERA render/fetch path; do not pull Facebook webhook or dedup work into this scope.
- the user required `Luna 5.6 max` -> use that exact model when available; never substitute another model silently.
- the user wanted the smallest fix and to close unnecessary MR scope -> prefer one immediate watcher and focused tests over cache, realtime, retry, or cross-repo architecture.

Reusable knowledge:
- Root cause: `MaxPanel` mounted while `rt_jera_feature_enabled` was false, so the old `mounted()` fetch did not run. When the flag later became true, the tab rendered but `fetched_jera_partner_connections` remained empty.
- Final watcher in `components/MaxPanel.vue` uses `immediate: true`, returns when flag is false, when a request is in flight, or when connections are already non-empty, then calls `fetchJeraPartnerConnections()`.
- The fetch method itself has an in-flight guard. No interval, focus listener, session cache, or Firebase realtime listener remains, so the watcher does not continuously spam requests.
- `completeClaimedDedup()` belongs to `/Users/tualek/ohochat/oho-webhook` and is unrelated to this JERA UI path.

Failures and how to do differently:
- The initial over-engineered Web MR added `sessionStorage` Remote Config caching, realtime updates, window-focus retry, and error state. These were outside the direct late-flag bug and were removed.
- Direct agent spawning with `gpt-5.6-luna` failed because that API surface reported it unavailable; a Codex task-creation route supported Luna and completed the work. Do not replace the requested model with Sol/Terra without permission.
- Full Web tests still had four pre-existing verification-token failures; report them separately rather than claiming the full suite is green.
- Manual Smartchat/contact-tab UAT and a fresh Web build were not completed, so do not call the MR fully merge-ready solely from focused tests.

References:
- Final commit: `c67c0018d436139d1a74002055ec7e489698daed` (`fix: fetch JERA connections after feature flag resolves`).
- Final effective diff against `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608`: only `components/MaxPanel.vue` and `test/components/MaxPanel.spec.js`, `54 insertions(+), 5 deletions(-)`.
- Validation: watcher `4/4` passed; store/Remote Config suite `34/34` passed; `git diff --check` passed; full MaxPanel suite `7 passed, 4 pre-existing failures`.
- Branch `tk-sprint-2616/feature/jera-tab-is-missing` was squashed and pushed with `git push --force-with-lease`; remote matched local and worktree was clean.
- Web MR: `oho/oho-web-app!874`; API MR `oho/oho-api!1293` was intentionally not modified.

## Thread `019ff927-ae16-79f0-a3ae-eaee875badce`
updated_at: 2026-08-13T03:30:22+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-25-55-019ff927-ae16-79f0-a3ae-eaee875badce.jsonl
rollout_summary_file: 2026-08-13T03-25-55-GBgq-analyze_line_cronjob_token_webhook_health_checks.md

description: วิเคราะห์ cronjob และ health check ของ LINE แยกการตรวจ token/webhook configuration ออกจาก synthetic message pipeline; outcome สำเร็จ
 task: inspect LINE cronjob logic and distinguish access-token, webhook, and end-to-end messaging checks
 task_group: ohochat LINE integration monitoring
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: validate-business-integration-status, check_line_messaging_health, LINE, access-token, webhook-endpoint, bot-info, Stream-Chat, x-line-signature, oho-webhook, bulkWrite
---

### Task 1: LINE integration-status validation

task: trace `POST /cronjob/validate-business-integration-status` and document LINE checks
task_group: oho-api cronjob validation
task_outcome: success

Preference signals:
- เมื่อผู้ใช้ถามว่า cronjob ตรวจ “webhook หรือ access token” -> ควร trace source และสรุปทั้ง checks และ non-checks อย่างชัดเจน แทนการตอบจากชื่อ job

Reusable knowledge:
- Source: `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js`
- Selects non-disabled businesses and `connection_status: complete` channels; limits 2,000 businesses/channels and runs platform checks with concurrency 2.
- LINE calls `GET https://api.line.me/v2/bot/info` with the channel access token, then `GET https://api.line.me/v2/bot/channel/webhook/endpoint`.
- Validates webhook `active` and compares LINE’s endpoint (trailing slash trimmed) with `channel.line.webhook_endpoint`, falling back to `${webhook_endpoint}/line/webhook/${businessId}`.
- Non-429 errors mark `is_access_token_valid: false` and `connection_status: incomplete`; 429 is skipped without changing state.
- Inactive/mismatched webhook marks channel incomplete and stores `line.is_webhook_active` and `line.is_webhook_endpoint_valid`. Results are persisted with `channelModel.bulkWrite()`.
- Does not test real message delivery, queue/Stream Chat processing, LINE channel secret, or auto-recover incomplete channels.

Failures and how to do differently:
- Webhook endpoint errors are currently classified as token invalid, so distinguish token failure from webhook/API/network failure when interpreting status.
- No tests were found specifically covering `validateLineConnectionStatus`; source inspection is not runtime proof.

References:
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:210-305`
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.class.js:10-22`
- `oho-api/docs/modules/cronjob.md:196-214`

### Task 2: Synthetic LINE messaging health check

task: trace `check_line_messaging_health` in oho-cronjob and verify whether it checks LINE Platform directly
task_group: oho-cronjob synthetic monitoring
task_outcome: success

Reusable knowledge:
- `oho-cronjob` remote `origin/develop` at SHA `50f5149` contains Firebase HTTPS function `check_line_messaging_health`; schedule configuration was not present in the repository and live deployment was not verified.
- Function creates a synthetic LINE webhook payload, POSTs directly to OHO `/line/webhook/{businessId}`, stores the message in Firestore, waits 30 seconds, queries Stream Chat, and compares the text. Match => healthy; mismatch/error => unhealthy; state changes notify Slack.
- Its configured channel access token is not used to call LINE Platform APIs, so this job does not validate access tokens and does not test the true LINE Platform → OHO path.
- Receiver calls `/business/:businessId/line/verify-signature`; `oho-api/src/services/business/line/verify-signature/verify-signature.class.js` computes HMAC-SHA256 but currently logs mismatches and returns `{ ok: true }` instead of rejecting. Synthetic success is therefore not proof of real signature validation.
- For webhook monitoring, HTTP 200 is insufficient; inspect downstream terminal state such as Stream Chat or source-message metrics.

Failures and how to do differently:
- `rtk find` does not support compound predicates; use native `find` or `rg --files | rg` for file discovery.
- Initial `git ls-remote` failed due DNS/network; rerun with network permission succeeded. Keep local branch evidence separate from live remote/deployment evidence.

References:
- `oho-cronjob:functions/service/check-oho-line-messaging-health/check-oho-line-messaging-health-service.js:17-153`
- `oho-cronjob:functions/utils/send-oho-webook.js:11-30`
- `oho-webhook/src/controllers/line/line.controller.ts:38-210`
- `oho-webhook/src/controllers/line/handler.ts:93-108, 1186-1257`
- `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:12-61`

## Thread `019ff928-f2ca-73c0-b341-947ac2fac315`
updated_at: 2026-08-13T03:41:12+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-27-18-019ff928-f2ca-73c0-b341-947ac2fac315.jsonl
rollout_summary_file: 2026-08-13T03-27-18-nG9D-jera_mr_ponytail_cleanup_and_validation.md

---
description: Applied ponytail scope reduction to JERA feature-flag MRs in isolated worktrees; API timeout hardening and Web cache/retry deletion validated partially, but changes were not pushed and UAT remained unrun
task: JERA MR cleanup and ship-readiness implementation
task_group: /Users/tualek/ohochat / GitLab MR implementation workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: JERA, oho-api, oho-web-app, MR-1293, MR-874, ponytail, Remote Config, immediate watcher, feature_flags, Promise.race, timeout, isolated worktree, baseline test failures
---

### Task 1: Apply minimal JERA MR cleanup

task: Reduce over-engineering in API/Web JERA feature-flag MRs and validate merge readiness.
task_group: GitLab MR implementation and review
 task_outcome: partial

Preference signals:
- The user required ponytail simplification and approved deleting speculative `sessionStorage` cache, realtime listener, and focus/error retry behavior; similar work should prefer the smallest diff that still satisfies the source plan.
- The user initially required Luna 5.6 max, but after two unavailable-model errors explicitly said to proceed; do not substitute unavailable models without explicit authorization.

Reusable knowledge:
- Approved scope: keep Level 1 immediate `is_jera_feature_enabled` watcher and Level 3 API login `feature_flags`; defer Level 2 retry/error recovery.
- API changes in `/private/tmp/oho-api-mr1293`: 2-second fail-soft login feature-flag timeout, duplicate assertion removal, and pass-through assertion consolidation.
- Web changes in `/private/tmp/oho-web-mr874`: remove sessionStorage cache, realtime `onConfigUpdate` listener, `has_jera_partner_connections_error`, window-focus retry, and related tests; retain immediate watcher and in-flight guard.
- Validation passed: API Node 20, 2 suites/14 tests, SWC build, diff check; Web Node 22 targeted watcher 5/5, store 34/34, Nuxt build with `OHO_WEBSOCKET_URL=https://localhost`, diff check.
- Full MaxPanel-related suites have four baseline failures each on both base and patched worktrees; classify these separately from cleanup regressions.

Failures and how to do differently:
- Changes were made only in isolated detached worktrees and never committed/pushed; remote MR HEADs therefore did not contain the implementation. Before claiming merge readiness, commit/push and re-fetch MR diff/pipeline.
- Real Smartchat `?room=` refresh/deep-link and contact-tab UAT was not run; keep verdict NO-GO until those flows are verified.
- `Promise.race` timeout does not cancel the Firebase request. Add a delayed-rejection test or explicitly verify the promise is consumed after timeout before relying on the 2-second hardening.
- Isolated Web worktrees lack `node_modules`; temporarily symlink dependencies only inside the worktree, supply required config env (`OHO_WEBSOCKET_URL=https://localhost`), then remove the symlink and verify status.

References:
- `/private/tmp/oho-api-mr1293/src/services/authentication-member/login/login.hooks.js:17,103-134`
- `/private/tmp/oho-web-mr874/components/MaxPanel.vue:359-368`
- `/private/tmp/oho-web-mr874/plugins/firebase-remote-config.js:8-57`
- API MR: `oho/oho-api!1293`; Web MR: `oho/oho-web-app!874`
- User-authorized fallback after Luna failure: “งั้นก็ทำได้เลย ฉันเปลี่ยนเองไปแล้ว”

## Thread `019ff93b-c85a-7c20-af5f-a0727251ac2f`
updated_at: 2026-08-13T03:52:47+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-47-52-019ff93b-c85a-7c20-af5f-a0727251ac2f.jsonl
rollout_summary_file: 2026-08-13T03-47-52-NxJZ-fastship_facebook_recipient_send_error_gcp_diagnosis.md

---
description: Diagnosed Fastship Facebook message failures as recipient-specific Meta rejections, not a confirmed platform-wide outage; identified misleading generic UI mapping.
task: diagnose Fastship Facebook Messenger send failures from GCP logs
task_group: /Users/tualek/ohochat / Facebook production incident diagnosis
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Fastship, Facebook, Meta, GCP Logging, code 551, subcode 1893047, is_transient=false, get-error-message-send-message-fail.js, core-api--production
---

### Task 1: Diagnose Facebook recipient send errors

task: correlate Fastship Facebook send failures with raw Meta responses and determine whether Meta or OHO is responsible
task_group: Facebook production incident diagnosis
task_outcome: success

Preference signals:
- When the user asks whether Meta is broken and requests GCP logs, correlate business ID, Page ID, timestamps, raw platform errors, and successful sends before declaring an outage; separate UI wording from platform evidence.
- Keep the investigation read-only unless edits are explicitly requested.

Reusable knowledge:
- Fastship business `636b3215359066889e4edfe6` maps in the investigated logs to Facebook Page `595166650687417 (FastShip.co)`.
- The incident produced HTTP 400 Meta `OAuthException`, `code=551`, `error_subcode=1893047`, `is_transient=false`, with `This person isn't available right now/at the moment.`
- There were 11 matching failures from `10:00:07` through `10:07:31` ICT on 2026-08-13; no matching FastShip Page error was found after `10:07:31` through the checked window, while many other Fastship messages succeeded.
- Evidence supports a recipient/conversation-level restriction (possible block, deactivated/restricted account, or Meta recipient eligibility restriction), not a confirmed Meta-wide outage. `is_transient=false` means immediate retry is unlikely to help.
- OHO maps only Facebook `551/1545041` to the specific “ลูกค้าบล็อกช่องทาง” message in `oho-api/src/utils/get-error-message-send-message-fail.js:93-100`. Subcode `1893047` falls through to the generic platform-error fallback at lines `181-195`, explaining the misleading UI.

Failures and how to do differently:
- Broad `gcloud logging read` searches are noisy and truncate output. Narrow queries by `resource.labels.service_name="core-api--production"`, business/Page ID, exact subcode, and a tight timestamp range; output selected fields only.
- Do not infer a Meta outage from the generic UI message. Compare failed and successful sends and inspect the raw `code`, `error_subcode`, and `is_transient` fields.
- Logs included credentials in Axios URLs; never store or echo them. Replace with `[REDACTED_SECRET]`.

References:
- GCP project/service: `oho-platform` / `core-api--production`.
- Source mapping: `oho-api/src/utils/get-error-message-send-message-fail.js:93-100,181-195`.
- Raw error signature: `HTTP 400`, `OAuthException`, `code=551`, `error_subcode=1893047`, `is_transient=false`.
- Recommended conclusion wording: recipient-specific Meta rejection; advise contacting the customer through another channel rather than repeatedly retrying.

## Thread `019ff944-2c61-78d0-ab18-072ed186d997`
updated_at: 2026-08-16T18:03:59+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl
rollout_summary_file: 2026-08-13T03-57-02-TJMH-line_webhook_migration_hardening_and_webhook2_routing_review.md

---
description: Reviewed and hardened a LINE webhook migration workflow; identified production safety gaps, wrote a manifest-first plan, and verified webhook2 routing/observability constraints.
task: LINE webhook migration audit and safe webhook2 rollout planning
task_group: /Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint
 task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: LINE webhook, migrate-line-webhook.ts, allowed-host, manifest, rollback, checkpoint, register_webhook_at, webhook2.oho.chat, Cloud Run, URL map, Cloud Tasks, source-messages
---

### Task 1: Audit initial LINE webhook migration

task: Review whether the migration script satisfies DB discovery, whitelist detection, LINE verification, backup, DB update, and rollback requirements.
task_group: script-oho LINE webhook migration
task_outcome: success

Preference signals:
- When the user asked “ครอบคลุมแล้วรึยัง” and specified “backup ไว้ทั้งหมด” plus rollback, future reviews should trace the full mutation/recovery flow and cite exact files/lines before editing.

Reusable knowledge:
- Canonical endpoint construction is `${webhook_endpoint}/line/webhook/${businessId}` from `oho-api/src/services/channel/line/line.hooks.js:91,237`.
- Initial flow had test → PUT LINE → GET verify → DB update, but backup was persisted after `processChannel()` returned, leaving a crash window.
- Initial `--old-host` filter was not equivalent to an explicit “DB host outside whitelist” classification.

Failures and how to do differently:
- Do not treat post-mutation backup as sufficient. Persist and validate the complete immutable before-state manifest before the first PUT.
- Rollback must use a mutation journal, not merely manifest membership; dry-run-only entries must not be reverted.
- Backup all changed DB fields with presence markers, not only the endpoint.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts`
- Validation: `npm run migrate:line-webhook:help` passed; no DB/LINE mutation was run.

### Task 2: Plan migration hardening

task: Produce an implementation-ready plan without modifying the migration implementation.
task_group: script-oho migration planning
task_outcome: success

Preference signals:
- User explicitly said “ไม่ต้องงั้นนายทำ plan มาอย่างเดียวก่อน” -> stop at the plan artifact and do not implement or delegate until explicitly asked.
- User said `register_webhook_at` need not be updated -> migration and rollback must never write or restore `line.register_webhook_at`.

Reusable knowledge:
- Plan artifact: `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/plan.md`.
- Required design: explicit `--allowed-host`; DB+LINE inventory; immutable atomic manifest; manifest-bound apply; conditional DB writes; durable journal; exact `$set`/`$unset` rollback; request timeout/retry; non-zero exit on unresolved failure.
- Apply must not recompute candidates or accept a new scope outside the reviewed manifest.

Failures and how to do differently:
- Requested model `gpt-5.6-luna` was unavailable; available sub-agent models were `gpt-5.6-sol` and `gpt-5.6-terra`. Do not silently substitute a model when the user specifically requests delegation.

References:
- `--allowed-host=<hostname>`
- `--manifest=<path> --execute --confirm=<token> --yes`
- `--manifest=<path> --rollback --execute --confirm=<token> --yes`

### Task 3: Inspect hardened implementation and webhook2 routing

task: Re-review changed migration code and determine how webhook2 should route and how to detect failures.
task_group: webhook2 rollout and production verification
task_outcome: partial

Preference signals:
- User corrected that same-day traffic was self-generated: “ไม่นับวันนี้เพราะ ฉันเอามาใช้เอง” -> exclude known manual/test windows before inferring historical production usage.
- User challenged absolute safety claims; future rollout advice should state residual loss modes instead of promising “ข้อความไม่หายแน่ๆ”.

Reusable knowledge:
- Implemented files include `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, and a manifest-first `migrate-line-webhook.ts` with digest, atomic write, whitelist classification, journal phases, timeout/polling, and exact DB snapshots. `register_webhook_at` is excluded from payloads.
- `webhook2.oho.chat` certificate was observed `ACTIVE`; `/line` returned HTTP 200. URL-map host/path routing can send selected `fullPathMatch` paths to `webhook--production` while the matcher default remains `oho-webhook-production`.
- Multiple `fullPathMatch` entries in one route rule have OR semantics; use them for 2–3 businesses sharing the same backend/weight. Use `prefixMatch: /line/webhook/` to route all LINE webhook paths on webhook2.
- Core API cron validation uses DB `line.webhook_endpoint` when present and only falls back to `context.app.get('webhook_endpoint')`; no actual cron host-whitelist consumer was found.
- Cloud Tasks failure is a message-loss risk: `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135` logs task creation failure without rethrowing, while the LINE controller can still return 200 at `src/controllers/line/line.controller.ts:145-174`.

Failures and how to do differently:
- Never infer ingress topology from resource names alone. Verify DNS, frontend, certificate/target proxy, URL map/backend, and logs.
- Never count manual tests as historical production traffic.
- Verify the full chain: LINE ingress → `add_queue_success`/task creation → task processing → `sync_message_success` → user-visible message. HTTP 200 alone is insufficient.

References:
- URL map resource: `oho-webhook-lb`; matcher `line-webhook2-canary`.
- Core API: `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:267-283`.
- Webhook queue path: `oho-webhook/src/helpers/cloud_tasks.api.ts:125-135`; `oho-webhook/src/controllers/line/line.controller.ts:145-174`.
- Relevant statuses: `receive_webhook`, `add_queue_fail`, `add_queue_success`, `sync_message_inprogress`, `sync_message_fail`, `sync_message_success`, `add_retry_queue_fail`, `add_dead_letter_queue_fail`, `dropped`.

## Thread `019ff9cf-2564-7b40-af25-0306981e9625`
updated_at: 2026-08-13T06:44:50+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T13-28-50-019ff9cf-2564-7b40-af25-0306981e9625.jsonl
rollout_summary_file: 2026-08-13T06-28-50-Iwy9-minimal_jera_tab_watcher_fix_and_commit.md

---
description: Minimal Web-only fix for JERA tab missing after delayed Firebase flag resolution, validated with focused tests and committed on the feature branch
 task: fix delayed JERA feature-flag watcher in oho-web-app
 task_group: oho-web-app JERA MR workflow
 task_outcome: success
 cwd: /private/tmp/oho-web-mr874
 keywords: JERA, MaxPanel, is_jera_feature_enabled, immediate watcher, sessionStorage, onConfigUpdate, Firebase Remote Config, Jest, git diff --check, ffe26f0e
---

### Task 1: Fix delayed JERA tab rendering

task: Replace mount-only JERA connection fetching with a minimal reactive watcher.
task_group: oho-web-app JERA MR !874
task_outcome: success

Preference signals:
- The user required work only in `/private/tmp/oho-web-mr874`, explicitly forbade touching API MR `!1293`, and required inspecting/preserving dirty work first -> future similar work should verify worktree and scope before edits.
- The user required the smallest root-cause fix and explicitly prohibited cache, realtime listener, focus retry, extra error state, messaging/webhook changes, and merge-ready claims without UAT -> keep implementation narrow and disclose unrun UAT.

Reusable knowledge:
- `components/MaxPanel.vue` now uses an immediate watcher on `is_jera_feature_enabled`; it returns when false, when `is_fetching_jera_partner_connections` is true, or when `fetched_jera_partner_connections` is non-empty, otherwise it fetches.
- `plugins/firebase-remote-config.js` was restored to target base parity. The final patch removes `sessionStorage` cache, `onConfigUpdate`, focus retry, and `has_jera_partner_connections_error`.
- Focused watcher tests passed 4/4. Store/API-vs-browser Remote Config precedence tests passed 34/34. `git diff --check` passed.
- Full `MaxPanel.spec.js` retained 4 pre-existing verification-token failures outside the patch; report them separately rather than claiming the full suite passed.

Failures and how to do differently:
- Dependencies were initially absent (`sh: jest: command not found`); `npm ci` restored them. Node `v26.5.0` is outside the repo’s declared Node `^22.0.0` engine.
- Build and manual Smartchat/contact-tab UAT were not run. Required residual checks include delayed `false -> true`, hard refresh/deep-link `?room=...`, and connected/incomplete JERA flows.

References:
- Worktree: `/private/tmp/oho-web-mr874`
- MR: `oho/oho-web-app!874`
- Base SHA: `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608`
- Focused test: `npm test -- --runInBand test/components/MaxPanel.spec.js -t 'MaxPanel JERA partner connection fetch'`
- Store test: `npm test -- --runInBand test/store/index.spec.js`

### Task 2: Commit the approved fix

task: Commit the validated MR changes on the requested feature branch.
task_group: oho-web-app git workflow
task_outcome: success

Preference signals:
- After initially forbidding commits, the user explicitly authorized committing on `tk-sprint-2616/feature/jera-tab-is-missing` -> commit only after explicit later approval; do not push without separate authorization.

Reusable knowledge:
- Detached worktree was attached to `tk-sprint-2616/feature/jera-tab-is-missing`; only the three MR files were staged.
- Commit `ffe26f0e fix: fetch jera connections after flag resolution` created successfully.
- Worktree is clean, branch is ahead 1 of origin, and no push occurred.

Failures and how to do differently:
- The commit-helper skill said not to mutate git, but the user’s later explicit commit authorization superseded that constraint; preserve this distinction when interpreting similar rollouts.

References:
- Commit: `ffe26f0e`
- Branch: `tk-sprint-2616/feature/jera-tab-is-missing`
- Verification: `git rev-list --left-right --count origin/tk-sprint-2616/feature/jera-tab-is-missing...HEAD` returned `0 1`.

## Thread `019ffa0c-a821-7e62-9ee7-6f5b71ace63c`
updated_at: 2026-08-14T01:50:14+00:00
cwd: /Users/tualek/thaivagroups
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T14-36-01-019ffa0c-a821-7e62-9ee7-6f5b71ace63c.jsonl
rollout_summary_file: 2026-08-13T07-36-01-4exm-disable_cookie_wow_deploy_and_sync_main.md

description: ปิด Cookie Wow ใน Thaiva frontend, deploy production ผ่าน tag v1.7.6 และ fast-forward release เข้า main; lesson สำคัญคือ tag deploy ต้อง sync main ก่อนสรุปงาน
 task: disable-cookie-wow-and-release
 task_group: /Users/tualek/thaivagroups/thaiva-frontend
 task_outcome: success
 cwd: /Users/tualek/thaivagroups/thaiva-frontend
 keywords: Cookie Wow, Next.js, layout.tsx, git tag, v1.7.6, production deploy, main, fast-forward, dirty lockfiles

### Task 1: Disable Cookie Wow and deploy

task: Comment out the active Cookie Wow scripts in the Thaiva frontend, commit only that change, tag and deploy production.
task_group: frontend release/deployment
task_outcome: success

Preference signals:
- when asking to remove it temporarily, the user said: "เอาตัว cookie wow ออกไปก่อน comment code ก็ได้" -> preserve the old integration as comments when disabling temporarily.
- when asking for release, the user said: "commit และ deploy ปิด tag ให้ก่อนเลย" -> inspect existing dirty changes and deployment workflow, then commit only the requested scope.

Reusable knowledge:
- Active Cookie Wow loading was in `src/app/[locale]/layout.tsx`, with scripts for `https://cookiecdn.com/cwc.js` and config ID `LFXyXJb3exYPCcS7zqsnEMNM`.
- `package-lock.json` and `yarn.lock` had unrelated pre-existing modifications; they were intentionally left unstaged.
- Commit `606d216` (`fix: temporarily disable Cookie Wow`) changed only `src/app/[locale]/layout.tsx` by wrapping the script block in a JSX comment.
- Production tag workflow triggers on tags matching `v*`. Existing remote tags had advanced through `v1.7.5`, so `v1.7.6` was selected after checking the remote.
- Production verification via cache-busting curl eventually showed no `cookiecdn.com`, `cookieWow`, or Cookie Wow config ID in the returned HTML.

Failures and how to do differently:
- `npm run lint -- --file ...` could not run because `next` was absent from `node_modules`; record lint as unverified rather than passing it.
- `gh` could not inspect Actions because the stored GitHub token was invalid and private-repo API calls returned 404. Verify deployment from the production artifact/HTML when CI visibility is unavailable.
- Do not treat a text search hit as active runtime code; inspect comments, feature gates, and render/call reachability first.

References:
- `/Users/tualek/thaivagroups/thaiva-frontend/src/app/[locale]/layout.tsx`
- `606d216 fix: temporarily disable Cookie Wow`
- `v1.7.6`
- Remote tag peeled commit: `606d2169a0f21966aa4c5b0ce1e3dafccad3482d`

### Task 2: Sync release into main

task: Merge the deployed tag release into `main` and push it.
task_group: git release hygiene
task_outcome: success

Preference signals:
- after the tag deploy, the user corrected: "merge เข้า main ไว้ด้วยสิ" -> a tag-only production release is incomplete; ensure the main branch contains the deployed release before reporting completion.

Reusable knowledge:
- The release branch contained `v1.7.3` through `v1.7.6`, while remote `main` had already advanced to `v1.7.5` from another session. After confirming this with `git ls-remote`, `main` was fast-forwarded to `606d216` using `git merge --ff-only hotfix/disable-cookie-wow`.
- `git push origin main:main` succeeded; final remote `main` and tag `v1.7.6` point to the same commit.
- Final worktree intentionally still contains only the unrelated dirty lockfiles.

Failures and how to do differently:
- The initial release left production history only on tags/release branch and did not update `main`; add a mandatory post-tag check: compare `origin/main` with the deployed tag and fast-forward main when appropriate.

References:
- Final verification: `606d2169a0f21966aa4c5b0ce1e3dafccad3482d refs/heads/main`
- Final status: `## main...origin/main` with `M package-lock.json` and `M yarn.lock` only

## Thread `019ffa4b-53d6-7f53-ab12-aac360e69732`
updated_at: 2026-08-13T08:54:13+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T15-44-28-019ffa4b-53d6-7f53-ab12-aac360e69732.jsonl
rollout_summary_file: 2026-08-13T08-44-28-1ngu-diagnose_thaimetal_line_postback_gcp_logs.md

---
description: Diagnosed Thaimetal LINE rich-menu postbacks that appear as “กดปุ่ม”; production evidence shows external/custom postbacks are synced before automation detection, so suppression must be narrowly scoped.
task: diagnose-thaimetal-line-postback-and-ignore-scope
task_group: line-webhook-gcp-production-debugging
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: LINE, postback, rich-menu, Thaimetal, กดปุ่ม, GCP Logging, oho-webhook, contact-send-message, Auto Reply Trigger, URI action
---

### Task 1: Diagnose Thaimetal LINE postback display and ignore scope

task: trace production LINE events for business 6a422c6fae5398680bf7d837 and determine whether custom rich-menu button events can be ignored
task_group: line-webhook-gcp-production-debugging
task_outcome: success

Preference signals:
- The user asked to “หา log ใน gcp ให้หน่อยว่ามาแบบไหน” and asked whether these events can be ignored -> for similar incidents, inspect real production payloads and source flow before recommending a filter or code change.
- The user’s concern is specifically removing unwanted customer-facing button activity, not disabling all postback functionality -> preserve existing Oho Auto Reply Trigger behavior and propose the narrowest business/payload-scoped suppression.

Reusable knowledge:
- Production evidence for Thaimetal showed LINE events shaped as `type: "postback"` with only `postback.data`, commonly `แคตตาล็อค`; no `displayText` or label was present.
- Observed payload values also included `ผลงานและการออกแบบประตู-หน้าต่าง`, `ข้อควรรู้ก่อนติดตั้งประตู-หน้าต่าง`, and `ตัวแทนจำหน่ายอลูมิเนียมเส้นไทยเม็ททอล`.
- `oho-webhook/src/controllers/line/helper.ts:127-133` parses `entry.postback.data` using `qs.parse` and sets `text` from `label`. For raw Thai data without `label=...`, text is undefined.
- `oho-webhook/src/controllers/line/handler.ts:691-708` calls `/contact-send-message` with the transformed postback before pattern detection.
- `oho-api/src/utils/message-converter/youpin-to-stream.js:296-301` and `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:386-399` fall back to the visible text `กดปุ่ม`.
- `handleEventTypePostback` checks `art_id`/`arp_id` for automation, but that check occurs after message synchronization; merely having no ART/ARP does not prevent the Stream message/notification.
- Existing Oho-managed postbacks use payloads such as `art_id=...&label=...`; a global postback ignore would break legitimate Auto Reply Trigger behavior.
- Preferred product-level options from the evidence: use LINE `URI action` for buttons that only open an external system; otherwise namespace external postbacks (for example `external_action=thaimetal_catalog`) and suppress only that namespace for business `6a422c6fae5398680bf7d837`. Adding `label=แคตตาล็อค` changes the preview text but does not suppress the event.

Failures and how to do differently:
- Querying `jsonPayload` without a nested member failed: `INVALID_ARGUMENT: Cannot match a nested type 'jsonPayload'.` Use `jsonPayload.message:` or `SEARCH(...)` in Cloud Logging filters.
- Broad business-ID searches returned noisy, very large output. Narrow by `resource.labels.service_name`, `jsonPayload.message`, timestamp, and event type; summarize only timestamp, service, payload shape, and relevant IDs.
- GCP CLI initially could not write `~/.config/gcloud` due to permissions. Elevated execution was required for the historical payload aggregation; never preserve signed headers, reply tokens, channel tokens, or other secrets in memory.

References:
- `/Users/tualek/ohochat/oho-webhook/src/controllers/line/helper.ts:127-133`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/line/handler.ts:206-214`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/line/handler.ts:691-708`
- `/Users/tualek/ohochat/oho-api/src/utils/message-converter/youpin-to-stream.js:296-301`
- `/Users/tualek/ohochat/oho-api/src/services/contact-send-message/contact-send-message.hooks.js:386-399`
- GCP query pattern: `gcloud logging read 'timestamp>=... AND resource.type="cloud_run_revision" AND resource.labels.service_name="oho-webhook-production" AND jsonPayload.message:"/webhook/<businessId>" AND jsonPayload.message:"\"type\":\"postback\""' --project=oho-platform --format=json`
- Representative event: `type=postback`, `postback.data="แคตตาล็อค"`, business `6a422c6fae5398680bf7d837`, timestamp `2026-08-13T08:35:42Z`.

## Thread `019fff67-f5d7-74e3-b7d8-06a0b1faf7f3`
updated_at: 2026-08-14T08:35:41+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/14/rollout-2026-08-14T15-33-51-019fff67-f5d7-74e3-b7d8-06a0b1faf7f3.jsonl
rollout_summary_file: 2026-08-14T08-33-51-50Px-trace_keyword_broadcast_permission_403.md

description: Traced 403 on keyword creation and identified the exact member permission plus an authentication identity mismatch
 task: diagnose keyword API permission for broadcast group
 task_group: ohochat/oho-api authorization debugging
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: keyword, broadcast, permissions, role_permission, FeathersJS, JWT, 403, checkMemberPermission

### Task 1: Diagnose keyword broadcast permission

task: Determine which permission is required for POST `/core/latest/keyword` with `group: "broadcast"`.
task_group: ohochat/oho-api authorization debugging
task_outcome: success

Preference signals:
- The user asked directly in Thai, “มันต้องใช้ permission อะไร” (“which permission is required?”) -> future responses should lead with the exact permission string, then briefly show the source path.

Reusable knowledge:
- `oho-api/src/services/keyword/keyword.hooks.js` maps `group: "broadcast"` through the default `_.kebabCase()` branch and constructs `keyword.broadcast.create` for a create request.
- If the request includes `_id`, `action` becomes `update`, so the required permission is `keyword.broadcast.update`.
- The permission list is read from `params.member.role_permission.permissions`; `memberJWTStrategy` populates `role_permission` during JWT authentication.
- Keyword docs define the general mapping: `tag → keyword.contact-tag.{action}`, `contact_label → keyword.chat-tag.{action}`, `arp_group_id → keyword.arp-group.{action}`, other groups → `keyword.{kebab-case-group}.{action}`.

Failures and how to do differently:
- Do not replay a curl containing live credentials. Treat pasted Authorization headers/cookies as compromised and recommend revoke/rotation; use source inspection instead.
- The provided Authorization JWT and cookie JWT visibly contained different member identity claims, so re-login and capture a fresh request before diagnosing the wrong role as the definitive cause.

References:
- Exact permission: `keyword.broadcast.create`
- Hook logic: `/Users/tualek/ohochat/oho-api/src/services/keyword/keyword.hooks.js:380-409`
- Create hook order: `/Users/tualek/ohochat/oho-api/src/services/keyword/keyword.hooks.js:512-525`
- JWT role population: `/Users/tualek/ohochat/oho-api/src/auths/memberJWTStrategy.js:21-24`
- Permission documentation: `/Users/tualek/ohochat/oho-api/docs/modules/keyword.md:126-137`
- Exposed credentials: [REDACTED_SECRET]

## Thread `01a00e8b-895f-7940-acb9-9691f197cf38`
updated_at: 2026-08-17T07:23:15+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-17/referenced-chatgpt-conversation-this-is-an
rollout_path: /Users/tualek/.codex/sessions/2026/08/17/rollout-2026-08-17T14-07-00-01a00e8b-895f-7940-acb9-9691f197cf38.jsonl
rollout_summary_file: 2026-08-17T07-07-00-j3zG-oho_webhook_domain_mapping_cutover_audit.md

description: Audited OHO LINE webhook cutover from oho-webhook-production to webhook-production; found partial readiness, live image/env drift, old hostname still domain-mapped to old service, signature mismatch bypass, and Cloud Tasks error-swallowing risk
 task: audit-live-oho-webhook-domain-mapping-cutover
 task_group: ohochat-infrastructure-line-webhook
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: oho-webhook-production, webhook--production, webhook.oho.chat, webhook2.oho.chat, Cloud Run, URL map, DomainMapping, LINE signature, Cloud Tasks, OHO_WEBHOOK_URL, source-messages
---

### Task 1: Audit deployment, routes, and config parity

task: compare deployed OHO webhook revisions, routes, image digests, and redacted env configuration
task_group: ohochat-infrastructure-line-webhook
task_outcome: partial

Preference signals:
- The user asked for confirmation from source, deployment config, and runtime path, and wanted verified facts separated from production-only checks -> future infrastructure audits should explicitly separate repository evidence, live-cloud evidence, and unverified assumptions.
- The user said the new service would use the same image/env -> verify serving image digests and redacted env metadata independently rather than accepting the assertion.

Reusable knowledge:
- Both deployed revisions expose LINE routes `/line`, `/line/webhook/:businessId`, and `/line/message/:businessId`; static diff between commits `85a4da17` and `eb898476` showed no changes to the LINE controller, handler, router, Cloud Tasks helper, or Core API helper.
- Live images differ: old `oho-webhook-production-00149-vcc` serves `sha256:26cb7ee453df9d9d6c60f6c1efab80c3cccdc610a5410cfa8efe997fe17944bc`; new `webhook--production--eb898476--v1-85-0` serves `sha256:de0c69a1d7a76103c3424b2bfa2eb2ad4294b97e0b66191394e6547fa01e18ce`. Artifact tags map to `85a4da17` and `eb898476`.
- Redacted env comparison found common `OHO_API_URL`, `QUEUE_ID`, `USE_QUEUE`, MongoDB, and Redis configuration, but differences in `OHO_WEBHOOK_URL`, `QUEUE_SLOW_COUNT` (30 vs 20), secret source for `OHO_API_KEY`/TikTok secret, missing old LINE Notify/Sentry/Signoz variables, and new Meta MMD variables.
- `OHO_WEBHOOK_URL` should normally differ per service because `oho-webhook/src/helpers/cloud_tasks.api.ts:99` constructs callback URLs from it; new-service tasks should callback to `webhook--production`.

Failures and how to do differently:
- Do not claim image/env parity from source similarity or deployment intent. Re-check the serving revision digest and env source/value metadata immediately before cutover.
- Same route declarations do not prove runtime parity when env, observability, scale, and secret references differ.

References:
- `oho-webhook/src/controllers/line/line.controller.ts:30-31`
- `oho-webhook/src/index.ts`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99-135`
- `oho-webhook/deploy.sh`
- Safe operational values observed: old `OHO_WEBHOOK_URL=https://oho-webhook-production-avgjmmzg7q-as.a.run.app`, new `OHO_WEBHOOK_URL=https://webhook--production-avgjmmzg7q-as.a.run.app`; both `QUEUE_ID=oho--webhook--production`; `QUEUE_SLOW_COUNT` old 30/new 20.

### Task 2: Audit hostname routing and domain mapping

task: determine whether webhook.oho.chat actually routes to webhook--production and assess backend-only cutover behavior
task_group: ohochat-infrastructure-line-webhook
task_outcome: partial

Reusable knowledge:
- URL map `oho-webhook-lb` lists both hosts, but its `/line/webhook/` rule is old weight 0/new weight 100 only on the LB path. Default backend remains old `oho-webhook-production`.
- `webhook2.oho.chat` resolves through the LB and reached `webhook--production`; `webhook.oho.chat` resolves via CNAME `ghs.googlehosted.com.` to a Cloud Run DomainMapping whose `routeName` is still `oho-webhook-production`.
- Live request logs over an approximately two-minute sample showed `webhook.oho.chat` → old service: 52 LINE ingress requests, while `webhook2.oho.chat` → new service: 926 LINE ingress requests. Host inclusion in a URL map is not sufficient evidence that DNS uses that LB.
- DomainMapping status for `webhook.oho.chat`: `Ready=True`, `CertificateProvisioned=True`, `DomainRoutable=True`; current route target is old service.
- Cloud Run DomainMapping is a one-shot 100% remap, unlike weighted LB routing. Google documentation describes DomainMapping as Preview and recommends an external Application Load Balancer for production custom-domain routing.

Failures and how to do differently:
- Always check DNS, forwarding rule/target proxy, URL map, domain-mapping `routeName`, and service request logs together. Do not infer actual routing from URL-map host rules alone.

References:
- URL-map rule: `/line/webhook/`, old weight 0/new weight 100; default old backend.
- DomainMapping: `webhook.oho.chat` → `oho-webhook-production`.
- Read-only checks returned HTTP 200 for `https://webhook.oho.chat/line`, `https://webhook--production-avgjmmzg7q-as.a.run.app/line`, and `https://webhook2.oho.chat/line`.

### Task 3: Assess LINE signature verification and message-loss safety

task: verify whether LINE signature checking and end-to-end processing work after routing to the new service
task_group: ohochat-infrastructure-line-webhook
task_outcome: partial

Reusable knowledge:
- `oho-webhook/src/controllers/line/handler.ts:93-108` forwards the request body and `x-line-signature` to Core API `/business/:businessId/line/verify-signature`.
- Core API logs showed `/line/verify-signature` statuses `201: 9446` and `400: 554` in a recent 10,000-request sample; no observed 401 intersection. This supports connectivity/channel lookup, not cryptographic enforcement.
- `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:38-58` logs signature mismatch and returns `{ ok: true }`; invalid signatures are currently bypassed rather than rejected.
- `oho-webhook/src/helpers/cloud_tasks.api.ts` catches `createTask` failures and logs `Task create failed` without rethrowing. `oho-webhook/src/controllers/line/line.controller.ts:145-174` can then record `add_queue_success` and return 200, suppressing LINE redelivery.
- Recent new-service logs showed LINE handler errors, Core API POST failures, and task creation failures; one sample counted up to 205 handler errors and 16 task-create failures in 10 minutes. Do not claim zero message loss.

Failures and how to do differently:
- HTTP 200, Core API 201, or `add_queue_success` is not terminal delivery proof. Require ingress → task creation → callback → `sync_message_success` → persisted/Stream state.
- Before a 100% cutover, fix or compensate for swallowed task-creation failures, ensure `webhookEventId` idempotency/redelivery, and perform a real LINE-message canary.
- Do not call signature verification enforced until mismatch behavior rejects invalid signatures or an independently verified enforcement layer exists.

References:
- `oho-webhook/src/controllers/line/handler.ts:93-108, 1186-1207`
- `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:32-61`
- `oho-webhook/src/controllers/line/line.controller.ts:145-214, 324-362`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99-135`
- Useful status states: `receive_webhook`, `add_queue_success`, `add_queue_fail`, `sync_message_success`, `sync_message_fail`.

### Task 4: Locate health-check and hardcoded old-service references

task: identify health-check URLs and replay/logging references that must be reviewed for cutover
task_group: ohochat-infrastructure-line-webhook
task_outcome: partial

Reusable knowledge:
- `oho-cronjob@origin/develop:functions/config/default.json:30` uses `https://webhook.oho.chat/line/webhook/`; `functions/utils/send-oho-webook.js:15-16` appends the business ID. Same-host domain cutover should redirect this automatically; no URL change is needed.
- The synthetic health check waits 30 seconds and checks Stream Chat, but it does not call LINE APIs or prove real LINE Platform → OHO delivery. Live function deployment/schedule could not be verified because `cloudfunctions.functions.get` permission was denied in project `oho-cronjob`.
- `oho-api/src/services/incoming-webhook-log/replay/replay.hooks.js:219` hardcodes `oho-webhook-production` for Cloud Logging queries; during rollback/stabilization it should search both old and new services or become configurable.
- `oho-api/src/services/incoming-webhook-log/replay-failed-log/replay-failed-log.class.js` uses configured `webhook_endpoint` and therefore follows the hostname configuration.
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:43` references `webhook2.oho.chat` for a separate LINE endpoint migration flow; do not conflate it with backend-only domain cutover.

Failures and how to do differently:
- Do not claim health-check deployment or schedule verification when IAM blocks the live read.
- Distinguish endpoint references that follow the hostname from service-name references that can omit new-service logs.

References:
- `oho-cronjob/functions/config/default.json:30`
- `oho-cronjob/functions/utils/send-oho-webook.js:11-30`
- `oho-cronjob/functions/service/check-oho-line-messaging-health/check-oho-line-messaging-health-service.js:17-153`
- `oho-api/src/services/incoming-webhook-log/replay/replay.hooks.js:210-229`
- Permission error: `Permission 'cloudfunctions.functions.get' denied`.

## Thread `01a01d47-b087-73f2-a4b1-1d6c0eae945c`
updated_at: 2026-08-20T08:21:51+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T10-47-12-01a01d47-b087-73f2-a4b1-1d6c0eae945c.jsonl
rollout_summary_file: 2026-08-20T03-47-12-FxFO-line_webhook_migration_rollback_scope_senior_summary.md

---
description: Evidence-first LINE webhook migration audit found an eligibility bug, scoped a no-DB LINE-only rollback, and produced a senior Markdown report; final state was externally changed and must be revalidated before any write.
task: audit-line-webhook-migration-and-line-only-rollback
task_group: /Users/tualek/ohochat/script-oho LINE migration workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: LINE, webhook, Thai PBS, migrate-line-webhook.ts, manifest, migrate.journal.json, rollback, LINE-only, connection_status, line_other, webhook2.oho.chat, split-brain, Cloud Logging
---

### Task 1: Thai PBS migration eligibility audit

task: identify original Thai PBS LINE webhook and explain why migration selected it
task_group: LINE migration eligibility
 task_outcome: success

Preference signals:
- The user asked why Thai PBS qualified, requiring the exact `classification → eligible → apply` explanation rather than a superficial endpoint lookup.
- The user wanted historical LINE state distinguished from stale DB state; future audits should prioritize the immutable manifest’s captured LINE endpoint.

Reusable knowledge:
- Thai PBS original LINE endpoint: `https://openapi.thaipbs.net/line_webhook/v1/account/thaipbs`.
- Thai PBS DB before-state: `https://webhook.oho.chat/line/webhook/63511e3b5e964b28d3ba5ccb`.
- `migrate-line-webhook.ts` sets `eligible=true` when DB host is outside `--allowed-host`; LINE inspection changes classification to `line_other` but does not clear `eligible`, and apply filters on `eligible`. This allowed an external custom LINE endpoint to be migrated.

Failures and how to do differently:
- Add a hard exclusion/manual-review state for `line_other`; do not rely on `connection_status` as an eligibility guard unless the code explicitly enforces it.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:781-823`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:1146-1158`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-20260816154033-5ef5ef03.json`

### Task 2: External-domain migration inventory

task: enumerate migrated channels whose captured LINE endpoint was not `webhook.oho.chat`
task_group: migration inventory and manifests
task_outcome: success

Preference signals:
- When the user asked for IDs directly, stop runtime log exploration and provide exact business/channel identifiers and artifact paths.
- Do not infer real usage from DB endpoint, `connection_status`, HTTP 200, or migration eligibility.

Reusable knowledge:
- Correlate immutable manifests with migrate journals and count only actual mutation phases; exclude dry-run-only and `db_synced` entries when measuring LINE changes.
- Broad inventory artifact: `/Users/tualek/ohochat/line-migration-non-oho-old-domains.md` (615 channels, 179 businesses, 109 old LINE domains in the observed manifests).
- The incomplete-before-migration rollback pool was 237 channels / 32 businesses; 5 channels were later hard-deleted by LINE disconnect and cannot be rolled back through the tool.

Failures and how to do differently:
- A complex `jq` shell-to-Markdown pipeline failed from quoting. Generate structured JSON first, then render Markdown with Node.

References:
- `/Users/tualek/ohochat/line-migration-non-oho-old-domains.md`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-*.json`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-*.json.migrate.journal.json`

### Task 3: LINE-only rollback scope and senior report

task: derive and verify rollback scope without touching MongoDB, then summarize impact for senior leadership
task_group: rollback safety and management reporting
task_outcome: partial

Preference signals:
- The user’s final rollback predicates were: original LINE endpoint external; pre-migration status `incomplete`; current status still `incomplete`; no LINE state drift; exclude Thai PBS.
- The user explicitly said “อย่าพึ่ง rollbackนะ” and later requested Markdown; future agents must remain read-only until a fresh explicit execution command and should produce the report/artifacts first.
- The user requested LINE-only rollback: change LINE endpoint only and leave MongoDB untouched.

Reusable knowledge:
- Initial derived safe scope was 128 channels / 28 businesses; dry-run passed 128/128. A later read-only refresh found an external process had already changed 111 channels back to exact old endpoints, leaving 17 on `webhook2.oho.chat`.
- Latest verification artifact: `/private/tmp/line-128-current-state.json`, checked `2026-08-20T08:19:01.027Z`.
- Latest counts: `exact_old=111`, `target=17`, `other=0`, `unavailable=0`, active drift 0, DB target exact 128/128, current status incomplete 128/128, Thai PBS 0.
- Business grouping: 11 all changed, 14 all target, 3 mixed. The 111 changed channels create split-brain because LINE is external while MongoDB still says `webhook2`.
- Senior artifact: `/Users/tualek/ohochat/line-webhook-rollback-senior-summary.md`; it contains business IDs and complete 128-channel appendices with old URLs.

Failures and how to do differently:
- Existing rollback CLI restores MongoDB after LINE PUT and is unsafe for LINE-only use. It lacks a dedicated LINE-only mode/token/journal, JIT status recheck, and reliable compensation/reconciliation after PUT timeout or crash.
- Never reuse the original rollback command for LINE-only work. Implement and test a separate fail-closed flow, refresh LINE/Mongo state immediately before mutation, execute serially, GET-verify, and stop on conflict.
- The 111 endpoint changes were not performed by this agent; local dry-run journals had no executed/rolled-back entries, so actor is unknown.

References:
- `/Users/tualek/ohochat/line-webhook-rollback-senior-summary.md`
- `/private/tmp/line-128-current-state.json`
- `/private/tmp/line-rollback-executable-incomplete-20260814060805-d10d4e2e.json`
- `/private/tmp/line-rollback-executable-incomplete-20260816154033-5ef5ef03.json`
- Exact verification: `111/111` changed URLs match immutable old URL including path; `17` remain target; Mongo writes from this investigation: none.

## Thread `01a01d60-e36c-7140-9da6-1c95bb416e54`
updated_at: 2026-08-20T04:21:01+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T11-14-44-01a01d60-e36c-7140-9da6-1c95bb416e54.jsonl
rollout_summary_file: 2026-08-20T04-14-44-BWOU-meta_business_ai_page_permission_routing_analysis.md

---
description: วิเคราะห์ flow ขอ permission เพิ่มและ Meta Business AI สำหรับ Facebook Page เดิม; ยืนยันว่า webhook subscription ทำอัตโนมัติได้บางส่วน แต่ Default routing และ Business AI activation ต้องให้ Page admin ทำผ่าน Meta UI
 task: analyze-meta-business-ai-permission-and-routing-flow
task_group: /Users/tualek/ohochat / Meta Business AI Facebook onboarding
 task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, Facebook Page, permissions, reissue, subscribed_apps, subscribed_fields, standby, Conversation Routing, Default routing app, business_ai
---

### Task 1: Analyze Meta Business AI permission and routing flow

task: ตรวจ PDF ล่าสุดและ code เพื่อสรุป UX/API สำหรับ Page ที่เชื่อมต่อแล้ว
 task_group: Meta Business AI Facebook onboarding
 task_outcome: success

Preference signals:
- เมื่อผู้ใช้ถามเรื่อง “กรณีเชื่อมต่อช่องทางไปแล้ว มีปุ่มเพื่อขอสิทธิ์การเข้าถึงเพิ่มเติม” -> ควรออกแบบ flow สำหรับ Page เดิมโดยไม่บังคับสร้าง connection ใหม่
- ผู้ใช้ต้องการแยกประเด็น permission, webhook subscription, routing และ Business AI activation อย่างชัดเจน -> ควรตอบภาษาไทยแบบ evidence-first และไม่รวมทุกอย่างเป็น permission เดียว

Reusable knowledge:
- PDF ระบุ `Business AI opt-in checkbox` ในหน้าสุดท้ายของ standard connection flow; สิ่งนี้ไม่ใช่ Facebook permission dialog และ onboarding ปัจจุบันยังผ่าน Meta Business Suite/MBS
- OAuth reissue มีอยู่แล้วใน `oho-web-app/pages/business/_biz_id/setting/integration.vue` (`requestFbPagePermission`, `onReIssueFbPagePermission`, `handleReIssueFbPagePermission`) แต่ UI reconnect เดิมผูกกับ `connection_status === 'incomplete'`; ยังไม่มีปุ่มสำหรับ Page ที่เชื่อมสำเร็จแล้วแต่ต้องการเปิด Business AI ภายหลัง
- Create Facebook channel เรียก `requestPageSubscribedApp()` และส่ง fields ได้แก่ `messages`, `messaging_postbacks`, `messaging_referrals`, `message_echoes`, `message_reads`, `messaging_handovers`, `standby`, `feed` ไปที่ `POST /{PAGE_ID}/subscribed_apps`
- Facebook patch/reissue flow ตรวจ permissions และอัปเดต token แต่ไม่ได้เรียก `POST /{PAGE_ID}/subscribed_apps` ซ้ำ; Page เก่าจึงอาจไม่มี `standby` หลังเพิ่ม requirement ใหม่
- `standby` ต้องเปิดสองระดับ: app-level `POST /{APP_ID}/subscriptions` ด้วย App Access Token และ page-level `POST /{PAGE_ID}/subscribed_apps` ด้วย Page Access Token
- `subscribed_apps` จัดการ webhook fields ไม่ใช่ Conversation Routing หรือ Default routing app และไม่มีหลักฐานจาก public API ที่ยืนยันว่า OHO ตั้ง Default routing app แทน Page admin ได้โดยตรง
- แนะนำแยก UI เป็น `ขอสิทธิ์ Facebook เพิ่ม` สำหรับ OAuth/token และ `ตั้งค่า Business AI` สำหรับ activation/routing; หลัง Page admin ตั้งค่าใน Meta UI ให้มี `ตรวจสอบอีกครั้ง`

Failures and how to do differently:
- Live Facebook settings verification ไม่สำเร็จ (temporary block/robots denial) และ Meta developer docs บางหน้าตอบ 429; ห้ามอ้างว่า Page จริงหรือ routing ถูกยืนยันแล้ว
- OAuth reauthorization อย่างเดียวไม่สามารถสรุปว่า Business AI เปิดใช้งานหรือ Default routing เปลี่ยนแล้ว ต้องตรวจ `GET /{PAGE_ID}/business_ai`, routing configuration และ fresh-message runtime behavior แยกกัน

References:
- `/Users/tualek/ohochat/docs/meta-business-ai/[External] Business AI Integration Guide for Messaging Partners - v4.pdf`
- `/Users/tualek/ohochat/oho-web-app/pages/business/_biz_id/setting/integration.vue:1463-1495`
- `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js:8-24`
- `/Users/tualek/ohochat/oho-api/src/services/channel/facebook/facebook.hooks.js:458-487`
- Exact endpoint: `POST /{PAGE_ID}/subscribed_apps`
- Exact status endpoint from PDF: `GET /{PAGE_ID}/business_ai`

## Thread `01a01d68-a198-7300-b70e-054c80cb3a68`
updated_at: 2026-08-20T11:51:59+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T11-23-11-01a01d68-a198-7300-b70e-054c80cb3a68.jsonl
rollout_summary_file: 2026-08-20T04-23-11-evpK-meta_business_ai_review_repeated_cloud_run_startup_failures.md

---
description: Meta Business AI branch review found repeated Cloud Run startup crashes caused by missing preserved imports and Feathers whole-module hook exports; runtime fixes were pushed but final deploy success was not verified.
task: review-and-stabilize-meta-business-ai-feature-branch-for-staging
task_group: /Users/tualek/ohochat/oho-api Meta Business AI deployment/debugging
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-api
keywords: Meta Business AI, oho-1802, Cloud Run, Feathers hooks, ReferenceError, formingChatStreamPayload, formingCreateDataPayload, startup smoke test, GitLab pipeline, Stream Chat
---

### Task 1: Review branch staging readiness

task: review remote Meta Business AI branch across oho-api/oho-webhook
task_group: Meta Business AI staging review
task_outcome: partial

Preference signals:
- The user asked whether the branch was ready for staging and repeatedly challenged unsupported certainty; future reviews should report exact evidence and distinguish build/focused tests from deploy/canary readiness.
- The user prefers detailed Thai explanations with file paths, commits, logs, severity, and honest limits.
- Preserve unrelated dirty worktree artifacts and commit/push only explicitly scoped files.

Reusable knowledge:
- `standby` is evidence another app may own delivery, not proof of Meta Business AI; `message.ai_generated === true` is author identity, not activation or ownership.
- Approved Facebook wiring uses explicit `channel.meta_business_ai_enabled`, persists standby customer messages before suppressing OHO automation, and uses tenant-scoped `${businessId}@meta-ai` Stream identity with fallback.
- Focused tests, `git diff --check`, and HTTP 200 do not establish canary/deploy readiness; require captured payload replay and terminal Mongo/Redis/Stream verification.

Failures and how to do differently:
- No MR/spec was found (`glab mr list ... -F json` returned `[]`), so readiness should remain conservative.
- Backend removal of Remote Config lookup does not mean the workspace-wide `rt_meta_business_ai_enabled` flag is gone; classify runtime/UI/config hits across repos.

References:
- Remote SHAs: `oho-api a0157308c5efbd4121badbad949bb86f9b55b0ce`, `oho-webhook 3ac7ca224c408a1fb1691576ea236eb6005b752c`
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`

### Task 2: Diagnose and fix Cloud Run startup failures

task: repair runtime breakages introduced by Meta hook integration and push fixes
task_group: oho-api deployment debugging
task_outcome: partial

Reusable knowledge:
- Pipeline sequence: `31240`/`#95411` failed on missing `end-case` import; `31241`/`#95416` failed on the same missing imports in `no-case`; `31245`/`#95426` failed on Feathers `Error: 'formingChatStreamPayload' is not a valid hook type`; `31246`/`#95431` failed on `Error: 'formingCreateDataPayload' is not a valid hook type`.
- Root cause: Meta commit `39c42fb27` replaced existing import blocks instead of adding Meta imports alongside them, and exported helper functions from hooks modules passed wholesale to `service.hooks(hooks)`.
- Fixes: preserve `prepareCloseCaseContactUpdateData` and `emitChatSessionStatusUpdatedEvent`; register Facebook hooks as `service.hooks({ before, after, error })`; restore `STREAM_CHAT_SOURCE`/`loggerSendMessageToStreamChat`; restore `chatEngine` for self-assign.
- CI `.gitlab-ci.yml` only builds with SWC and deploys; it does not lint, run tests, or perform startup/service-registration smoke checks. Build success therefore missed runtime crashes.

Failures and how to do differently:
- Do not fix only the first crash. Audit all modified hook modules, all `service.hooks(hooks)` registrations, removed imports, and `no-undef` call sites before redeploying.
- Validate static guards themselves; the first hook-shape checker falsely passed because it mishandled `.hooks` path resolution.
- Focused validation was incomplete: build passed (`1562 files`), Facebook/self-assign tests passed, bot-send had 6 quick-reply expectation failures, and broad lint contained unrelated/pre-existing errors.

References:
- Pushed commit: `b803ae00b fix: restore hook runtime dependencies`
- Changed runtime files: `src/services/channel/facebook/facebook.service.js`, `src/services/bot-send-message/bot-send-message.hooks.js`, `src/services/contact/member-assign/self/self.hooks.js`
- Exact errors: `ReferenceError: prepareCloseCaseContactUpdateData is not defined`; `Error: 'formingChatStreamPayload' is not a valid hook type`; `Error: 'formingCreateDataPayload' is not a valid hook type`

### Task 3: Clarify excluded deploy/test artifacts

task: distinguish runtime self-assign fix from deploy-test helper files
 task_group: Git push scope clarification
task_outcome: uncertain

Preference signals:
- User said: “ไม่เอาไฟล์ selft ที่ไว้เทส deploy push ไป” -> future pushes should list exact included/excluded files and clarify ambiguous filenames before pushing.

Reusable knowledge:
- `package.json`, `scripts/check-feathers-hooks-shape.js`, and `.codegraph/` were excluded from `b803ae00b`.
- `self.hooks.js` was included because restoring `chatEngine` was a runtime fix; the user’s final intent about removing it was not confirmed.

References:
- Commit `b803ae00b`
- Excluded: `package.json`, `scripts/check-feathers-hooks-shape.js`, `.codegraph/`

## Thread `01a01dd5-0450-7923-a90f-1997e16484f0`
updated_at: 2026-08-20T07:25:12+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T13-21-34-01a01dd5-0450-7923-a90f-1997e16484f0.jsonl
rollout_summary_file: 2026-08-20T06-21-34-UCOc-meta_business_ai_staging_gates_owner_fix_develop_sync.md

description: Implemented Meta Business AI staging-gate fixes across oho-api/oho-webhook; committed locally, but staging deployment and live proof remain undone
 task: Meta Business AI staging readiness fixes
 task_group: /Users/tualek/ohochat
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, pass_thread_control, 928891643393937, 263902037430900, messaging_handovers, subscribed_apps, standby, origin/develop, 66233ae, canonical dedup, replay retry, Mongo, Stream, Node 20, staging UAT

### Task 1: Fix owner comparison, sync webhook baseline, and validate staging gates

task: Fix Facebook Business AI owner targeting, union-safe subscription, webhook develop sync, and staging-gate validation
task_group: Meta Business AI / Facebook Messenger onboarding
task_outcome: partial

Preference signals:
- when the user invoked ponytail and specified “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause” -> prefer the smallest root-cause diff; avoid one-item abstractions such as a dedicated `FACEBOOK_SUBSCRIBED_FIELDS` array.
- when the user said staging had not passed and challenged “staging ยังไม่ผ่านจะขึ้น uat ได้ยังไง” -> report lifecycle gates strictly as code validation/commit → staging deploy → live staging proof → staging pass → UAT; before staging deployment, say UAT is not reached rather than calling UAT evidence missing.
- when the user required honest validation and no premature readiness claim -> separate focused local tests/builds from Meta live subscription, replay, terminal Mongo/Stream state, and deployment evidence.

Reusable knowledge:
- `oho-api/src/utils/meta-business-ai.js` previously treated both `928891643393937` and `263902037430900` as known AI owners. `263902037430900` is Page Inbox/Business Suite according to the webhook-side contract; it must not satisfy the configured AI target check. Current logic compares `currentOwnerAppId` only with `targetAppId`, so Page Inbox ownership triggers `pass_thread_control` to the configured AI App ID.
- `request-page-subscribed-app.js` uses GET → union existing fields → POST → GET verification, matches the OHO app by `subscribed_apps[].id`, preserves marketing fields, adds `messaging_handovers` only in Facebook mode, and excludes `message_deliveries`.
- `oho-webhook` merge resolution preserved canonical per-event dedup in `handler.ts`; request-level `checkDuplicate` was not reintroduced. Internal replay/retry requests bypass the canonical Redis claim, retaining `66233ae` behavior.
- Local commits created: API onboarding `3ae53be72ba89bb18f1be60d9ae84840a7c6a174`; API authority `96a244b7a64136f56eb2fc4891cddb8e2895b7b0`; webhook merge `6f5418082240e8fc761274a2b8b04212c0e4105e`. They remained ahead of the remote feature branches and were not pushed.
- App-level standby and Page-level subscription verification are separate staging gates. The onboarding documents require app-level `POST /{APP_ID}/subscriptions`, Page-level `GET /{PAGE_ID}/subscribed_apps` matched by App ID, raw Meta replay, and terminal Mongo/Stream verification.
- `message_deliveries` is optional delivery observability, not a Business AI staging acceptance gate, because runtime AI identity/activation/handoff does not consume delivery receipts.
- Graph URL helpers are already centralized in both services (`graphUrl()`); Business AI status intentionally uses `api.facebook.com/v25.0`, while normal Graph calls use `graph.facebook.com/v25.0`.

Failures and how to do differently:
- `meta-business-ai.spec.js` and `member-send-message.hooks.spec.js` could not load under the available Node runtime because the old dependency stack failed with `TypeError: Cannot read properties of undefined (reading 'prototype')` in `buffer-equal-constant-time`/`jwa`. Node 20 was not available; rerun those suites in the repository’s Node `^20.0.0` environment.
- Do not treat focused tests, build success, or HTTP 200 as staging/UAT proof. No staging deploy, live Meta subscription inspection, Meta replay, or terminal Mongo/Stream verification occurred in this rollout.
- Keep unrelated dirty artifacts uncommitted and unstaged unless explicitly in scope; `.codegraph`, `.claude-worktrees`, and `plan.md` remained outside the scoped commits.

References:
- `/Users/tualek/ohochat/oho-api/src/utils/meta-business-ai.js`
- `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js`
- `/Users/tualek/ohochat/oho-api/src/services/channel/facebook/facebook.hooks.js`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/facebook.controller.ts`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts`
- `/Users/tualek/ohochat/docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- Focused API result: 3 suites / 12 tests passed (`get-page-business-ai-status`, `request-page-subscribed-app`, `facebook.hooks`).
- Focused webhook result: 3 suites / 24 tests passed (`facebook-canonical-events`, `facebook-meta-business-ai`, `facebook-dedup-events`).
- Both `npm run build` commands and `git diff --check` passed.
- Exact user correction: `staging ยังไม่ผ่านจะขึ้น uat ได้ยังไง`.

## Thread `01a01df6-bec3-7252-86b4-5299037a5b66`
updated_at: 2026-08-20T16:22:16+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T13-58-25-01a01df6-bec3-7252-86b4-5299037a5b66.jsonl
rollout_summary_file: 2026-08-20T06-58-25-WPC6-meta_mcp_and_meta_business_ai_staging_fix.md

---
description: Meta Developer Tools MCP was configured and OAuth-authenticated but Codex could not complete the Streamable HTTP handshake; separate Meta Business AI fixes were implemented, committed in both repos, and staging showed successful webhook/core requests but incomplete end-to-end proof.
task: configure_meta_mcp_and_fix_meta_business_ai_flow
task_group: /Users/tualek/ohochat Meta/Codex integration and Facebook webhook workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Developer Tools MCP, meta_developer_tools, mcp.facebook.com/devtools, OAuth, Sse(None), Streamable HTTP, Meta Business AI, contact.create, contact.hooks.js, Facebook webhook, Cloud Logging, staging-1, b687a89d, a4196c8
---

### Task 1: Configure Meta Developer Tools MCP

task: add and authenticate Meta Developer Tools MCP for Codex, then verify a real MCP tool call.
task_group: Codex MCP setup
 task_outcome: partial

Preference signals:
- The user asked “set mcp devtools meta ให้ใช้งานได้หน่อย” -> setup must include authentication and real tool-call verification, not just writing a URL into config.

Reusable knowledge:
- Codex config is `/Users/tualek/.codex/config.toml`.
- The working server entry is `[mcp_servers.meta_developer_tools]` with `url = "https://mcp.facebook.com/devtools"` and `enabled = true`.
- OAuth completed successfully, but actual MCP initialization failed with `expect accepted or json, got Sse(None), when process initialized notification response`.

Failures and how to do differently:
- Do not call this fully working until `devtools_discovery` succeeds. OAuth/config status alone is insufficient.
- The failure appears to be Codex/Meta Streamable HTTP interoperability, not missing credentials.

References:
- `codex mcp login meta_developer_tools`
- `codex mcp get meta_developer_tools`
- `Successfully logged in to MCP server 'meta_developer_tools'.`
- `codex-cli 0.146.0`
- `unexpected server response: expect accepted or json, got Sse(None)`

### Task 2: Fix Meta Business AI contact flow and logging

task: repair the downstream contact-create contract, expected read-event handling, and logging; preserve unrelated deploy/CI edits; commit both repos.
task_group: Meta Business AI backend/webhook fix
 task_outcome: success

Preference signals:
- The user said “ไฟล์ deploy กับ gitlab ci นายแก้ไขทำไมเอาออไว้เหมือนเดิมได้ไหม” -> preserve pre-existing dirty deploy/CI files and do not touch them without explicit scope.
- The user asked “แล้วไม่ต้องแก้ oho api หรอ” -> explain the root cause and distinguish required core API changes from optional logging changes.
- The user asked “commit ให้หน่อย ทั้งสอง repo” -> make separate commits in both repositories while excluding unrelated untracked files.

Reusable knowledge:
- `/contact/upsert` passed Meta Business AI fields into `/contact.create`, where Joi validation rejected them. The required downstream fix was in `oho-api/src/services/contact/contact.hooks.js`.
- Added validation for `meta_business_ai_enabled`, `facebook_delivery_authority`, `facebook_delivery_authority_observed_at`, and `facebook_meta_business_ai_observed_at`.
- Webhook read events with missing contacts can return 404 as an expected ignore case.
- Cloud Logging was normalized to one line in both services; this is observability-only and does not replace the core API fix.
- Verification: webhook build passed; Facebook tests passed 21/21; core contact/upsert tests passed 11/11 when restricted to `src` and run with a compatibility shim for removed Node utility APIs; Prettier and diff checks passed.
- Deploy/CI files were restored to no-diff state.

Failures and how to do differently:
- Normal Jest scanned `.claude/worktrees`, causing duplicate manual mocks, and legacy dependencies failed on Node 26 (`Utils.isRegExp`, `Utils.isDate`). Use `--runTestsByPath` with `--roots src` and the tested compatibility shim, or use the repo’s supported Node version.
- Never stage `.codegraph/`, `.claude-worktrees/`, `plan.md`, or other pre-existing untracked artifacts when committing targeted fixes.

References:
- `oho-api/src/services/contact/contact.hooks.js`
- `oho-api/src/services/contact/contact.hooks.spec.js`
- `oho-api/src/logger.js`
- `oho-webhook/src/controllers/facebook/handler.ts`
- `oho-webhook/src/helpers/logger.ts`
- `b687a89d fix: complete Meta Business AI contact flow`
- `a4196c8 fix: harden Facebook webhook handling`

### Task 3: Verify live staging message flow

task: determine whether an inbound Facebook message is processed normally on staging-1 after the commits.
task_group: live staging verification
 task_outcome: partial

Preference signals:
- The user asked whether “ข้อความเข้าละ ทุกอย่างทำได้ปกติเนอะ” -> provide evidence from live webhook/core/terminal state and distinguish confirmed steps from unverified downstream behavior.

Reusable knowledge:
- Core revision `core-api--staging-1--b687a89d--6203b324--v2-27-1` was live and handled repeated `/contact/upsert` requests with HTTP 201.
- Messaging-related core requests returned HTTP 200/201; webhook returned HTTP 200 and showed recent Facebook activity.
- No recent core error appeared in the first targeted window, but later queries found one core ERROR at `2026-08-20T16:19:01.388Z` and one webhook ERROR at `2026-08-20T16:14:57.069Z`.
- No queried `member-send-message/inbox` records were found, so end-to-end Stream/member-message delivery was not proven.

Failures and how to do differently:
- The user interrupted before error payloads and final correlation were retrieved. Keep the verdict partial/uncertain rather than claiming all behavior is normal.
- Future verification should correlate one unique test message through webhook receipt, `/contact/upsert`, message persistence, `/member-send-message/inbox` or Stream write, and exact error details.

References:
- `gcloud logging read 'resource.labels.service_name="webhook--staging-1" ...'`
- `gcloud logging read 'resource.labels.service_name="core-api--staging-1" ...'`
- Services: `webhook--staging-1`, `core-api--staging-1`
- Remaining error timestamps: `2026-08-20T16:19:01.388Z`, `2026-08-20T16:14:57.069Z`

## Thread `01a01ff8-eccf-7753-bac3-73ea2e052baf`
updated_at: 2026-08-21T03:50:43+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T23-20-02-01a01ff8-eccf-7753-bac3-73ea2e052baf.jsonl
rollout_summary_file: 2026-08-20T16-20-02-fC5p-staging_1_meta_ai_latency_handover_cli_mongodb_verification.md

---
description: Evidence-based staging-1 Meta Business AI latency audit, unresolved Facebook handover diagnosis, and verified MongoDB CLI workflow using transient Bitwarden credentials
 task: staging-1 observability and Meta Business AI runtime verification
task_group: ohochat production-debugging-workflow
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: staging-1, meta-business-ai, Cloud Run, gcloud logging, latency, ai_generated, take_thread_control, 2018001, mongosh, Bitwarden, MongoDB Compass, CLI
---

### Task 1: Compare Meta Business AI deploy latency

task: compare Cloud Run latency and errors before/after `meta-business-ai` deployment
 task_group: ohochat-gcp-observability
 task_outcome: partial

Preference signals:
- When the user asked whether deployment caused a “latency performance drop,” future investigations should compare matched real telemetry, endpoint mix, error rates, and feature-path timing before concluding.

Reusable knowledge:
- Current service: `core-api--staging-1`, project `oho-platform`, region `asia-southeast1`; deployed revision `core-api--staging-1--b687a89d--6203b324--v2-27-1` received 100% traffic.
- Before revision `b803ae00`: 492 requests, p50 13.0ms, p95 161.5ms, p99 15.8s, max 47.1s; 1 5xx. After revision `b687a89d`: 227 requests, p50 17.4ms, p95 266.1ms, p99 2.16s, max 15.0s; 0 4xx/5xx. Samples and endpoint mix were not matched, so this is not a definitive regression proof.
- Stream `/message` timing was healthy post-deploy (p50/p95 24/42ms vs 30/63ms pre); 4 `ai_generated` entries and 0 AI errors were observed.
- One `[GCP-metric]` timeout lasted 32.8s. `streamChat.js:72-85` batches metric writes; `gcp-metric.js:64-77` awaits `createTimeSeries`. This is an instrumentation/background path, not evidence that the Meta AI message handler is slow.

Failures and how to do differently:
- `gcloud monitoring time-series list` was unavailable and beta installation required an interactive prompt; use narrowly filtered Cloud Logging when Monitoring CLI is unavailable.
- Always sort latency values before percentile calculation. Broad `gcloud logging read` output is noisy/truncated; filter `log_id("run.googleapis.com/requests")`, service, revision, endpoint, and tight UTC windows.

References:
- `gcloud logging read 'log_id("run.googleapis.com/requests") AND resource.type="cloud_run_revision" ...'`
- `oho-api/src/sdk/streamChat.js`
- `oho-api/src/utils/gcp-metric.js`
- Error string: `4 DEADLINE_EXCEEDED ... Waiting for LB pick`

### Task 2: Diagnose `take_thread_control` recipient error

task: map Meta recipient/Page/App context for OAuth error 100/subcode 2018001
 task_group: ohochat-facebook-handover
 task_outcome: partial

Preference signals:
- The user provided an exact error and payload; future diagnosis should verify recipient ID, Page ID, Page token ownership, and target App before changing payload fields.

Reusable knowledge:
- Error: `(#100) ไม่พบผู้ใช้ที่แมตช์`, `OAuthException`, code `100`, subcode `2018001`.
- Payload used recipient `27336453096027036`, target app `643233536614550`, metadata `admin takeover`.
- Handover logic is in `oho-webhook/src/controllers/facebook/meta-business-ai.ts`; canonical recipient/control parsing is also in `facebook/block.ts`.

Failures and how to do differently:
- Diagnosis remained unresolved because the investigation initially selected the staging-4 Compass tab and did not complete live Page/App/token mapping. Verify the exact staging-1 channel before any conclusion.

References:
- `take_thread_control`, `pass_thread_control`, `target_app_id`, `2018001`
- `oho-webhook/src/controllers/facebook/meta-business-ai.ts`

### Task 3: Run read-only staging-1 MongoDB query through CLI

task: verify contact/channel Meta Business AI flags with `mongosh`
 task_group: ohochat-mongodb-cli
 task_outcome: success

Preference signals:
- User said `หยุดใช้ computer use` -> use CLI/API only from now on; do not open apps or use Computer Use for database checks.
- Preserve secrets: inject credentials transiently, never print them, and clear clipboard/process state after the query.

Reusable knowledge:
- `mongosh` is `/opt/homebrew/bin/mongosh`.
- Compass URI record: `/Users/tualek/Library/Application Support/MongoDB Compass/Connections/acb178fa-b4cd-40c2-9b20-39cb7d1e24ac.json`.
- The unlocked Bitwarden item `Oho Mongo stagiing` supplied the password transiently. Final read-only query succeeded against `oho-app-staging-1`.
- Verified contact `6a872802a3b0cdb0765c2675`: `status=bot`, `chat_status=fallback`, `meta_business_ai_enabled=false`.
- Linked Facebook channel `6a873328a3b0cdb0765c2eda`: `display_name=ChicaChicken`, `platform_id=1175851975615394`, `is_enable_chatbot=true`, `meta_business_ai_enabled=false`.
- Therefore OHO chatbot is enabled while Meta Business AI is disabled at both contact and channel levels.

Failures and how to do differently:
- This `mongosh` rejects standalone `--serverSelectionTimeoutMS`; place it in the URI query string.
- Strip a trailing slash from Compass connection strings before appending `/oho-app-staging-1`; otherwise `Invalid database name: /oho-app-staging-1` occurs.
- Nested shell quoting stripped JavaScript quotes once, causing `SyntaxError: Identifier directly after number`; prefer a temporary `.js` file or robust heredoc.

References:
- URI shape: `mongosh "${mongo_uri}/oho-app-staging-1?authSource=admin&serverSelectionTimeoutMS=5000" --quiet --norc --password "$mongo_password"`
- Final verified platform ID: `1175851975615394`

## Thread `01a02016-3517-7881-bd17-46c9326b74aa`
updated_at: 2026-08-20T16:54:41+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T23-52-01-01a02016-3517-7881-bd17-46c9326b74aa.jsonl
rollout_summary_file: 2026-08-20T16-52-01-fk14-meta_business_ai_subscribed_fields_review.md

description: ตรวจสอบ Facebook Meta Business AI subscribed_fields; พบว่ารายการ 8 fields ขาด messaging_handovers ส่วน message_deliveries เป็น optional observability และ 13 fields เป็น test-page baseline ไม่ใช่ minimum contract
 task: review_meta_business_ai_subscribed_fields
 task_group: /Users/tualek/ohochat/meta-business-ai
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, Facebook, subscribed_fields, messaging_handovers, standby, message_deliveries, feed, Page subscription, union verify

### Task 1: ตรวจสอบ Facebook Page subscription fields

task: review_meta_business_ai_subscribed_fields
task_group: Meta Business AI / Facebook onboarding
task_outcome: success

Preference signals:
- ผู้ใช้ถามเป็นภาษาไทยว่า `docs/meta business ai ขาด subscribed_fields ไหนไหม` -> งาน review ลักษณะนี้ควรตอบภาษาไทยและอ้างอิง repo/หลักฐานโดยตรง

Reusable knowledge:
- Base fields ใน `oho-api/src/utils/facebook/request-page-subscribed-app.js` คือ `messages`, `messaging_postbacks`, `messaging_referrals`, `message_echoes`, `message_reads`, `standby`, `feed`.
- Facebook mode เพิ่ม `messaging_handovers`; ดังนั้นรายการผู้ใช้ให้มาขาด `messaging_handovers`.
- `message_deliveries` ถูกระบุใน `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md` ว่า optional delivery observability ไม่ใช่ staging acceptance gate.
- `feed` ไม่ใช่ Meta Business AI field โดยตรง แต่ควรคงไว้หาก legacy feature ใช้งานอยู่.
- “13 fields” คือ baseline ของ test page; ไม่ใช่ minimum contract ที่ต้องเพิ่ม fields อื่นให้ครบเลข 13.
- Subscription update ต้อง GET existing → union required fields → POST → GET verify; ห้าม replace fields เดิม.

Failures and how to do differently:
- Direct Meta docs เปิดไม่ได้เพราะ `429 Too Many Requests`; ใช้ repo evidence และผลค้นจาก Meta Postman API Network พร้อมระบุข้อจำกัด ไม่ควรอ้างว่า direct docs ถูก verify สำเร็จ.
- `git status` จาก `/Users/tualek/ohochat` ได้ `fatal: not a git repository`; repo อยู่ใน subdirectories จึงต้องหา working repository ก่อนใช้ git commands.

References:
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:10-18`
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:70-74`
- `docs/meta-business-ai/HANDOFF.md:15,116`
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md:45,49-56`
- Exact error: `fatal: not a git repository (or any of the parent directories): .git`
- Exact web error: `Failed to fetch ... (429 Too Many Requests)`

## Thread `01a0227d-3bea-70b1-905c-ba05014690f2`
updated_at: 2026-08-21T06:15:26+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/21/rollout-2026-08-21T11-03-47-01a0227d-3bea-70b1-905c-ba05014690f2.jsonl
rollout_summary_file: 2026-08-21T04-03-47-rNB0-meta_business_ai_staging_readiness_handoff.md

description: Evidence-first Meta Business AI staging-1 readiness audit with local safety/performance fixes; local validation passed but staging/UAT/prod proof and commit state remained incomplete
 task: audit-and-harden-meta-business-ai-for-staging-uat-prod
 task_group: /Users/tualek/ohochat
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, oho-api, oho-webhook, staging-1, standby, ai_generated, facebook_delivery_authority, fallback schedule race, Firebase Remote Config, Cloud Tasks, Mongo primary, Stream, performance baseline, handoff

### Task 1: Local Meta Business AI hardening and staging readiness

task: audit-and-harden-meta-business-ai-for-staging-uat-prod
task_group: Meta Business AI backend/webhook release workflow
task_outcome: partial

Preference signals:
- when the user said “เบื้องต้น commit ไปที่ brach working” -> commit only on the named working feature branches; keep push/deploy/config/replay as separate approvals.
- when the user asked “ขอให้ทำ handoff ก่อนได้ไหม” and then “ได้ไหม” -> provide the evidence-based handoff before taking the next deployment or mutation step.
- the user’s scope remained `oho-api` and `oho-webhook`; preserve unrelated dirty files and do not include `.codegraph/`, `.claude-worktrees/`, `plan.md`, or `/private/tmp` diagnostics in intended commits.

Reusable knowledge:
- Pinned branches at audit time: API `8e2370c44ce3a3fc8b9c01e2d97f57adc9f7e7ed`; webhook `9960270e6595366c417ecc2e7bc68e1b16c74aa4`.
- Local validation passed: API 12 focused suites / 162 passed / 2 skipped; API SWC compiled 1,564 files; webhook 3 focused suites / 28 passed; webhook `tsc -p tsconfig.release.json --noEmit`; formatting and `git diff --check`.
- Local fixes covered immediate `standby` suppression, fail-closed authority send guards, new-contact authority initialization, selective bulk takeover, Firebase Remote Config 1.5-second fail-soft timeout with single-flight caching, and delayed fallback-task race protection.
- Scheduled fallback protection uses an active schedule lookup with `.read('primary')`, `.maxTimeMS(5000)`, and fail-closed skip behavior. It also skips if `last_contact_date` is newer than the schedule creation time.
- Staging baseline: API p50 19 ms, p95 217 ms, p99 7.63 s, max 31.68 s; `/contact-send-message` max 31.68 s versus 563 ms on the prior revision. Webhook sample size was only 14 requests with max 21.43 s, insufficient for a ship verdict.
- Custom-domain webhook traffic and direct Cloud Run Meta callback traffic used different services; validate both routes after deployment.

Failures and how to do differently:
- Do not claim staging/UAT/prod readiness from focused tests or HTTP 200. Required evidence still includes captured-payload replay, terminal Mongo/Redis/Stream state, real Graph take/return behavior, latency/error comparison, canary, and rollback.
- Credentials/permissions prevented exact staging Page/Contact Mongo inspection and target Stream inspection; local credentials pointed to a different dataset/app.
- The rollout authorized commits on the working branches, but no actual commit command/output is present in the evidence. Verify `git status`, `git log`, and commit SHAs before stating that commits exist.
- The latest user request prioritizes a handoff; prepare that artifact and explicitly list what is verified, not run, and required for staging approval.

References:
- `/Users/tualek/ohochat/docs/meta-business-ai/staging-1-readiness-2026-08-21.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/handoff-2026-08-21-prod-overlap-staging.md`
- `/Users/tualek/ohochat/docs/meta-business-ai/HANDOFF.md`
- `oho-api/src/utils/meta-business-ai.js`
- `oho-api/src/firebase-remote-config.js`
- `oho-api/src/services/bot-send-message/schedule/schedule.class.js`
- `oho-webhook/src/controllers/facebook/meta-business-ai.ts`
- `oho-webhook/src/controllers/facebook/handler.ts`
- Exact verification string: `Test Suites: 12 passed, 12 total; Tests: 2 skipped, 162 passed, 164 total`
- Exact readiness verdict: `ยังไม่พร้อม deploy staging-1 และยังไม่ได้ขอ confirmation`

## Thread `01a03185-0c19-7bf2-9a56-536792abf3b2`
updated_at: 2026-08-24T10:16:19+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T09-06-38-01a03185-0c19-7bf2-9a56-536792abf3b2.jsonl
rollout_summary_file: 2026-08-24T02-06-38-x1yq-meta_business_ai_webapp_rereview_fetch_fanout_blocker.md

---
description: Review-only re-review of Meta Business AI web-app diff found correct sender identity and request refresh behavior, but an unconditional per-client contact fetch is a P1 performance/scope blocker; tests passed locally while lint and staging remained unverified
task: review_meta_business_ai_web_app_working_diff
task_group: /Users/tualek/ohochat/oho-web-app / Meta Business AI frontend review
task_outcome: partial
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Meta Business AI, ai_generated, @meta-ai, chat/request created, handleSmartchatRealtimeUpdate, refreshChatRoomBadgeRealtime, DEFAULT_UPDATE_FIELDS, API fan-out, Jest, eslint, code-review
---

### Task 1: Re-review Meta Business AI web-app diff

task: review_meta_business_ai_web_app_working_diff
task_group: Meta Business AI frontend review
 task_outcome: partial

Preference signals:
- When the user said “review อีกรอบ”, the agent performed a fresh review rather than relying on the previous verdict; similar follow-ups should re-pin the current worktree/diff and revalidate earlier assumptions.
- The review stayed review-only, did not edit/stage/commit/push, and excluded unrelated untracked worktrees/files; preserve this boundary for similar user requests.
- The user expects Thai, evidence-first findings with severity and exact paths when reviewing Meta Business AI.

Reusable knowledge:
- Current tracked diff was on branch `tk-sprint-2616/feature/oho-1802-meta-biz-ai`, HEAD `89b81b1f3e4ddd4c4270d6048aabcfd811c30b10`, across five files: `components/Smartchat/Conversation.vue`, `plugins/smart-chat-helper.js`, `store/modules/websocket.js`, `test/plugins/smart-chat-helper.spec.js`, `test/store/modules/websocket.spec.js`.
- Sender implementation is correct in principle: `message.ai_generated === true` or `user.id` ending `@meta-ai` maps to existing sender type `bot`; `getSender` returns `Meta AI`; the AI check precedes `@inbox`, preserving the fallback `{businessId}@inbox + ai_generated:true` contract. `Conversation.vue` reuses sender type for bot/right-side bubble styling.
- Backend request flow sets `status='request'` in `oho-api/src/services/contact/bot-assign/request/request.hooks.js`; emitted `chat/request created` payload contains `contact_id` but not the full status. The prior web-app badge path `refreshChatRoomBadgeRealtime` early-returns when both unread/unresponded flags are false, so the current room did not refresh until a room switch.
- `handleSmartchatRealtimeUpdate` already supports authoritative fetch/merge when passed `_id=contact_id`, `DEFAULT_UPDATE_FIELDS`, and `is_fetch_contact:true`.
- Focused Jest validation passed after isolating the real files: `npm test -- --runInBand --silent --runTestsByPath ...` → 2 suites / 116 tests passed. The first broad path run also collected duplicate tests from `.claude-worktrees`; use `--runTestsByPath` or exclude worktrees in this checkout.

Failures and how to do differently:
- P1: `store/modules/websocket.js:308-317` unconditionally dispatches `handleSmartchatRealtimeUpdate` with `is_fetch_contact:true` for every `chat/request created` event received by every connected client. This causes API fan-out even when the client is not viewing that room and both badge flags are disabled, violating the repo rule that disabled feature behavior should be unchanged. Preserve the existing badge-refresh behavior and narrow direct fetch to the currently open room/necessary condition, or otherwise prove the fetch is required for all clients.
- P3: `Conversation.vue:2590-2596` calls `getSenderType()` but recomputes `is_agent`; use `sender_type === 'agent'` as the source of truth to avoid duplicated classification.
- P2: `test/plugins/smart-chat-helper.spec.js:30-37` supplies both `ai_generated:true` and `business-id@meta-ai`, so it does not independently validate suffix fallback. Add `@meta-ai` without `ai_generated`.
- ESLint was not verified because the checkout has no local `eslint` executable (`npm ls eslint --depth=0` showed empty; command failed with `./node_modules/.bin/eslint: No such file or directory`).
- No staging/UAT proof was obtained; focused tests and `git diff --check` do not establish deploy readiness.

References:
- `store/modules/websocket.js:299-317` — `chat/request created` listener and unconditional fetch dispatch.
- `store/modules/smartchat.js:774-783` — `refreshChatRoomBadgeRealtime` early return when both badge flags are disabled.
- `oho-api/src/services/contact/bot-assign/request/request.hooks.js:56-67` — request endpoint forces `status='request'`.
- `plugins/smart-chat-helper.js:51-112` — Meta AI author detection and sender naming.
- `components/Smartchat/Conversation.vue:2588-2611` — corner bubble classification.
- `test/plugins/smart-chat-helper.spec.js:30-75` — sender tests, missing isolated suffix case.
- `test/store/modules/websocket.spec.js:116-161` — request-event test currently codifies unconditional fetch.
- Validation command: `npm test -- --runInBand --silent --runTestsByPath /Users/tualek/ohochat/oho-web-app/test/plugins/smart-chat-helper.spec.js /Users/tualek/ohochat/oho-web-app/test/store/modules/websocket.spec.js` → `Test Suites: 2 passed, Tests: 116 passed`.

## Thread `01a03271-ccdf-7331-a5f9-270c1b5c2923`
updated_at: 2026-08-24T06:49:56+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T13-25-13-01a03271-ccdf-7331-a5f9-270c1b5c2923.jsonl
rollout_summary_file: 2026-08-24T06-25-13-41hN-staging_1_meta_business_ai_performance_runtime_audit.md

---
description: Read-only GCP staging-1 audit after Meta Business AI deployment; global latency did not regress, but a deployed emitter bug breaks realtime contact/badge updates after successful AI messages.
task: audit-staging-1-meta-business-ai-performance-and-runtime-errors
task_group: /Users/tualek/ohochat / GCP staging observability and Meta Business AI
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, staging-1, Cloud Run, gcloud logging, ai_generated, businessChannel, updateMetaBusinessAiContactStatus, contact/upsert, Cloud Tasks, Stream, 0075eedb
---

### Task 1: Audit staging performance and feature runtime

task: compare matched pre/post Cloud Run telemetry and trace Meta AI message delivery.
task_group: GCP staging performance diagnosis
task_outcome: partial

Preference signals:
- when asked to check whether deployment caused a performance drop, the user expects matched UTC windows, endpoint mix, error rates, and feature-path timing—not conclusions from HTTP 200 or broad logs.
- the final response separated verified performance findings from unverified CPU/RAM/terminal-state claims and used Thai evidence-first reporting.

Reusable knowledge:
- GCP target is project `oho-platform`, region `asia-southeast1`; `core-api--staging-1` revision `core-api--staging-1--0075eedb--6203b324--v2-27-1` served 100% traffic.
- Matched windows were pre `2026-08-23T08:35:19.295000Z–19:31:45.647587Z` and post `2026-08-23T19:31:45.647587Z–2026-08-24T06:28:12Z`.
- Aggregate request metrics: pre `n=163 p50=15.8ms p95=495.7ms p99=2.90s max=34.6s`; post `n=632 p50=16.6ms p95=190.4ms p99=2.59s max=41.5s`; no 5xx in either window. Non-OPTIONS p95 improved from 1.991s to 0.205s.
- Nine unique `ai_generated` messages each correlated to Stream `/message 201` within 34–96ms; Stream calls were ~22–30ms. One `take_thread_control` took 1.114s; four `pass_thread_control` calls took 1.907–2.080s, with no OAuth/handoff failures.
- GCP metric `DEADLINE_EXCEEDED` errors are background instrumentation noise (`streamChat.js` → `ScheduledDataPusher` → `gcp-metric.js`), not proof that Meta AI message handling is slow.

Failures and how to do differently:
- `gcloud` initially failed because sandboxed execution could not write `~/.config/gcloud`; use read-only elevated commands when necessary.
- Large JSON log queries truncated and failed parsing; split by bounded time windows and aggregate with sorted `gcloud logging read` output.
- `gcloud monitoring time-series` was unavailable, so do not claim CPU/RAM/instance saturation from this audit.

References:
- Log filter: `log_id("run.googleapis.com/requests") AND resource.type="cloud_run_revision" AND resource.labels.service_name="core-api--staging-1"`
- Revision: `core-api--staging-1--0075eedb--6203b324--v2-27-1`

### Task 2: Diagnose Meta AI functional defect

task: trace feature-specific runtime errors to deployed source and determine user-visible impact.
task_group: Meta Business AI post-deploy correctness
 task_outcome: partial

Preference signals:
- when runtime logs reveal a feature-specific error, the user expects deployed-SHA/source correlation and distinction between successful message delivery and successful UI/state propagation.
- when local worktree drift is detected, preserve other sessions’ changes; inspect the deployed SHA with `git show` and do not edit or revert without authorization.

Reusable knowledge:
- Nine `[member-send-message/inbox] update meta business ai contact status FAIL!` errors matched nine AI replies. Error text: `businessId or channel paths is required`.
- Deployed `oho-api/src/services/member-send-message/inbox/inbox.hooks.js` called `businessChannel(businessId)` without a path after Stream delivery. `oho-api/src/socket.io.js:20-24` requires a path and throws.
- Therefore AI messages reached Stream, but `contact/profile updated` and unread/unresponded realtime broadcasts could be skipped, leaving contact/badge UI stale while HTTP remained 201.
- Fourteen `contact/upsert` 404s were caused by standby `read` events with `is_upsert:false`; requests were only ~14–54ms, so treat as error noise unless further evidence links them to a real delivery issue.
- A quiet refresh from `2026-08-24T06:28:12Z` to `06:46:01Z` showed zero new feature errors, core 5xx, or webhook ERROR logs; this does not prove a fix.

Failures and how to do differently:
- Do not call Meta AI ready merely because Stream writes succeed; verify contact state, websocket broadcasts, and terminal datastore state.
- Do not attribute isolated 12–35s tails to the emitter bug without trace-level causal evidence.

References:
- Deployed SHA: `0075eedbc4943621dd236bcd8e1f1662186b53b4`
- Error: `businessId or channel paths is required`
- Files: `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:262-270`; `oho-api/src/socket.io.js:20-24`
- Webhook revision: `webhook--staging-1--e3b35076--v1-85-0`

## Thread `01a03276-58b0-7101-bb0e-2909ee1da2ff`
updated_at: 2026-08-24T07:30:45+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T13-30-11-01a03276-58b0-7101-bb0e-2909ee1da2ff.jsonl
rollout_summary_file: 2026-08-24T06-30-11-mh6n-meta_business_ai_ponytail_hardening_and_runtime_gates.md

---
description: Ponytail hardening for Meta Business AI on oho-api/oho-webhook; local fixes and focused validation passed, but staging/runtime proof remains intentionally incomplete
 task: meta-business-ai-backend-webhook-ponytail-hardening
 task_group: /Users/tualek/ohochat
 task_outcome: partial
 cwd: /Users/tualek/ohochat
 keywords: Meta Business AI, oho-api, oho-webhook, Ponytail, chat_status, is_unresponded, primary retry, authority guard, denylist, k6, T9.1, T9.2, T9.3, staging
---

### Task 1: Meta Business AI backend/webhook hardening

task: Implement minimal Meta Business AI fixes on `tk-sprint-2616/feature/oho-1802-meta-biz-ai`.
task_group: oho-api + oho-webhook Meta Business AI
 task_outcome: partial

Preference signals:
- User said “อย่าแก้ Redis lease หรือ matcher ก่อนมี runtime evidence” -> do not modify Redis lease, ownership matcher, or adjacent contracts without captured runtime evidence.
- User required minimal Ponytail scope and preservation of dirty worktrees -> do not commit, stage, push, reset, or broaden into `oho-web-app`.
- User expects exact validation boundaries and honest runtime gaps -> distinguish focused tests/builds from staging/UAT proof.

Reusable knowledge:
- API authority fields are guarded in `src/services/contact/contact.hooks.js`; internal `/contact/upsert` passes `__fromContactUpsert: true`, while external providers are rejected with `Meta authority fields require /contact/upsert`.
- T6 read-receipt lookup retries primary once only when secondary misses and `is_upsert=false`, using `.read('primary').maxTimeMS(5000)`.
- T3 status handling is deliberately split: chat-status patch/profile emit failure is logged, then `is_unresponded` clearing still runs in its own fail-soft block.
- Load test required scenarios fail fast on missing config; optional LINE is omitted when incomplete; takeover is not part of the performance run.
- Final local validation: API focused 3 suites/20 tests; inbox follow-up 1 suite/6 tests; webhook focused 2 suites/21 tests; webhook build/release type-check; API build; Prettier; syntax checks; `git diff --check`.
- Runtime gates remain: staging replay, actual k6 traffic, terminal Mongo/Redis/Stream verification, real Graph takeover/return, canary, rollback, and T9.1/T9.2/T9.3 evidence.

Failures and how to do differently:
- API Jest initially failed before executing tests because Jest scanned `.claude/worktrees` duplicate mocks and Node/dependency compatibility errors (`Utils.isRegExp`, `Utils.isDate`, `buffer-equal-constant-time`). Isolate with `--roots src` and a temporary compatibility shim; report environment blockers separately.
- Initial k6 inspection failed because Trend metrics collided with exported scenario function names. Rename metrics (`memberSendFbOffTrend`, etc.).
- A first webhook denylist patch iterated all entries/events and returned true for any denial, incorrectly blocking allowed messages in mixed batches. It was removed from the candidate and its test deleted; per-event denylist behavior is separate future work.

References:
- Branch: `tk-sprint-2616/feature/oho-1802-meta-biz-ai` in both repos.
- API: `src/services/contact/contact.hooks.js`, `src/services/contact/upsert/upsert.class.js`, `src/services/contact/upsert/upsert.hooks.js`, `src/services/member-send-message/inbox/inbox.hooks.js`, `src/services/channel/facebook/facebook.hooks.js`, `src/utils/meta-business-ai.js`.
- Webhook: `src/controllers/facebook/block.ts`, `src/controllers/facebook/meta-business-ai.ts`.
- Load test: `load-tests/meta-business-ai.js`, `load-tests/meta-business-ai.var.json.example`.
- No commit/stage/push/deploy was performed.

### Task 2: Chat-status isolation and lifecycle load-test correction

task: Ensure `is_unresponded` clearing continues after chat-status failure and align lifecycle self-assign load-test payload with endpoint contract.
task_group: oho-api inbox hook + k6 lifecycle scenario
 task_outcome: success

Preference signals:
- User explicitly requested removing the early return so clearing continues after `chat_status` failure -> preserve independent failure handling and regression coverage.
- User specified self-assign payload `{ team_id }` and removal of `assign_member_id` -> use the real endpoint contract and keep config minimal.

Reusable knowledge:
- `updateMetaBusinessAiContactStatus` now logs chat-status failure but continues into the `is_unresponded` clear block.
- Lifecycle payload is exactly `{ team_id: FB_OFF_LIFECYCLE.assign_team_id }`; `assign_member_id` no longer appears in code or example config.
- Lifecycle waits `sleep(6)` after close to exceed the 5-second self-assign cooldown.
- Final inbox test proves both directions: chat-status failure still invokes clear; clear failure does not prevent chat-status emit.

References:
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:241-285`.
- `oho-api/src/services/member-send-message/inbox/inbox.hooks.spec.js`.
- `oho-api/load-tests/meta-business-ai.js:190-218`.
- Final k6 command used dummy non-secret `VAR_JSON` and `k6 inspect`; no actual traffic was run.

## Thread `01a03314-b2c2-71d0-a739-b4f9779e359e`
updated_at: 2026-08-24T09:37:22+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T16-23-09-01a03314-b2c2-71d0-a739-b4f9779e359e.jsonl
rollout_summary_file: 2026-08-24T09-23-09-Ozdc-oho_1802_meta_business_ai_webapp_fixes.md

description: Implemented scoped Meta Business AI web-app sender identity and handoff contact refresh on branch tk-sprint-2616/feature/oho-1802-meta-biz-ai; local focused validation passed, staging/UAT not run
task: OHO-1802 Meta Business AI web-app W1/W2 implementation
task_group: /Users/tualek/ohochat/oho-web-app
task_outcome: success
cwd: /Users/tualek/ohochat/oho-web-app
keywords: Meta Business AI, ai_generated, @meta-ai, @inbox, smart-chat-helper, Conversation.vue, chat/request created, handleSmartchatRealtimeUpdate, DEFAULT_UPDATE_FIELDS, Jest, Ponytail

### Task 1: Meta AI sender identity and bubble styling

task: Add Meta AI author detection and render it using the existing bot sender type.
task_group: oho-web-app Smartchat sender rendering
task_outcome: success

Preference signals:
- The user asked to follow the plan and keep scope narrow; the plan explicitly says not to create a new `meta-ai` sender type, state machine, endpoint, or feature flag -> future similar fixes should reuse existing `bot` behavior and preserve unrelated dirty work.

Reusable knowledge:
- `plugins/smart-chat-helper.js` now treats `message.ai_generated === true` or `user.id` ending in `@meta-ai` as sender type `bot`, before the `@inbox` check. This supports both `${businessId}@meta-ai` and the API fallback `${businessId}@inbox` with `ai_generated:true`.
- `getSender` returns `Meta AI` for the same per-message identity; normal `${businessId}@inbox` without `ai_generated` remains `agent-inbox` and keeps the platform label.
- `Conversation.vue:getCornerBubble` reuses `$smartChatHelper.getSenderType(m)` for bot/broadcast styling and keeps the JERA partner fallback.

Failures and how to do differently:
- The first W1 test fixture incorrectly passed `{ getters }` directly even though the plugin entrypoint destructures `{ store }`; correcting it to `{ store: { getters } }` made the focused test pass.
- Do not run broad formatting on `Conversation.vue`; the file had pre-existing formatting drift and reformatting would expand the diff beyond scope.

References:
- `plugins/smart-chat-helper.js:51-54,80-104`
- `components/Smartchat/Conversation.vue:2588-2611`
- `test/plugins/smart-chat-helper.spec.js`

### Task 2: Refresh current contact on `chat/request created`

task: Ensure an open Smartchat room refetches its contact after Meta AI hands off to a request state.
task_group: oho-web-app websocket/contact realtime updates
task_outcome: success

Preference signals:
- The plan required “authoritative fetch” independent of badge flags and explicitly rejected new Meta-specific APIs/state -> future changes should dispatch the existing contact update action with the established field contract.

Reusable knowledge:
- In `store/modules/websocket.js`, the `chat/request created` listener now dispatches:
  `handleSmartchatRealtimeUpdate({ event_message: { ...message, _id: _.get(message, "contact_id") }, options: { update_fields: DEFAULT_UPDATE_FIELDS, is_fetch_contact: true } })`.
- This replaces `refreshChatRoomBadgeRealtime` only for this event, avoiding its early return when both `rt_unread_feature_enabled` and `rt_unresponded_feature_enabled` are false.
- Existing `newCustomerRequest` notification and favicon behavior remains unchanged.

Failures and how to do differently:
- Running `npx jest ...` failed because it was interpreted as an npm script (`Missing script: "jest"`). Use `npm test -- --runInBand --runTestsByPath ...` in this repo.
- Running Jest from the repository root reports duplicate manual mocks under the pre-existing `.claude-worktrees` directory. Use `--runTestsByPath` and report the warnings rather than deleting user files.

References:
- `store/modules/websocket.js:1-6,299-319`
- `test/store/modules/websocket.spec.js:116-163`
- Passing command: `npm test -- --runInBand --runTestsByPath /Users/tualek/ohochat/oho-web-app/test/plugins/smart-chat-helper.spec.js /Users/tualek/ohochat/oho-web-app/test/store/modules/websocket.spec.js /Users/tualek/ohochat/oho-web-app/test/components/Smartchat/Conversation.spec.js`
- Validation: `Test Suites: 3 passed, 3 total; Tests: 130 passed, 130 total`
- Validation: `node_modules/.bin/prettier --check plugins/smart-chat-helper.js store/modules/websocket.js test/plugins/smart-chat-helper.spec.js test/store/modules/websocket.spec.js` passed; `git diff --check` passed.
- Worktree remained uncommitted; existing untracked files were preserved. Staging/UAT was not run.

## Thread `01a03341-aaf8-71b0-b02d-3f7bdc25fcc2`
updated_at: 2026-08-24T10:28:24+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T17-12-16-01a03341-aaf8-71b0-b02d-3f7bdc25fcc2.jsonl
rollout_summary_file: 2026-08-24T10-12-16-Xs6C-meta_business_ai_review_webapp_staging_fixes.md

---
description: Meta Business AI staging review plus minimal web-app fixes for sender labeling, inbox styling, socket fetch scope, and classification tests
 task: review-meta-business-ai-and-fix-webapp-staging-findings
task_group: /Users/tualek/ohochat Meta Business AI and Smartchat workflow
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, Meta Business Agent, @meta-ai, @inbox, chat/request created, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, sender_type, staging, T9.1, T9.2, T9.3, Jest, duplicate mocks
---

### Task 1: Meta Business AI staging readiness review

task: Re-review current Meta Business AI branch and decide whether more code changes are needed before staging.
task_group: /Users/tualek/ohochat Meta Business AI staging/UAT review
task_outcome: partial

Preference signals:
- When the user invoked Ponytail review, they wanted only blocker/root-cause findings and no edits initially -> similar reviews should separate code blockers from live staging proof and avoid speculative scope.
- The user expects readiness claims to distinguish local tests/builds from live staging/UAT evidence -> never call this production-ready without current-HEAD review plus live replay and terminal-state proof.

Reusable knowledge:
- Current heads differed from the review’s referenced SHAs: API was `eb067226`, webhook was `b917fb9`; re-review current commits before relying on an older APPROVE verdict.
- D5 is a real residual risk: `guardFacebookBotSend` blocks bot sends whenever `meta_business_ai_enabled === true`, so disabling Meta AI externally while the DB flag remains true can silence OHO. Minimal mitigation is disable -> reconnect/refresh -> verify the flag becomes false; no polling layer was added.
- T9.1 must capture the real Meta ownership error before deleting discovery logging. T9.2 must prove one Mongo/Stream persistence and zero OHO/ARP/fallback automation on standby. T9.3 must compare matched endpoint/revision/traffic samples rather than assert a target like `<100ms`.
- Focused webhook/API checks were not equivalent to full readiness; broader API tests were affected by Node/Jest/worktree compatibility. Verdict was conditional GO to staging only, not UAT/production.

Failures and how to do differently:
- Do not reuse a review tied to stale SHAs.
- Do not infer Meta activation or ownership from `standby`, `ai_generated`, HTTP 200, or unit tests alone.
- Keep live proof and local validation as separate gates.

References:
- `/Users/tualek/ohochat/oho-api/src/utils/meta-business-ai.js:282-292`.
- `/Users/tualek/ohochat/oho-api/src/services/member-send-message/member-send-message.class.js:153-185`.
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts:1370-1398`.
- Required live checks: T9.1 ownership replay, T9.2 standby isolation, T9.3 matched latency, and D5 disable/reconnect verification.

### Task 2: Meta sender display label and inbox styling

task: Preserve `@inbox` classification/styling while displaying Meta messages as `Meta Business Agent`.
task_group: /Users/tualek/ohochat/oho-web-app Smartchat sender rendering
task_outcome: success

Preference signals:
- The user explicitly corrected that removing `if (_.endsWith(id, "@inbox"))` would make `@inbox` disappear and specified the label `Meta Business Agent` -> keep internal sender IDs and change only the visible label.

Reusable knowledge:
- `@inbox` is an internal Stream sender ID and remains necessary for agent-inbox positioning/color.
- Meta detection supports both `ai_generated === true` and an `@meta-ai` ID suffix.

Failures and how to do differently:
- A prior refactor replaced direct `@inbox` detection with `sender_type === "agent-inbox"`; restore/use the ID check where exact inbox styling is required.

References:
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:2590-2600`.
- `/Users/tualek/ohochat/oho-web-app/plugins/smart-chat-helper.js:51-54,104`.

### Task 3: Fix P1/P2/P3 web-app staging findings

task: Remove request-event fetch fan-out, make sender classification single-source, and independently test `@meta-ai` fallback.
task_group: /Users/tualek/ohochat/oho-web-app web-app staging readiness
task_outcome: success

Preference signals:
- The user called P1 fetch fan-out a blocker and requested minimal targeted changes without staging/commit or touching untracked files -> preserve the existing badge path, add only scoped active-room fetch behavior, and report dirty-tree status.
- The user requested the `@meta-ai` fallback be tested without `ai_generated` -> test independent detection signals instead of combining them in one fixture.

Reusable knowledge:
- `chat/request created` should dispatch `newCustomerRequest` and retain `refreshChatRoomBadgeRealtime` for all clients. Only when both `rt_unread_feature_enabled` and `rt_unresponded_feature_enabled` are false, and `contact_id` equals `$nuxt.$route.query.room`, should it additionally dispatch `handleSmartchatRealtimeUpdate` with `is_fetch_contact: true`.
- In `Conversation.vue`, use `sender_type === "agent"` as the source of truth for agent classification; retain explicit `@inbox` handling for inbox styling.
- Targeted command passed `117/117` tests. Duplicate Jest mock warnings came from `.claude-worktrees`, but the requested test paths passed. `git diff --check` passed; lint was not run because local ESLint was unavailable.

Failures and how to do differently:
- Previous implementation fetched every contact on every client receiving `chat/request created`, causing global API fan-out. Preserve badge refresh and gate authoritative fetch by active-room identity.
- Previous test supplied both `ai_generated: true` and `@meta-ai`, so suffix fallback could silently break. Use a fixture with suffix only.
- Do not treat the duplicate mock warnings as test failures, but disclose them and use `--runTestsByPath` to avoid broad worktree scanning.

References:
- `/Users/tualek/ohochat/oho-web-app/store/modules/websocket.js:298-330`.
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:2588-2608`.
- `/Users/tualek/ohochat/oho-web-app/test/plugins/smart-chat-helper.spec.js:28-45`.
- `/Users/tualek/ohochat/oho-web-app/test/store/modules/websocket.spec.js:116-202`.
- `npm test -- --runInBand --runTestsByPath test/store/modules/websocket.spec.js test/plugins/smart-chat-helper.spec.js`

## Thread `01a0334d-49c2-7dd2-ad12-70396594dcb0`
updated_at: 2026-08-24T11:02:14+00:00
cwd: /Users/tualek/Documents/Codex/2026-08-24/new-chat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T17-24-58-01a0334d-49c2-7dd2-ad12-70396594dcb0.jsonl
rollout_summary_file: 2026-08-24T10-24-58-kSu4-local_files_mcp_secure_tunnel_setup.md

---
description: Created and locally bound a sandboxed local-files MCP plugin; local tests and handshake pass, but Secure MCP Tunnel remains unstarted until the user supplies an OpenAI Runtime API key via environment.
task: create-and-connect-sandboxed-local-files-mcp
task_group: local-mcp-plugin-and-secure-tunnel
task_outcome: partial
cwd: /Users/tualek/Documents/Codex/2026-08-24/new-chat
keywords: MCP, local-files, stdio, LOCAL_FILES_ROOT, LOCAL_FILES_ALLOW_WRITE, tunnel-client, Secure MCP Tunnel, CONTROL_PLANE_API_KEY, PyYAML
---

### Task 1: Build sandboxed local-files MCP plugin

task: implement local file MCP server and package as Codex plugin
task_group: local-mcp-plugin
task_outcome: success

Preference signals:
- The user explicitly chose `/Users/tualek/ohochat` as the permitted folder -> future similar setup should use that exact root and avoid broad home-directory access.
- The user asked the agent to manage setup, but did not explicitly request writes -> keep read-only as the default and require `LOCAL_FILES_ALLOW_WRITE=1` for write exposure.

Reusable knowledge:
- Plugin path: `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files`.
- Tools: `list_directory`, `read_file`, `search_files`; `write_file` is dynamically exposed only when `LOCAL_FILES_ALLOW_WRITE=1`.
- All paths are resolved under `LOCAL_FILES_ROOT`; traversal and symlink escapes are rejected. Delete, move, shell, and arbitrary command execution are intentionally absent.
- Bound launcher sets `LOCAL_FILES_ROOT=/Users/tualek/ohochat` and invokes `server.py`.

Failures and how to do differently:
- The system Python lacked `yaml`, so the plugin validator initially failed with `ModuleNotFoundError: No module named 'yaml'`. Unit tests and JSON checks still ran; validation later passed using a temporary stub module. Prefer a runtime with the validator dependencies or install/use the official bundled dependencies rather than relying on a stub for future validation.
- An initial raw smoke-test command accidentally joined JSON messages with literal backslash-n characters, producing `invalid JSON: Extra data`; rerunning with actual newline delimiters passed.

References:
- `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/server.py`
- `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/.mcp.json`
- `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/run-local-files.sh`
- `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/.codex-plugin/plugin.json`
- `python3 -B -m unittest -v test_server.py` -> 3 tests passed
- `Plugin validation passed: /Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files`

### Task 2: Configure Secure MCP Tunnel

task: connect local-files server to ChatGPT through OpenAI Secure MCP Tunnel
task_group: secure-mcp-tunnel

task_outcome: partial

Preference signals:
- The user supplied tunnel ID `tunnel_6a8c2342048c819192e0d4f70a8f6c59` and asked the agent to handle setup -> proactively create the local profile and report the exact remaining credential/permission blocker without asking for the secret in chat.
- The user asked where `CONTROL_PLANE_API_KEY` comes from -> explain it as an OpenAI Platform Runtime API key, distinct from ChatGPT tokens and `OPENAI_ADMIN_KEY`.

Reusable knowledge:
- Homebrew full client is installed at `/opt/homebrew/bin/tunnel-client`, version `0.0.12+881c9a8...`.
- Created profile: `/Users/tualek/.config/tunnel-client/local-files.yaml`.
- Profile references `api_key: "[REDACTED_SECRET]"`, tunnel ID `tunnel_6a8c2342048c819192e0d4f70a8f6c59`, and launcher `/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/run-local-files.sh`.
- Doctor result: config/profile/URLs passed; `control_plane_api_key` failed because environment variable `CONTROL_PLANE_API_KEY` was unset.
- OpenAI’s documented path is Platform Runtime API keys with Tunnels Read + Use; ChatGPT custom apps require Developer Mode and Secure MCP Tunnel for private/local servers.

Failures and how to do differently:
- Do not use `/Users/tualek/Downloads/tunnel-client-runtime-cloudflared-source-v0.0.12` as the client binary. Inspection showed Go source (`go.mod`, `cmd/`, `pkg/`, rebuild scripts), not an executable full client with `init` and `doctor`.
- Do not report the tunnel as active until the user exports the runtime key, `doctor` passes, and the daemon is running/healthy. Current state is configured but not connected.

References:
- `tunnel-client init --sample sample_mcp_stdio_local --profile local-files --tunnel-id tunnel_6a8c2342048c819192e0d4f70a8f6c59 --mcp-command '/Users/tualek/Documents/Codex/2026-08-24/new-chat/outputs/local-files/run-local-files.sh'`
- `tunnel-client doctor --profile local-files --explain --json`
- Exact failure: `environment variable "CONTROL_PLANE_API_KEY" is not set`
- Next commands: `export CONTROL_PLANE_API_KEY='[REDACTED_SECRET]'`; `tunnel-client doctor --profile local-files --explain`; `tunnel-client run --profile local-files`
- Never request or store the API key in chat or memory.

## Thread `01a03371-c57c-7932-b347-aa128b3766b3`
updated_at: 2026-08-24T12:44:25+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T18-04-49-01a03371-c57c-7932-b347-aa128b3766b3.jsonl
rollout_summary_file: 2026-08-24T11-04-49-4cQH-safe_local_mcp_core_no_delete.md

---
description: Implemented and verified a Python 3.9 local MCP core with scoped filesystem/Git access and capability-level no-delete enforcement; full Remote Desktop Commander integration remains incomplete.
task: build-safe-local-mcp-core
 task_group: /Users/tualek/ohochat remote-mcp
 task_outcome: success
cwd: /Users/tualek/ohochat
keywords: remote-mcp, MCP, Remote Desktop Commander, Python 3.9, stdio, Streamable HTTP, workspace root, path traversal, symlink escape, bearer token, Origin, no-delete, git read-only
---

### Task 1: Investigate and avoid duplicating Remote Desktop Commander

task: identify whether the requested 184-tool capability already exists as an installed plugin
 task_group: plugin/MCP discovery
 task_outcome: partial

Preference signals:
- The user asked for broad “Full access” but explicitly prohibited deletion without asking first -> similar future work should model safety as unavailable destructive capabilities or explicit approval gates, not rely only on natural-language instructions.

Reusable knowledge:
- Codex config contained project references for `remote-desktop-commander-plugin`, but those directories contained only `outputs/` and `work/`, not a usable repository.
- Catalog lookup found `Remote Desktop Commander` with app ID `app-6a057d268ebc8191a27d7c7096cab4f6`; plugin management reported it was `not_installed`.
- Agent-side tools could inspect permissions/dependencies and uninstall, but no install/connect tool was available for this app.
- Official setup requires adding the plugin in ChatGPT Web and connecting a machine; the in-app page was logged out, so installation was not completed.

Failures and how to do differently:
- Do not claim the existing catalog entry is usable merely because it appears in the catalog. Verify installed status and perform a real tool call after installation.
- Browser setup reached the install page but stopped at login rather than attempting to bypass authentication.

References:
- Catalog: `/Users/tualek/.codex/cache/remote_plugin_catalog/d335c3c53219bb8f.json`
- App ID: `app-6a057d268ebc8191a27d7c7096cab4f6`
- Setup URL: `https://desktopcommander.app/mcp/chatgpt/`

### Task 2: Build the local MCP core

task: create a safe local MCP server for read/add/update/copy/Git operations without deletion
 task_group: remote-mcp implementation
 task_outcome: success

Preference signals:
- The requested safety boundary was “เพิ่ม-อัปเดต-แก้ไขได้ ยกเว้น ลบ” -> final tool catalog contains no delete, move, rename, unlink, arbitrary shell, or project-command tool.

Reusable knowledge:
- `/Users/tualek/ohochat/remote-mcp/remote_mcp.py` is stdlib-only and compatible with the available Python `3.9.6` runtime.
- Exposed tools: `workspace_list`, `read_file`, `search_text`, `write_file`, `apply_patch`, `copy_file`, `git_status`, `git_diff`, `git_log`.
- Paths must be relative to one explicit root; absolute paths, parent traversal, and symlink escapes are rejected.
- Writes are bounded and use temporary-file replacement. `apply_patch` requires exactly one `old_text` match. Copy preserves the source.
- Git commands are read-only and scoped to a selected nested repository; external diff/fsmonitor and interactive prompts are disabled.
- HTTP uses `/mcp` and `/health`, requires `REMOTE_MCP_TOKEN`, accepts only loopback binding, and checks configured/default-safe Origins.
- Supports MCP protocol versions `2025-06-18` and `2025-03-26` over stdio and minimal Streamable HTTP.

Failures and how to do differently:
- Initial delegated Luna work stalled and produced only an incomplete test file; the local agent implemented the bounded core instead.
- Sandbox socket restrictions caused HTTP tests to fail with `PermissionError: [Errno 1] Operation not permitted`; rerun loopback integration tests with appropriate elevated permission when the environment blocks binds.
- Keep one canonical implementation; the temporary duplicate `server.py` and `test_server.py` were removed.

References:
- Implementation: `/Users/tualek/ohochat/remote-mcp/remote_mcp.py`
- Tests: `/Users/tualek/ohochat/remote-mcp/test_remote_mcp.py`
- README: `/Users/tualek/ohochat/remote-mcp/README.md`
- Verification command: `cd /Users/tualek/ohochat/remote-mcp && python3 -m unittest -v`
- Result: `Ran 7 tests in 2.591s` / `OK`
- Compile check: `python3 -c 'from pathlib import Path; compile(Path("remote_mcp.py").read_text(encoding="utf-8"), "remote_mcp.py", "exec")'`

## Thread `01a0339a-6b7c-7ba1-9247-3f8cb0212b69`
updated_at: 2026-08-24T12:08:53+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T18-49-13-01a0339a-6b7c-7ba1-9247-3f8cb0212b69.jsonl
rollout_summary_file: 2026-08-24T11-49-13-YJ4J-meta_business_ai_ponytail_review_fixes.md

---
description: Cross-repo Meta Business AI review fixes completed with focused validation; legacy web implementation removed and API recovery hardened, but changes remain uncommitted and staging/UAT are pending
task: apply Meta Business AI branch review using Ponytail minimal-diff scope across oho-web-app, oho-api, and oho-webhook
task_group: /Users/tualek/ohochat / Meta Business AI cross-repo review and staging readiness
task_outcome: partial
cwd: /Users/tualek/ohochat
keywords: Meta Business AI, OHO-1802, Ponytail, oho-web-app, oho-api, oho-webhook, 64eb8249, ownershipConfirmed, thread_owner, ai_generated, chat/request created, 622851382610562, Jest haste collisions
---

### Task 1: Apply cross-repo Meta Business AI review fixes

task: remove legacy web footprint, fix ownership recovery, update observation timestamp/docs/logging, and validate focused tests
 task_group: Meta Business AI review / staging readiness
 task_outcome: partial

Preference signals:
- when the user requested “แก้ตามนี้ได้ไหม ponytail มาดู และ matcock ด้วย” -> prefer the smallest root-cause diff, delete speculative layers, and avoid broad refactors.
- existing dirty worktrees were deliberately preserved and no commit/push was made -> future agents should not reset, revert, stage, commit, or push without explicit authorization.
- the final report separated focused test results from unrun staging/UAT -> do not claim merge or production readiness from local tests alone.

Reusable knowledge:
- `oho-web-app` inherited legacy commit `64eb8249`, which added about 1,231 lines across Meta UI/state-machine files, old Firebase flag/state, and unsupported `/meta-business-ai/takeover` and `/return-to-ai` endpoints. The current plan explicitly says not to cherry-pick it.
- The minimal web scope is sender identity plus open-room realtime refresh. `ai_generated === true` or a user ID ending `@meta-ai` maps to sender type `bot` and name `Meta AI`; ordinary `@inbox` without `ai_generated` remains `agent-inbox`.
- `chat/request created` now fetches the open contact using `handleSmartchatRealtimeUpdate` with `_id=contact_id`, `DEFAULT_UPDATE_FIELDS`, and `is_fetch_contact:true`; closed rooms retain badge refresh.
- API send recovery passes `ownershipConfirmed:true` after a positive Facebook ownership error. `takeFacebookThreadControl()` skips the passive `thread_owner` read only in that recovery path; assign/bulk defensive reads remain.
- `facebook_meta_business_ai_observed_at` now updates only when the incoming valid observation is newer than the stored timestamp.
- Current runtime uses `622851382610562` as the return-to-AI target. `928891643393937` is historical/unreproducible and must not be hardcoded or used as an ownership oracle.
- Webhook unmatched pass-control logging is now structured with `event: 'meta_business_ai_handoff_unmatched'`.

Failures and how to do differently:
- A first large-file restoration truncated `Conversation.vue`; it was repaired by restoring the parent in bounded ranges. Use chunked reads for large files.
- Incorrect Jest ignore syntax expanded to full suites. Use `--runTestsByPath` for focused verification.
- Existing `.claude` worktrees cause duplicate manual mock warnings/collection failures. Do not delete user worktrees; distinguish collision failures from the passing target suites.
- API Meta tests required a temporary Node 26 `SlowBuffer` shim because an old dependency accessed `SlowBuffer`; the shim was removed afterward.

References:
- Plan: `docs/meta-business-ai/plan-oho-web-app-2026-08-24.md`
- Legacy commit: `64eb8249`
- Web: `plugins/smart-chat-helper.js`, `store/modules/websocket.js`, `components/Smartchat/Conversation.vue`
- API: `src/utils/meta-business-ai.js`, `src/services/member-send-message/member-send-message.class.js`, `src/services/contact/upsert/upsert.hooks.js`
- Webhook: `src/controllers/facebook/handler.ts`
- Validation: web `117/117` focused tests and `Conversation.spec.js 14/14`; API Meta `47/47` and ownership retry `6/6`; webhook `18/18`; API SWC build and webhook TypeScript build passed.
- Final state: all changes are working-tree modifications only; staging replay, live ownership verification, full build/UAT, and production canary were not run.

## Thread `01a033bb-2b53-7d32-a3ae-05d7361135e5`
updated_at: 2026-08-24T12:33:42+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T19-24-59-01a033bb-2b53-7d32-a3ae-05d7361135e5.jsonl
rollout_summary_file: 2026-08-24T12-24-59-o5w1-partial_remote_mcp_core_implementation_stopped_before_verifi.md

---
description: Started a scoped Python 3.9 stdlib-only local MCP core in remote-mcp; user stopped immediately after implementation was added, so functionality remains unverified.
task: implement minimal auditable local MCP core
 task_group: local-mcp-implementation
task_outcome: partial
cwd: /Users/tualek/ohochat/remote-mcp
keywords: MCP, JSON-RPC, Streamable HTTP, Python 3.9, unittest, path escape, symlink, workspace boundary, public seam, stop request
---

### Task 1: Implement remote-mcp core

task: implement minimal auditable local MCP core
 task_group: local-mcp-implementation
task_outcome: partial

Preference signals:
- The user required “Create only /Users/tualek/ohochat/remote-mcp” and prohibited touching paths outside it -> enforce the requested directory boundary strictly.
- The user said “STOP immediately. Do not run any more commands and do not create or edit any files.” -> stop requests take precedence over pending verification or cleanup.
- The user required exact test results and no commit/stage -> distinguish created code from verified completion.

Reusable knowledge:
- Public tests targeted `MCPServer` and `create_http_server`, with allowlisted tools only: workspace_list, read_file, search_text, write_file, apply_patch, copy_file, git_status, git_diff, git_log.
- Required security seams included absolute/parent/symlink escape rejection, safe writes/copies/exact single-match patches, JSON-RPC dispatch, protocol versions 2025-06-18 and 2025-03-26, HTTP `/mcp`, `/health`, token, and Origin checks.
- The implementation was added after the first test run, but no subsequent test or syntax verification occurred.

Failures and how to do differently:
- Initial command `rtk python3 -B -m unittest -v` failed with `ModuleNotFoundError: No module named 'remote_mcp'` because tests were run before implementation. If work resumes, rerun tests first, then inspect only failures.
- Do not claim success: README, full verification, and final scope/status checks are incomplete.
- After an explicit stop, perform no further commands or file changes until resumed by the user.

References:
- `/Users/tualek/ohochat/remote-mcp/test_remote_mcp.py`
- `/Users/tualek/ohochat/remote-mcp/remote_mcp.py`
- Exact test command: `rtk python3 -B -m unittest -v`
- Exact pre-implementation failure: `ImportError: Failed to import test module: test_remote_mcp` / `ModuleNotFoundError: No module named 'remote_mcp'`

## Thread `01a05792-79ea-74f3-abcd-9ea74e06432e`
updated_at: 2026-08-31T11:31:47+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/31/rollout-2026-08-31T18-26-52-01a05792-79ea-74f3-abcd-9ea74e06432e.jsonl
rollout_summary_file: 2026-08-31T11-26-52-AzlI-global_session_efficiency_defaults.md

description: Enabled centralized RTK monitoring, Caveman concise mode, and Ponytail minimal-diff defaults across managed AI tools, including an always-applied Cursor rule; final profiles and RTK monitoring verified
 task: enable-global-session-efficiency-defaults
 task_group: /Users/tualek/ai-main configuration and cross-tool session workflow
 task_outcome: success
 cwd: /Users/tualek/ohochat
 keywords: ai-main, workflow.md, install.sh, RTK, rtk gain, Caveman, Ponytail, Cursor rules, alwaysApply, profile budgets, OpenCode, Qwen, Zcode

### Task 1: Enable global RTK/Caveman/Ponytail defaults

task: add centralized session-efficiency defaults and sync them to every managed AI tool
task_group: ai-main global configuration
task_outcome: success

Preference signals:
- User asked to make RTK, Caveman, and Ponytail available in “ทุก session” -> configure centrally and propagate across tools by default, not per-session.
- Preserve exact paths, commands, numbers, errors, risks, and evidence while keeping replies concise; use smallest root-cause diff, reuse first, avoid unrelated edits, preserve dirty work.

Reusable knowledge:
- Shared defaults belong in `/Users/tualek/ai-main/config/workflow.md`; `install.sh --sync` compiles and deploys them.
- Full configs verified in Claude, Codex, Gemini, OpenCode, Qwen, and Zcode. Cursor needs a separate global MDC rule at `~/.cursor/rules/session-efficiency.mdc` with `alwaysApply: true`; skill symlinks alone are not automatic rules.
- Final profile budgets passed: full ~2859, lean ~1599, min ~630 tokens.
- `rtk gain` verified operational with 27,338 commands and 87.8M tokens saved (65.9%).

Failures and how to do differently:
- Patch tool rejected files outside request cwd with `LSP file path must be inside request cwd`; edit from the target repo or use shell-based edits, then verify generated files.
- Verbose defaults exceeded lean/min ceilings; compact the shared rule and rebuild until budgets pass.
- Sandbox RTK tracking access failed with `unable to open database file`; use elevated execution for `rtk gain` verification.

References:
- Command: `rtk ./install.sh --sync` from `/Users/tualek/ai-main`
- Files: `/Users/tualek/ai-main/config/workflow.md`, `/Users/tualek/ai-main/install.sh`, `/Users/tualek/ai-main/config/cursor-rules/session-efficiency.mdc`
- Cursor rule: `--- description: Session efficiency defaults; alwaysApply: true ---`
- RTK result: `Tokens saved: 87.8M (65.9%)`

## Thread `01a05796-1807-7993-9bd1-5d0a87e4b8cf`
updated_at: 2026-08-31T11:41:48+00:00
cwd: /Users/tualek/ohochat
rollout_path: /Users/tualek/.codex/sessions/2026/08/31/rollout-2026-08-31T18-30-49-01a05796-1807-7993-9bd1-5d0a87e4b8cf.jsonl
rollout_summary_file: 2026-08-31T11-30-49-ihHh-web_stream_credential_rotation_decision_map.md

description: Web-only architecture review mapped the user’s numbered questions to verified current behavior and proposed credential-rotation flow; key takeaway is to await bootstrap credentials, not Firebase, and rebuild Stream client outside the SDK on version mismatch.
task: web-stream-credential-version-and-business-switch-review
task_group: /Users/tualek/ohochat / web architecture consultation
task_outcome: success
cwd: /Users/tualek/ohochat
keywords: web-app, StreamChat, stream_client, initStream, window.location.replace, tokenProvider, credential_version, key_fingerprint, Firebase Remote Config, fire-and-forget, bootstrap, business switch

### Task 1: Web credential rotation and business switching

task: web-stream-credential-version-and-business-switch-review
task_group: web architecture consultation
task_outcome: success

Preference signals:
- when the response covered both platforms, the user said “focus คำตอบของ web app พอ” -> scope future answers to the requested platform immediately.
- when the user wanted the result easier to use, they asked “เอาคำตอบ map กับคำถามให้หน่อย” -> preserve original numbering and answer in a direct question-to-answer table.
- when discussing async behavior, the user requested an easy explanation and asked whether it could use await instead of fire-and-forget -> explain the benefit with a simple flow such as `bootstrap/login -> await -> initStream()`.

Reusable knowledge:
- `/oho-web-app/plugins/firebase-remote-config.js` starts `fetchAndApplyRemoteConfig(...).catch(...)` without awaiting it; this is intentional after hydration. Await bootstrap/login credentials before creating Stream, not the whole Firebase plugin.
- `/oho-web-app/components/Smartchat/Conversation.vue:1516` creates `StreamChat` with `$config.stream_key`, reads `oho_member.streamToken`, calls `connectUser`, and stores the client. No `tokenProvider`, `credential_version`, or `key_fingerprint` exists in the current web code.
- `/oho-web-app/components/Smartchat/Conversation.vue:1546` only initializes when `!this.stream_client`; an in-memory business switch would reuse the old client unless teardown/rebuild is explicit.
- `/oho-web-app/components/SwitchBusiness.vue:202` uses `window.location.replace('/business/{id}/smartchat?status=me')`, so the current switch reloads the page, resets Vuex, and causes a new client to be created. This does not prove a no-reload switch would be safe.
- Recommended contract: bootstrap/login returns `stream_key`, `stream_token`, `credential_version`, and optionally `key_fingerprint`; initial sequence is `await bootstrap/login -> credentials/version -> create Stream client`.
- On socket/polling version change: await bootstrap again, compare version/fingerprint, then `disconnectUser -> create new StreamChat -> connectUser` under an owner outside the SDK.
- `key_fingerprint` is optional but useful for detecting mismatched configuration; compare/telemetry only and never log secrets.

Failures and how to do differently:
- The initial answer mixed web and mobile; future replies should obey a platform narrowing request without repeating unrelated findings.
- The user asked again whether question 05 had been answered; explicitly state “current web has no credential_version transport” before describing the proposed bootstrap/socket design.
- Keep current repository facts separate from recommendations: the version/fingerprint bootstrap contract is not implemented yet.

References:
- `/Users/tualek/ohochat/oho-web-app/plugins/firebase-remote-config.js:85-89`
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:1516-1526`
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:1531-1547`
- `/Users/tualek/ohochat/oho-web-app/components/SwitchBusiness.vue:202-216`
- `/Users/tualek/ohochat/oho-web-app/store/index.js:103-125`

