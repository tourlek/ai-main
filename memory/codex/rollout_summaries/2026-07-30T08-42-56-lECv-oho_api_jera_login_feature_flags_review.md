thread_id: 019fb230-e359-7f60-893d-3467569eb66b
updated_at: 2026-07-30T08:50:25+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-42-56-019fb230-e359-7f60-893d-3467569eb66b.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: tk-sprint-2616/develop

# Read-only re-review found one new ship blocker in the JERA feature-flag login diff

Rollout context: Reviewed `/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing` at branch `tk-sprint-2616/featurn/jera-tab-is-missing`, HEAD `ebfb71e1232797c973f6c7720acf33482db004de`, without editing files.

## Task 1: Review login feature-flag diff

Outcome: partial

Preference signals:
- The user explicitly required a fresh, read-only review grounded in live `git diff`, `git status`, quoted file/line evidence, and independently run tests -> future reviews should distrust summaries, pin the actual worktree state first, avoid edits, and report evidence-first findings in the requested structure.

Key steps:
- Verified status contained only modified `src/firebase-remote-config.js`, modified `src/services/authentication-member/login/login.hooks.js`, and untracked `src/services/authentication-member/login/login.hooks.spec.js`; no `node_modules` or symlink residue remained.
- Confirmed the invalid top-level hook export was fixed: `login.hooks.js` exports only `before`, `after`, and `error`; the feature hook is appended at `after.create`.
- Confirmed genuine rejected flag promises are caught, logged, and return the Feathers context unchanged. `logger.warnWithOptions` exists in `src/logger.js:339-357` with the expected options-first signature.
- Found a new P1 blocker: `fetchServerTemplate()` catches Firebase outages and returns a null/stale template (`firebase-remote-config.js:40-52`). `getBooleanWithState()` converts a missing template to `{ value: false, configLoaded: false }` (`:124-129`), while `getBoolean()` discards `configLoaded` and returns only `false` (`:140-142`). `isJeraFeatureEnabled()` uses this value-only path (`:228-229`), so `Promise.all` resolves and the login response marks all flags as authoritative false instead of entering the hook catch. The frontend then prevents later browser Remote Config values from overriding those false flags via `store/index.js:103-128`, so a configured-true JERA tab can remain hidden during a cold-start Firebase outage.
- The regression test only mocks an artificial rejection (`login.hooks.spec.js:149`), so it does not cover the real outage path.
- Standards review found no material DRY/SOLID/dead-code/TODO issue, but the new JS spec violates the repo preference to use TypeScript where possible, uses a runtime-generated ObjectId rather than fixture-derived data, and has Prettier/ESLint errors. These are non-blocking compared with the outage bug.

Actual validation:
- Standard Jest execution under Node `v20.20.2` was blocked before discovery by sandbox `EPERM` writes under `/T/jest_dx/*`.
- A read-only in-memory Jest cache workaround ran both focused suites successfully: `2 suites passed, 11 tests passed`.
- Final status still had only the expected 2 modified files plus 1 untracked spec; no node_modules residue.

Verdict: ship-blocking issue found: distinguish unavailable Remote Config from an evaluated false before attaching API-authoritative flags. Original two blockers are fixed only for genuine promise rejection and invalid exports.
