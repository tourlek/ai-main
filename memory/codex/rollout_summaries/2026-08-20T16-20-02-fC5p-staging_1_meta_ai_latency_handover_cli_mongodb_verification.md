thread_id: 01a01ff8-eccf-7753-bac3-73ea2e052baf
updated_at: 2026-08-21T03:50:43+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T23-20-02-01a01ff8-eccf-7753-bac3-73ea2e052baf.jsonl
cwd: /Users/tualek/ohochat

# Staging-1 Meta Business AI verification, handover debugging, and CLI workflow correction

Rollout context: Work was performed in `/Users/tualek/ohochat` against GCP project `oho-platform`, Cloud Run staging-1, MongoDB Compass/CLI, and Meta Business AI/Facebook Messenger paths.

## Task 1: Compare staging-1 latency before/after `meta-business-ai` deploy

Outcome: partial

Preference signals:
- The user asked whether the deployment caused a “latency performance drop,” so future checks should compare real before/after telemetry, endpoint mix, errors, and feature-path timing rather than infer from HTTP 200 or a few logs.

Key steps:
- Identified current revision `core-api--staging-1--b687a89d--6203b324--v2-27-1`, deployed at `2026-08-20T16:02:47Z` (23:02 ICT), with 100% traffic.
- Compared Cloud Run request logs using `log_id("run.googleapis.com/requests")`, revision filters, sorted latency values, and status counts.
- Baseline revision `b803ae00`: 492 requests, p50 13.0ms, p95 161.5ms, p99 15.8s, max 47.1s; 489 2xx/3xx, 2 4xx, 1 5xx.
- Post-deploy revision `b687a89d`: 227 requests, p50 17.4ms, p95 266.1ms, p99 2.16s, max 15.0s; 227 2xx/3xx, no 4xx/5xx.
- `/contact/chat/aggregate` remained a major tail source: pre p95 17.8s vs post p95 12.4s, but samples and traffic mix differed.
- Meta AI evidence: 4 `ai_generated` entries, 0 AI errors; Stream `/message` timing improved from p50/p95 30/63ms pre-deploy to 24/42ms post-deploy.
- Found one post-deploy core-api error: `[GCP-metric] Write metric time series fail!` with `DEADLINE_EXCEEDED` after 32.8s. Source inspection showed this is background instrumentation from `streamChat.js` → `ScheduledDataPusher` → `writeTimeSeriesData`, not the Meta AI message write path.

Failures and how to do differently:
- Cloud Monitoring CLI command `gcloud monitoring time-series list` was unavailable; beta installation was interactive and failed. Cloud Logging was used instead.
- Initial percentile calculation was invalid because latency values were not sorted; later commands added `sort -n`.
- Broad log queries were noisy/truncated. Future queries should filter service, revision, `log_id("run.googleapis.com/requests")`, endpoint, and narrow UTC windows.
- The result is not a definitive regression verdict because before/after request counts and endpoint mixes differ; repeat with matched endpoint/traffic windows before claiming a performance change.

Reusable knowledge:
- `core-api--staging-1` is in `asia-southeast1`, project `oho-platform`.
- `streamChat.js:72-85` batches rate-limit metric writes every 60s; `gcp-metric.js:64-77` awaits GCP metric writes and logs timeout failures. This path can create observability latency/noise but is separate from direct Stream message timing.

References:
- `gcloud run revisions describe core-api--staging-1--b687a89d--6203b324--v2-27-1 --region=asia-southeast1 --project=oho-platform`
- `gcloud logging read 'log_id("run.googleapis.com/requests") AND resource.type="cloud_run_revision" ...'`
- Error: `4 DEADLINE_EXCEEDED: Deadline exceeded after 32.801s ... Waiting for LB pick`
- Files: `/Users/tualek/ohochat/oho-api/src/sdk/streamChat.js`, `/Users/tualek/ohochat/oho-api/src/utils/gcp-metric.js`, `/Users/tualek/ohochat/oho-api/src/utils/scheduled-data-pusher.js`

## Task 2: Diagnose Facebook `take_thread_control` error

Outcome: partial

Preference signals:
- The user supplied the exact Meta error and payload and expected source/data-driven diagnosis, not speculation. Future work should map recipient/Page/App/token context before proposing a payload change.

Key steps:
- Error was `OAuthException code 100`, subcode `2018001`, “user not found,” for recipient ID `27336453096027036`, target app `643233536614550`.
- Source search confirmed handover handling in `oho-webhook/src/controllers/facebook/meta-business-ai.ts` and canonical recipient handling in Facebook webhook code.
- MongoDB Compass was initially used, but the wrong staging-4 tab was selected before correcting to staging-1. This left the handover diagnosis unresolved.

Failures and how to do differently:
- The investigation did not complete the required mapping of recipient ID to the actual Page/app/token context.
- Do not use a similarly named Compass tab or `.env` blindly; verify exact environment and channel/page mapping first.
- The next probe should inspect staging-1 channel records and verify `platform_id`, Page token ownership, app ID, and whether the recipient ID is a Page-scoped user ID for that Page.

References:
- Error: `(#100) ไม่พบผู้ใช้ที่แมตช์`, subcode `2018001`
- Payload recipient: `27336453096027036`; target app: `643233536614550`
- Files: `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/meta-business-ai.ts`, `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/block.ts`

## Task 3: Verify staging-1 MongoDB state using CLI and Bitwarden

Outcome: success

Preference signals:
- The user explicitly said “หยุดใช้ computer use” and prefers CLI/API. Future runs must use `mongosh`/CLI only, never open Computer Use, and report credential or permission blockers instead of retrieving secrets interactively.
- Credentials must not be printed; use process-local injection and clear temporary clipboard/state after the command.

Key steps:
- Found `/opt/homebrew/bin/mongosh` and the Compass connection record, but the stored password was unavailable to CLI.
- After the user asked about Bitwarden, the unlocked vault contained `Oho Mongo stagiing`; the password was used transiently for one read-only `mongosh` query and clipboard was cleared afterward.
- Corrected two CLI issues: this `mongosh` does not accept `--serverSelectionTimeoutMS` as a standalone flag (put it in the URI), and a trailing slash in the URI caused `Invalid database name: /oho-app-staging-1`.
- Final query succeeded against `oho-app-staging-1` and returned:
  - Contact `6a872802a3b0cdb0765c2675`: `status=bot`, `chat_status=fallback`, `meta_business_ai_enabled=false`.
  - Linked Facebook channel `6a873328a3b0cdb0765c2eda`: display name `ChicaChicken`, platform ID `1175851975615394`, `is_enable_chatbot=true`, `meta_business_ai_enabled=false`.
- Conclusion: OHO chatbot is enabled while Meta Business AI is disabled at both contact and channel levels.

Failures and how to do differently:
- Compass connection secrets are encrypted/separate; do not assume its saved URI includes the password.
- Avoid nested shell quoting for JavaScript; one attempt stripped quotes and produced `SyntaxError: Identifier directly after number`. Prefer a temporary `.js` file or carefully escaped heredoc for future `mongosh` queries.

References:
- Connection record: `/Users/tualek/Library/Application Support/MongoDB Compass/Connections/acb178fa-b4cd-40c2-9b20-39cb7d1e24ac.json`
- Final query used `mongosh "${mongo_uri}/oho-app-staging-1?authSource=admin&serverSelectionTimeoutMS=5000" --quiet --norc --password "$mongo_password"`
- Final verified channel platform ID: `1175851975615394`

