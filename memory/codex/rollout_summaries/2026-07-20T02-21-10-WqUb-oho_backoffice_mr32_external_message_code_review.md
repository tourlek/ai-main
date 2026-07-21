thread_id: 019f7d53-c7cc-7ea2-9fb1-76d2f5ace193
updated_at: 2026-07-20T02:28:26+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/20/rollout-2026-07-20T09-21-10-019f7d53-c7cc-7ea2-9fb1-76d2f5ace193.jsonl
cwd: /Users/tualek/ohochat

# Code review of MR !32 for OHO backoffice external-message admin UI

Rollout context: The user asked for a code review of GitLab MR !32 in `/Users/tualek/ohochat/oho-backoffice`, using the `code-reviewer` skill and focusing on the actual diff/lines in GitLab. The review was read-only and centered on the new external-message catalog/whitelist UI, API wrapper, and menu entries. The reviewer explicitly prioritized security → performance → correctness → maintainability and used line-cited evidence from the live head SHA `18d4af10`.

## Task 1: Review MR !32 external-message catalog/whitelist UI

Outcome: partial

Preference signals:
- The user asked in Thai to “review mr นี้ให้หน่อย” and attached the `code-reviewer` skill -> future review requests in this repo should assume the user wants a structured code review, not implementation.
- The earlier memory for this same area already emphasized line-cited, read-only review habits; this rollout reinforced that the user cares about concrete file/line evidence and repo-specific behavior checks.
- The review output was expected to be merge-oriented and severity-ranked; the final response gave P1/P2 style blockers instead of generic commentary, which matches the user’s likely preference for actionable review findings.

Key steps:
- Pulled `glab mr view 32 -F json`, `glab mr diff 32`, and the repo’s `AGENTS.md` to anchor review on the actual MR metadata, diff refs, and review rules.
- Inspected the new files introduced by the MR: `api/externalMessageApps.js`, `components/ExternalMessage/WhitelistAppChecklist.vue`, `pages/external-message-apps.vue`, `pages/external-message-whitelist.vue`, and `store/modules/menu.js`.
- Verified the MR moved external-message catalog/whitelist flows from mock to real Core API endpoints and introduced pagination, select-all, search, validation, and request-sequence guards.
- Ran static checks: `git diff --check` passed; Prettier reported a formatting warning only in `api/endpoint.js`.
- The final review identified four main issues, two of them blockers: a late whitelist save can overwrite the newly selected business’s baseline, and resetting the whitelist page to 1 does not refetch page 1 data, leaving stale rows visible. Two medium issues were also called out: dialog save operations were not bound to a dialog instance, and debounced business search could still be overwritten by an older in-flight response.

Failures and how to do differently:
- The MR was not cleanly “success” because the review found two correctness blockers that should be fixed before merge.
- The review also exposed a recurring failure mode for this feature area: async state updates were guarded in several places, but not consistently across save/search/page-reset paths. Future review or implementation work should re-check every await boundary for request identity / state drift.
- Prettier warning on `api/endpoint.js` means formatting should be run before merge even when functional diff is otherwise correct.

Reusable knowledge:
- This feature area is highly race-prone: business switching, save, list refresh, dialog open/close, and debounced search all need request-identity or snapshot guards.
- In `pages/external-message-whitelist.vue`, changing business resets `app_page` but does not automatically reload the page-1 list; that state transition should be treated as a correctness checkpoint.
- `fetchAllExternalMessageApps()` is used for whole-catalog validation and select-all behavior; it walks every page because the API wrapper only supports paginated reads.
- The MR intentionally keeps `app_id` immutable on edit to avoid orphaning existing whitelists, which is a durable data-integrity rule for this admin model.
- The repository’s Nuxt app uses `glab -F json` for GitLab MR inspection and `git diff --check` is a useful quick sanity check for these reviews.

References:
- [1] `glab mr view 32 -F json` showed MR !32 metadata: source branch `feature/tk-sprint-2614/oho-1177-whitelist-business`, target `develop`, head SHA `18d4af10d7c74fd8a736a4e839df8052f9c02900`.
- [2] `api/externalMessageApps.js` introduced Core API wrappers and page-walking validation: `fetchExternalMessageApps`, `fetchAllExternalMessageApps`, `searchBusinessDirectory`, `fetchBusinessWhitelist`, `updateBusinessWhitelist`.
- [3] `pages/external-message-whitelist.vue:321-333` was flagged because `saved_app_ids` from an older save can overwrite `loaded_app_ids` for a newer business if the user switches during save.
- [4] `pages/external-message-whitelist.vue:269-279` was flagged because `app_page = 1` is set without reloading the first page, so the pager can show page 1 with stale rows from another page.
- [5] `pages/external-message-apps.vue:284-301` was flagged because the save path awaits validation before snapshotting dialog state, so a reopened dialog can be affected.
- [6] `pages/external-message-whitelist.vue:211-226` was flagged because debounced search alone does not prevent older in-flight requests from winning and replacing newer results.
- [7] `git diff --check` passed; `prettier --check` warned on `api/endpoint.js`.

## Task 1: Review MR !32 external-message catalog/whitelist UI

task: code review of GitLab MR !32 for external-message admin UI changes
task_group: oho-backoffice code review / nuxt2 admin UI
task_outcome: partial

Preference signals:
- when the user asked “review mr นี้ให้หน่อย” with the `code-reviewer` skill, they wanted a real review workflow rather than a rewrite or implementation task.
- when the review involved this external-message area, the user’s accepted pattern was to surface concrete blocker-level races and line-cited findings, not just general “looks good” feedback.

Reusable knowledge:
- `glab mr view 32 -F json` returned the live MR metadata and diff refs; `glab mr diff 32` gave the substantive patch.
- `git diff --check` passed on the MR, but Prettier warned on `api/endpoint.js`.
- The feature introduces several async state transitions that must be guarded by request sequence or snapshot logic to avoid cross-business or stale-response corruption.

Failures and how to do differently:
- Treat page resets, saves, and search as independent async boundaries; do not assume earlier guards cover later state transitions.
- When a dialog can be closed/reopened during validation, snapshot the dialog/form state before the first await or bind the operation to a dialog token.

References:
- `pages/external-message-whitelist.vue:321-333`
- `pages/external-message-whitelist.vue:269-279`
- `pages/external-message-apps.vue:284-301`
- `pages/external-message-whitelist.vue:211-226`
- `api/externalMessageApps.js`
- `glab mr view 32 -F json`
- `glab mr diff 32`
- `git diff --check b3a96113c8c15408a487352d5e38a7ec5d50c3ef 18d4af10d7c74fd8a736a4e839df8052f9c02900`
