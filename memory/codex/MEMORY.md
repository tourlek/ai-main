# Task Group: /Users/tualek/ohochat/script-oho / migrate-unread.ts correctness review
scope: Read-only correctness-review memory for `unread-unresponded/migrate-unread.ts`, especially checkpoint semantics, cleanup-vs-backfill invariants, crash/resume safety, and refactor sanity checks that must be proven from code lines rather than comments.
applies_to: cwd=/Users/tualek/ohochat/script-oho; reuse_rule=reuse for similar correctness reviews in this checkout when the user wants evidence-first analysis of `migrate-unread.ts` or nearby migration-state logic, but re-check the live file because line numbers and safety guarantees can drift.

## Task 1: Review checkpoint semantics versus cleanup-read-by assumptions, cleanup can trust incomplete proof

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed checkpoint membership is coarser than "Stream-verified" comments imply)

### keywords

- migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, INCLUDE_PARTIAL, runLegacyReadByReconcilePass, skippedNoChannel, partial, completed, loadCheckpoint, backfillCompleted, verified, checkpoint safety

## Task 2: Review cleanup cutoff parity, cleanup lacks the 90-day bound used elsewhere

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed cleanup query omits `last_active_at` cutoff even though backfill/reconcile apply it)

### keywords

- readByCutoffDate, DAYS, last_active_at, cleanup-read-by, runReadByToUnreadByPass, runLegacyReadByReconcilePass, resolveBusinessIds, MAX_DOCS_PER_BIZ, filter parity, HAS_LEGACY_READ_BY

## Task 3: Review crash/resume safety and totals refactor, buildTotals wiring confirmed with checkpoint caveats

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed `buildTotals()` coverage and exposed non-atomic checkpoint writes)

### keywords

- CHECKPOINT_SUFFIX, STATUS_FILE, saveCheckpoint, saveStatus, buildTotals, temp-file rename, crash-safety, loadCheckpoint, processedCount, cleanup mode, resume

## User preferences

- when the user says `Trace the actual filter/gating logic, not the comments` and asks for line citations -> treat comments as non-binding, ground every behavioral claim in source lines/snippets, and do not smooth over gaps with intent-based reasoning. [Task 1][Task 2]
- when the user asks for `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` per item -> keep the review tightly structured and map each verdict to exact code lines. [Task 1]
- when the user asks whether one pass uses the `same DAYS/readByCutoffDate bound` as another -> compare the exact query objects across all relevant passes and surrounding guards, not just the obvious function or comment. [Task 2]
- when the user asks about shared `CHECKPOINT_FILE` / `STATUS_FILE` semantics or refactor sanity -> explicitly trace mode dispatch, suffix logic, write paths, and whether any hand-built state objects remain. [Task 3]

## Reusable knowledge

- `INCLUDE_PARTIAL` is opt-in only (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`), and `runLegacyReadByReconcilePass()` only runs inside that branch. A business can still become checkpoint-complete without legacy Stream verification because `partial` means budget exhaustion only and checkpointing checks only `!isDryRun && !result.partial`. [Task 1][Task 3]
- Cleanup trusts checkpoint membership directly via `loadCheckpoint()` and `backfillCompleted.has(id.toString())`; the checkpoint file stores only `{ completed: [...] }`, with no durable proof about reconcile coverage, skipped unresolved channels, or whether a business was verified under the current semantic config. [Task 1][Task 3]
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when a cutoff exists, but cleanup does not carry any date window. It filters only by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`. [Task 2]
- `resolveBusinessIds()` only narrows the business/channel universe; it does not encode doc freshness or backfill coverage. `MAX_DOCS_PER_BIZ` is `null`, so partial/budget limiting is not a protective invariant here. [Task 2]
- Cleanup mode reads checkpoint membership only and does not itself write checkpoint/status files, so it cannot overwrite backfill state by itself. `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but not cutoff/stream/partial semantics. [Task 3]
- `saveStatus()` uses a temp-file rename, but `saveCheckpoint()` writes directly to the checkpoint file. `loadCheckpoint()` swallows JSON parse/read errors and returns an empty set, so checkpoint corruption degrades into silent "start over" behavior. [Task 3]
- The 2026-07-14 review also found that cleanup resolves the current `connection_status: "complete"` channel set at runtime, so a business gaining new complete channels after backfill can make cleanup target docs outside the original backfill snapshot. [Task 2][Task 3]
- `buildTotals()` is the single totals builder now: both `saveStatus()` call sites use it, and no third hand-built totals literal remained. `processedCount++` happens before checkpoint eligibility is decided, so status can show business progress that has not been durably checkpointed. [Task 3]

## Failures and how to do differently

- Symptom: comments say a business is "verified" or cleanup is "safe to drop". Cause: the code does not persist any proof beyond membership in `completed`. Fix/pivot: inspect what the code actually stores and what cleanup consumes before accepting safety claims. [Task 1]
- Symptom: cleanup appears to mirror backfill/reconcile scope. Cause: the file comments suggest full-population behavior, but the actual queries diverge and cleanup omits the `last_active_at` cutoff. Fix/pivot: compare query objects and cutoff propagation across every related pass. [Task 2]
- Symptom: future resume logic assumes checkpoint files are durable and config-specific. Cause: checkpoint writes are non-atomic and the suffix key omits semantic dimensions such as cutoff/stream/partial choices. Fix/pivot: treat checkpoint correctness and resume safety as separate review items, not as implied by shared file names alone. [Task 3]
- Symptom: a review report sounds safe because the refactor is tidy. Cause: source-of-truth reasoning stopped at comments or naming instead of tracing state transitions and persisted artifacts. Fix/pivot: verify file-write paths, mode dispatch, and all remaining literal builders before concluding the refactor is safe. [Task 1][Task 3]

# Task Group: /Users/tualek/ohochat/oho-api / unread-unresponded performance debugging
scope: Root-cause performance memory for unread/unresponded slowdowns in `oho-api`; use for attribution work that must separate expensive count paths from write-side stamping.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar unread/unresponded performance investigations in this repo, but re-check the current query shape, indexes, and incident evidence before assuming the same bottleneck still exists.

## Task 1: Diagnose unread/unresponded slowdown, root cause attributed to unread count query

### rollout_summary_files

- rollout_summaries/2026-07-11T15-21-15-jDcH-unread_unresponded_db_performance_root_cause.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T22-21-15-019f51c4-bc6d-7223-a93d-e4ee27e97fe7.jsonl, updated_at=2026-07-11T15:24:30+00:00, thread_id=019f51c4-bc6d-7223-a93d-e4ee27e97fe7, confirmed count-path root cause from incident evidence)

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

# Task Group: /Users/tualek/ohochat/oho-api / Thai code review of unread-unresponded changes
scope: Review-only memory for `oho-api` unread/unresponded diffs, especially query composition, validation limits, and review reporting style; use when the user asks whether backend changes are okay, not when they ask for direct implementation.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar code reviews in this repo or nearby search-hook work, but re-verify exact query shape, failing tests, and worktree-specific files before treating any blocker as still open.

## Task 1: Review `oho-api` unread/unresponded and bulk-send changes in `mr-1285-fixes`, blocker findings

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, worktree-specific review found blocker-level query-composition risks)

### keywords

- oho-api, code review, unread, unresponded, convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, cacheService, Redis, Jest, Mongo query composition

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 2: Verify unread/unresponded rollout coverage and remaining blockers, partial confidence

### rollout_summary_files

- rollout_summaries/2026-07-11T13-46-00-iIfu-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/11/rollout-2026-07-11T20-46-00-019f516d-893b-7923-a4b3-96517d54a6c0.jsonl, updated_at=2026-07-11T14:32:17+00:00, thread_id=019f516d-893b-7923-a4b3-96517d54a6c0, targeted Jest passed but Mongo-backed proof was unavailable)

### keywords

- MONGODB_URI, compute-badge-counts, Promise.allSettled, channel-eligible-members, cacheService, Redis timeout, bot-send-message.hooks.spec.js, quick-reply failures, updateContactProfile

## Task 3: Review earlier unread/unresponded diff, blocker findings

### rollout_summary_files

- rollout_summaries/2026-06-26T10-07-42-z14x-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl, updated_at=2026-06-26T10:19:09+00:00, thread_id=019f0366-4780-7b21-a9b4-c309436efcc5, earlier review established the same hook-chain failure pattern)

### keywords

- oho-api, unread, unresponded, search-query-converter, addVisibilityFilter, bulk send, convertUnreadUnrespondedQuery, Jest, type-check, Mongo query composition

## User preferences

- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged. [Task 1][Task 3]
- when the user asked only whether the changes were okay -> stay review-first and findings-first; do not jump into fixing code unless asked. [Task 1][Task 2][Task 3]
- when the review flow is in Thai and the user is evaluating a local diff -> concise Thai blocker findings are the right default, not implementation-heavy prose. [Task 1][Task 2]

## Reusable knowledge

- `convertUnreadUnrespondedQuery.ts` has a special both-flags path; both the June and July reviews say this area must be traced through the full query lifecycle, not judged in isolation. `countBaseQuery`, `TYPED_FILTER_FIELDS`, parser coercion, and later visibility rewrites all affect whether the unread/unresponded shape survives. [Task 1][Task 3]
- `search-query-converter.ts` and related typed-filter handling explicitly preserve only `read_by`, `is_unresponded`, and `read_by.0`; any future query-shape change that introduces `$or` / `$and` needs matching parser and converter updates. [Task 1][Task 3]
- Focused Jest on `src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts` is the early gate for this task family; a mismatch in the both-flags case is a blocker before deeper reasoning about downstream hooks. [Task 1][Task 3]
- `bulk.class.js` now updates contact state directly, and the rollout also touched cache and broadcast-adjacent utilities: `src/utils/compute-badge-counts.ts` uses `Promise.allSettled`, `src/utils/channel-eligible-members.ts` returns `null` on lookup failure or >2000 eligible members, and `src/utils/cache/index.js` wraps Redis commands with a 3s timeout. These affect how unread state propagates and fails. [Task 1][Task 2]
- `src/models/contact.model.spec.ts` and `src/models/chat-session.model.spec.ts` verify `unread_by` and `is_unresponded` are absent on bare documents when flags are off, which is a useful regression boundary when review touches defaults or rollout safety. [Task 2]

## Failures and how to do differently

- Symptom: unread/unresponded filter breaks or disappears when `search` or sale-visibility paths are involved. Cause: the new filter shape is vulnerable to typed-filter coercion and `addVisibilityFilter()` rebuilding `context.params.query` with its own `$or`. Fix/pivot: audit the full hook chain, including parser and visibility rewrite stages, not just the helper that first injected the condition. [Task 1][Task 3]
- Symptom: review looks formatted clean but still has semantic bugs. Cause: `git diff --check` passed while the diff still contained blocker-level query-composition issues. Fix/pivot: do not treat formatting sanity as correctness; use focused tests and path tracing. [Task 1]
- Symptom: repo-wide validation gives noisy or misleading confidence. Cause: `npm run type-check` had unrelated TypeScript failures and `src/services/bot-send-message/bot-send-message.hooks.spec.js` still had 6 unrelated quick-reply failures. Fix/pivot: prefer targeted Jest suites and report exactly which failures are pre-existing versus relevant. [Task 1][Task 2][Task 3]
- Symptom: rollout verification stops short of DB proof. Cause: Mongo-backed tests could not run without `MONGODB_URI`. Fix/pivot: state the missing datasource explicitly and avoid claiming `explain()`-level or integration-level confidence when the DB-backed path was never exercised. [Task 2]
- The customer-message and reply write paths still need race analysis; targeted tests passed, but live interleaving behavior was not proven in this review-only rollout. Keep that uncertainty explicit rather than flattening it into “all good.” [Task 2]

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
