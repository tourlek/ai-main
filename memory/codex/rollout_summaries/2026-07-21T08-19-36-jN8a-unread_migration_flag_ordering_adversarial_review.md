thread_id: 019f83c2-4d93-7f91-b205-955f99879506
updated_at: 2026-07-21T08:28:49+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T15-19-37-019f83c2-4d93-7f91-b205-955f99879506.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/oho-1171-add-metadata-of-message-send-to-streamchat

# Adversarial read-only review of unread/unresponded migration and flag-ordering claims

Rollout context: The user asked for a strict, evidence-first adversarial code review of `script-oho/unread-unresponded/migrate-unread.ts` and related `oho-api` master-branch code, with a machine-consumed Markdown report covering 13 claims, the safe ordering decision, missed issues, and a ranked improvement plan. The review was read-only, used `git show master:<path>` for `oho-api`, and had to cite file:line evidence for every claim.

## Task 1: Verify/refute 13 draft claims about migration, flags, and runtime behavior

Outcome: success

Preference signals:
- The user explicitly required "Adversarial code review, READ-ONLY" and "Do not trust the draft findings file's claims at face value" -> future similar reviews should independently re-derive from source instead of accepting prior findings.
- The user required "Every claim you make must cite file:line evidence you actually read" -> future reviews should stay citation-dense and avoid uncited synthesis.
- The user requested a structured verdict table with CONFIRMED / PARTIALLY CORRECT / REFUTED / CANNOT VERIFY -> future similar reports should keep itemized verdicts rather than a narrative-only answer.

Key steps:
- Read the entire `migrate-unread.ts` in chunks, plus supporting files for unread/unresponded payloads, clear-write hooks, badge counts, eligibility lookup, schemas, and monitor/reporting helpers.
- Rechecked `oho-api` on `master` via `git show` and compared runtime guards, query shapes, and index declarations against the draft claims.
- Verified the active `.env` block shape without printing secrets, and cross-checked generated status/report artifacts from the prior production run.

Failures and how to do differently:
- The draft overstates several risks by collapsing guarded clear-writes into unguarded decay; future reviews should distinguish "ungated by feature flag" from "unguarded against stale writes." The source uses `last_contact_date` ordering guards on clears.
- Some claim wording relied on current-state assumptions that could not be proven from repo alone (for example, actual production index existence and exact live cluster behavior); those should be downgraded to CANNOT VERIFY or PARTIALLY CORRECT unless a concrete artifact exists.
- The flag-order argument is not answered by migration script comments alone; it requires tracing both write paths and read/count paths together.

Reusable knowledge:
- Customer-message SET writes are feature-gated; clear writes are unconditional but still protected by ordering guards and field-existence guards.
- `migrate-unread.ts` still has a dangerous Step 0 legacy `read_by` rewrite path that can overwrite/normalize `unread_by` after live writes if run in the wrong order.
- The migration script’s current completion/checkpoint model is weaker than the user-visible meaning of "done": checkpoint membership, status persistence, and residual correctness are separate concerns.
- The report should treat `oho-api` master schema/docs as the source of truth, not the checked-out worktree.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:1-84, 108-183, 356-464, 588-966, 971-1168, 1190-1437, 1441-1671, 1679-1879, 1888-2328`
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:12-38`
- `oho-api@master:src/utils/build-clear-unread-unresponded-payload.ts:17-33`
- `oho-api@master:src/webhook/stream.js:94-172`
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:634-686`
- `oho-api@master:src/services/member-send-message/bulk/bulk.class.js:171-208`
- `oho-api@master:src/services/bot-send-message/bot-send-message.hooks.js:540-576`
- `oho-api@master:src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-69`
- `oho-api@master:src/services/contact-send-message/contact-send-message.hooks.js:213-237`
- `oho-api@master:src/utils/channel-eligible-members.ts:10-38, 40-116`
- `oho-api@master:src/utils/compute-badge-counts.ts:32-95, 114-139`
- `oho-api@master:src/services/contact/chat-search/chat-search.class.js:96-111`
- `oho-api@master:src/services/chat-session/group/search/search.class.js:86-99`
- `oho-api@master:src/models/contact.model.js:211-219, 638-664`
- `oho-api@master:src/models/chat-session.model.js:78-86, 128-152`
- `oho-api@master:src/firebase-remote-config.js:184-215`
- `script-oho/unread-unresponded/analyze-business-size.ts:47-65, 246-345`
- `script-oho/unread-unresponded/monitor-migrate-unread.ts:78-176`
- `script-oho/unread-unresponded/helpers/biz-summary.ts:1-72`
- `script-oho/unread-unresponded/helpers/classify-is-unresponded.ts:31-52`
- `script-oho/package.json:5-17`
- `script-oho/ecosystem.config.js:1-77`
- `script-oho/unread-unresponded-deploy-runbook.md:1-183` (local, not on master)

## Task 2: Determine safe ordering and identify missed hazards

Outcome: success

Preference signals:
- The user explicitly asked whether "run migration script first, then turn on flags afterwards" is safe, and asked for a single recommended ordering with minimum required code changes -> future similar reviews should answer with a concrete protocol, not just fault-finding.
- The user asked to consider per-tenant "migrate then flip within minutes" against actual runtime per business -> future similar planning should compare operational exposure window against observed per-tenant durations, not assume a whole-gate atomic switch.
- The user explicitly included the alternative "gate clear-writes on flag || field-exists" -> future similar work should test proposed mitigations against existing guards and failure modes rather than accepting them as self-evident.

Key steps:
- Cross-checked clear-write guards: every clear path found in source uses `last_contact_date`/event timestamp ordering plus existence checks where relevant.
- Compared write-side gating to read-side/count-side gating, especially badge counts and quick-filter conversion.
- Cross-checked the migration script’s own Step 0 behavior against live write semantics and against the production duration spread from prior status/report files.

Failures and how to do differently:
- The initial intuitive answer "migration first, flags later" is not enough because Step 0 can overwrite live `unread_by` from stale `read_by` while flags are already on; future similar decisions should treat backfill/write races as first-class and not only reason about decay.
- The proposed `flag || field-exists` fix is not a real ordering solution; it mostly duplicates current semantics once fields exist and does not solve the live-read/backfill interaction.
- Per-tenant switching must account for long-tail business durations; a few minutes is not a safe assumption when some tenants run for many minutes.

Reusable knowledge:
- The safest protocol from the review was to separate write-preparation from public-read rollout: do not enable the public unread/unresponded experience until migration/backfill is proven correct for that tenant.
- The strongest remaining blocker is Step 0’s ability to rewrite `unread_by` from legacy `read_by` after live writes, which makes flag-on-first risky without additional gating.
- The runtime observation that one business can take much longer than others means "flip immediately after backfill" is not operationally atomic enough to rely on as a safety boundary.

References:
- `oho-api@master:src/webhook/stream.js:127-172`
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:667-685`
- `oho-api@master:src/services/member-send-message/bulk/bulk.class.js:186-202`
- `oho-api@master:src/services/bot-send-message/bot-send-message.hooks.js:564-575`
- `oho-api@master:src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-69`
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:28-38`
- `oho-api@master:src/utils/build-clear-unread-unresponded-payload.ts:17-33`
- `oho-api@master:src/utils/compute-badge-counts.ts:62-95`
- `oho-api@master:src/services/contact/helper-hook/convert-unread-unresponded-query.ts:29-84`
- `script-oho/unread-unresponded/migrate-unread.ts:393-464, 615-674, 733-791, 857-946, 971-1155, 1215-1257, 1394-1420, 1546-1560, 2012-2177`
- `script-oho/reports/migrate-unread-report-prod-gate-small-2026-07-08T14-33-49.md:45-58`
- `script-oho/migrate-unread-by-status-prod-explicit-target.json:1-75`

## Task 3: Identify additional bugs, races, and operational hazards

Outcome: success

Preference signals:
- The user asked for "What the Claude agents missed — bugs, race conditions, correctness issues, or operational hazards not in the draft at all" -> future similar reviews should dig beyond the obvious claims and surface cross-cutting issues.
- The user wanted the highest-value section to be the missed hazards -> future reviews should prioritize latent correctness and ops gaps over cosmetic concerns.

Key steps:
- Traced secondaryPreferred reads, checkpoint completion, status persistence, and cleanup eligibility.
- Compared status vs checkpoint durability and looked for stale-cache / stale-read behavior.
- Compared analyzer coverage to migration scope and checked for schema/report drift.

Failures and how to do differently:
- Guarded bulk updates can fail silently when the read snapshot is stale; future reviews should compare the count of intended writes to actual modified counts, not just the intended batch size.
- Cleanup uses current runtime channel membership, not the exact backfill snapshot; future reviews should treat re-resolving business/channel scope as a potential drift source.
- The monitor and report formats already diverge; future maintenance should reuse one shared step definition source.

Reusable knowledge:
- Status writes are atomic-rename based, but checkpoint writes are direct `writeFileSync`; silent parse errors on checkpoint load become empty-set reprocessing.
- `processedCount`/totals can advance even when a business is not checkpointed yet, so progress UI is not proof of durable completion.
- `analyze-business-size.ts` counts workload based on current filters and cutoff, but it does not include the same `mock_seed_key` exclusion that migration uses.
- The current migration/monitor/reporting surface has schema drift: the migration reports 12 step rows, while the monitor renders a shorter 10-row set.
- There are no direct repo tests exercising the dangerous migration interleavings; only the classifier was extracted into a pure helper.

References:
- `script-oho/unread-unresponded/migrate-unread.ts:1441-1459, 1465-1535, 1660-1671, 1704-1739, 1793-1868, 2012-2177, 2248-2309`
- `script-oho/unread-unresponded/analyze-business-size.ts:151-165, 246-345, 417-442`
- `script-oho/unread-unresponded/monitor-migrate-unread.ts:78-176`
- `script-oho/unread-unresponded/helpers/biz-summary.ts:1-72`
- `script-oho/unread-unresponded/helpers/classify-is-unresponded.ts:31-52`
- `oho-api@master:src/utils/channel-eligible-members.ts:59-93`
- `oho-api@master:src/firebase-remote-config.js:19-70`
- `oho-api@master:src/models/contact.model.js:638-664`
- `oho-api@master:src/models/chat-session.model.js:128-152`

## Task 4: Propose a ranked improvement plan

Outcome: success

Preference signals:
- The user explicitly asked for a ranked improvement plan including CLI ergonomics, dry-run default, confirmation banner, file split, deduplication, and observability -> future similar outputs should separate required pre-prod changes from nice-to-haves.
- The user asked whether splitting the one-shot migration script is worth it -> future similar plans should weigh maintainability against immediate operational risk instead of reflexively modularizing.

Key steps:
- Mapped the current operational entrypoints from `package.json` and `ecosystem.config.js`.
- Compared the migration, analysis, and monitor scripts for duplicated step definitions and output drift.
- Assessed whether boot-time index creation is acceptable for a prod migration.

Failures and how to do differently:
- A large refactor into many files is probably too risky immediately before a one-shot production run; future similar recommendations should prefer a small, high-value extraction around config/state/contracts rather than a full decomposition right before rollout.
- Dry-run defaults and confirmation banners are most valuable when they fail closed and are tied to the actual target DB/host, not just the environment label.
- Index readiness should be validated explicitly before relying on Mongoose boot behavior.

Reusable knowledge:
- The current migration script is already operating as an operational tool with checkpoint/status/report files; any refactor should preserve those artifacts and shared step definitions.
- The deployment runbook is local/ignored and references `db.chat_sessions`, which does not match the actual `chat-sessions` collection name on master.
- Mongoose defaults to `autoIndex:true` unless overridden by app/config options; that means index creation may happen at model init unless deployment config disables it.
- The current codebase already has repeated definitions for step labels and reporting rows across migration, monitor, and analysis.

References:
- `script-oho/package.json:8-11`
- `script-oho/ecosystem.config.js:1-77`
- `script-oho/unread-unresponded/migrate-unread.ts:1888-2328`
- `script-oho/unread-unresponded/analyze-business-size.ts:1-450`
- `script-oho/unread-unresponded/monitor-migrate-unread.ts:1-230`
- `script-oho/unread-unresponded/helpers/biz-summary.ts:1-72`
- `script-oho/unread-unresponded-deploy-runbook.md:24-183`
- `oho-api@master:src/mongoose_connector.js:12-21, 72-87, 117-120`
- `node_modules/mongoose/lib/index.js:66-71, 196-198`
- `node_modules/mongoose/lib/model.js:1304-1316`

