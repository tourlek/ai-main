thread_id: 019fb720-b89a-7483-ad06-486d9c12dd1e
updated_at: 2026-07-31T07:53:55+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-43-22-019fb720-b89a-7483-ad06-486d9c12dd1e.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: develop

# Read-only audit of the one-sprint `contact_chat_states` refactor plan concluded NO-SHIP

Rollout context: Reviewed the plan against `oho-api origin/develop@6d85562a` and `oho-websocket origin/develop@2c766c62`; local API `develop` was two commits behind. No files, branches, or git state were modified. The stated production flag/data assumptions were accepted as user-provided context, not independently verified.

## Task 1: Audit section 5 refactor plan

Outcome: success

Preference signals:

- The user required “branch develop, read-only — do NOT modify anything” and exact file:line evidence -> future reviews should pin the actual branch/object state, preserve repository state, and cite every substantive claim.
- The user requested a direct `SHIP / NEEDS-CHANGES / NO-SHIP` verdict with numbered findings and severity -> report should be concise, judgmental, severity-ranked, and evidence-first.
- The user explicitly asked to verify all eight concerns, cross-repo mark-read paths, call-site count, and missed work -> similar audits should trace the whole contract rather than reviewing only the proposed schema.

Key findings:

1. **BLOCKER: state schema lacks the ordering timestamp.** Existing SET, CLEAR, and mark-read writes guard on `last_contact_date`; proposed state only has `last_active_at`. These are distinct: `last_active_at` advances for any room action, while `last_contact_date` tracks the latest customer message. State needs both, with explicit initialization. Guarded upsert is unsafe because a missing state doc will not be created, while an upsert can race into duplicate `_id` insertion.
2. **BLOCKER: write centralization is overstated.** Although unread SET helpers are shared, `last_active_at` and scope fields are updated by many independent paths, including member/bot replies, bulk sends, group messages, close-case, spam changes, comments, partner paths, and assignment-related flows. Without synchronization, sorting, spam filtering, and visibility drift.
3. **BLOCKER: state-first page-of-20 pagination breaks current filtering.** `validateMemberChannelPermission` can be applied before the state query, but sale visibility rebuilds contact-specific `$or` filters involving `sale_owner`, `assignee`, `assign_to`, tags, and labels. Fetching 20 state IDs first then filtering contacts yields underfilled/skipped pages; `$in` also does not preserve state sort order.
4. **BLOCKER: keyword search is incompatible with removing fields from Atlas stored source.** Contact and group search currently apply typed unread/unresponded `$match` before `$lookup`, relying on storedSource fields. Removing them makes matches fail. Contact legacy, contact optimized, and group Atlas pipelines all need a different join/filter/pagination design.
5. **BLOCKER: existing `countBaseQuery` cannot be applied directly to the lean state collection.** It retains tab, visibility, assignment, tag, and starred filters, and `computeBadgeCounts` passes the full filter to `countDocuments`. Counts need a join, additional mirrored fields, or a narrower contract; permission and sale visibility must remain enforced.
6. **BLOCKER: backfill source of truth is undefined.** The existing `is_unresponded` classifier is explicitly heuristic based on `chat_status` and timestamps; missing/invalid timestamps can classify as true. Safe migration should copy exact old state only where it exists, avoid inventing historical unresponded state, and define an authoritative unread reconstruction source.
7. **HIGH: emitter claim is false.** Generic and eligibility emitters re-query documents; several write paths ignore update results or use `updateOne`, so there is no universal returned state document. A per-path returned-state contract is required, and emitters still need contact/session snapshots plus merged state.
8. **HIGH: cross-repo mark-read requires coordinated model/deployment changes.** `oho-api` and `oho-websocket` have different resolution, emission, and model behavior. Both still model old `unread_by` fields. New models, tests, and deployment ordering are needed before canary enablement. Quick grep found no unread/unresponded references in `oho-cronjob origin/develop@50f5149a` or `oho-developer-api origin/develop@7bb3bf2a`.
9. **MEDIUM: proposed `type` is ambiguous.** `chat-session.type` already means `messaging | group`; the new state proposal uses `contact | group`. Prefer an explicit entity discriminator such as `entity_type` or preserve room vocabulary and namespace IDs.
10. **INFO: close-case transaction compatibility is feasible.** Both close-case callers pass the same Mongo session to the current clear write. A second collection can participate atomically if its model uses the same app DB connection and receives `{session}`; add rollback tests.
11. **BLOCKER: two weeks is unrealistic for the stated DoD.** Scope includes multiple SET/CLEAR writers, two webhook repos, numerous emitters, many timestamp/scope consumers, three search paths, a new endpoint, backfill, indexes, explain plans, QA, web coordination, and deployment/runbook work. The plan also omits lifecycle synchronization, initialization, endpoint authorization, exact backfill rules, cross-service rollout ordering, and stale-event/upsert tests.

Recommended pivot: either keep storage unchanged and split badge counts from search, or build and synchronize the new state collection plus mark-read paths and dark-verify/backfill it while deferring read cutover. Skipping dual-write of old fields may be justified by the stated flag-off/no-live-data assumptions, but skipping synchronization of ordering and mirrored scope fields is not.

Reusable knowledge:

- Durable unread contract: SET writes are flag-gated; CLEAR writes are unconditional; realtime broadcasts are flag-gated.
- High-value audit path: payload source -> ordering guard -> DB result -> broadcast audience/payload -> search/count/filter/frontend consumer.
- Existing search tests explicitly cover unread/unresponded composition with tags and pagination, so a storage move must preserve those contracts.
- `last_contact_date` and `last_active_at` must not be treated as interchangeable.

Failures and how to do differently:

- CodeGraph was unavailable because the checkout had no `.codegraph` index; the audit correctly pivoted to `git grep` and `git show` against pinned remote objects.
- Git commands emitted macOS temp/cache permission warnings, but source inspection proceeded; validation was structural/source-only, not behavioral or production telemetry.
- Do not accept the plan’s “writes are centralized” or “write returns state” claims without enumerating every direct model write and checking returned values.

References:

- Plan: `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md:99-159`.
- API target: `origin/develop@6d85562a41dd438ae00fb68409ca484cbcb53e12`.
- Websocket target: `origin/develop@2c766c62da63ab1693a8bff928bdb78eceb64c80`.
- Ordering write: `src/services/contact-send-message/contact-send-message.hooks.js:230-239`.
- Search converter: `src/services/chat-session/utils/search-query-converter.ts:149-195`.
- Count base: `src/services/contact/chat-search/build-count-base-query.ts:14-21`.
- Transaction clear: `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:51-69` and close-case callers.
- Mark-read: `src/webhook/stream.js:127-170`; websocket equivalent at `oho-websocket/src/webhook/stream.js:143-205`.
