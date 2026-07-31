thread_id: 019fb235-7d01-7910-8c06-037d382b4d1e
updated_at: 2026-07-30T08:56:35+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-47-57-019fb235-7d01-7910-8c06-037d382b4d1e.jsonl
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
git_branch: tk-sprint-2616/featurn/jera-tab-is-missing

# Read-only Firebase Remote Config cache review found three ship blockers

Rollout context: Reviewed uncommitted `plugins/firebase-remote-config.js` and new tests in worktree `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing`, branch `tk-sprint-2616/featurn/jera-tab-is-missing`, HEAD `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608`. No files were edited.

## Task 1: Review cache, Firebase SDK behavior, regressions, and tests

Outcome: fail

Preference signals:
- The user required “Review-only (do not edit files)” and exact file:line grounding -> future reviews should remain strictly read-only and cite only inspected source evidence.
- The user explicitly required checking installed SDK behavior rather than trusting implementation claims -> inspect runtime/type declarations directly and report missing local dependencies honestly.
- The user required a verdict-first structure with ship blockers, nice-to-haves, and per-test quality -> preserve this compact, evidence-first output shape.

Key steps:
- Inspected the live diff, full plugin, full test file, branch/status, and unchanged surrounding paths.
- Resolved Firebase SDK evidence from parent repo `node_modules` because the worktree had no local `node_modules`; installed `@firebase/remote-config` was version `0.8.0`, matching the lockfile.
- Verified `sessionStorage` is origin + top-level-tab scoped; opener tabs may initially copy storage but later changes are independent.
- Traced SDK custom-signal persistence, realtime fetch, shared IndexedDB response writes, `activate()`, observer dispatch, and cache behavior.
- `git diff --check` and `node --check` passed. Jest could not run because sandboxed temp haste-map writes failed with `EPERM`.

Failures and how to do differently:
- Ship blocker 1: cache-hit path at `plugins/firebase-remote-config.js:109-115` returns and registers realtime before `setCustomSignals()` at `:118-124`. SDK loads persisted custom signals from shared storage and realtime fetch uses them, so a tab can fetch another business’s signal and cache those flags under the current business. Set/verify current signals before registering realtime.
- Ship blocker 2: `activate()` is not bound to the response fetched by this tab. SDK writes `last_successful_fetch_response` to shared IndexedDB, then separately rereads it during `activate()` (`index.esm.js:597`, `:286-310`). Another tab can overwrite it between operations; both initial and realtime paths can then commit/cache wrong-business flags. The `degradedToSharedCache` guard only covers explicit fallback activation.
- Ship blocker 3: `setCustomSignals()` catches/suppresses storage failures in SDK (`index.esm.js:512-517`), while the plugin continues and treats the fetch as trustworthy, writing a per-business cache entry. Track whether signals were successfully applied; do not populate the safe cache when signal scoping is uncertain.
- The SDK call shape is correct, but the claim that runtime only invokes `next` is false: declarations include `next`, `error`, and `complete`; runtime invokes `next` and propagates `error`, but no `complete` call was found. The plugin handles `next` and `error`.
- TTL separation is implemented as described: normal cache hits enforce five minutes (`:109-115`), while failure fallback accepts any-age same-business entries (`:137-141`). Five minutes is defensible but not established by a product SLO.
- `degradedToSharedCache` correctly prevents explicit fallback results from being written, but does not protect successful-path/realtime races or failed custom-signal application.
- Test quality: cache-hit, realtime update, and no-business-id tests are weak for their strongest claims; stale-cache test does not verify refreshed write; all Firebase behavior is mocked and none tests shared IndexedDB interleaving. Other fetch/cache/fallback tests meaningfully cover their local behavior.

Reusable knowledge:
- In Firebase Remote Config 0.8.0, IndexedDB uses database `firebase_remote_config`; storage is segmented by app/name/namespace/key, but custom signals and last successful response are not keyed by `business_id`.
- SDK realtime observer signature is `onConfigUpdate(remoteConfig, observer)`; runtime error propagation exists even though the stream never completes.
- Existing store semantics make API-provided feature flags authoritative: `store/index.js:122-128` filters browser Remote Config updates against `feature_flags_api_keys`.

References:
- Plugin: `plugins/firebase-remote-config.js:64-70,95,109-159,169-192`.
- Tests: `test/plugins/firebase-remote-config.spec.js:76-244`.
- SDK: `/Users/tualek/ohochat/oho-web-app/node_modules/@firebase/remote-config/dist/esm/index.esm.js:286-310,351-369,597-624,1343-1388,1761-1826`; declarations `dist/src/api.d.ts:144`, `dist/src/public_types.d.ts:239-252`.
- Validation: `git diff --check` and `node --check` passed; Jest failed with `EPERM` writing a temp haste-map.
