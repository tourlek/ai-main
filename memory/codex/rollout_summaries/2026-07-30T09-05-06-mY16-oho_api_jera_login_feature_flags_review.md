thread_id: 019fb245-30e8-7533-a6c3-ba67f1a607a4
updated_at: 2026-07-30T09:14:18+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-06-019fb245-30e8-7533-a6c3-ba67f1a607a4.jsonl
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
git_branch: tk-sprint-2616/featurn/jera-tab-is-missing

# Read-only review of the oho-api JERA login feature-flag fix

Rollout context: Reviewed uncommitted changes in `/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing`, branch `tk-sprint-2616/featurn/jera-tab-is-missing`, HEAD `ebfb71e1232797c973f6c7720acf33482db004de`. No source edits were made.

## Task 1: Review Firebase Remote Config/login feature-flag changes

Outcome: success

Preference signals:
- The user explicitly required “review only, do not edit files,” exact line evidence, real test counts, and a ship-blocking verdict -> future reviews should remain read-only, source-first, and judgmental with file:line citations.

Key steps:
- Inspected the exact diff, including the untracked `login.hooks.spec.js`.
- Traced the cold-start path through `fetchServerTemplate`, shared cache/single-flight logic, `evaluateServerConfig`, `getBooleanWithState`, `getLoginFeatureFlags`, and the login after-hook.
- Grepped external callers of the pre-existing feature-flag functions and verified their implementation/call sites were untouched.
- Audited all changed tests and independently checked the cache-boundary claim with a runtime probe.
- Ran both targeted specs under Node `v20.20.2`; final result was 2 suites and 13 tests passed. No temporary `node_modules` symlink remained.

Failures and how to do differently:
- The initial Jest run failed before discovery because the read-only sandbox blocked temp haste-map/cache writes (`EPERM`). A no-write launcher was then used to execute the tests; report this limitation rather than claiming the ordinary command worked.
- The test comment claiming a 2-of-4 partial result is impossible is incorrect. At the TTL boundary, `Date.now()` calls can straddle cache expiry, producing mixed loaded/unloaded results. The implementation safely omits unloaded keys, but the comment/test should be corrected in a future patch.

Reusable knowledge:
- Cold start is safely handled: failed fetch leaves `cachedTemplate` null; `evaluateServerConfig()` returns null; `getBooleanWithState()` returns `{ value: false, configLoaded: false }`; `getLoginFeatureFlags()` only inserts values when `configLoaded` is true, so it returns `{}` and the login hook attaches no false-valued keys.
- Mapping is correct: JERA, unread, and unresponded use their exact keys, default `false`, and `businessSignal(businessId)`; search optimization uses its exact key, default `false`, and `{}`.
- Existing `getBoolean`, `getString`, `getNumber`, `isSearchOptimizationEnabled`, `isUnreadFeatureEnabled`, and `isUnrespondedFeatureEnabled` implementations and external callers were unchanged. `isJeraFeatureEnabled` is newly added and unused, so it is non-blocking dead code under the repo’s no-dead-code standard.
- The signal test only proves a 3-business/1-no-signal count; it does not prove search optimization is specifically the no-signal check. This is a non-blocking coverage weakness.

References:
- `src/firebase-remote-config.js:35-52,55-71,79-85,119-130,153-186`
- `src/services/authentication-member/login/login.hooks.js:117-129,152-168`
- External callers: `src/webhook/stream.js:159`; `src/services/contact/chat-search/chat-search.hooks.js:55`; `src/services/contact/chat-search/shared-hooks.js:189`; `src/services/bot-send-message/bot-send-message.hooks.js:909`; `src/services/chat-session/hooks/emit-chat-session-event.js:198,256`; `src/utils/resolve-unread-unresponded-flags.ts:22-23`
- Verification: `PASS` for both specs; `Test Suites: 2 passed, 2 total`; `Tests: 13 passed, 13 total`; `git diff --check` passed.
