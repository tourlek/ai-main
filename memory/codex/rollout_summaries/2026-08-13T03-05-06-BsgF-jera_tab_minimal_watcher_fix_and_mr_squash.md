thread_id: 019ff914-9f48-7db3-aec9-3c772585e8f1
updated_at: 2026-08-13T06:57:27+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-05-06-019ff914-9f48-7db3-aec9-3c772585e8f1.jsonl
cwd: /Users/tualek/ohochat

# JERA tab race fix narrowed and pushed

Rollout context: The user asked to review two GitLab MRs for over-engineering, then requested a minimal fix for the JERA tab disappearing when the feature flag resolves after `MaxPanel` mounts. The user explicitly required `gpt-5.6-luna` at max, and the task was completed in `/private/tmp/oho-web-mr874` without touching the API MR.

## Task 1: Narrow JERA fix and remove over-engineering

Outcome: success

Preference signals:
- The user corrected scope drift: `completeClaimedDedup()` and Facebook webhook logic are unrelated to the JERA tab issue -> future agents must trace the render/fetch path first and keep JERA work limited to feature-flag resolution, `MaxPanel`, and partner-connection fetching.
- The user explicitly requested Luna 5.6 max; the direct delegation API rejected that model, but a Codex task creation path supported it -> use the explicitly requested model only and do not substitute another model.
- The user prefers minimal, focused diffs and wants unrelated MRs closed rather than expanding scope -> delete speculative cache/listener/retry layers when the root cause is a simple lifecycle race.

Key steps:
- Root cause confirmed: `MaxPanel` mounted while `rt_jera_feature_enabled` was false, so the old mount-only fetch did not run; when the flag later became true, the tab rendered but partner connections were still empty.
- Luna reduced the Web MR to an immediate watcher on `is_jera_feature_enabled`, with guards for false flag, in-flight fetch, and already-loaded connections.
- Removed the Web MR's `sessionStorage` cache, Firebase realtime listener, window-focus retry, and extra error state/retry behavior. `plugins/firebase-remote-config.js` now matches the target base.
- Reduced tests to four focused watcher cases: fetch on enable, no refetch after data exists, no fetch while in flight, and no fetch when disabled.
- API MR `!1293` was not changed or closed by the agent; the user indicated they would close it themselves.

Validation:
- Focused watcher tests: 4 passed.
- Store/Remote Config precedence tests: 34 passed.
- Full `MaxPanel.spec.js`: 7 passed, 4 pre-existing failures in unrelated verification-token tests.
- `git diff --check`: passed.
- Manual Smartchat/contact-tab UAT and Web build were not run; merge-readiness was not claimed before UAT.

Delivery:
- Squashed the Web branch's three commits (`ef2e687a`, `c031b35c`, `ffe26f0e`) into `c67c0018 fix: fetch JERA connections after feature flag resolves`.
- Force-pushed only `tk-sprint-2616/feature/jera-tab-is-missing` with `--force-with-lease`; branch and remote matched and worktree was clean.
- Effective diff: only `components/MaxPanel.vue` and `test/components/MaxPanel.spec.js`, 54 insertions and 5 deletions.

Failures and how to do differently:
- The first direct `spawn_agent` attempt failed because `gpt-5.6-luna` was unavailable in that API surface; do not silently substitute `gpt-5.6-sol` or `terra`. Use a supported task-creation path or report inability.
- Earlier review incorrectly treated API bootstrap, Remote Config caching, retry logic, and webhook dedup as part of the direct JERA fix. Avoid this by identifying the exact runtime chain from symptom to render/fetch before proposing cross-repo changes.
- The Web worktree initially had over-engineered cache/realtime/retry code and extra tests. The final implementation correctly removed them, but manual UAT remained outstanding.

Reusable knowledge:
- In `MaxPanel.vue`, the minimal race fix is an `immediate: true` watcher on `is_jera_feature_enabled`; fetch only when enabled, not already fetching, and `fetched_jera_partner_connections` is empty.
- The watcher is not a continuous spam source: it has no interval, focus listener, or realtime listener; the method also has an in-flight guard. Remounts and explicit connect/disconnect refreshes can still fetch intentionally.
- `completeClaimedDedup()` belongs to `/Users/tualek/ohochat/oho-webhook` Facebook webhook processing and is unrelated to the JERA tab render/fetch path.

References:
- Web MR: https://gitlab.boonmeelab.com/oho/oho-web-app/-/merge_requests/874
- API MR: https://gitlab.boonmeelab.com/oho/oho-api/-/merge_requests/1293
- Final commit: `c67c0018d436139d1a74002055ec7e489698daed`
- Changed files: `/private/tmp/oho-web-mr874/components/MaxPanel.vue`, `/private/tmp/oho-web-mr874/test/components/MaxPanel.spec.js`
- Root cause report: `/Users/tualek/ohochat/oho-web-app/jera-tab-missing-report.md`
