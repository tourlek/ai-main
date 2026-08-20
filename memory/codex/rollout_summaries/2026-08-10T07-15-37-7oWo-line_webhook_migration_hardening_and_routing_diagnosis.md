thread_id: 019fea86-e89e-79c3-b1e3-68a6504098fc
updated_at: 2026-08-17T04:40:27+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl
cwd: /Users/tualek/ohochat

# LINE webhook migration review, hardening plan, and production routing investigation

Rollout context: Work occurred primarily in `/Users/tualek/ohochat/script-oho`, with supporting source checks in `oho-api`, `oho-webhook`, and live GCP/LINE logs. The user wanted a production-safe migration of LINE webhook URLs from old domains to whitelisted gateway domains, with pre-verification, backup, rollback, and no message loss.

## Task 1: Audit the original migration script

Outcome: partial

Preference signals:
- The user asked whether the script covered DB discovery, domain mismatch detection, endpoint verification, LINE API update, DB update, complete backup, and rollback. Future reviews should trace the full operational path rather than only inspect the diff.
- The user explicitly wanted backup before any mutation and rollback protection against lost messages. Treat mutation ordering and recoverability as hard acceptance criteria.

Key steps:
- Confirmed URL construction matches OHO’s LINE connect flow: `${webhook_endpoint}/line/webhook/${businessId}`.
- Traced the intended sequence: LINE test → LINE PUT → GET verification → MongoDB update.
- Found the original implementation wrote backup after `processChannel()` completed, so a crash after LINE/DB mutation could leave no rollback source.
- Found dry-run entries and already-new entries could enter the backup, and rollback did not reliably distinguish channels actually mutated from channels merely inspected.
- Found rollback only stored endpoint fields, not all mutated DB state.
- Found `--old-host` semantics were opposite the requirement: it filtered hosts to migrate instead of explicitly selecting DB domains outside a whitelist.
- Found confirmation tokens were not bound to candidate IDs/count or manifest content.
- Found partial failures were summarized but did not force a non-zero exit.

Reusable knowledge:
- OHO’s existing LINE connect code uses `PUT /v2/bot/channel/webhook/endpoint`, then GETs the endpoint; it does not use LINE’s test endpoint first.
- LINE’s `POST /v2/bot/channel/webhook/test` accepts an endpoint and returns `success`, `statusCode`, `reason`, and `detail`; it verifies delivery of an empty-event request, not full message processing.
- `oho-webhook` exposes `/line/webhook/:businessId`; `/line` returns `{ page: 'LINE Home' }`.

Failures and how to do differently:
- Do not treat a backup written after mutation as safe. Snapshot all candidates and persist an immutable manifest atomically before the first PUT.
- Do not use DB `connection_status` or `is_access_token_valid` as proof that the LINE token works; call LINE and classify the live result.
- Do not claim production readiness from help output alone; the original review only ran `npm run migrate:line-webhook:help`, not DB or LINE mutations.

References:
- `script-oho/migrate-line-webhook-endpoint/migrate-line-webhook.ts:916` original test/PUT/DB flow.
- `migrate-line-webhook.ts:1373` original post-processing backup write.
- `migrate-line-webhook.ts:762` original broad query.
- `oho-api/src/services/channel/line/line.hooks.js:237-286` connect flow.

## Task 2: Write and inspect the hardening plan/implementation

Outcome: partial

Preference signals:
- The user corrected scope to “plan only” and said not to implement yet. Future agents should stop after producing the plan when explicitly asked, even if implementation work was previously discussed.
- The user specified that `line.register_webhook_at` should not be updated. This decision was incorporated into both migration and rollback requirements.
- The user asked for a specific sub-agent model (`5.6luna`, max effort). The environment rejected that model; future agents must report the limitation and must not silently substitute another model.

Key steps:
- Replaced `plan.md` with an implementation-ready plan covering explicit `--allowed-host`, inventory classification, immutable manifest, digest-bound apply, atomic writes, durable journal, conditional DB writes, compensation, exact rollback, timeouts, exit semantics, tests, and canary rollout.
- Later inspected the changed implementation and found new files: `migrate-line-webhook.helpers.ts`, `migrate-line-webhook.helpers.spec.ts`, expanded `migrate-line-webhook.ts`, README, and plan.
- The implementation includes manifest schema/digest, atomic JSON writes, manifest-bound confirmation tokens, journal phases such as `line_put_requested`, and explicit omission of `line.register_webhook_at`.

Reusable knowledge:
- The hardened script defaults to concurrency 1, requires `--allowed-host` for dry-run, and requires a reviewed manifest for apply/rollback.
- Manifest entries preserve DB field presence/value for endpoint, validity, active state, and `updated_at`; access tokens are not included.
- Rollback should use journal/live-state evidence, not merely manifest membership.
- Tests cover digest tampering, atomic writes, token binding, phase classification, rollback selection, and absence of `register_webhook_at` from payloads.

Failures and how to do differently:
- The requested `gpt-5.6-luna` was unavailable; spawning failed with “Unknown model `gpt-5.6-luna`”. Do not substitute `gpt-5.6-sol` or another model without explicit approval.
- The plan-only phase was successful, but the later implementation review was not a complete proof of production safety; live migration behavior still requires focused tests and controlled canary validation.

References:
- `script-oho/migrate-line-webhook-endpoint/plan.md` (466 lines; implementation plan).
- `migrate-line-webhook.helpers.ts` and `.spec.ts`.
- `migrate-line-webhook.ts:781-834` classification and LINE inventory.
- `migrate-line-webhook.ts:1027-1097` manifest validation/revalidation.

## Task 3: Diagnose migrated/unmigrated traffic and routing

Outcome: partial

Preference signals:
- The user repeatedly challenged assumptions with concrete production evidence and expected live DNS, route, logs, and DB reconciliation before conclusions. Future agents should validate ingress topology first, not infer it from resource names.
- The user values concise operational explanations of why specific channels/businesses were skipped and what exact remediation is safe.

Key steps:
- Production manifests showed 69 channels across 62 businesses classified `unmigratable_invalid_token`; all LINE GET webhook calls returned HTTP 401 authentication failure. Therefore the script correctly did not POST test, PUT LINE, or update DB for them.
- DB still showed `is_access_token_valid: true` and `connection_status: complete`; this is stale state. OHO’s LINE payload builder contains a duplicate `is_access_token_valid: true` assignment that can override the real validation result, and the validation cron only scans `.limit(2000)` without pagination.
- Inbound webhook delivery is independent of channel access-token validity: LINE sends to the configured webhook using the webhook setting/channel secret, while OHO uses access tokens for LINE API calls, replies, profile/media, and endpoint changes.
- Business `652f64468e7d21abc6e62235` was deleted from OHO but still received LINE traffic. Logs showed LINE ingress 200, Cloud Tasks 200, then Core API `/business/652f.../line/verify-signature` 400 with “Channel doesn't exists!”, so HTTP 200 at ingress did not mean successful processing.
- Initial URL-map advice was corrected after live DNS checks: `webhook2.oho.chat` resolves to the LB IP, but `webhook.oho.chat` is a Cloud Run domain mapping (`CNAME ghs.googlehosted.com`) and bypasses the URL map. Adding an LB host rule alone would not affect old-domain traffic. The LB certificate also only covered `webhook2.oho.chat`.
- For deleted businesses, the safe source-side action is to disable “Use webhook” in LINE Developers Console; revoking access tokens alone does not stop inbound webhook delivery. There is no LINE API DELETE webhook endpoint.

Failures and how to do differently:
- Do not infer that `oho-webhook-lb` handles every webhook domain. Verify DNS → frontend IP → proxy/certificate → URL map → backend → request logs.
- Do not recommend remapping the old Cloud Run domain immediately when the requirement is no message loss and eventual retirement of the old domain. Keep it alive until LINE endpoints are migrated or webhooks are disabled at source.
- Do not use HTTP 200 from webhook ingress as delivery proof; downstream handlers can fail while acknowledging the request.

References:
- Manifest: `migrate-line-webhook-manifest-prod-20260816182025-5ef5ef03.json`; journal recorded 69 token failures.
- Error string: `LINE GET webhook failed (401): {"message":"Authentication failed..."}`.
- `oho-api/src/services/channel/line/line.hooks.js:145-150` duplicate validity assignment.
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:13-35,223-263` limited scan and 401 handling.
- `oho-api/src/services/business/line/verify-signature/verify-signature.hooks.js` channel lookup requires current business/channel record.
- Live DNS evidence: `webhook.oho.chat → ghs.googlehosted.com`; LB IP `34.149.183.186` belongs to `webhook2.oho.chat`.
- Live route: URL map `oho-webhook-lb`, matcher `line-webhook2-rollout`, `/line/webhook/` weighted 100% to `webhook--production`, but only for `webhook2.oho.chat`.

Final status: the migration hardening design is substantially improved, but production remediation remains incomplete for stale/invalid-token channels and orphaned deleted-business webhooks. Do not force DB updates or remove the old domain until each LINE channel is either reconnected/migrated or explicitly disabled at LINE.
