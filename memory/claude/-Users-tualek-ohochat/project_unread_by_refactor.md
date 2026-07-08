---
name: project-unread-by-refactor
description: "oho-api unread feature incident (2026-07-08) and the read_by → unread_by refactor state, flag off pending canary relaunch"
metadata: 
  node_type: memory
  type: project
  originSessionId: 01acfddb-9c1c-4ad1-973b-02998bc0e1e8
---

Unread feature incident 2026-07-08: enabling `rt_unread_feature_enabled` melted prod Mongo —
badge count used `read_by: {$nin: [null, id]}` (negation on array = no index, fetch all contacts
per business per poll, no maxTimeMS; requests up to 173s). Flag turned off same night.

Refactor (2026-07-09, code complete, not yet committed/deployed): field inverted to `unread_by`
(members who have NOT read; equality query, index-friendly). Full plan in `oho-api/plan.md`,
incident analysis in `oho-api/incident-unread-count-slowdown-2026-07-08.md`.

Key decisions:
- unread definition: per-member — someone else reading does not mark it read for you
- `unread_by` set to channel-eligible members (channel_permission only, NOT sale visibility —
  read path `addVisibilityFilter` covers that) on customer message; `$pull` self on read/reply
- missing/empty `unread_by` = not unread → no migration needed; `read_by` had no real data
- indexes on Atlas named `idx_contact_unread_filter_v3` / `idx_chat_session_unread_filter_v3`
  (v3 suffix, `_filter_` not `_by_` — model names must match or autoIndex conflicts)
- UAT explain verified: docsExamined 0, count from index keys only
- before flag relaunch: T4 business_id targeting in firebase-remote-config.js (currently caches
  one evaluated config per process — per-tenant conditions can't work), Atlas Search storedSource
  update to `unread_by`, canary per business

**Why:** multi-session refactor spanning code + Atlas + Firebase; next session needs the state
without re-deriving.
**How to apply:** when oho-api unread/badge/chat-search perf comes up, read plan.md and the
incident file first; never reintroduce $nin on read_by/unread_by.
