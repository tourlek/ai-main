thread_id: 019fb73d-b08e-7d42-947c-493c374ac7c0
updated_at: 2026-07-31T08:25:23+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T15-15-01-019fb73d-b08e-7d42-947c-493c374ac7c0.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: develop

# Rev.2 adversarial review of unread/unresponded one-sprint refactor plan

Rollout context: Read-only review of `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md` against `oho-api`. The local branch was `develop@fadce8537`, four commits behind `origin/develop@a98fb25a`; OHO-1272 worktree was `bbe0ac735` with an uncommitted 21-file diff. No files were modified and no tests were run.

## Task 1: Review rev.2 and produce a production-enableable sprint plan

Outcome: success

Preference signals:
- The user explicitly required an “Adversarial review round 2,” aggressive scope challenge, exact `file:line` evidence, a verdict, numbered findings, prioritized backlog, and cut-line -> future reviews should be direct, evidence-first, read-only, and avoid rubber-stamping revised plans.
- The user asked to re-read the plan and verify it against the live repo rather than trusting the prior review or plan claims -> pin branch/worktree revisions and inspect current source/diffs before carrying findings forward.

Key findings:
- Verdict: `NEEDS-CHANGES`.
- Track B is premature. Under the planned contact-first read direction, `last_active_at` remains needed on the source contact/chat-session collection for sorting, while `is_spam` can remain source-side. Only identity/scope, ordering metadata, `unread_by`, and `is_unresponded` are needed for an initial dark state write. The plan itself says Phase 2 should first measure member distribution and SET latency (`plan:237-240`) but rev.2 skips that go/no-go.
- Badge counts cannot currently be driven from only `{business_id, channel_id, is_spam, unread_by}` without changing the contract: `countBaseQuery` preserves tab filters such as status, assignment, tags, starred scope, and sale visibility (`build-count-base-query.ts:17`; integration test `chat-search-badge-count-scope.test.ts:4-18`).
- Feature flags currently gate customer SET payload/eligible-member resolution only. `buildCustomerMessageUnreadPayload` calls `getEligibleMemberIds` only when unread is enabled (`src/utils/build-customer-message-unread-payload.ts:28-37`), but the common `last_contact_date` write still occurs on every inbound message (`contact-send-message.hooks.js:213-239`). CLEAR and mark-read are intentionally unconditional (`build-clear-unread-unresponded-payload.ts:18-20`; `webhook/stream.js:94-160`). A new dark write would therefore add hot-path writes even with feature flags off unless protected by a dedicated per-business dark-write flag, timeout/maxTimeMS, fail-soft handling, metrics, and repair path.
- Cross-collection ordering is not solved by copying `last_contact_date`: old/new writes can commit in different orders. State needs a monotonic event timestamp or sequence and conditional updates that reject older events. Backfill must also avoid overwriting newer live state.
- Track A has no user-visible performance effect without a web consumer. The API currently computes badges before returning search results (`chat-search.class.js:96-115`), while rev.2 excludes web work. Either ship a minimal web change using `include_counts=false`/the new endpoint for silent and realtime refetches, or drop Track A.
- OHO-1272 must land before Track B. The worktree centralizes clear writes through `applyClearUnreadUnrespondedWrites` across eight paths, including bot, broadcast, inform, notify, group bot/member, bulk, and member send. `origin/develop` overlaps six of those files after `bbe0ac735`, so Track B first creates conflict and semantic-regression risk.
- Exact `diff = 0` is not a valid dark-verify criterion because old/new writes can race and fail-soft writes can leave transient stale state. Use normalized semantic comparison, mismatch age/grace windows, repair/reconciliation, and require zero persistent aged mismatches across two full scans plus recorded mismatch/error-rate limits.
- The DoD is not production-enableable: it ends at staging/UAT backfill and a design document, while production backfill tooling, Atlas index verification, rollout metrics, and runbook remain unresolved.

Prioritized backlog and cut-line:
1. Rebase/land OHO-1272 on current `origin/develop`; run targeted clear/cache/flag specs and verify all clear sites.
2. Decide historical-data semantics (start fresh vs reconstruct); build idempotent, dry-run-default, allowlisted, resumable migration tooling.
3. Verify deployed Atlas indexes with `explain()` and define metrics/rollback thresholds.
4. Deliver an end-to-end badge-count performance change: minimal web consumer plus API behavior that stops inline count work; otherwise drop Track A.
5. Canary existing storage in production and measure eligible-member distribution, document/index size, and SET latency.
6. Complete the read/state design covering contact-first lookup, badge scope, monotonic ordering, repair, dark-write flag, and final indexes.

Cut-line: do not implement Track B dual-write, mirror `last_active_at`/`is_spam`, state-backed counts, read cutover, or old-field deletion this sprint unless measurements prove existing-storage writes are the bottleneck and the design is approved.
