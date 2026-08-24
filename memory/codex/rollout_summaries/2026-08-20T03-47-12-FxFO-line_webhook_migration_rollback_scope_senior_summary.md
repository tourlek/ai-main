thread_id: 01a01d47-b087-73f2-a4b1-1d6c0eae945c
updated_at: 2026-08-20T08:21:51+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T10-47-12-01a01d47-b087-73f2-a4b1-1d6c0eae945c.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration audit, rollback scoping, and senior report

Rollout context: Work in `/Users/tualek/ohochat`, primarily `script-oho/migrate-line-webhook-endpoint`, with production manifests/journals and read-only Mongo/LINE/Cloud Logging checks. The user ultimately required a LINE-only rollback analysis and a Markdown senior summary; no production write was authorized in the final state.

## Task 1: Identify Thai PBS’s original webhook and migration eligibility

Outcome: success

Preference signals:
- The user asked to verify historical rollback/migration state rather than assume from current DB config -> future audits should compare immutable manifest DB state with the LINE endpoint captured before migration.
- The user challenged why Thai PBS qualified for migration -> explain the exact `classification → eligible → apply` path, not just report the endpoint.

Key steps:
- Manifest `migrate-line-webhook-manifest-prod-20260816154033-5ef5ef03.json` showed Thai PBS LINE endpoint: `https://openapi.thaipbs.net/line_webhook/v1/account/thaipbs`.
- DB before-state was `https://webhook.oho.chat/line/webhook/63511e3b5e964b28d3ba5ccb`; `Test-Thai PBS` used `https://openapi.thaipbs.net/line_webhook/v1/account/thaipbs-test`.
- Source inspection found DB `webhook.oho.chat` was classified non-whitelisted, setting `eligible=true`; later LINE inspection changed classification to `line_other` but did not reset eligibility.

Failures and how to do differently:
- The migration tool treated `connection_status` as reporting-only and allowed `line_other` entries to remain eligible. Future migrations must exclude custom/external LINE endpoints unless explicitly approved.

Reusable knowledge:
- `classifyDbEndpoint()` marks a DB host outside `--allowed-host` as `db_non_whitelisted`; `inspectLineForEntry()` can change this to `line_other` without changing `eligible`.
- Apply filters on `entry.eligible`, so `line_other + eligible=true` can be mutated.

References:
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:781-823`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:1146-1158,1342-1350`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-20260816154033-5ef5ef03.json`

## Task 2: Enumerate migrated channels whose original LINE endpoint was external

Outcome: success

Preference signals:
- The user asked for the complete list and later requested IDs directly, saying “ไม่ต้องเช็ค log แล้ว ส่ง id มาจะไปเช็คเอง” -> provide exhaustive machine-readable IDs and avoid unnecessary runtime investigation when the user wants to verify independently.
- The user distinguished historical/manual traffic from real production evidence -> do not infer usage from DB endpoint or migration eligibility alone.

Key steps:
- Correlated all production manifests with migrate journals and counted only mutation phases (`migrated`/`db_synced` handling was separated).
- Generated `/Users/tualek/ohochat/line-migration-non-oho-old-domains.md`.
- Initial broad result: 615 channels, 179 businesses, 109 external domains; Thai PBS accounted for 2 channels on `openapi.thaipbs.net`.
- For the incomplete-before-migration rollback criterion, the relevant pool was 237 channels / 32 businesses; 5 channels had been hard-deleted, leaving 232 live.

Failures and how to do differently:
- A large shell `jq` Markdown generator failed due to quoting; the reliable pivot was to emit JSON first, then format it with Node.
- Do not treat DB before-state as authoritative: 612/613 channels had DB `webhook.oho.chat` while their captured LINE endpoint was external.

Reusable knowledge:
- LINE disconnect hard-deletes channel documents; deleted channels must be excluded from rollback. Source evidence: `disconnect.class.js:10-14` and `disconnect.hooks.js:226-253`.
- Existing artifact contains business/channel IDs, old domains, old URLs, and sample LINE OA names.

References:
- `/Users/tualek/ohochat/line-migration-non-oho-old-domains.md`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-*.json`
- `/Users/tualek/ohochat/script-oho/migrate-line-webhook-manifest-prod-*.json.migrate.journal.json`

## Task 3: Define rollback scope and produce senior Markdown summary

Outcome: partial

Preference signals:
- The user explicitly narrowed rollback to: original LINE endpoint external, pre-migration `connection_status=incomplete`, current status still `incomplete`, no LINE drift, exclude Thai PBS, and “LINE-only” with no DB writes -> future agents must revalidate every predicate immediately before mutation and keep Mongo untouched.
- The user repeatedly stopped execution: “อย่าพึ่ง rollbackนะ” -> analysis, manifests, tests, and dry-runs may proceed, but never perform LINE PUT/Mongo writes without a fresh explicit command.
- The user requested a senior-facing Markdown report -> lead with scope, current state, impact, decision boundary, then put full IDs/URLs in appendices.

Key steps:
- Initial safe scope: 128 channels / 28 businesses after excluding 97 now-complete channels, 5 deleted channels, and 7 LINE-state conflicts; dry-run passed 128/128.
- A later read-only verification found an external process had already changed LINE state: 111/128 now matched the immutable old LINE endpoint, while 17/128 remained on `webhook2.oho.chat`; Mongo remained target-state for all 128.
- Current grouping: 11 businesses changed all scoped channels, 14 changed none, 3 are mixed. Active state matched 128/128; other/unavailable endpoints were 0.
- Created `/Users/tualek/ohochat/line-webhook-rollback-senior-summary.md` with complete 128-channel appendix and business-level summary.

Failures and how to do differently:
- The existing rollback CLI always restores Mongo after changing LINE; it cannot safely implement LINE-only rollback. It also lacks JIT `connection_status` recheck, separate LINE-only journal/token semantics, and robust compensation/reconciliation after LINE PUT timeout or crash.
- Never use the original rollback command for LINE-only work. First implement and test a fail-closed LINE-only mode, then refresh state and derive a new manifest.
- The final observed split-brain state was not attributable to this agent; local dry-run journals had no executed/rolled-back entries. Treat actor and exact timing as unknown.

Reusable knowledge:
- The senior report’s verified state at `2026-08-20T08:19:01.027Z`: 111 exact-old, 17 target, 0 other/unavailable; Mongo target exact for 128; all current status incomplete; Thai PBS 0.
- Impact: 111 LINE endpoints no longer route directly to OHO while DB still says `webhook2`, creating intentional source-of-truth mismatch. Endpoint/HTTP evidence does not prove terminal persistence or successful external processing.
- Final requested mutation scope, if still approved, is 17 channels—not 128—but only after a new read-only refresh and explicit authorization.

References:
- `/Users/tualek/ohochat/line-webhook-rollback-senior-summary.md`
- `/private/tmp/line-128-current-state.json`
- `/private/tmp/line-rollback-executable-incomplete-20260814060805-d10d4e2e.json`
- `/private/tmp/line-rollback-executable-incomplete-20260816154033-5ef5ef03.json`
- Verification counts: `exact_old=111`, `target=17`, `lineActiveDrift=0`, `dbTargetExact=128`
