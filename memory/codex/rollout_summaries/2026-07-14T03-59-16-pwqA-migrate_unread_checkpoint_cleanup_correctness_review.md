thread_id: 019f5ec7-6f0f-7e72-a7b6-720887ff0ac8
updated_at: 2026-07-14T04:02:56+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl
cwd: /Users/tualek/ohochat/script-oho
git_branch: main

# Read-only correctness review of `unread-unresponded/migrate-unread.ts` focusing on checkpoint/cleanup safety and cleanup-vs-backfill invariants

Rollout context: The user requested a read-only review of `/Users/tualek/ohochat/script-oho/unread-unresponded/migrate-unread.ts` with strict grounding in code lines/snippets, specifically to verify checkpoint semantics, date-window bounds, crash/resume safety, and a recent `buildTotals()` refactor. The investigation stayed within the file and used line-numbered reads.

## Task 1: Verify checkpoint meaning vs cleanup-read-by assumptions

Outcome: success

Preference signals:
- The user explicitly required: "Trace the actual filter/gating logic, not the comments" and "Every claim about behavior must cite the actual code (line numbers/snippets) you read in this file" -> future similar reviews should prioritize source lines over doc comments and treat comments as non-binding until enforced by code.
- The user requested a "structured_output_contract" with per-item CONFIRMED/REFUTED/PARTIALLY-CONFIRMED and line numbers -> future review responses should keep a tight evidence-first format.

Key steps:
- Read `INCLUDE_PARTIAL`, `runLegacyReadByReconcilePass`, `partial`, and checkpoint write logic around `runForBusiness`.
- Traced cleanup eligibility to `loadCheckpoint()` membership only, with no extra proof field or env guard.
- Confirmed backfill can mark a business complete even if `INCLUDE_PARTIAL` was false/unset, because `partial` only tracks budget exhaustion and checkpointing only checks `!isDryRun && !result.partial`.

Failures and how to do differently:
- The comments claim cleanup is safe after unread_by is “verified,” but the code does not enforce that. Future reviews should not accept comment-level guarantees without a corresponding persisted signal.
- `skippedNoChannel` is returned from reconcile but is not used as a checkpoint gate; that is a subtle mismatch worth checking whenever “verified” is claimed.

Reusable knowledge:
- `runLegacyReadByReconcilePass()` is opt-in only under `INCLUDE_PARTIAL`; absence of that env means a business can still become checkpoint-complete without legacy Stream verification.
- Cleanup mode trusts checkpoint membership directly: `eligible = businessIds.filter(id => backfillCompleted.has(id.toString()))`.
- Checkpoint file contents are just `{ completed: [...] }`; there is no per-business metadata about whether legacy reconcile ran, whether the current Stream verification was complete, or whether a pass skipped unresolved channels.

References:
- `migrate-unread.ts:132-135` (`INCLUDE_PARTIAL` definition)
- `migrate-unread.ts:1335-1391` (legacy reconcile only inside `if (INCLUDE_PARTIAL)`)
- `migrate-unread.ts:1398` (`partial = budget !== null && budget <= 0`)
- `migrate-unread.ts:2153-2159` (`!isDryRun && !result.partial` controls checkpointing)
- `migrate-unread.ts:1454-1458` (`saveCheckpoint()` only stores completed IDs)
- `migrate-unread.ts:1792-1798` (cleanup trusts checkpoint membership)
- `migrate-unread.ts:890-896`, `migrate-unread.ts:965` (reconcile can skip unresolved channels and still return normally)

## Task 2: Verify cleanup-read-by date window vs backfill/reconcile window

Outcome: success

Preference signals:
- The user explicitly asked whether cleanup should apply the same `DAYS/readByCutoffDate` bound as steps 0a/0b and reconcile, and to "confirm whether this gap is real" -> future reviews should always compare filter shapes across all related passes, not just the main one.
- The user also asked to trace whether `resolveBusinessIds`, checkpointing, or budget handling prevents old docs from slipping through -> future reviews should check surrounding invariants, not only the obvious filter.

Key steps:
- Traced `DAYS` to `readByCutoffDate`, then compared step 0a/0b filters and legacy reconcile filters against cleanup filters.
- Confirmed cleanup has no `last_active_at` bound, while backfill and reconcile do.
- Checked `resolveBusinessIds`, checkpoint scope, and `MAX_DOCS_PER_BIZ` to see if they indirectly prevent stale docs from being cleaned; they do not.

Failures and how to do differently:
- The cleanup filter operates on all `HAS_LEGACY_READ_BY` docs in eligible businesses and channel sets, regardless of age. That means older docs outside the verification window can still have `read_by` removed.
- The file’s comment says the legacy reconcile pass scans the full population, but the actual code still applies `cutoffDate`; comments and code diverge here, so future reviews should verify both the pass-level filter and any per-pass cutoff propagation.

Reusable knowledge:
- `runReadByToUnreadByPass()` and `runLegacyReadByReconcilePass()` both accept a cutoff and apply `last_active_at` gating.
- Cleanup mode does not carry any date window: it only filters by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`.
- `resolveBusinessIds()` only filters the business list and the set of channels with `connection_status: "complete"`; it does not encode doc freshness or backfill coverage.
- `MAX_DOCS_PER_BIZ` is `null`, and `partial` only means budget exhaustion; it does not protect against “unverified but not partial” business runs.

References:
- `migrate-unread.ts:127-128` (`DAYS = 90` by default)
- `migrate-unread.ts:1920-1921` (`readByCutoffDate` derivation)
- `migrate-unread.ts:1219-1225` (step 0a/0b cutoff application)
- `migrate-unread.ts:855-858` (legacy reconcile cutoff application)
- `migrate-unread.ts:1820-1830` (cleanup filters: no cutoff)
- `migrate-unread.ts:1853-1863` (cleanup `$unset read_by` writes)
- `migrate-unread.ts:1714-1729` (`resolveBusinessIds()` only filters business IDs with complete channels)
- `migrate-unread.ts:137` (`MAX_DOCS_PER_BIZ = null`)

## Task 3: Check checkpoint/status/crash-safety and totals consolidation

Outcome: success

Preference signals:
- The user asked about shared `CHECKPOINT_FILE`/`STATUS_FILE`, `CHECKPOINT_SUFFIX`, and whether a partial/budget-limited pass can incorrectly be marked complete -> future reviews should explicitly test these state-machine boundaries.
- The user requested a “sanity-check” for the totals object consolidation and asked to confirm no third hand-built totals object literal remains -> future reviews should scan for duplicate literal builders after refactors that claim to centralize state.

Key steps:
- Traced file naming and mode dispatch for cleanup vs backfill.
- Verified cleanup uses the same naming scheme but does not write status/checkpoint, so it cannot overwrite backfill state.
- Checked that the suffix logic isolates `-explicit-target`, `-gate-X`, and default runs, but also noted the suffix does not encode all semantic config dimensions.
- Verified the totals refactor: both status save call sites now use `buildTotals()` and no third manual totals literal remained.

Failures and how to do differently:
- `saveCheckpoint()` writes directly to the checkpoint file without the same temp-file/rename protection used by `saveStatus()`, so a crash during checkpoint write could corrupt the file and make `loadCheckpoint()` fall back to an empty set.
- A shared suffix is enough for gate/target isolation, but not enough to capture every config dimension (for example, cutoff/stream/partial semantics are not serialized into the checkpoint key), so future reviews should inspect whether a persisted proof needs more than just gate/target identity.

Reusable knowledge:
- Cleanup mode reads checkpoint membership only and does not itself mutate `CHECKPOINT_FILE` or `STATUS_FILE`.
- `CHECKPOINT_SUFFIX` is `-explicit-target` when explicit targets are set, otherwise `-gate-${GATE_FILTER}`, otherwise empty.
- Partial/budget exhaustion is handled consistently: `partial` is derived from budget, and checkpointing is skipped when `result.partial` is true.
- The consolidated totals helper is actually wired in both status save call sites: the mid-business flush and the end-of-business flush.

References:
- `migrate-unread.ts:204-210` (`CHECKPOINT_SUFFIX`, `CHECKPOINT_FILE`, `STATUS_FILE`)
- `migrate-unread.ts:1751-1760` (cleanup mode logs and uses the shared checkpoint file)
- `migrate-unread.ts:1792-1798` (cleanup membership check only)
- `migrate-unread.ts:1454-1458` (`saveCheckpoint()` implementation)
- `migrate-unread.ts:1665-1667` (`saveStatus()` temp-file rename)
- `migrate-unread.ts:1985-2009` (`buildTotals()` single source of truth)
- `migrate-unread.ts:2028-2040`, `migrate-unread.ts:2162-2173` (both `saveStatus()` call sites use `buildTotals()`)
- `migrate-unread.ts:2075-2081` (checkpoint skip logic on resume)
- `migrate-unread.ts:2153-2159` (only non-partial, non-dry-run businesses are checkpointed)
- `migrate-unread.ts:2317-2326` (mode dispatch: cleanup vs backfill)

## Other issues found

- Cleanup resolves the current channel list at runtime, so if a business gains new `connection_status: "complete"` channels after backfill, cleanup can now target docs that were not part of the original backfill snapshot.
- `loadCheckpoint()` swallows JSON parse/read errors and returns an empty set, which can convert a corrupted checkpoint file into a silent “start over” behavior.
- `processedCount++` happens before the checkpoint decision, so status may show business progress even for runs that are not checkpointed.

## Totals-consolidation sanity check

Verdict: confirmed — there is no third hand-built totals object literal; both `saveStatus()` call sites use `buildTotals()`.
