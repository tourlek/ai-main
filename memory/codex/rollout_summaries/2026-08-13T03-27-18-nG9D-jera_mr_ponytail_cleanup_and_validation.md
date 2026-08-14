thread_id: 019ff928-f2ca-73c0-b341-947ac2fac315
updated_at: 2026-08-13T03:41:12+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-27-18-019ff928-f2ca-73c0-b341-947ac2fac315.jsonl
cwd: /Users/tualek/ohochat

# JERA MR scope cleanup and ship-readiness implementation

Rollout context: The user asked to apply the approved ponytail plan to `oho-api!1293` and `oho-web-app!874`, initially requesting Luna 5.6 max. Luna was unavailable twice; after the user explicitly allowed proceeding, changes were made in isolated worktrees without commit/push.

## Task 1: Apply minimal cleanup and timeout hardening

Outcome: partial

Preference signals:

- The user asked to “ทำตาม plan เลย” and later allowed proceeding without Luna -> once the requested model is unavailable, implementation may proceed only after explicit user authorization; do not silently substitute before that authorization.
- The user requested ponytail simplification -> prefer deletion over speculative caching/realtime/retry abstractions and keep the diff minimal.

Key steps:

- API worktree `/private/tmp/oho-api-mr1293`: added a 2-second fail-soft timeout around login feature-flag evaluation, removed duplicate absence assertions, and merged the redundant pass-through assertion into the success test.
- Web worktree `/private/tmp/oho-web-mr874`: removed `sessionStorage` flag caching, realtime Remote Config listener, error state, window-focus retry, and related tests; retained the immediate JERA flag watcher and in-flight guard.
- Updated GitLab MR descriptions for both MRs to describe the reduced scope and validation.
- Kept changes uncommitted/unpushed; main checkouts were left untouched.

Validation:

- API Node 20: 2 suites, 14 tests passed; SWC build passed; `git diff --check` passed.
- Web Node 22: targeted JERA watcher suite 5/5 and store suite 34/34 passed; Nuxt build passed using `OHO_WEBSOCKET_URL=https://localhost`; `git diff --check` passed.
- Full `MaxPanel.spec.js` and `MaxPanelJeraProfilePanel.spec.js` retained four baseline failures each, reproduced on both base and patched worktrees.
- Real Smartchat deep-link/refresh and contact-tab UAT was not run, so merge readiness remained unverified.

Failures and how to do differently:

- Luna model was unavailable: `Unknown model gpt-5.6-luna; Available models: gpt-5.6-sol, gpt-5.6-terra`. The agent correctly did not substitute until the user explicitly permitted proceeding.
- Web isolated worktrees lacked dependencies; a temporary symlink was used for build and then removed. The first build also required `OHO_WEBSOCKET_URL=https://localhost` because Nuxt config constructs `new URL(process.env.OHO_WEBSOCKET_URL)`.
- The API timeout uses `Promise.race`; the underlying Firebase promise is not cancelled. The MR description asks reviewers to verify no unhandled rejection, but this was not validated with a delayed rejection test.
- Code was changed only in `/private/tmp` worktrees and not pushed, so the GitLab MR HEADs remained unchanged. A future agent must commit/push or provide a patch before claiming the remote MRs contain the cleanup.

Reusable knowledge:

- The approved minimal scope is Level 1 immediate JERA watcher plus Level 3 server login feature flags; Level 2 retry/error recovery is intentionally deferred.
- The Web Remote Config plugin should remain the pre-MR browser fetch fallback; API-provided feature flags remain authoritative through `setRemoteConfigFeatureFlags` filtering.
- Deploy order is API first, then Web. No DB migration or backfill is required.

References:

- API worktree: `/private/tmp/oho-api-mr1293`
- Web worktree: `/private/tmp/oho-web-mr874`
- API timeout: `src/services/authentication-member/login/login.hooks.js:17,103-134`
- Web watcher: `components/MaxPanel.vue:359-368`
- Web plugin simplified to pre-MR behavior: `plugins/firebase-remote-config.js:8-57`
- Reported reduction: approximately `-130 lines`.
- MR descriptions updated remotely, but code changes were not committed/pushed.
