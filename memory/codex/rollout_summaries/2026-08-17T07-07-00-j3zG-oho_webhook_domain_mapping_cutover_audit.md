thread_id: 01a00e8b-895f-7940-acb9-9691f197cf38
updated_at: 2026-08-17T07:23:15+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/17/rollout-2026-08-17T14-07-00-01a00e8b-895f-7940-acb9-9691f197cf38.jsonl
cwd: /Users/tualek/Documents/Codex/2026-08-17/referenced-chatgpt-conversation-this-is-an

# OHO webhook domain-mapping cutover audit found the live setup is only partially cut over and not ready for a 100% hostname remap

Rollout context: The user asked for a source/config/runtime audit covering route parity, image/env parity, LINE signature verification, domain-mapping effects, and hardcoded health-check/replay URLs. Work was performed across `/Users/tualek/ohochat/oho-webhook`, `oho-api`, `oho-cronjob`, and `script-oho`. No production config, deployment, or routing mutation was performed.

## Task 1: Audit webhook routes and deployment parity

Outcome: partial

Preference signals:

- The user requested confirmation from “source, deployment config and runtime path” and wanted facts separated from production checks -> future audits should distinguish repository evidence, live GCP evidence, and unverified assumptions.
- The user specifically stated that the new service would use the same image/env -> this was tested rather than accepted at face value; future audits should verify image digests and redacted env metadata independently.

Key steps:

- Source routing inventory found both revisions expose `/line`, `/line/webhook/:businessId`, and `/line/message/:businessId`; other platform routes are `/facebook`, `/instagram`, `/tiktok`, and dead-letter routes.
- Old live revision `oho-webhook-production-00149-vcc` serves image digest `sha256:26cb...44bc`; new revision `webhook--production--eb898476--v1-85-0` serves `sha256:de0c...18ce`. Artifact Registry mapped these to tags/commits `85a4da17` and `eb898476`; the image digests are not equal.
- Diff between the two commits showed no changes in the LINE controller, LINE handler, router, Cloud Tasks helper, or Core API helper, so static LINE path parity was supported despite image mismatch.
- Redacted env comparison showed common values for `OHO_API_URL`, `QUEUE_ID`, `USE_QUEUE`, and database/Redis references, but differences in `OHO_WEBHOOK_URL`, `QUEUE_SLOW_COUNT` (old 30, new 20), secret source for `OHO_API_KEY`/TikTok secret, missing old LINE Notify/Sentry/Signoz variables, and new Meta MMD variables.
- `OHO_WEBHOOK_URL` differs intentionally: old points to the old Cloud Run URL and new points to the new Cloud Run URL, because Cloud Tasks callbacks are constructed from this variable.

Failures and how to do differently:

- Do not claim “same image/env” from deployment history or source similarity. Compare the serving revision digest and redacted env source/value metadata live.
- Do not treat same route declarations as full runtime parity; intentional env differences and downstream dependencies still require approval.

Reusable knowledge:

- `oho-webhook/src/controllers/line/line.controller.ts:30-31` defines `/webhook/:businessId` and `/message/:businessId` under `/line`.
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99` builds callback URLs as `${process.env.OHO_WEBHOOK_URL}${path}`.
- `oho-webhook/deploy.sh` deploys the service as `$SERVICE_NAME--$ENV`; production deployment uses `webhook--production` and revisions can be deployed with no traffic.

References:

- Live image evidence: old `sha256:26cb7ee453df9d9d6c60f6c1efab80c3cccdc610a5410cfa8efe997fe17944bc`; new `sha256:de0c69a1d7a76103c3424b2bfa2eb2ad4294b97e0b66191394e6547fa01e18ce`.
- Route check: `rtk git diff --exit-code 85a4da17 eb898476 -- src/index.ts src/controllers/line/line.controller.ts src/controllers/line/handler.ts src/helpers/router.ts src/helpers/cloud_tasks.api.ts src/helpers/oho.api.ts`
- Runtime env values: `OHO_WEBHOOK_URL` old=`https://oho-webhook-production-avgjmmzg7q-as.a.run.app`, new=`https://webhook--production-avgjmmzg7q-as.a.run.app`; `QUEUE_ID` equal; `QUEUE_SLOW_COUNT` old=`30`, new=`20`.

## Task 2: Audit live URL-map, DNS, and domain mapping

Outcome: partial

Key steps:

- The live URL map `oho-webhook-lb` contains both `webhook.oho.chat` and `webhook2.oho.chat`, with `/line/webhook/` weighted old 0/new 100. The new backend targets `webhook--production`; the default backend still targets `oho-webhook-production`.
- Request logs showed approximately 2 minutes of traffic with `webhook.oho.chat` sending 52 LINE ingress requests to the old service, while `webhook2.oho.chat` sent 926 LINE ingress requests to the new service.
- DNS showed `webhook.oho.chat` resolves through `ghs.googlehosted.com` and the old Cloud Run DomainMapping, while `webhook2.oho.chat` resolves to the load balancer IP `34.149.183.186`. Thus, merely listing both hosts in the URL map does not mean both hosts use the same routing plane.
- DomainMapping API evidence showed `webhook.oho.chat` is `Ready`, `CertificateProvisioned`, and `DomainRoutable`, with `routeName: oho-webhook-production` and CNAME `ghs.googlehosted.com.`.
- Read-only GET checks returned HTTP 200 for `/line` on the old hostname, new service URL, and `webhook2.oho.chat`.

Failures and how to do differently:

- Do not infer actual hostname routing from URL-map host rules alone. Check DNS, forwarding rules/target proxy, domain-mapping routeName, and service request logs together.
- The existing `webhook.oho.chat` path is still a one-shot Cloud Run DomainMapping to the old service; it has not been cut over merely because a separate LB hostname routes to the new backend.

Reusable knowledge:

- URL-map backend: `oho-webhook-lb-be-webhook-production` → serverless NEG `oho-webhook-lb-neg-webhook-production` → Cloud Run `webhook--production`.
- Existing old backend: `oho-webhook-lb-be-cloudrun-webhook-1` → NEG `oho-webhook-lb-network-group-serverless` → `oho-webhook-production`.
- Both backends use HTTPS, 30-second timeout, and request logging sample rate 1.0.
- Cloud Run DomainMapping is a 100% remap, not a weighted canary; Google documentation describes this feature as Preview and recommends an external Application Load Balancer for production custom-domain routing.

References:

- URL-map evidence: host rules for `webhook2.oho.chat` and `webhook.oho.chat`; `/line/webhook/` old weight 0/new weight 100; default old backend.
- DomainMapping evidence: `routeName: oho-webhook-production`; conditions `Ready=True`, `CertificateProvisioned=True`, `DomainRoutable=True`.
- Read-only checks: `curl https://webhook.oho.chat/line`, `curl https://webhook--production-avgjmmzg7q-as.a.run.app/line`, and `curl https://webhook2.oho.chat/line` all returned 200.

## Task 3: Verify LINE signature path and processing safety

Outcome: partial

Key steps:

- `webhook--production` successfully called Core API `/business/:businessId/line/verify-signature`; a recent Core API log sample had 9,446 HTTP 201 responses and 554 HTTP 400 responses, with no observed 401 intersection for the signature path.
- The webhook handler forwards the request body and `x-line-signature` from `oho-webhook/src/controllers/line/handler.ts:93-108`.
- Core API loads the channel using business ID and LINE destination, then computes HMAC-SHA256 using the channel secret.
- However, `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:38-58` logs mismatches and returns `{ ok: true }`; it does not reject invalid signatures. Therefore connectivity/channel lookup works, but cryptographic signature enforcement cannot be claimed.
- Recent new-service logs showed LINE handler errors, Core API POST failures, and task creation failures. A later sample counted up to 205 LINE handler errors and 16 task-create failures in 10 minutes; endpoint classification included many `/contact/upsert` 404/500 responses.
- `cloudTasksService.post()` catches task creation errors and logs `Task create failed` without rethrowing. The controller can then record `add_queue_success` and return HTTP 200, which can suppress LINE redelivery.

Failures and how to do differently:

- HTTP 200, Core API 201, or `add_queue_success` is not terminal-delivery proof. Require ingress → task creation → callback → `sync_message_success` → persisted/Stream state.
- Before claiming safety, fix or compensate for swallowed Cloud Tasks creation failures and define idempotency/redelivery behavior using `webhookEventId`.
- Do not describe current LINE signature handling as enforced until mismatch behavior is changed to reject or a separately verified enforcement layer is demonstrated.

Reusable knowledge:

- Relevant source states include `receive_webhook`, `add_queue_success`, `add_queue_fail`, `sync_message_success`, and `sync_message_fail`.
- The controller currently returns 200 on webhook processing errors in multiple paths, so production health must be evaluated through source-message terminal state and Cloud Tasks metrics, not HTTP status.

References:

- `oho-webhook/src/controllers/line/handler.ts:93-108, 1186-1207`
- `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:32-61`
- `oho-webhook/src/controllers/line/line.controller.ts:145-214`
- `oho-webhook/src/helpers/cloud_tasks.api.ts:99-135`
- Core API log sample: `/line/verify-signature` statuses `201: 9446`, `400: 554`.

## Task 4: Find health checks and hardcoded old-service references

Outcome: partial

Key steps:

- `oho-cronjob@origin/develop:functions/config/default.json:30` uses `https://webhook.oho.chat/line/webhook/`; `functions/utils/send-oho-webook.js:15-16` appends the business ID and POSTs to that hostname. This should follow a same-host domain cutover automatically and does not need a URL change.
- The synthetic health check waits 30 seconds and checks Stream Chat, so it is useful for OHO ingestion-to-terminal verification, but it does not exercise the real LINE Platform → OHO path or validate a LINE access token against LINE APIs.
- Live deployment state for `check_line_messaging_health` could not be verified because the account lacked `cloudfunctions.functions.get` permission in project `oho-cronjob`.
- `oho-api/src/services/incoming-webhook-log/replay/replay.hooks.js:219` hardcodes `oho-webhook-production` when querying Cloud Logging; this should search both old and new services during the rollback window, then be updated after stabilization.
- `replay-failed-log.class.js` uses configured `webhook_endpoint`, so it follows the configured hostname rather than hardcoding the old Cloud Run service.
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:43` references `webhook2.oho.chat` for a separate LINE endpoint-migration flow; it should not be changed as part of backend-only domain mapping cutover.

Failures and how to do differently:

- Do not claim the health-check schedule or live deployment is verified when IAM prevents reading the function deployment.
- Distinguish operational endpoint references from log-query/service-name references: the former may follow the hostname cutover; the latter can silently omit new-service logs.

References:

- `oho-cronjob/functions/config/default.json:30`
- `oho-cronjob/functions/utils/send-oho-webook.js:11-30`
- `oho-cronjob/functions/service/check-oho-line-messaging-health/check-oho-line-messaging-health-service.js:17-153`
- `oho-api/src/services/incoming-webhook-log/replay/replay.hooks.js:210-229`
- Permission failure: `Permission 'cloudfunctions.functions.get' denied`.

## Overall verdict

Outcome: partial / rework before cutover. The new service has the expected LINE route shapes and Core API connectivity, but live image and env parity are false, the old hostname still maps directly to the old service, signature mismatches are bypassed, and task-creation/processing errors prevent a zero-loss claim. Before remapping `webhook.oho.chat`, verify the intended image digest, approve env differences, fix or reconcile task-creation failures, send a real LINE test message, and prove the full terminal path. No production state was changed during this rollout.
