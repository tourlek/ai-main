---
name: script-oho-migrate-unread-review
description: Review `script-oho/unread-unresponded/migrate-unread.ts` when the user wants a read-only source audit, catchup/backfill correctness check, or one decided rollout plan with file-line evidence.
argument-hint: "[question, mode, or rollout concern]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# Script OHO Migrate Unread Review

## When to Use

Use this when the task is about `/Users/tualek/ohochat/script-oho/unread-unresponded/migrate-unread.ts`, especially:

- `catchup`, `backfill`, `cleanup-read-by`, checkpoint/resume safety, or residual logic
- whether `unread_by` / `is_unresponded` can be reconstructed safely
- migration index/paging/explain readiness
- requests for one decided rollout plan rather than another concern list

Do not use this for implementation unless the user explicitly asks to edit code or run the migration.

## Inputs and Context to Gather

1. Confirm boundaries first.
   - read-only review
   - no DB / Stream connections unless the user explicitly reopens scope
   - whether `oho-api@master` must be treated as the source of truth
2. Pin the two code surfaces:
   - `/Users/tualek/ohochat/script-oho`
   - `/Users/tualek/ohochat/oho-api`
3. Capture the exact question shape:
   - cleanup mechanics
   - checkpoint/cutoff/resume correctness
   - catchup feasibility
   - final rollout plan
4. Read the live migration code first, then the matching `oho-api` write/clear paths.
5. If the user named prior review notes or a brief, read that first, but treat it as suspect until the code matches it.

## Procedure

1. Start with source-of-truth setup.
   - Use `git show master:<path>` or equivalent for `oho-api` when the user says the checked-out tree is stale.
   - Read `script-oho/unread-unresponded/migrate-unread.ts` and nearby helpers directly from the current checkout.
2. Trace the live behavior before judging the migration.
   - SET side: `build-customer-message-unread-payload.ts`
   - CLEAR side: member/bot/bulk/case-close paths and `src/webhook/stream.js`
   - Eligibility limits: `channel-eligible-members.ts`
3. If the question is about `is_unresponded`, audit provenance before entertaining heuristics.
   - Check whether the repo preserves a reply ledger or only timestamps/state snapshots.
   - If it only preserves timestamps plus coarse status, answer that historical reconstruction is not safe.
4. If the question is about `catchup`, inspect:
   - watermark selection
   - current recompute inputs
   - guard fields
   - group-session parity
   - completion criteria
   - over-cap / missing-stream handling
5. If the question is about scale/readiness, inspect:
   - `pagedFind()` sort/paging key
   - available contact/chat-session indexes
   - whether `hint()` / `explain()` is enforced
   - whether done criteria are exact-ID based or aggregate-count based
6. If the question is about cleanup/checkpoints, inspect:
   - `cleanup-read-by` gating
   - checkpoint file contents and suffix logic
   - cutoff parity with other passes
   - atomicity of checkpoint/status writes
7. Synthesize the answer in the user’s requested shape.
   - For adversarial review: answer each numbered question and end with ship/no-ship.
   - For final-plan review: give one decided plan, name assumptions explicitly, and keep concerns subordinate to the decision.

## Efficiency Plan

- Grep exact anchors first: `cleanup-read-by`, `resolvePasses`, `classifyIsUnresponded`, `pagedFind`, `saveCheckpoint`, `buildTotals`, `readByCutoffDate`, `guardMisses`, `overCap`, `streamMissing`.
- Do not read broad repo history unless the current code leaves a real ambiguity.
- Reuse the same audit order each time: live SET/CLEAR contract -> migration logic -> index/paging -> completion proof.
- Stop once you can support the answer with line-cited proof; do not widen into speculative ops advice unless the user asked for rollout planning.

## Pitfalls and Fixes

- Symptom: review assumes the checked-out `oho-api` tree is current. Likely cause: skipped `master` verification. Fix: use `git show master:<path>` when the user flags checkout staleness.
- Symptom: answer drifts into heuristic `is_unresponded` reconstruction. Likely cause: timestamps were mistaken for a reply ledger. Fix: reject the heuristic unless the repo shows authoritative reply provenance.
- Symptom: catchup sounds exact because it replays current Stream state. Likely cause: current state was confused with historical state. Fix: check whether eligibility/timestamps/clears are historically invertible; if not, frame it as best effort only.
- Symptom: migration is called scalable because `maxTimeMS` is set. Likely cause: timeout guard confused with index proof. Fix: require index-aligned paging and fail-closed `explain()`.
- Symptom: cleanup is treated as safe because comments say so. Likely cause: checkpoint contents were not inspected. Fix: read what is actually persisted and what cleanup actually consumes.
- Symptom: done criteria look clean numerically. Likely cause: aggregate residuals can cancel different docs. Fix: prefer exact-ID residual tracking.

## Verification Checklist

- The answer states whether the review was read-only and whether DB/Stream access stayed closed.
- `oho-api` source-of-truth choice is explicit when checkout staleness matters.
- Load-bearing claims cite exact file:line evidence or say `cannot verify from repo`.
- The answer distinguishes reconstructible `unread_by` logic from non-reconstructible `is_unresponded` history when applicable.
- Index/paging conclusions are tied to real index declarations and current query shape.
- Completion claims distinguish aggregate counters from exact-ID proof.
- Cleanup/checkpoint answers name the actual persisted state and any config gaps.
