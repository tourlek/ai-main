---
name: reference-gcp-logging-console
description: GCP project id and Cloud Run service naming for building Cloud Logging Console deep-links for ohochat services
metadata: 
  node_type: memory
  type: reference
  originSessionId: 16adad7d-f6c9-4d64-93af-1b6a1c733bb9
---

GCP project id for all ohochat Cloud Run services is `oho-platform` (confirmed from `oho-platform-471561a0a5a6.json` service account file at repo root).

Cloud Run service names follow `<SERVICE_NAME>--<ENV>` (e.g. `core-api--production`, `websocket--production`). `SERVICE_NAME` per repo is set in that repo's `.gitlab-ci.yml` (`oho-api` → `core-api`).

Logs Explorer deep-link template (matches URLs already used in past incident docs, e.g. `incident-websocket-2026-05-29.md`):

```
https://console.cloud.google.com/logs/query;query=<URL-ENCODED-QUERY>;timeRange=<ISO-START>%2F<ISO-END>?project=oho-platform
```

Query fields are newline-separated (`%0A` when encoded), ANDed implicitly. Common fields:
- `resource.type="cloud_run_revision"`
- `resource.labels.service_name="core-api--production"`
- `severity>=WARNING` or `severity>=ERROR`
- `textPayload:"<substring>"` for a specific log tag/message

`timeRange` is optional — omit it and the console defaults to the last hour, which is too narrow for periodic/cronjob logs; widen the picker manually in that case.

**Why:** built while diagnosing a Facebook comment-reply outage for business `64f8341f8585e0ed65ee8864` — needed to hand the user a working Logs Explorer link for `[Validate-business-integration-status]` / `Fetch facebook granular scopes FAIL` log lines in `oho-api`.
**How to apply:** reuse this project id + naming pattern whenever asked to link to Cloud Run logs for any `oho-*` service, instead of guessing or asking the user for the project id again.
