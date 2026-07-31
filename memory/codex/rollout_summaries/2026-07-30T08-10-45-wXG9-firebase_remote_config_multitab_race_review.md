thread_id: 019fb213-6e6a-7ca2-9032-29a514b9a891
updated_at: 2026-07-30T08:16:29+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-10-45-019fb213-6e6a-7ca2-9032-29a514b9a891.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: tk-sprint-2616/develop

# Read-only Firebase Remote Config web/mobile design review concluded that mirroring mobile is unsafe and unnecessary

Rollout context: Cross-repo advisory review of the already-fixed JERA feature-flag bug. No files were modified. The review inspected application code, Flutter code, installed Firebase JS SDK source/typings, and Firebase documentation.

## Task 1: Analyze multi-tab cache race and recommend web strategy

Outcome: success

Preference signals:
- The user required “Do NOT modify any files” and demanded every SDK claim be labeled as source-grounded or documentation-based -> future reviews should remain strictly read-only and explicitly distinguish evidence sources with file:line citations.
- The user requested a direct verdict, cost reality check, and concrete implementation sketch in a fixed order -> similar design reviews should preserve that evidence-first structure and avoid vague approval.

Key steps:
- Read `oho-flutter-mobile/lib/core/services/remote_config_service.dart` completely.
- Inspected `oho-web-app/plugins/firebase-remote-config.js`, Vuex flag precedence, business switching, and server-side flag bootstrap.
- Verified installed `@firebase/remote-config@0.8.0` source and typings rather than assuming documented behavior.
- Checked Firebase pricing, quota, and real-time loading documentation.

Failures and how to do differently:
- Do not port the mobile pattern directly: Flutter’s `clearRemoteConfigCache()` sets `minimumFetchInterval` to zero and never restores 12 hours, so it permanently disables throttling for that instance after the first signal update (`remote_config_service.dart:62-75`).
- Do not treat real-time updates as a solution to cross-tab business isolation; the real-time path fetches with cache age zero but still uses shared app/namespace storage and does not key cached results by custom-signal combination.

Reusable knowledge:
- The installed JS SDK persists Remote Config records in IndexedDB database `firebase_remote_config`; composite keys contain Firebase app ID/name, namespace, and record key, not custom signals (`node_modules/@firebase/remote-config/dist/index.cjs.js:1024-1040,1253-1256`). Active config, last successful response/timestamp, and custom signals are single records in that namespace (`:1081-1121`).
- Cache freshness compares only timestamp against `minimumFetchIntervalMillis`, not the business signal that produced the response (`:586-610`). Therefore a same-origin Tab A for business X can load/activate a recently cached business-Y config from Tab B during the interval window. The race is real, though activation may return false if the shared response is already active.
- JS supports `onConfigUpdate` (singular), not Flutter’s `onConfigUpdated`, via public typings and implementation (`remote-config-public.d.ts:289-304`; `index.cjs.js:523-545`). The real-time fetch bypasses the normal interval (`:1788-1805`) and callbacks require the app to call `activate()` before getters see the update (`:1820-1830`).
- Current correctness is server-authoritative: API login supplies four flags (`oho-api/.../login.hooks.js:119-140,175-187`), Vuex marks API keys authoritative (`oho-web-app/store/index.js:103-128,502-512`), and browser Remote Config cannot overwrite them. Business switching is a hard reload (`SwitchBusiness.vue:202-215`) but does not isolate shared IndexedDB across tabs.
- Firebase documentation indicates 12 hours is the recommended production interval. As of the review date, fetches were no-charge; announced pricing from September 1, 2026 gives 100,000 free fetches/day, then $0.000006/request through 10 million/day. Actual OHO volume was not measured, so urgency should be based on Firebase usage metrics rather than assumption.
- Recommendation: choose the simpler safer variant—remove the automatic browser Remote Config network path after verifying server flag rollout, retain Vuex/API defaults and E2E overrides, and fail closed to false if server flags are unavailable. Do not add interval tuning, business-ID bypass, or real-time listeners. Optionally add observability for login responses missing `feature_flags`; clean up authority bookkeeping separately.

References:
- `oho-web-app/plugins/firebase-remote-config.js:16-17,36-41,52-57,85-89`
- `oho-flutter-mobile/lib/core/services/remote_config_service.dart:21-33,39-47,62-75`
- `node_modules/@firebase/remote-config/dist/index.cjs.js:586-610` (cache hit logic)
- `node_modules/@firebase/remote-config/dist/index.cjs.js:1149-1155` (persisted custom signals)
- Firebase package versions: `firebase@12.9.0`, `@firebase/remote-config@0.8.0`
- Validation should use two same-origin tabs on different businesses, alternate hard reloads, and compare each tab’s flags with its own login response; also test server RC failure remains fail-soft.

