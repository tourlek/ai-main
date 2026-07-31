thread_id: 019fb247-9cdc-76a3-a098-2b88906c3dc1
updated_at: 2026-07-30T09:16:07+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-07-45-019fb247-9cdc-76a3-a098-2b88906c3dc1.jsonl
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing
git_branch: tk-sprint-2616/featurn/jera-tab-is-missing

# Read-only Firebase Remote Config re-review completed

Rollout context: Reviewed `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing` on branch `tk-sprint-2616/featurn/jera-tab-is-missing`, without editing tracked files.

## Task 1: Re-review cache-hit signal ordering

Outcome: success

Preference signals:
- The user explicitly required “Fresh, review-only” and “Do NOT edit any files,” with claims grounded in actual `file:line` evidence -> future reviews should remain strictly read-only and evidence-first.
- The user required a verdict up front, separate non-blocking items, and real test counts -> provide compact structured review reports rather than exploratory commentary.
- The user asked not to re-litigate accepted SDK risks #2/#3 -> distinguish previously accepted residual risk from genuinely new blocking findings.

Key steps:
- Verified `setCustomSignals()` is awaited once at `plugins/firebase-remote-config.js:115-121`, before every listener-registration path: cache hit `:123-128`, fetch-failure same-business fallback `:141-145`, and normal/shared-cache path `:137-163`.
- Confirmed `businessId` is resolved once at `:107-108` and reused consistently for signals, cache, and listener behavior.
- Confirmed the accepted-risk comment at `:7-17` accurately describes non-atomic shared IndexedDB `fetch/activate` behavior and SDK-swallowed signal storage failures.
- Confirmed the regression test at `test/plugins/firebase-remote-config.spec.js:96-101` checks both the correct business ID and setter-before-listener ordering. Jest’s `mock.invocationCallOrder` worked in the actual run and would fail against the old cache-hit implementation.
- Reconfirmed safeguards: zero minimum fetch interval `:98`, test override `:173-178`, missing API key return `:180-190`, fire-and-forget initialization `:192-196`, and `degradedToSharedCache` protection `:132-160`.

Failures and how to do differently:
- Initial Jest attempts failed before collection because the sandbox rejected temp/cache writes (`EPERM`). The successful run used the repository’s Jest 27 dependencies with `NODE_ENV=test`, `NODE_PATH`, `--runInBand --cache=false --coverage=false`, and an in-memory suppression of Jest cache/coverage writes. Report environment failures separately from test failures.
- The worktree changed concurrently during review; the final snapshot was re-read and re-tested before the verdict. Future reviews should re-pin hashes/status after any detected concurrent edit.

Reusable knowledge:
- Actual final test result: 1 suite passed, 9 tests passed, 0 failed, 0 snapshots.
- No `node_modules` symlink was created; final check showed none present.
- The test file is untracked (`?? test/plugins/firebase-remote-config.spec.js`) and must be added before commit/MR.
- Non-blocking documentation nit: the header says the wrapper does not trust `activate()` as fallback, but `activate()` is still used when no matching session cache exists (`:141-148`); wording could clarify this exception.
- Hypothesis only: when no `businessId` exists, the wrapper passes `{}` to `setCustomSignals()` (`:116-118`), and the installed SDK treats an empty map as a no-op, so an older persisted signal may remain. This predates the reviewed fix and was not established as a blocking reachable regression.

References:
- Final plugin SHA-256: `0274d13dc3b82cf6a46cdf9628a9ba6a25c27f9fb3d70c00046ed564335f4a4f`
- Final test SHA-256: `b99dafda71d6a067848e11a5a9bf96594da162572a8810bdeddef8fb3c752419`
- Test command basis: `NODE_ENV=test NODE_PATH=/Users/tualek/ohochat/oho-web-app/node_modules ... jest test/plugins/firebase-remote-config.spec.js --runInBand --cache=false --coverage=false`
