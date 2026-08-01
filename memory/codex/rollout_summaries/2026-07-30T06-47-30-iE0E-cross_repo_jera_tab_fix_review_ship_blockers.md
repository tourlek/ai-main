thread_id: 019fb1c7-36c8-7a02-92cc-6ab6c74fcc58
updated_at: 2026-07-30T06:56:14+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T13-47-30-019fb1c7-36c8-7a02-92cc-6ab6c74fcc58.jsonl
cwd: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing
git_branch: tk-sprint-2616/featurn/jera-tab-is-missing

# Cross-repo read-only review found ship blockers in the JERA race fix

Rollout context: Reviewed uncommitted changes in separate `oho-web-app` and `oho-api` worktrees without editing files. Targeted Jest runs were attempted but blocked by sandbox `EPERM` haste-map writes.

## Task 1: Review oho-api login feature-flag hook

Outcome: fail

Key findings:
- **Ship blocker:** `login.hooks.js:138-145` exports `addFeatureFlagsToResult` as an extra top-level property, while `login.service.js:16` passes the entire object to `service.hooks(hooks)`. Feathers validates every top-level key and throws `'<name>' is not a valid hook type`; the service cannot register/start.
- **Ship blocker:** `Promise.all` at `login.hooks.js:121-126` has no recovery. A flag evaluation rejection aborts login after earlier after-hooks have run; `error.create` is empty. `firebase-remote-config.js` catches template-fetch errors but leaves `template.evaluate()` unguarded.
- `business_id` is server-derived: authentication runs first, membership is queried using authenticated `params.user._id`, and `params.member` is refreshed from the database before the flag hook reads it (`login.hooks.js:36-70, 146-150`).
- JERA flag logic is not meaningfully DRY-violating; it reuses `businessSignal()` and `getBoolean()` like the unread/unresponded wrappers.
- New tests mock all Remote Config helpers and test output shape, business arguments, and concurrency, but directly import the helper. They miss invalid Feathers registration, rejection behavior, real flag implementation, and production hook wiring. The pass-through identity test is tautological, and handcrafted IDs violate the repo’s fixture-derived testing standard.

## Task 2: Review oho-web-app MaxPanel fix

Outcome: partial

Key findings:
- The flag watcher is reactive and `immediate: true` (`MaxPanel.vue:361-374`), so a late `false → true` flag update can trigger the JERA connection fetch. Focus retry is correctly gated by enabled/idle/error state (`:375-383`), and fetch bookkeeping sets/clears the error flag (`:725-753`).
- The removed contact-change behavior is not reintroduced: `contact_id` only resets `active_profile_source` (`:402-406`); fetch calls are from flag/focus watchers or explicit connect/disconnect actions (`:361-383, 754-760`).
- Tests cover individual handler branches and error/success bookkeeping, but invoke watchers directly. They do not prove Vuex-to-Vue reactivity, `immediate: true`, real visibility-change flow, or in-flight concurrency. The “flag re-evaluates true” case is artificial for a boolean watcher.

## Task 3: Frontend/backend interaction

Outcome: partial

- The mechanisms are connected: login commits `res.feature_flags` into Vuex (`store/index.js:300-302, 502-512`), and MaxPanel reads the same flag (`MaxPanel.vue:447-448`). API keys are authoritative and later browser Remote Config values are filtered (`store/index.js:103-128`), preventing ordinary overwrite/double-fetch races.
- A remaining recovery risk exists: if server Remote Config cold-start evaluation returns default `false`, the API marks that false value authoritative and a later browser `true` cannot replace it, potentially keeping JERA hidden for the session.
- Targeted test execution failed with `EPERM` while Jest attempted to write haste-map files; no test pass was verified.
