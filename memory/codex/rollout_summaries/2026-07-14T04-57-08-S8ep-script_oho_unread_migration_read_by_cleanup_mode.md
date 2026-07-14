thread_id: 019f5efc-691c-7000-8729-9eceb1cc207d
updated_at: 2026-07-14T06:43:07+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T11-57-08-019f5efc-691c-7000-8729-9eceb1cc207d.jsonl
cwd: /Users/tualek/ohochat

# The user asked how to remove legacy `read_by` after running the unread migration, and the rollout confirmed an existing cleanup mode in `script-oho`.

Rollout context: The thread started with a code-review discussion about unresolved blockers around legacy `read_by` / new `unread_by` migration and a remaining event-ordering race. The user then narrowed to operationally asking how to delete `read_by` after running the migration script.

## Task 1: Clarify whether deleting `read_by` closes the migration blockers

Outcome: success

Preference signals:
- The user asked, in Thai, for a short answer and repeatedly narrowed the question: `ขอสรุปสั้นๆ` and then `ถ้างั้นถ้า run migration script ที่ script-oho แล้ว จะลบ read_byยังไง` -> they prefer brief, direct operational answers once the concept is clear, not long re-explanations.
- Earlier they asked whether migration order meant the two blockers were effectively gone; that indicates they care about the exact safety condition for removing legacy `read_by`, not just whether the new feature is enabled.

Key steps:
- Checked the existing `script-oho/unread-unresponded/migrate-unread.ts` implementation rather than guessing.
- Found the script already has a separate `--mode=cleanup-read-by` path and that it is intentionally not auto-chained after backfill.
- Verified the cleanup mode only writes when both `--execute` and `--confirm-cleanup-read-by` are passed.
- Verified cleanup only targets businesses already marked complete in the current env/gate checkpoint, and it unsets `read_by` on both `contacts` and `chat-sessions`.

Failures and how to do differently:
- The first answer correctly warned that `read_by` removal alone only closes one of the original review blockers unless `unread_by` backfill is done first. Future agents should keep that distinction explicit: backfill first, cleanup second.
- The script is still an uncommitted work-in-progress, so future operational guidance should not assume it is production-ready without rechecking the exact file state.

Reusable knowledge:
- `script-oho/unread-unresponded/migrate-unread.ts` already contains a dedicated cleanup path: `--mode=cleanup-read-by`.
- Cleanup is intentionally gated by two flags: `--execute` and `--confirm-cleanup-read-by`.
- Cleanup is checkpoint-gated: it only unsets `read_by` for businesses already marked complete in the current env/gate checkpoint file.
- The cleanup logic currently targets both `contacts` and `chat-sessions` collections.
- The script comments state the intent clearly: `read_by` is the rollback path until `unread_by` has been spot-checked.

References:
- `script-oho/unread-unresponded/migrate-unread.ts`
- `package.json`: `"migrate:unread:cleanup-read-by": "node -r @swc-node/register unread-unresponded/migrate-unread.ts --mode=cleanup-read-by"`
- Cleanup guard snippet: `--execute AND --confirm-cleanup-read-by`
- Cleanup filter snippet: `... HAS_LEGACY_READ_BY` / `$unset: { read_by: "" }`
- Output from assistant’s final guidance: use `NODE_ENV=uat npm run migrate:unread:cleanup-read-by` for dry run, and add `-- --execute --confirm-cleanup-read-by` for the write run

