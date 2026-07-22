thread_id: 019f8412-1e0f-7e93-b5dd-807abd10d7d0
updated_at: 2026-07-21T09:58:39+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/oho-1171-add-metadata-of-message-send-to-streamchat

# Adversarial read-only design review of the proposed `script-oho` catchup mitigation against `oho-api@master`

Rollout context: The user asked for a strict, evidence-cited review of a proposed `--mode=catchup --since=<watermark>` mitigation in `script-oho/unread-unresponded/`, with the fixed constraints that `oho-api` must not change and feature flags stay OFF during migration. The review had to use `git show master:<path>` for `oho-api` and direct reads for `script-oho`, avoid DB/GetStream connections, and answer 8 specific questions.

## Task 1: Review whether catchup can safely repair unread/unresponded state

Outcome: partial

Preference signals:
- The user explicitly required “READ-ONLY, adversarial” and “Do NOT edit files / run migration / connect to DB,” which indicates they want future reviews to stay evidence-first and strictly non-invasive.
- The user required file:line evidence for every claim and to say “cannot verify from repo” when needed, which suggests future similar reviews should default to hard citations rather than synthesis or inference.
- The user asked for an 8-question breakdown plus a final verdict on whether the mitigation is “sound enough to ship,” indicating a preference for structured, decision-oriented adversarial review rather than a broad narrative.

Key steps:
- Pinned backend truth from `oho-api@master` only and treated `script-oho` as proposal state.
- Traced the live customer-message write path for contacts and group chat-sessions, the Stream `message.read` path, member/bot/broadcast/case-close CLEAR paths, the runtime eligible-member cap, and the migration script’s proposed catchup pass.
- Compared the proposed catchup recompute inputs (`unread_by`, `is_unresponded`) against the real write paths and current indexes/guards.
- Checked current `script-oho` implementation details: `classifyIsUnresponded`, catchup watermark selection, stream state handling, checkpoint semantics, paging/maxTimeMS, and completion criteria.

Failures and how to do differently:
- The proposed catchup shape is not exact-repair safe because it recomputes from current eligibility and Stream state rather than from a fully invertible historical event log. Future similar mitigations should be treated as best-effort rebaseline unless they explicitly preserve historical membership/read snapshots.
- `classifyIsUnresponded()` does not match the live state machine closely enough for exact repair: customer SETs can leave `chat_status` stale, and member/bot/broadcast/close-case CLEARs are unconditional but guarded only by timestamps. Future reviews should compare against the full live SET/CLEAR matrix, not just a simplified classifier.
- The watermark (`last_contact_date >= since OR last_active_at >= since`) is not sufficient to find every doc whose badge state can change, because some CLEARs do not advance either timestamp. Future reviews should include explicit timestamp-change vs. state-change divergence checks.
- Catchup’s current guard set is too weak: it guards only timestamps, not `chat_status`, current unread/unresponded fields, channel type, or current membership snapshot. Future similar catchups need to consider that Stream state and member eligibility can change independently of contact timestamps.
- Completion criteria based on aggregate `guardMisses/overCap/streamMissing` are not enough for exact correctness; identity-based residual/retry verification is needed. Future reviews should reject numeric-only “zero residual” claims when they can hide different pending docs.

Reusable knowledge:
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` shows the live customer-message SET payload is split by feature flags: `unread_by` is written only when unread is enabled and a non-null eligible list exists; `is_unresponded` is written only when unresponded is enabled.
- `oho-api@master:src/utils/channel-eligible-members.ts:12-18,59-93` shows the runtime cap at 2000 eligible members; above cap it returns `null` and skips unread tracking entirely. Catchup must not write a partial eligible list in this case.
- `oho-api@master:src/webhook/stream.js:127-149` shows Stream `message.read` pulls `unread_by` only and uses a `last_contact_date` ordering guard, but does not advance timestamp fields.
- `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:661-685`, `src/services/member-send-message/bulk/bulk.class.js:186-202`, `src/services/chat-session/group/member/send-message/send-message.hooks.js:419-428`, `src/services/chat-session/group/bot/send-message/internal/internal.class.js:24-35`, and `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-68` show the main CLEAR paths are unconditional CLEARs with timestamp guards.
- `script-oho/unread-unresponded/migrate-unread.ts:2244-2447` defines catchup as an unconditional recompute over docs touched since `--since`, using Stream read state plus `classifyIsUnresponded()` and write guards on only `last_contact_date`/`last_active_at`.
- `script-oho/unread-unresponded/helpers/steps.ts:129-140` defines the proposed catchup watermark as `last_contact_date >= since OR last_active_at >= since`.
- `script-oho/unread-unresponded/helpers/migration-cli.ts:476-480` rejects catchup without `--include-stream`, and `:502-507` gives catchup its own state-file suffix so it cannot be mistaken for backfill.
- `script-oho/unread-unresponded/migrate-unread.ts:2391-2403` shows the actual catchup write guard only checks `_id`, `last_contact_date`, and `last_active_at`, which is insufficient for exact reconstruction under concurrent live writes.
- `script-oho/unread-unresponded/migrate-unread.ts:2724-2743` shows completion depends only on guard/skip counters in catchup, not on a read-only residual scan like backfill.

References:
- [1] `oho-api@master:src/services/contact-send-message/contact-send-message.hooks.js:157-236` — customer-message path writes `chat_status`/`first_chat_at` unconditionally, then `last_contact_date` plus `unreadPayload` under `$lte` guard.
- [2] `oho-api@master:src/services/chat-session/group/contact-user/send-message/send-message.class.js:19-36` — group customer-message path writes `last_active_at` and then `last_contact_date` plus `unreadPayload`.
- [3] `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` — unread/unresponded flags are independently gated; eligible-member list is skipped when unread flag is off or lookup returns null.
- [4] `oho-api@master:src/utils/channel-eligible-members.ts:12-18,59-93` — 2000-member cap and skip behavior.
- [5] `oho-api@master:src/webhook/stream.js:94-149` — Stream `message.read` `$pull`s unread only, with ordering guard.
- [6] `oho-api@master:src/services/member-send-message/member-send-message.hooks.js:661-685`, `src/services/member-send-message/bulk/bulk.class.js:186-202`, `src/services/bot-send-message/*`, `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-68` — unconditional CLEAR sites with `$lte` guards.
- [7] `script-oho/unread-unresponded/helpers/classify-is-unresponded.ts:27-41` — simplified classifier.
- [8] `script-oho/unread-unresponded/helpers/steps.ts:129-140` and `script-oho/unread-unresponded/migrate-unread.ts:2244-2403` — catchup mode definition and guard set.
- [9] `script-oho/unread-unresponded/migrate-unread.ts:2529-2743` — primary reads, checkpointing, and completion rules.

## Task 2: Assess scale, paging, indexes, and completion criteria

Outcome: partial

Preference signals:
- The user explicitly asked for scale assessment using the repo’s real query plan risk and asked for “what index/paging change would make 5-6M feasible,” which indicates future similar reviews should include concrete index-shaped advice, not just qualitative risk.
- The user also asked whether the tightened completion criteria (`guardMisses===0 && overCap===0 && streamMissing===0 + zero residual`) are satisfiable on a busy large tenant, which signals they care about operational realism, not only logical correctness.

Key steps:
- Checked the paged-read shape and maxTimeMS settings in `script-oho`.
- Inspected contact/chat-session indexes in `oho-api@master`.
- Compared stream batch/delay throttles against the proposed 5–6M scale.
- Compared backfill completion rules against catchup’s simpler completion rules.

Failures and how to do differently:
- The current `_id`-sorted keyset page plus range filters is not aligned with the available indexes, so the query-plan risk is real. Future similar work should verify whether the paging key is a prefix of an actual compound index, and if not, propose an index or a different paging key explicitly.
- `maxTimeMS=60000` is a good failure shield but becomes a hard-stop if the plan is not indexable; future reviews should treat it as a guardrail, not a scalability solution.
- Completion criteria based on aggregate counts are too weak for busy/over-cap tenants, especially when stream eligibility can vary per channel and when catchup skips unknown/over-cap docs. Future reviews should require identity-based residuals or an explicit “best effort” acceptance policy.

Reusable knowledge:
- `script-oho/unread-unresponded/migrate-unread.ts:185-198` centralizes paged reads through `.sort({ _id: 1 }).limit(...).maxTimeMS(QUERY_MAX_TIME_MS)`.
- `oho-api@master:src/models/contact.model.js:429-432,562-565,632-665` show indexes around `last_active_at`, `last_contact_date`, `unread_by`, and `is_unresponded`, but not a compound shape that naturally supports `_id`-sorted pagination for the catchup OR query.
- `oho-api@master:src/models/chat-session.model.js:109-152` shows group-session indexes with similar limitations.
- `script-oho/unread-unresponded/migrate-unread.ts:2332-2434` shows the catchup pass is throttled by `STREAM_QUERY_BATCH=30` and `STREAM_DELAY_MS=300`.
- `script-oho/unread-unresponded/migrate-unread.ts:2788-2849` writes a catchup report and `script-oho/unread-unresponded/migrate-unread.ts:2421-2433` records per-batch heartbeat, which can be reused for operational monitoring.

References:
- [10] `script-oho/unread-unresponded/migrate-unread.ts:185-198` — paged read helper with `_id` sort and `maxTimeMS`.
- [11] `oho-api@master:src/models/contact.model.js:429-432,562-565,632-665` — contact indexes for chat list, unread count, unread list, unresponded list.
- [12] `oho-api@master:src/models/chat-session.model.js:109-152` — chat-session indexes.
- [13] `script-oho/unread-unresponded/migrate-unread.ts:2332-2434` — catchup per-batch Stream pacing and write throttling.
- [14] `script-oho/unread-unresponded/migrate-unread.ts:2724-2743` — catchup business completion rule.
- [15] `script-oho/unread-unresponded/migrate-unread.ts:2788-2849` — catchup report generation.

