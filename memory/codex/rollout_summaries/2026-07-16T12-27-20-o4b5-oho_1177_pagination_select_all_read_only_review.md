thread_id: 019f6ae5-4dea-7a62-b818-7b3d28db18df
updated_at: 2026-07-16T12:35:11+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/16/rollout-2026-07-16T19-27-20-019f6ae5-4dea-7a62-b818-7b3d28db18df.jsonl
cwd: /Users/tualek/ohochat/oho-backoffice
git_branch: feature/tk-sprint-2614/oho-1177-whitelist-business

# Read-only OHO-1177 review found four correctness risks in pagination/select-all integration and several cleanup issues

Rollout context: Reviewed only the requested uncommitted files in `/Users/tualek/ohochat/oho-backoffice` on `feature/tk-sprint-2614/oho-1177-whitelist-business`, using the supplied backend contract as ground truth. No files were edited, staged, committed, or branched. The worktree contained modifications in all three tracked target files and untracked `api/externalMessageApps.js`; line references were refreshed after concurrent scoped changes.

## Task 1: Pagination and select-all correctness review

Outcome: success

Preference signals:
- The user required “read-only, do NOT edit any files” and a written report only -> future reviews should inspect without modifying artifacts.
- The user required every correctness claim to cite actual file lines and requested ranked findings -> future reports should be evidence-first, severity ordered, and avoid speculative issues.
- The user explicitly asked to verify cross-page checkbox preservation, total-based select-all state, async races, last-page recursion, backend-contract adherence, and comment cleanliness -> use these as a checklist for similar reviews.

Key findings, ranked:
1. High: `pages/external-message-whitelist.vue:77-83,174-186,276-304` — Save remains enabled while select-all asynchronously fetches the entire catalog. A save can PATCH the old selection during `fetchAllExternalMessageApps()`, then copy the newly selected IDs into `loaded_app_ids`, making `is_dirty` false although the backend still has the old whitelist.
2. High: `pages/external-message-apps.vue:147-149,201-216,235-256,267-289` — duplicate-name validation races `loadValidationAppList()`. Dialog opening starts the fetch without awaiting it, and Save remains available while `validation_app_list` is empty. Since the backend does not reject duplicate names, a fast submit can create/update a duplicate name; this regresses the prior whole-catalog validation behavior.
3. High: `pages/external-message-whitelist.vue:174-186,224-259` — select-all result is not associated with `whitelist_request_seq` or the initiating business. A select-all request started for business A can resolve after switching to B and overwrite B's `selected_app_ids`.
4. Medium: `pages/external-message-whitelist.vue:145-172` and `pages/external-message-apps.vue:173-199` — page requests have no stale-response guard. Rapid page changes can let an older response overwrite `app_list`, `total`, error state, or loading state, leaving displayed rows inconsistent with the current pager.
5. Low: `api/externalMessageApps.js:12-13,26-33` — helper clamps `$limit` with `_.clamp`, while the verified API rejects values above 50 with BadRequest. Current callers use valid 10/20/50 values, so this is mainly an adapter-contract mismatch and hidden invalid input.

Checked with no issue:
- `components/ExternalMessage/WhitelistAppChecklist.vue:19-28,80-105`: Element UI's checkbox-group model preserves IDs from unrendered pages; toggling a visible checkbox does not replace the full array.
- `components/ExternalMessage/WhitelistAppChecklist.vue:86-95`: all/indeterminate derivation against catalog `total` is consistent with the supplied cascade contract.
- `pages/external-message-apps.vue:173-195`: last-page step-back is bounded and refetches without leaving loading stuck.

Comment/code cleanliness findings:
- Remove dead `.pagination-wrap .selected-text` styling at `components/ExternalMessage/WhitelistAppChecklist.vue:174-185`; no matching element is rendered there, and single-child flex declarations are redundant.
- Shorten/remove the `impact_text` narration and single-use variable at `pages/external-message-apps.vue:298-307`.
- Reduce verbose comments that restate obvious flow in `api/externalMessageApps.js:1-7,78-79,91-92` and `components/ExternalMessage/WhitelistAppChecklist.vue:140-146`; retain only non-obvious constraints such as route key `app_id` and the reason for flex/nowrap overrides.

References: Element UI checkbox source confirmed group updates dispatch the full group value; prior HEAD showed the catalog was previously loaded as a whole list, supporting the duplicate-name regression finding. No tests or runtime browser validation were run.
