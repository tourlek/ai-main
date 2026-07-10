# Task Group: /Users/tualek/ohochat/oho-api / Thai code review of unread-unresponded query changes
scope: Review-only memory for `oho-api` diff reviews around unread/unresponded search filters, query composition, and validation signals; reuse for similar backend review tasks in this repo, not as a generic fix runbook.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar code reviews in this repo or closely related search-hook work, but re-verify exact query shape and test status against the current checkout before treating the findings as still open.

## Task 1: Review `oho-api` unread/unresponded and bulk-send changes, blocker findings

### rollout_summary_files

- rollout_summaries/2026-06-26T10-07-42-z14x-oho_api_unread_unresponded_code_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/06/26/rollout-2026-06-26T17-07-42-019f0366-4780-7b21-a9b4-c309436efcc5.jsonl, updated_at=2026-06-26T10:19:09+00:00, thread_id=019f0366-4780-7b21-a9b4-c309436efcc5, review found blocker-level query-composition regressions)

### keywords

- oho-api, code review, unread, unresponded, convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, Jest, Mongo query composition

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## User preferences

- when the user asked `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม` -> future similar review responses should be direct, Thai, and judgmental instead of generic or hedged. [Task 1]
- when the user asked whether the changes were okay, not for implementation help -> default to review-first and findings-first; do not jump into fixing code unless asked. [Task 1]

## Reusable knowledge

- `convertUnreadUnrespondedQuery.ts` now has a special both-flags path that returns `$or` / `$and` instead of the previous top-level AND-style injection. That shape change also forced `chat-search.hooks.js` and `chat-session/group/search/search.hooks.js` to omit `$or` from `countBaseQuery`, so future review of this area should trace the full query lifecycle, not just the helper. [Task 1]
- `search-query-converter.ts` explicitly preserves only `read_by`, `is_unresponded`, and `read_by.0` as typed filters; any future filter-shape change that introduces `$or` / `$and` needs a corresponding converter update or the parser boundary becomes unsafe. [Task 1]
- `bulk.class.js` now writes `is_unresponded: false` and optionally `$addToSet` on `read_by` directly via `contactModel.updateOne(...)` instead of the previous shared helper, so unread/unresponded review in this diff touched both search behavior and contact-state mutation. [Task 1]
- Focused Jest on `src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts` was the useful validation signal for this diff; `git diff --check` passed, while repo-wide `npm run type-check` was noisy because of unrelated pre-existing TypeScript failures. [Task 1]

## Failures and how to do differently

- Symptom: both unread+unresponded branch fails the focused spec. Cause: the new OR-path behavior is not aligned with the existing contract. Fix/pivot: run the focused Jest first and treat a mismatch at `convert-unread-unresponded-query.spec.ts:106` as a blocker before reasoning about downstream hooks. [Task 1]
- Symptom: unread/unresponded filter breaks when `search` is present. Cause: the new `$or` shape can leak into `search-query-converter` / parser coercion paths that only explicitly preserve `read_by`, `is_unresponded`, and `read_by.0`. Fix/pivot: whenever this filter shape changes, audit typed-filter preservation and parser coercion together. [Task 1]
- Symptom: unread/unresponded filter disappears on `chat.view-sale` style paths. Cause: `addVisibilityFilter()` rebuilds `context.params.query` with its own `$or`, which can overwrite the earlier composition. Fix/pivot: inspect later hook rewrites, not just the helper that first injected the unread/unresponded logic. [Task 1]
- Do not treat `npm run type-check` as decisive proof for this repo when the failure list is already known to be unrelated to the touched diff; prefer targeted tests and exact hook-chain inspection. [Task 1]

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
