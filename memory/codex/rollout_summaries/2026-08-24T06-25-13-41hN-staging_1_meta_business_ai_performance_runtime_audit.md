thread_id: 01a03271-ccdf-7331-a5f9-270c1b5c2923
updated_at: 2026-08-24T06:49:56+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/24/rollout-2026-08-24T13-25-13-01a03271-ccdf-7331-a5f9-270c1b5c2923.jsonl
cwd: /Users/tualek/ohochat

# Staging-1 Meta Business AI performance and runtime-log audit

Rollout context: Read-only investigation in `/Users/tualek/ohochat` against GCP project `oho-platform`, Cloud Run region `asia-southeast1`, services `core-api--staging-1` and `webhook--staging-1`. The deployed core revision was `core-api--staging-1--0075eedb--6203b324--v2-27-1` at 100% traffic; webhook revision was `webhook--staging-1--e3b35076--v1-85-0` at 100%.

## Task 1: Determine whether Meta Business AI caused a staging performance regression

Outcome: partial

Preference signals:
- The user asked to inspect GCP logs for abnormal performance after deploying Meta Business AI. The investigation therefore used matched UTC windows, endpoint-level breakdowns, status counts, and source/runtime correlation instead of treating HTTP 200 as proof.
- The user expects evidence-first, detailed Thai explanations with explicit limits; the final result separated global performance, Meta AI message timing, functional errors, and unverified CPU/RAM/terminal-state claims.

Key steps:
- Initial sandboxed `gcloud` calls failed because `~/.config/gcloud` was not writable. Read-only elevated calls succeeded.
- Compared pre-deploy `2026-08-23T08:35:19Z–19:31:45Z` with post-deploy `2026-08-23T19:31:45Z–2026-08-24T06:28:12Z` using `log_id("run.googleapis.com/requests")`, service/revision filters, sorted latency values, and route-specific queries.
- Aggregate core-api results: pre 163 requests, p50 15.8ms, p95 495.7ms, p99 2.90s, max 34.6s; post 632 requests, p50 16.6ms, p95 190.4ms, p99 2.59s, max 41.5s. Non-OPTIONS p95 improved from 1.991s to 0.205s. No 5xx occurred in either matched window.
- Meta AI path: 9 unique `ai_generated` payloads were observed; each correlated with a Stream `/message 201` within 34–96ms, with Stream API timings of roughly 22–30ms. One `take_thread_control` call took 1.114s; four `pass_thread_control` calls took 1.907–2.080s. No OAuth, handoff, or takeover failures were found.
- Tail outliers included `/contact-send-message` at 34.513s with a webhook Cloud Tasks callback at 34.770s, and `/contact/upsert` at 12.156s with a task callback at 12.591s. These were isolated bursts, not evidence of a global regression.
- Two GCP metric timeout errors were found; source history identifies this as background instrumentation (`streamChat.js` → `ScheduledDataPusher` → `gcp-metric.js`), not direct Meta AI Stream message handling.

Failures and how to do differently:
- A first JSON aggregation failed because `gcloud` output was truncated/invalid; splitting queries into smaller windows and using line-count/route-level aggregation worked.
- `gcloud monitoring time-series` was unavailable, so CPU/RAM/instance saturation was not verified. Do not claim infrastructure saturation or full staging readiness from these logs alone.
- Broad warning/error counts mixed unrelated application errors and preflight requests; narrow by service, revision, route, user agent, trace, and time window.

Reusable knowledge:
- `core-api--staging-1` is in `oho-platform/asia-southeast1`; current revision `0075eedb...v2-27-1` served 100% traffic during the audit.
- `webhook--staging-1` handled Meta events on revision `e3b35076...v1-85-0`.
- `200` from Facebook/webhook or Cloud Tasks is not terminal processing proof; correlate with downstream core API, Stream, Mongo/Redis, and source-message terminal markers.

References:
- Core revision: `core-api--staging-1--0075eedb--6203b324--v2-27-1`
- Webhook revision: `webhook--staging-1--e3b35076--v1-85-0`
- Matched log filter basis: `log_id("run.googleapis.com/requests") AND resource.type="cloud_run_revision" AND resource.labels.service_name="core-api--staging-1"`
- Final performance figures: pre `n=163 p50=0.015806696 p95=0.495739110 p99=2.896477376 max=34.638796003`; post `n=632 p50=0.016572320 p95=0.190405908 p99=2.585195359 max=41.544072102`.

## Task 2: Diagnose Meta Business AI functional errors and tail behavior

Outcome: partial

Preference signals:
- The user’s concern was not only latency but “what is wrong” after deployment. Future audits should trace every feature-specific error to deployed source and distinguish message delivery success from UI/state-update correctness.
- Preserve dirty worktrees and avoid editing or reverting another session’s changes; the agent explicitly switched to `git show` at the deployed SHA when local source drift was detected.

Key steps:
- Found 9 occurrences of `[member-send-message/inbox] update meta business ai contact status FAIL!` exactly matching 9 Meta AI replies. Error: `businessId or channel paths is required`.
- Deployed source at `oho-api/src/services/member-send-message/inbox/inbox.hooks.js` calls `businessChannel(businessId)` without a path. `oho-api/src/socket.io.js` requires both a business ID and at least one path, so it throws after the Stream send succeeds.
- Consequence: Meta AI messages reach Stream, but `contact/profile updated` and unread/unresponded realtime broadcasts can be skipped, leaving contact/badge UI state stale while the HTTP request still returns 201.
- Separately, 14 `contact/upsert` 404s came from webhook standby `read` events for contact source `38165946003019186`, with `is_upsert:false`; each request took about 14–54ms. These are likely expected read-event missing-contact noise rather than the performance bottleneck, but they remain a functional/error-log issue.
- After `2026-08-24T06:28:12Z`, a refresh through `06:46:01Z` found no new Meta AI status errors, core 5xx, or webhook ERROR logs; this is only a quiet-window observation, not proof of a fix.

Failures and how to do differently:
- Do not call the feature ready because all AI messages reached Stream. Verify post-send contact state and realtime broadcasts separately.
- Do not infer that the 34-second `/contact-send-message` outlier was caused by the Meta AI emitter bug; the traced request included Meta/Stream operations but no core warning/error, and causality was not fully proven.
- Do not edit the shared worktree during diagnosis when another session has modified the same hook; pin deployed SHA and obtain explicit authorization before patching.

Reusable knowledge:
- `businessChannel(businessId, ...paths)` throws `businessId or channel paths is required` when no path is supplied.
- Deployed SHA: `0075eedbc4943621dd236bcd8e1f1662186b53b4`, commit `fix: take meta business ai off hot paths and block bots by flag`.
- Relevant deployed locations: `oho-api/src/services/member-send-message/inbox/inbox.hooks.js:262-270` and `oho-api/src/socket.io.js:20-24`.
- Meta AI author evidence is `message.ai_generated === true`; observed messages used app ID `263902037430900` and standby delivery. This identifies message author, not necessarily ownership or activation by itself.

References:
- Exact error: `businessId or channel paths is required`
- Exact log: `[member-send-message/inbox] update meta business ai contact status FAIL!`
- Source helper: `function businessChannel(businessId, ...paths)`
- Feature-specific source: `oho-api/src/services/member-send-message/inbox/inbox.hooks.js`
- Dirty-worktree note: local `oho-api` had unrelated/session changes; no files were modified or reverted.
