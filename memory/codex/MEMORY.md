# Task Group: /Users/tualek/ohochat/oho-api / keyword API authorization and 403 diagnosis

scope: Identify the exact member permission for keyword create/update requests and diagnose an authenticated 403 without replaying credentials.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse the permission mapping for the current `oho-api` keyword hooks after confirming the request group/action and authenticated member; never reuse pasted tokens or cookies.

## Task 1: Diagnose broadcast keyword creation permission; success

### rollout_summary_files

- rollout_summaries/2026-08-14T08-33-51-50Px-trace_keyword_broadcast_permission_403.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/14/rollout-2026-08-14T15-33-51-019fff67-f5d7-74e3-b7d8-06a0b1faf7f3.jsonl, updated_at=2026-08-14T08:35:41+00:00, thread_id=019fff67-f5d7-74e3-b7d8-06a0b1faf7f3, success; source-traced exact permission and identity mismatch)

### keywords

- POST /core/latest/keyword, group: broadcast, keyword.broadcast.create, keyword.broadcast.update, checkMemberPermission, role_permission.permissions, memberJWTStrategy, FeathersJS, JWT, 403

## User preferences

- when the user asks “มันต้องใช้ permission อะไร” -> lead with the exact permission string, then briefly show the source path. [Task 1]

## Reusable knowledge

- For `POST /core/latest/keyword` with `group: "broadcast"`, the default `_.kebabCase()` branch checks `keyword.broadcast.create`; if `_id` is present, it treats the request as update and checks `keyword.broadcast.update`. [Task 1]
- Permissions come from `params.member.role_permission.permissions`, populated by `memberJWTStrategy`. General mapping: `tag → keyword.contact-tag.{action}`, `contact_label → keyword.chat-tag.{action}`, `arp_group_id → keyword.arp-group.{action}`, otherwise `keyword.{kebab-case-group}.{action}`. [Task 1]

## Failures and how to do differently

- Symptom: a captured 403 is attributed to the intended role. Cause: Authorization JWT and cookie JWT may represent different members. Fix: re-login and capture one fresh identity before treating role configuration as the cause. [Task 1]
- Symptom: investigation replays a curl containing credentials. Cause: treating a pasted request as safe test input. Fix: inspect source instead; treat exposed Authorization headers/cookies as compromised and recommend revocation/rotation. [Task 1]

# Task Group: /Users/tualek/ohochat / LINE integration monitoring, webhook migration risk, and terminal delivery evidence

scope: Distinguish LINE access-token/webhook configuration checks, synthetic OHO ingestion, migration safety, and true terminal delivery; use for monitoring, migration, or message-loss questions across `oho-api`, `oho-cronjob`, and `oho-webhook`.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=retrace current source/config and live deployment state before operating; source inspection, webhook HTTP 200, and LINE webhook-test success are not real LINE Platform-to-terminal-delivery proof.

## Task 1: Trace LINE token/webhook cronjob and synthetic messaging health; success

### rollout_summary_files

- rollout_summaries/2026-08-13T03-25-55-GBgq-analyze_line_cronjob_token_webhook_health_checks.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-25-55-019ff927-ae16-79f0-a3ae-eaee875badce.jsonl, updated_at=2026-08-13T03:30:22+00:00, thread_id=019ff927-ae16-79f0-a3ae-eaee875badce, success; separates configuration checks from synthetic terminal check)

### keywords

- validate-business-integration-status, validateLineConnectionStatus, check_line_messaging_health, /v2/bot/info, webhook/endpoint, x-line-signature, verify-signature, Stream Chat, channelModel.bulkWrite, HTTP 429

## Task 2: Audit LINE webhook migration, load-balancer canary, and Cloud Tasks loss path; partial

### rollout_summary_files

- rollout_summaries/2026-08-13T03-57-02-TJMH-line_webhook_migration_safety_review_and_canary_rollout.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl, updated_at=2026-08-14T09:53:26+00:00, thread_id=019ff944-2c61-78d0-ab18-072ed186d997, partial; verified webhook2 routing and end-to-end canary gates)

### keywords

- migrate-line-webhook, --allowed-host, immutable manifest, routeAction.weightedBackendServices, defaultService, Cloud Tasks, createTask, add_queue_success, webhookEventId, LINE redelivery, zero message loss

## User preferences

- when the user asks whether a cronjob checks “webhook หรือ access token” -> trace source and state both checks and non-checks rather than infer from the job name. [Task 1]
- when reviewing LINE migration, the user required whitelist discovery, new-endpoint verification before LINE mutation, LINE PUT before DB update, and complete backup/rollback -> trace the full state machine with concrete file:line evidence. [Task 2]
- when evaluating canary YAML or message loss, give direct routing/propagation/backend-failure distinctions and no unsupported “100% safe” claim. [Task 2]

## Reusable knowledge

- `validate-business-integration-status` runs `/v2/bot/info` with the channel access token, then `/v2/bot/channel/webhook/endpoint`; it validates `active` and expected endpoint (trailing slash trimmed), bulk-writes state, skips HTTP 429, but does not send a real message, validate channel secret, queue/Stream processing, or auto-recover incomplete channels. Webhook-info failures are currently classified as token invalid even when network/API failure is possible. [Task 1]
- `check_line_messaging_health` creates a synthetic signed payload and POSTs directly to OHO, then waits and checks Stream Chat. Its configured token is not used against LINE APIs, so it checks OHO ingestion/terminal state, not token validity or the true LINE Platform path. `verify-signature` logs a mismatch and returns `{ ok: true }`, so synthetic success is not signature-enforcement proof. [Task 1]
- Safe endpoint migration is inventory DB + LINE -> durable immutable before-state -> test new endpoint -> PUT LINE -> GET verify -> DB update -> final verify. Use explicit `--allowed-host`, manifest-bound apply/rollback, journal only mutated channels, exact `$set`/`$unset` restoration, and non-zero partial-failure status; omit `line.register_webhook_at`. [Task 2]
- `webhook2.oho.chat` had an ACTIVE certificate and `/line` returned HTTP 200. Use old `oho-webhook-production` as default and exact business-path rules to `webhook--production`; multiple `fullPathMatch` rules in one route rule are OR semantics. This is staged-routing evidence, not message-delivery proof. [Task 2]
- Priority 1 exact URL-map path wins over Priority 2; `defaultService: old` handles only unmatched requests, not a selected new backend's 5xx/timeout. Old 99/new 1 reduces blast radius but cannot guarantee zero loss. [Task 2]
- Current loss path: `createTask` catches/logs failure, controller records `add_queue_success` and returns 200, so LINE may stop retrying while the message is lost. Require task creation before 200; on failure record `add_queue_failed` and return 5xx, with `webhookEventId` idempotency, enabled redelivery, and terminal-state reconciliation. [Task 2]

## Failures and how to do differently

- Symptom: “healthy” or HTTP 200 is called end-to-end safe. Cause: configuration checks, synthetic direct POST, webhook-test, and queue acceptance each omit different parts of production delivery. Fix: verify real LINE event -> queue creation/completion -> persistence/Stream terminal state, and separate live scheduler/deployment evidence from repository evidence. [Task 1][Task 2]
- Symptom: migration rollback cannot recover a crash/partial run. Cause: backup after mutation, dry-run entries treated as touched, or incomplete field snapshots. Fix: persist before-state before first mutation and use per-channel journal phases/conflict detection. [Task 2]

# Task Group: /Users/tualek/ohochat / Facebook Messenger recipient-error and LINE postback production diagnosis

scope: Read-only production-log diagnosis that correlates raw platform payloads, source mappings, and successful traffic before recommending a narrow remedy.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=requery the exact business/time window and current mappings; preserve read-only scope unless an edit is explicitly authorized.

## Task 1: Diagnose Fastship Facebook recipient send errors; success

### rollout_summary_files

- rollout_summaries/2026-08-13T03-47-52-NxJZ-fastship_facebook_recipient_send_error_gcp_diagnosis.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-47-52-019ff93b-c85a-7c20-af5f-a0727251ac2f.jsonl, updated_at=2026-08-13T03:52:47+00:00, thread_id=019ff93b-c85a-7c20-af5f-a0727251ac2f, success; recipient-specific Meta rejection)

### keywords

- Fastship, core-api--production, OAuthException, code=551, error_subcode=1893047, is_transient=false, get-error-message-send-message-fail.js, Facebook Page 595166650687417

## Task 2: Diagnose Thaimetal LINE rich-menu postback “กดปุ่ม”; success

### rollout_summary_files

- rollout_summaries/2026-08-13T08-44-28-1ngu-diagnose_thaimetal_line_postback_gcp_logs.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T15-44-28-019ffa4b-53d6-7f53-ab12-aac360e69732.jsonl, updated_at=2026-08-13T08:54:13+00:00, thread_id=019ffa4b-53d6-7f53-ab12-aac360e69732, success; narrow business/payload suppression only)

### keywords

- Thaimetal, LINE postback, rich-menu, กดปุ่ม, external_action=thaimetal_catalog, art_id, arp_id, jsonPayload.message, oho-webhook-production, URI action

## User preferences

- when the user asks whether Meta is broken and asks for GCP logs -> correlate business/Page, timestamps, raw platform response, and successful sends before declaring an outage; distinguish UI wording from platform evidence. [Task 1]
- when the user asks “หา log ใน gcp ให้หน่อยว่ามาแบบไหน” and whether an event can be ignored -> inspect real payloads and source flow first, then propose the narrowest customer-facing suppression. [Task 2]

## Reusable knowledge

- Fastship's raw response was HTTP 400 `OAuthException`, `code=551`, `error_subcode=1893047`, `is_transient=false`; evidence supports a recipient/conversation restriction, not Meta-wide outage, and immediate retry is unlikely to help. OHO maps only `551/1545041` to a specific block message, so `1893047` falls to generic UI fallback. [Task 1]
- Thaimetal events were `type: "postback"` with raw Thai `postback.data` and no label/displayText. Webhook transforms label-less data to undefined text before `/contact-send-message`; API preview then falls back to `กดปุ่ม`. Auto-reply checks happen after synchronization, so no `art_id`/`arp_id` does not suppress the Stream message. [Task 2]
- Use a LINE URI action for external-only buttons; if postback is necessary, namespace it and suppress only that namespace for business `6a422c6fae5398680bf7d837`. Do not globally ignore postbacks because `art_id=...&label=...` supports Oho Auto Reply Triggers. [Task 2]

## Failures and how to do differently

- Symptom: broad Cloud Logging reads are noisy/truncated or fail matching bare `jsonPayload`. Fix: narrow by service, business/Page, exact error/event, and tight time range; use `jsonPayload.message:` or `SEARCH(...)`, output selected fields, and redact credentials as `[REDACTED_SECRET]`. [Task 1][Task 2]

# Task Group: /Users/tualek/thaivagroups/thaiva-frontend / temporary Cookie Wow disablement, tag-triggered production release, and main sync

scope: Temporarily disable the active Cookie Wow loader while preserving unrelated worktree changes, then release, verify deployed HTML, and align `origin/main` with the deployed tag.
applies_to: cwd=/Users/tualek/thaivagroups/thaiva-frontend; reuse_rule=inspect the current workflow/tags, branch topology, and active integration before changing or deploying; release facts below are historical.

## Task 1: Disable Cookie Wow, tag v1.7.6, and verify production; success

### rollout_summary_files

- rollout_summaries/2026-08-13T07-36-01-4exm-disable_cookie_wow_deploy_and_sync_main.md (cwd=/Users/tualek/thaivagroups, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T14-36-01-019ffa0c-a821-7e62-9ee7-6f5b71ace63c.jsonl, updated_at=2026-08-14T01:50:14+00:00, thread_id=019ffa0c-a821-7e62-9ee7-6f5b71ace63c, success; deployed tag verified from live HTML)

### keywords

- Cookie Wow, cookiecdn.com, src/app/[locale]/layout.tsx, deploy-production.yml, v1.7.6, hotfix/disable-cookie-wow, package-lock.json, yarn.lock, next: command not found

## Task 2: Fast-forward the deployed release into main; success

### rollout_summary_files

- rollout_summaries/2026-08-13T07-36-01-4exm-disable_cookie_wow_deploy_and_sync_main.md (cwd=/Users/tualek/thaivagroups, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T14-36-01-019ffa0c-a821-7e62-9ee7-6f5b71ace63c.jsonl, updated_at=2026-08-14T01:50:14+00:00, thread_id=019ffa0c-a821-7e62-9ee7-6f5b71ace63c, success; `origin/main` and v1.7.6 converged on 606d216)

### keywords

- origin/main, git merge --ff-only, git ls-remote, git push origin main:main, 606d216, v1.7.6, release branch, dirty lockfiles

## User preferences

- when the user requests a temporary disablement and accepts comments -> preserve the original integration as a commented block. [Task 1]
- when unrelated lockfile changes already exist -> do not reset, touch, or stage them. [Task 1]
- when asked to “commit and deploy” -> inspect the repository's actual release workflow and verify live production rather than just git/tag state. [Task 1]
- when the user corrected “merge เข้า main ไว้ด้วยสิ” -> a tag-only production release is incomplete; ensure `origin/main` contains the deployed commit before reporting completion. [Task 2]

## Reusable knowledge

- Active Cookie Wow was the two-script block in `src/app/[locale]/layout.tsx`, not `CookieBanner.tsx`; it was temporarily commented. `.github/workflows/deploy-production.yml` deploys pushed `v*` tags. [Task 1]
- Latest remote tags can be ahead of local `main`; fetch the current release base before hotfixing. Stage only intended files, and if Actions access is unavailable, cache-bust/fetch production HTML and search for the removed loader/config strings. [Task 1]
- For a linear release branch, check `git ls-remote origin refs/heads/main`, use `git merge --ff-only`, push `main:main`, and verify the remote branch and deployed tag point to the same commit. [Task 2]

## Failures and how to do differently

- Symptom: tag push or file lint is called complete validation. Cause: tag does not prove deployment, and lint failed here because `next` was absent (`sh: next: command not found`). Fix: report the dependency limit, run `git diff --check`, then independently verify the deployed artifact. [Task 1]
- Symptom: deployed production is left only on a tag/release branch. Cause: release completion stopped after tag deployment. Fix: make branch-topology comparison and `main` sync a release-checklist step, while preserving unrelated dirty files. [Task 2]

# Task Group: /Users/tualek/ohochat/oho-web-app / JERA tab late-feature-flag race fix and MR !874 scope control

scope: Diagnose and minimally fix the JERA tab missing when the flag resolves after `MaxPanel` mounts; use for MR !874 / partner-connection fetch behavior, not webhook or API architecture.
applies_to: cwd=/private/tmp/oho-web-mr874 with source context `/Users/tualek/ohochat/oho-web-app`; reuse_rule=reuse the watcher pattern only after confirming the current flag/store/fetch contract and MR base; do not treat focused Jest results as manual Smartchat/contact-tab UAT.

## Task 1: Implement, squash, and push the minimal Web-only JERA watcher fix; success

### rollout_summary_files

- rollout_summaries/2026-08-13T03-05-06-BsgF-jera_tab_minimal_watcher_fix_and_mr_squash.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-05-06-019ff914-9f48-7db3-aec9-3c772585e8f1.jsonl, updated_at=2026-08-13T06:57:27+00:00, thread_id=019ff914-9f48-7db3-aec9-3c772585e8f1, success; final squashed Web MR scope and remote verified)
- rollout_summaries/2026-08-13T06-28-50-Iwy9-minimal_jera_tab_watcher_fix_and_commit.md (cwd=/private/tmp/oho-web-mr874, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T13-28-50-019ff9cf-2564-7b40-af25-0306981e9625.jsonl, updated_at=2026-08-13T06:44:50+00:00, thread_id=019ff9cf-2564-7b40-af25-0306981e9625, success; focused implementation and pre-squash commit evidence)

### keywords

- JERA, MaxPanel, is_jera_feature_enabled, rt_jera_feature_enabled, immediate watcher, fetched_jera_partner_connections, fetchJeraPartnerConnections, MR 874, c67c0018, Firebase Remote Config, sessionStorage, onConfigUpdate, force-with-lease

## Task 2: Apply the approved ponytail cleanup in isolated JERA MR worktrees; partial, superseded remotely by Task 1 Web push

### rollout_summary_files

- rollout_summaries/2026-08-13T03-27-18-nG9D-jera_mr_ponytail_cleanup_and_validation.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-27-18-019ff928-f2ca-73c0-b341-947ac2fac315.jsonl, updated_at=2026-08-13T03:41:12+00:00, thread_id=019ff928-f2ca-73c0-b341-947ac2fac315, partial; isolated cleanup was never committed/pushed)

### keywords

- JERA, ponytail, MR-1293, MR-874, /private/tmp/oho-api-mr1293, /private/tmp/oho-web-mr874, Promise.race, sessionStorage, onConfigUpdate, OHO_WEBSOCKET_URL, baseline failures

## User preferences

- when the user said `completeClaimedDedup()` was unrelated and asked whether the tab disappears because it renders before the flag arrives -> trace the actual render/fetch path first; do not pull Facebook webhook/dedup work into a JERA UI fix. [Task 1]
- when the user required the “smallest fix,” no API MR `!1293` edits, and preservation of unrelated dirty work -> inspect worktree/scope first and prefer the direct lifecycle fix over cache, realtime, retry, or cross-repo changes. [Task 1]
- when the user explicitly required `Luna 5.6 max` -> use that exact model when available; never silently substitute another model. [Task 1]
- when applying an approved plan, unavailable requested model does not authorize substitution; proceed only after explicit user permission. Prefer the ponytail scope: immediate watcher + API login feature flags, with speculative cache/realtime/retry recovery deferred. [Task 2]
- when the user required no merge-ready claim without Smartchat/contact-tab UAT -> report focused validation separately and name unrun manual/build checks. [Task 1]

## Reusable knowledge

- Root cause: `MaxPanel` mounted while `rt_jera_feature_enabled` was false, so mount-only fetching never ran. Once the flag became true, the tab rendered with empty `fetched_jera_partner_connections`. [Task 1]
- The minimal fix is an `immediate: true` watcher on `is_jera_feature_enabled`; return when false, an in-flight request exists, or connections are already non-empty, otherwise call `fetchJeraPartnerConnections()`. The fetch method also has an in-flight guard, so this is not continuous request spam. [Task 1]
- Final patch against `29b3a1b769bf0f1c9fb58e46a5a3e29cfb20d608` changed only `components/MaxPanel.vue` and `test/components/MaxPanel.spec.js`; cache/realtime/focus-retry/error-state code was removed and `plugins/firebase-remote-config.js` restored to base parity. [Task 1]
- Validation: watcher tests `4/4`, store/Remote Config tests `34/34`, `git diff --check` passed; final commit `c67c0018d436139d1a74002055ec7e489698daed` was squashed and pushed with `--force-with-lease`, remote matched local, and worktree was clean. [Task 1]
- The isolated cleanup used a 2-second fail-soft API `Promise.race`, removed Web sessionStorage/realtime/focus/error-retry layers, and passed targeted API/Web tests/builds. `Promise.race` did not cancel the Firebase request, full MaxPanel suites had baseline failures, and Smartchat/contact-tab UAT was unrun. The original isolated changes were not pushed, so do not mistake those worktrees for remote MR evidence. [Task 2]

## Failures and how to do differently

- Symptom: a simple late-flag UI race grows into cache/listener/retry/API/webhook work. Cause: proposing before tracing the symptom through mount, flag resolution, render, and fetch. Fix: map that chain first and delete speculative layers not required by the root cause. [Task 1]
- Symptom: `gpt-5.6-luna` delegation fails through one agent API. Cause: model availability differs by task-creation surface. Fix: use a supported Codex task-creation path or report inability; do not substitute Sol/Terra without permission. [Task 1]
- Symptom: full `MaxPanel.spec.js` is called green. Cause: four pre-existing verification-token failures remain; build and manual delayed-flag/hard-refresh/deep-link UAT were not run. Fix: label focused results precisely and keep merge readiness pending those checks. [Task 1]
- Symptom: isolated worktree validation is called remote merge readiness. Cause: changes were uncommitted/unpushed, and dependency symlinks/config were local test accommodations. Fix: commit/push then refetch MR diff/pipeline; classify baseline suite failures separately and run manual UAT. [Task 2]

# Task Group: /Users/tualek/ohochat / Meta Business AI backend MVP review, scoped implementation, and feature-flag scope correction

scope: Review and narrowly implement Facebook Meta Business AI across `oho-api` and `oho-webhook`; use for authority, identity, tenant safety, Redis dedup, send guards, and accurate cross-repo feature-flag claims.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse the backend/webhook contract only after tracing the current feature commits and worktree; UI/Remote Config scope is separate, and focused tests/builds are not canary proof.

## Task 1: Review and implement scoped Facebook Meta Business AI safety fixes; partial

### rollout_summary_files

- rollout_summaries/2026-08-10T08-42-58-K9az-meta_business_ai_scoped_review_and_luna_fixes.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T15-42-58-019fead6-e1dd-77a1-84ca-e7b90cfc6323.jsonl, updated_at=2026-08-10T17:19:20+00:00, thread_id=019fead6-e1dd-77a1-84ca-e7b90cfc6323, partial; focused fixes validated, production gates remain)
- rollout_summaries/2026-08-10T13-57-30-8fJv-meta_business_ai_minimal_integration_flag_scope_correction.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T20-57-30-019febf6-d717-7103-a1de-872be9834c91.jsonl, updated_at=2026-08-11T03:33:02+00:00, thread_id=019febf6-d717-7103-a1de-872be9834c91, partial; simplified MVP and remaining B1–B5 gates)

### keywords

- Meta Business AI, ai_generated, standby, facebook_delivery_authority, oho-api, oho-webhook, Redis lease, Lua CAS, business_id, Graph API, primary read, campaign TOCTOU, afccdd74e, c3dbadd

## Task 2: Correct the claim that no Meta Business AI feature flag remained; fail

### rollout_summary_files

- rollout_summaries/2026-08-10T13-57-30-8fJv-meta_business_ai_minimal_integration_flag_scope_correction.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T20-57-30-019febf6-d717-7103-a1de-872be9834c91.jsonl, updated_at=2026-08-11T03:33:02+00:00, thread_id=019febf6-d717-7103-a1de-872be9834c91, correction; active web-app Firebase Remote Config usage remains)

### keywords

- rt_meta_business_ai_enabled, firebase-remote-config.js, oho-web-app/store/index.js, Conversation.vue, RoomHeader.vue, SendMessageDisabled.vue, utils/meta-business-ai.js, backend RC lookup, workspace-wide rg

## Task 3: Review and narrow the Meta Business AI plan against the actual webhook contract; partial

### rollout_summary_files

- rollout_summaries/2026-08-11T09-28-34-wXtp-meta_business_ai_plan_review_and_scope_correction.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T16-28-34-019ff026-fc80-7881-8a12-5ba2c15991bb.jsonl, updated_at=2026-08-11T10:24:33+00:00, thread_id=019ff026-fc80-7881-8a12-5ba2c15991bb, partial; plan and focused implementation safely narrowed, blocked on activation evidence and terminal replay)

### keywords

- plan-fix-meta-ai-profile.md, ai_generated, meta-ai, inbox, hasMetaBusinessAiActivation, standby, take_thread_control, pass_thread_control, activation source, legacy meta_business_ai, 31 passed, 17 passed

## Task 4: Rewrite the Facebook-only MVP plan and review its implementation; rework before ship

### rollout_summary_files

- rollout_summaries/2026-08-11T04-34-21-HTzp-meta_business_ai_plan_review_correction_and_implementation_r.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-34-21-019fef19-a05e-7773-9301-06b8ab7c9e37.jsonl, updated_at=2026-08-14T06:34:08+00:00, thread_id=019fef19-a05e-7773-9301-06b8ab7c9e37, partial; corrected Facebook-only scope, local implementation evidence, and rework-before-ship P1s)

### keywords

- meta_business_ai_enabled, message.ai_generated === true, isMetaBusinessAiGeneratedEvent, @meta-ai, @inbox, upsert.hooks.js, upsert.class.js, 300-second lease, checkDuplicate(), skipped_authority_count, Node 24, Utils.isRegExp, broadcast

## Task 5: Implement approved Facebook Meta Business AI MVP corrections; partial

### rollout_summary_files

- rollout_summaries/2026-08-11T11-09-08-rVYn-meta_business_ai_mvp_correction_pass.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-09-08-019ff083-0ff1-7601-a36c-8514dad1e62b.jsonl, updated_at=2026-08-11T13:57:23+00:00, thread_id=019ff083-0ff1-7601-a36c-8514dad1e62b, partial; focused local validation passed, runtime/UAT remains unverified)

### keywords

- meta_business_ai_enabled, ai_generated, external-app whitelist, Facebook standby, take_thread_control, pass_thread_control, Redis lease, duplicate-create race, ${businessId}@meta-ai, ${businessId}@inbox, OHO_FB_APP_ID, git diff --check

## User preferences

- when reviewing this feature, the user asked for a detailed plan around “ข้อความไม่เข้าหรอ ? หรือ performance drop” -> trace message delivery, authority correctness, security/tenant scope, DB/Redis hot-path cost, and concrete worst cases rather than only the diff. [Task 1]
- when the user said to fix “แค่ scope ที่เป็น feature meta business ai ก่อน” and defer web-app design -> preserve dirty worktrees and keep backend/webhook changes separate from UI or unrelated channels. [Task 1]
- when the user corrected “ฉันบอกให้ใช้ 5.6 Luna max” -> do not silently substitute a nearby model; if the named model is unavailable, stop and report it. Once a plan is confirmed and implementation authorized, use a new `[Luna Working] - {name}` task with `gpt-5.6-luna` at max, hand it the approved contract/current worktree/tests/no-commit rule, then have Sol monitor and review the result; do not substitute if Luna max is unavailable. [Task 1] [ad-hoc note]
- when the user challenged “บอกว่าไม่มี feature flag แล้วทำไมยังมี ใน firebase config” -> acknowledge the overclaim directly and distinguish backend removal from repository-wide removal. [Task 2]
- when reviewing a Meta AI plan, the user requested “assumption/risk/edge case/validation/rollback/testing/observability/dependency/migration/security หรือ acceptance criteria” and “การแก้ไขที่ actionable และจัดลำดับความสำคัญ” -> organize concrete, prioritized changes around those categories, not merely a gap list. [Task 3]
- when the user confirmed `ai_generated` is a field Meta sends when Meta AI replied -> preserve the strict incoming boolean and separate message author identity from delivery authority; do not infer it from `app_id`, metadata, or channel. [Task 3]
- for Meta work, the user wants detailed Thai answers with evidence/path and honest limits; keep the MVP to proven contracts rather than a large multi-concern migration. [Task 3]
- when the user asks for a plan “พร้อมทำงาน” -> include scope/non-goals, phases, file boundaries, tests, rollout/rollback, and honest local-versus-UAT status. [Task 4]
- for approved Facebook-only work in `oho-api`/`oho-webhook`, preserve the dirty worktree: do not commit, push, reset, revert, delete, or stage, and do not expand into `oho-web-app`. Treat HTTP 200, focused tests, and queue acknowledgement as insufficient; inspect terminal datastore/Stream state for live claims. [Task 4]
- when the user invokes `ponytail full` -> “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause”; avoid premature abstraction or broad refactors. [Task 4]
- for approved Facebook Messenger-only corrections, keep the work in `oho-api`/`oho-webhook`, preserve dirty work, and report exact changed-file/test results plus runtime/UAT gaps rather than claiming production readiness. [Task 5]

## Reusable knowledge

- Pin actual feature code by reflog/topology when branch refs point at staging: the reviewed commits were `oho-api afccdd74e` and `oho-webhook c3dbadd`. Canonical Facebook events flatten `entry.messaging[]` and `entry.standby[]` with `__ohoChannel`; `message.ai_generated` is nested in that canonical event. [Task 1]
- Identity contract: `entry.__ohoChannel === 'standby' && entry.message.ai_generated === true` is sufficient Meta Business AI identity even without `app_id`; `standby` alone means another app may own delivery, while `ai_generated` is echo-author identity rather than thread ownership. [Task 1]
- Use top-level `facebook_delivery_authority` (`oho|other`) plus timestamp. `standby` customer events observe `other`; customer `messaging` returns `oho` only from prior `other`. Tenant-scope Take/Return by `_id + business_id`, validate Facebook, call Graph first, then conditionally persist only non-stale state; Graph failure preserves prior authority. [Task 1]
- Redis dedup needs pending lease ownership tokens: `completeWithTtl` and `releaseWithToken` must use Lua/CAS so an expired worker cannot mutate a newer claim. Automated Facebook sends use a primary read and fail closed if the authoritative contact is missing; measure p95 and primary load before rollout. [Task 1]
- Accurate feature-flag statement: backend Remote Config lookup was removed from `oho-api`/`oho-webhook`, but `rt_meta_business_ai_enabled` remains active in web-app store/plugin/Smartchat UI. Before a global-removal claim, run workspace-wide `rg -n -i "meta[_-]?business[_-]?ai|rt_meta_business_ai|business_ai"` with dependency/generated exclusions and classify hits as runtime, UI, config, docs, tests, or compatibility. [Task 2]
- `message.ai_generated === true` is a per-message Meta AI author signal that must be preserved in Stream. Both Facebook `messaging[]` and `standby[]` AI echoes use `${businessId}@meta-ai`; a human Business Suite echo without the field uses `${businessId}@inbox`. It is neither Page activation nor thread/delivery authority. [Task 3]
- In the earlier Task 3 checkout, no trustworthy Page/contact activation source was found: `standby`, `hop_context`, `app_id`, `metadata`, `thread_owner`, and `subscribed_apps` were insufficient alone, so `hasMetaBusinessAiActivation()` returned `false`. The newer Task 4 implementation instead uses explicit per-channel `meta_business_ai_enabled`; preserve legacy `meta_business_ai` schema compatibility and re-verify the current activation wiring before relying on either historical state. [Task 3][Task 4]
- Narrow the MVP to sender identity/author labeling with an explicit activation gate, non-goals, phases, acceptance checklist, rollback, and Definition of Done. Keep `meta_ai_profile`, Redis/Cloud Tasks, state-machine migration, cold provisioning, broad TypeScript conversion, and UI work out unless separately justified. Focused validation was API 5 suites/31 tests, webhook 1 suite/17 tests, builds, and `git diff --check`; full type-check had unrelated failures. [Task 3]
- The approved Facebook-only flow passes explicit `channel.meta_business_ai_enabled` through webhook context, contact upsert, automation guard, and controls. AI Stream identity is tenant-scoped `${businessId}@meta-ai`; provisioning may fall back to `${businessId}@inbox` while retaining `ai_generated: true`. Persist enabled Facebook standby customer messages before suppressing OHO chatbot/ARP/greeting/fallback/referral/scheduled automation. [Task 4]
- Do not remove `isMetaBusinessAiGeneratedEvent`: Stream membership does not identify the webhook author. Canonical Facebook events flatten both `messaging[]` and `standby[]`, so strict AI detection must cover both. [Task 4]
- The primary automation guard is tenant-scoped and fail-closed on a missing contact/query error; tenant-scoped Accept/Close Graph controls persist authority only after Graph success. Raw bulk Facebook broadcast is outside that per-contact guard. [Task 4]
- Current approved MVP wiring persists `channel.meta_business_ai_enabled` (default `false`) through webhook channel context, contact upsert/snapshot, automation guards, and control services. `message.ai_generated === true` is strict per-message author evidence only; unknown nested `meta_business_ai.identity` is ignored. [Task 5]
- External-app whitelist handling occurs after Facebook/page/contact validation: strict AI evidence is a narrow exception, unknown non-AI external apps stay fail-closed, and mixed batches must continue valid AI/customer events. Enabled Facebook standby customer messages persist before chatbot/ARP/greeting/fallback/referral/scheduled automation is blocked. [Task 5]
- Accept/Close Graph takeover/return is tenant-scoped and writes authority only after Graph success. Lazy Stream identity is `${businessId}@meta-ai`; provisioning failure falls back to `${businessId}@inbox` while retaining `ai_generated:true`; no cold provisioning/backfill/repair. Focused validation passed API `10 suites/50 tests`, webhook `5 suites/46 tests`, webhook TypeScript, and `git diff --check` in both repos with nothing staged. [Task 5]

## Failures and how to do differently

- Symptom: focused tests/builds are called merge/canary-ready. Cause: full suite, captured-payload replay, terminal Mongo/Stream checks, load testing, and production logs were not run. Fix: keep B1–B5 gates explicit; HTTP 200 or unit tests do not prove webhook delivery. [Task 1]
- Symptom: campaign delivery reaches a contact whose authority changed mid-batch. Cause: authority filtering is a batch snapshot. Fix: add measured per-recipient/send-time checks or gate campaigns. [Task 1]
- Symptom: a slow Redis worker races a reclaimed 300-second lease. Cause: no ownership token/CAS. Fix: block canary until tokenized Lua/CAS completion/release is present. [Task 1]
- Symptom: “no feature flag” overclaims scope. Cause: searched only backend/runtime. Fix: search and classify all repositories/layers; say “no backend RC lookup remains” when that is the verified boundary. [Task 2]
- Symptom: an oversized plan turns `ai_generated` or `standby` into authority/activation and claims performance benefit without a baseline. Cause: author identity, activation, state machine, and optimization were conflated. Fix: split these concerns; never use the fields to write authority or trigger Meta side effects. [Task 3]
- Symptom: unit tests/builds are called deploy-ready. Cause: the earlier Task 3 checkout had no explicit activation source and no real payload replay to terminal Mongo/Stream state; worktree also contained unrelated changes/deleted tests. Fix: isolate the intended diff, verify current `meta_business_ai_enabled` wiring, restore intended canonical/dedup coverage, and keep status blocked until real terminal replay verification. [Task 3][Task 4]
- Symptom: feature-off Meta channels acquire traffic-driven contact activation writes. Cause: `upsert.hooks.js:184-240` performs the snapshot write. Fix: remove the write so disabled channels have no new side effects. Authority/evidence persistence is also duplicated in `upsert.hooks.js:184-390` and `upsert.class.js:51-248`; use one shared atomic updater or simplify the duplicate fallback. [Task 4]
- Symptom: a worker outlives the fixed 300-second Redis dedup lease. Cause: no renewal in `block.ts:289-321` / `redis.service.ts:224-303`. Fix: add renewal or an explicit maximum-processing policy plus real Redis expiry/CAS integration tests. Remove dead `checkDuplicate()`/deprecated dedup methods if unused, and remove `skipped_authority_count` unless campaigns are explicitly in scope and guarded at send time. [Task 4]
- Symptom: `upsert.class.spec.js` fails before running on Node 24. Cause: dependency `config` calls `Utils.isRegExp`. Fix: report it as an environment/dependency blocker, not a passing code suite; focused mock-Redis tests and `git diff --check` do not replace live Meta replay, real Graph take/return, terminal Mongo/Redis/Stream checks, load test, canary, and rollback. [Task 4]
- Symptom: duplicate-create fallback lacks the activation snapshot. Cause: the fallback persisted standby authority before channel activation state. Fix: persist the activation snapshot first and keep regression coverage aligned with the actual fallback query shape. [Task 5]
- Symptom: focused suites are described as runtime proof. Cause: duplicate Jest mock warnings, missing `OHO_FB_APP_ID`, and unavailable localhost Redis do not exercise live behavior. Fix: keep full suites, captured-payload replay, real Graph controls, terminal Mongo/Redis/Stream checks, canary/rollback, and target app configuration as explicit remaining gates. [Task 5]

# Task Group: /Users/tualek/ohochat / Stream Chat queryChannels call-site and documentation review

scope: Locate active Stream Chat `queryChannels` traffic and correct `docs/queryChannels.md`; use for request-volume investigations or docs updates, with backend web paths kept distinct from Flutter and manual callers.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse the call-site map as a starting point, but re-run exact-call searches against the current checkout; this is documentation/call-path evidence, not a performance measurement.

## Task 1: Inventory active queryChannels uses and qualify documentation; success

### rollout_summary_files

- rollout_summaries/2026-08-11T11-28-28-MoHA-stream_querychannels_best_practices_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-28-28-019ff094-bfe0-7330-b67d-5c37089d39fe.jsonl, updated_at=2026-08-14T09:31:07+00:00, thread_id=019ff094-bfe0-7330-b67d-5c37089d39fe, success; call-site, SDK-network, and official best-practices review)

### keywords

- queryChannels, .queryChannels(, chat-proxy-singapore.stream-io-api.com, recoverStateOnReconnect, POST /channels, CID, docs/queryChannels.md, /contact/chat/search, /chat-session/group/search, stream_chat_service.dart, Conversation.vue, $limit === 0

## User preferences

- when the user asks where `queryChannel`/`queryChannels` is used -> distinguish active production calls, SDK-generated traffic, scripts, tests, docs, and commented-out code; return file:line evidence with runtime flow rather than raw grep output. [Task 1]
- when the user corrected “แต่หน้าบ้านมีเรียก https://chat-proxy-singapore.stream-io-api.com/ ด้วยนะ” -> inspect SDK integration and browser network paths before saying the frontend does not call a third-party API directly. [Task 1]
- when the user said “ทำเป็น .md ไฟล์ให้หน่อย” and requested official GetStream comparison -> save research as a reviewable Markdown artifact, cite primary documentation, and separate verified facts from inference and unrun validation. [Task 1]

## Reusable knowledge

- Active production backend calls are `oho-api/src/services/contact/chat-search/chat-search.class.js:46` via `GET /contact/chat/search` and `oho-api/src/services/chat-session/group/search/search.class.js:28` via `GET /chat-session/group/search`; web Smartchat/Groupchat callers converge on these endpoints. [Task 1]
- Flutter is a separate direct production caller: `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:331`, reached from `lib/modules/home/controllers/chat_list_controller.dart:915`, preconnecting chunks of 10 with `messageLimit: 100`. CLI/migration calls are manual/non-hot-path; the Facebook hook at `oho-api/src/services/conversations/facebook/facebook.hooks.js:372` is commented out. [Task 1]
- Qualify `docs/queryChannels.md:68-70`: neither backend path queries Stream when `$limit === 0` or database/search results are empty; Smartchat also skips for `feature_flag.skip_stream_channel_sync`, and Groupchat returns zero badges when starred scope cannot resolve an `_id`. `Conversation.vue` uses `channel.watch()`, not these search endpoints. [Task 1]
- `Conversation.vue:1517-1525` creates `StreamChat` with `https://chat-proxy-singapore.stream-io-api.com`, calls `channel.watch()` at `1595` and `channel.query()` at `2460`. The SDK’s reconnect recovery can call `queryChannels` through `POST /channels` using active CIDs, `last_message_at`, and limit 30; watch/query use `/channels/{type}/{id}/query`. [Task 1]
- The report `/Users/tualek/ohochat/queryChannels-best-practices-review.md` records official guidance: selective filters, CID preferred, explicit sort, max 30 channels, avoid redundant watch, and use `state:false`/`watch:false` when state/realtime is unnecessary. Current gaps include backend pass-through limits up to 50, no backend sort, Groupchat `type + id`, Flutter `id` only/no sort/`messageLimit: 100`, and a source-backed active-channel accumulation risk. Dashboard/runtime confirmation remains unrun. [Task 1]

## Failures and how to do differently

- Symptom: `queryChannel` search overstates active usage. Cause: docs, incidents, tests, comments, and unrelated variables match. Fix: follow broad discovery with `rg '\\.queryChannels\\('` in source/runtime directories and inspect comment delimiters. [Task 1]
- Symptom: “webapp has no direct Stream call.” Cause: searching application-level `queryChannels` only. Fix: trace SDK source and network endpoint/method paths; do not reduce Flutter `messageLimit: 100` or treat Groupchat CID/active-channel concerns as proven performance fixes without Dashboard or runtime evidence. [Task 1]
- Symptom: git status fails from `/Users/tualek/ohochat`. Cause: git metadata lives in component repositories. Fix: run git commands from the relevant subdirectory such as `/Users/tualek/ohochat/oho-api`; do not edit every frontend caller if the intended change is backend Stream-query behavior. [Task 1]

# Task Group: /Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an / Meta AI plan review request

scope: Route a resumed detailed review of `plan-fix-meta-ai-profile.md`; the original review was aborted before file inspection, so this block preserves request shape, not findings.
applies_to: cwd=/Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an; reuse_rule=reuse the review dimensions for the same or similar plan-review requests, but inspect the live plan and source before asserting any conclusion.

## Task 1: Review Meta AI profile plan; aborted before analysis

### rollout_summary_files

- rollout_summaries/2026-08-11T04-28-02-vw3l-meta_ai_plan_review_aborted.md (cwd=/Users/tualek/Documents/Codex/2026-08-11/referenced-chatgpt-conversation-this-is-an, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-28-02-019fef13-d776-7dc0-b2b5-fce38b9ab737.jsonl, updated_at=2026-08-11T04:28:15+00:00, thread_id=019fef13-d776-7dc0-b2b5-fce38b9ab737, uncertain; user aborted before inspection)

### keywords

- plan-fix-meta-ai-profile.md, Meta AI, plan review, assumption, risk, edge case, validation, rollback, testing, observability, dependency, migration, security, acceptance criteria

## User preferences

- when asking for a detailed plan review, the user requested “assumption/risk/edge case/validation/rollback/testing/observability/dependency/migration/security หรือ acceptance criteria” plus actionable prioritized changes -> inspect the target and context first, then report severity/priority, rationale, suggested wording or concrete changes, and a validation checklist. [Task 1]

## Reusable knowledge

- The requested target is `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`; this rollout did not open or validate it. [Task 1]

## Failures and how to do differently

- Do not carry forward findings from this rollout: it ended before analysis. If resumed, begin with the live file and relevant source/payload context rather than treating the requested categories as completed review evidence. [Task 1]

# Task Group: /Users/tualek/.codex / Sol planning and Luna implementation delegation workflow

scope: User-directed model/task handoff for implementation after an approved plan; use when creating a Codex implementation task.
applies_to: cwd=/Users/tualek/.codex; reuse_rule=reuse as the default delegated-implementation workflow unless the user names a different model/process; it does not authorize implementation before approval. [ad-hoc note]

## Task 1: Preserve the default model workflow from authoritative ad-hoc notes

### rollout_summary_files

- extensions/ad_hoc/notes/20260811-163011-sol-plan-luna-implement.md (cwd=/Users/tualek/.codex, rollout_path=extensions/ad_hoc/notes/20260811-163011-sol-plan-luna-implement.md, updated_at=2026-08-11, extension=ad_hoc authoritative note only)
- extensions/ad_hoc/notes/20260811-163349-luna-working-title-prefix.md (cwd=/Users/tualek/.codex, rollout_path=extensions/ad_hoc/notes/20260811-163349-luna-working-title-prefix.md, updated_at=2026-08-11, extension=ad_hoc authoritative note only)

### keywords

- gpt-5.6-sol, gpt-5.6-luna, reasoning effort max, Luna Working, approved plan, no-commit rule, implementation task, Sol review

## User preferences

- for consultation, investigation, grilling, decision-making, planning, and final review, use `gpt-5.6-sol`; after the user confirms a plan and authorizes implementation, create a new `[Luna Working] - {name}` Codex task using `gpt-5.6-luna` with reasoning effort `max`. [Task 1] [ad-hoc note]
- pass Luna the approved contract, current worktree state, completed partial work, tests, constraints, and no-commit rule; Sol monitors/reviews the result and reports evidence. If Luna max is unavailable, stop and tell the user rather than substituting a model. [Task 1] [ad-hoc note]

## Reusable knowledge

- The required task title prefix is exactly `[Luna Working] - {name}`; rename immediately if the creation flow cannot set it. [Task 1] [ad-hoc note]

## Failures and how to do differently

- Do not silently substitute a nearby model or start a Luna implementation task before explicit plan approval and implementation authorization. [Task 1] [ad-hoc note]

# Task Group: /Users/tualek/ohochat / Facebook Messenger attachment ingestion root-cause investigation

scope: Read-only diagnosis of Facebook image/file send failures across OHO source, GCP logs, GCS validity, and raw Meta errors; use before blaming OHO upload/metadata or retrying messages.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse the evidence sequence for similar Facebook/Instagram attachment failures, but re-query the incident window, business/page identifiers, and raw platform responses; do not expose tokens from logs.

## Task 1: Diagnose Gentle Clinic Facebook attachment failures; success

### rollout_summary_files

- rollout_summaries/2026-08-10T07-27-31-raWB-facebook_attachment_ingestion_root_cause_gentle_clinic.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-27-31-019fea91-cc0c-72a0-a973-d5bc782a9d01.jsonl, updated_at=2026-08-10T07:33:25+00:00, thread_id=019fea91-cc0c-72a0-a973-d5bc782a9d01, success; cross-business evidence supported Meta attachment ingestion failure)

### keywords

- Gentle Clinic, 67121be026ec0ed85e1d9208, Facebook Messenger Send API, code=100, error_subcode=2018047, Upload attachment failure, OAuthException, core-api--production, oho-platform, GCS, mediaUrl, youpin-to-facebook

## User preferences

- when the user asks for “rootcause” and whether it is the file, OHO metadata/upload, or Meta -> separate raw platform evidence from UI error mappings and compare the competing causes explicitly. [Task 1]
- when the user supplies a business ID and sample file URL -> search production logs by business/page/file identifiers, error code/subcode, and timestamps; keep the investigation read-only unless edits are requested. [Task 1]

## Reusable knowledge

- OHO sends an existing public GCS `mediaUrl` as `{ attachment: { type: 'image', payload: { url } } }` to Meta; it does not re-encode or re-upload before the Send API call. Relevant code: `oho-api/src/utils/message-converter/youpin-to-facebook.js:42-52` and `src/services/integration/facebook/reply-message/reply-message.class.js:30-35`. [Task 1]
- Thai UI text claiming Facebook does not support the file maps broad `code=100` + `error_subcode=2018047`; it is not a precise diagnosis. The observed raw shape was HTTP 400, `(#100) Upload attachment failure`, `OAuthException`, `code=100`, `error_subcode=2018047`. [Task 1]
- In the Gentle incident, supplied and related GCS images returned HTTP 200 and decoded as ordinary RGB/sRGB JPEGs; old reused and new uploads failed in the same period, while the same subcode appeared across unrelated businesses. Evidence supports a Meta attachment fetch/ingestion incident, not a corrupt OHO file or OHO re-upload defect. The sample JSON business ID `604e2c63...` was not Gentle Clinic’s `67121be...`; correlate send logs before attribution. [Task 1]
- Operational response: after failures cease for about 10–15 minutes, retry only failed attachments; do not resend the whole saved reply because successful text/media can duplicate. [Task 1]

## Failures and how to do differently

- Symptom: GCP log output is truncated/noisy. Cause: broad `gcloud logging read` searches. Fix: constrain service, exact `2018047`, business/page, narrow UTC range, and output only timestamp/severity/text/relevant labels. [Task 1]
- Symptom: local gcloud says its logs directory is not writable. Cause: local configuration permission, not necessarily application access. Fix: treat it as an environment warning when the proxy query still returns logs. [Task 1]
- Never store or repeat access tokens from raw Axios log lines; redact as `[REDACTED_SECRET]`. A Meta public status page saying “No known issues” is weaker than synchronized cross-business production evidence and does not rule out a partial incident. [Task 1]

# Task Group: /Users/tualek/ohochat/script-oho / LINE webhook domain migration hardening and canary operation

scope: Evidence-first review, plan, hardening, and one-channel canary operation of `migrate-line-webhook.ts`; use for LINE endpoint domain changes requiring exact rollback.
applies_to: cwd=/Users/tualek/ohochat/script-oho; reuse_rule=reuse the workflow and safety gates for this migration family, but re-read the current CLI/source and inspect live journals before any production operation; source/unit validation is not end-to-end proof.

## Task 1: Audit, plan, harden, and operate the LINE webhook migration; partial / final production outcome unverified

### rollout_summary_files

- rollout_summaries/2026-08-13T03-57-02-TJMH-line_webhook_migration_safety_review_and_canary_rollout.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-57-02-019ff944-2c61-78d0-ab18-072ed186d997.jsonl, updated_at=2026-08-14T09:53:26+00:00, thread_id=019ff944-2c61-78d0-ab18-072ed186d997, partial; fail-closed manifest plan, verified webhook2 routing, and terminal canary checks)
- rollout_summaries/2026-08-10T07-54-21-Wlnm-line_webhook_migration_review_config_audit.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-54-21-019feaaa-5edf-7453-8fdb-0bf9b642ca0c.jsonl, updated_at=2026-08-10T10:38:39+00:00, thread_id=019feaaa-5edf-7453-8fdb-0bf9b642ca0c, partial; safety audit and runtime-config boundary)
- rollout_summaries/2026-08-10T07-15-37-7oWo-line_webhook_migration_audit_hardening_and_production_runboo.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-15-37-019fea86-e89e-79c3-b1e3-68a6504098fc.jsonl, updated_at=2026-08-11T03:38:57+00:00, thread_id=019fea86-e89e-79c3-b1e3-68a6504098fc, partial; consolidated audit, plan-only boundary, implementation review, and canary guidance)
- rollout_summaries/2026-08-10T06-14-37-ygPX-harden_line_webhook_migration_recovery.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T13-14-37-019fea4f-0f09-7031-a11f-8b18c23fcf85.jsonl, updated_at=2026-08-10T07:28:25+00:00, thread_id=019fea4f-0f09-7031-a11f-8b18c23fcf85, partial; recovery/crash-window hardening)
- rollout_summaries/2026-08-10T04-32-13-Idz9-line_webhook_migration_hardening_scoped_dry_run.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T11-32-13-019fe9f1-4dfe-7963-a2c9-f930bfbf93e7.jsonl, updated_at=2026-08-10T06:55:37+00:00, thread_id=019fe9f1-4dfe-7963-a2c9-f930bfbf93e7, partial; one-channel read-only dry-run)

### keywords

- migrate-line-webhook.ts, --allowed-host, --old-host, manifest, manifest digest, db_update_requested, register_webhook_at, rollback_not_needed, migrate.journal.json, rollback.journal.json, LINE webhook/test, canary, APP_CONFIG, webhook_endpoint, OHO_WEBHOOK_URL

## User preferences

- when reviewing a migration, the user required DB whitelist classification, new-endpoint verification before LINE PUT, LINE update before DB update, and “backup ไว้ทั้งหมด” -> assess and implement the complete failure-safe sequence, not just happy-path calls. [Task 1]
- when the user said “ไม่ต้องงั้นนายทำ plan มาอย่างเดียวก่อน” -> keep the run plan-only and do not edit implementation until explicitly authorized. [Task 1]
- when the user specified `register_webhook_at` should not be updated -> never put it in migrate or rollback payloads. [Task 1]
- when giving production commands, the user wants one exact copy-pasteable command; no duplicated flags, no trailing-space continuation, and no `<token>` placeholder that zsh reads as redirection. [Task 1]
- when canarying a migration, the user prefers one channel/business, manifest inspection, applying that exact manifest, then a real LINE message with webhook/queue/terminal processing evidence before broader rollout. [Task 1]
- when evaluating historical production usage, the user corrected that manual/test traffic is not historical evidence -> exclude the user’s own test events before drawing an adoption or safety conclusion. [Task 1]

## Reusable knowledge

- Existing URL contract is `${webhook_endpoint}/line/webhook/${businessId}` in `oho-api/src/services/channel/line/line.hooks.js:237-286`; `oho-webhook/src/controllers/line/line.controller.ts:30-45` exposes `/webhook/:businessId`. LINE `POST /v2/bot/channel/webhook/test` proves endpoint testing only, not real-message processing. [Task 1]
- Use explicit `--allowed-host=<hostname>`; the old `--old-host` semantics were opposite the requirement. Before mutation, write an immutable, atomically persisted manifest that records exact presence/value of endpoint, validity, active state, and `updated_at`; bind apply confirmation to its digest. [Task 1]
- Apply must consume the reviewed manifest rather than rebuild candidates. Apply/rollback require exclusive `<manifest>.lock`; journal `line_put_requested`, `db_update_requested` before Mongo commit, `db_updated`, `migrated`, and compensation/conflict states. Exact rollback needs `$set`/`$unset` restoration of field presence. [Task 1]
- Static/unit validation: focused tests `11/11`, full tests `21/21`, and CLI help passed. The safe status is UAT/one-channel canary only until real-message, queue/terminal-processing, and rollback verification pass. [Task 1]
- URL-map priority/fallback is not a delivery guarantee, and current Cloud Tasks error swallowing can return 200 after failed enqueue. Preserve old backend/NEG, canary one business, and require task-create success before 200 plus event idempotency/redelivery/reconciliation for any zero-loss claim. [Task 1]
- `webhook2.oho.chat` had an ACTIVE certificate and `/line` returned HTTP 200. The staged topology is old `oho-webhook-production` by default with exact business `fullPathMatch` routes to `webhook--production`; DNS, certificate, URL map, backend, logs, Cloud Task attempts, `source-messages` terminal state, and a real OHO message must all be checked before claiming delivery. [Task 1]
- Runtime config boundary: change `oho-api` environment `webhook_endpoint` in the `APP_CONFIG` Secret Manager flow (GitLab config project `294` → `core-api-config--json--<env>`), then deploy `core-api` with the new secret version. Do not change `oho-webhook` `OHO_WEBHOOK_URL`: it is the internal Cloud Tasks callback base. The stale `webhook.oho.chat` text in `oho-web-app/pages/business/_biz_id/setting/integration.vue:824-1140` is in a commented block, so it does not require web-app deployment. [Task 1]
- Related skill: skills/oho-line-webhook-migration/SKILL.md. [Task 1]

## Failures and how to do differently

- Symptom: a post-mutation backup cannot reliably undo a crash/partial run. Cause: original backup was persisted after LINE/DB mutation, omitted states, did not bind confirmation to candidates, and could exit successfully despite reported failures. Fix: manifest-first, exact before-state, fail-closed exit semantics, and manifest-bound apply. [Task 1]
- Symptom: resumed or concurrent migration can corrupt/lose journal truth. Cause: revalidation rejected resumed candidates, there was no lock, and a DB-commit-to-journal crash window. Fix: state-aware revalidation, exclusive lock, and durable `db_update_requested` intent before commit; these P0s were statically/unit-wise addressed. [Task 1]
- Symptom: rollback says `rollback_not_needed` even though the channel was migrated. Cause: dry-run summary label is misleading; detail can say `would restore ...`. Fix: inspect both `<manifest>.migrate.journal.json` and `<manifest>.rollback.journal.json`, especially durable `migrated`/`dbUpdatedAt`, before declaring rollback unnecessary. [Task 1]
- Symptom: exact shell command fails. Cause: duplicate `--execute`/`--confirm` flags or `\\ ` with trailing space. Fix: produce a single clean command, validate flags occur once, and avoid multiline continuations unless essential. Do not record production tokens/identifiers in memory. [Task 1]
- Symptom: a cross-repo `rg` hit is called a deployment dependency. Cause: reachability/comments were not inspected. Fix: inspect enclosing comments, feature gates, route registration, and execution/render path; do not read an entire production secret merely to inspect one field. [Task 1]
- Symptom: a route/certificate or `add_queue_success` is called a safe rollout. Cause: it proves only a partial chain, and `createTask()` can be swallowed while the controller returns 200. Fix: revert to old `100`/new `0` on task-create failure, non-OK attempt, `sync_message_fail`, `dropped`, stuck `inprogress`, or canary 5xx/timeout. [Task 1]

# Task Group: /Users/tualek/Documents/migrant-labor-crm / new-machine local development setup

scope: Complete first-time macOS setup of Migrant Labor CRM, including Docker dependencies, Prisma database, seed, and NestJS API verification.
applies_to: cwd=/Users/tualek/Documents/migrant-labor-crm; reuse_rule=reuse the sequence for a new checkout/machine only after checking the current README, `.env.example`, tool versions, and existing user edits.

## Task 1: Set up the full local stack on a new Mac; success

### rollout_summary_files

- rollout_summaries/2026-08-09T06-26-19-LLdx-migrant_labor_crm_new_machine_local_setup.md (cwd=/Users/tualek/Documents/migrant-labor-crm, rollout_path=/Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T13-26-19-019fe533-6a13-7ce1-b33a-be843748c46b.jsonl, updated_at=2026-08-09T06:58:19+00:00, thread_id=019fe533-6a13-7ce1-b33a-be843748c46b, success; Docker, Prisma, seed, API, and HTTP check verified)

### keywords

- migrant-labor-crm, pnpm, CI=true, Docker Desktop, docker compose, Prisma, PostgreSQL, Redis, MinIO, NestJS, @mlcrm/api, ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY, EPERM, Schema engine error, /auth/me

## User preferences

- when setting up a repo, the user asked “run everything for me” -> inspect and execute the complete workflow rather than only listing commands. [Task 1]
- during setup, protect existing worktree changes and do not overwrite an existing `.env`. [Task 1]

## Reusable knowledge

- Stack: pnpm workspace with React/Vite, NestJS, Prisma/PostgreSQL, Redis/BullMQ, and MinIO. Standard setup is `pnpm install`, create `.env` from `.env.example` if absent, `docker compose up -d`, `pnpm db:generate`, `pnpm db:migrate`, `pnpm db:seed`, then `pnpm dev`. If frontend already runs, start API only with `pnpm --filter @mlcrm/api dev`. [Task 1]
- Local services: PostgreSQL `5432`, Redis `6379`, MinIO API `9000` and console `9001`; frontend defaults to API `http://localhost:3000`, so `apps/web/.env.local` / `VITE_API_URL` is only needed for non-default API URLs. Generate a fresh `JWT_SECRET` locally; never preserve it in memory. [Task 1]
- Completion evidence used here: containers healthy, three migrations applied, seed succeeded (optional `~/Downloads/power_of_attorney.pdf` absent), NestJS listening on `3000`, and `GET /auth/me` returned `401`—reachable API with authentication enforced. [Task 1]

## Failures and how to do differently

- Symptom: Compose command exists but cannot start services. Cause: Docker CLI is installed but daemon/socket is unavailable. Fix: check both `docker version` and `docker compose version`; start Docker Desktop and complete its user-owned privileged setup if necessary. Stale broken Docker symlinks previously required `brew install --cask docker --no-binaries`. [Task 1]
- Symptom: noninteractive install aborts with `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`. Fix: use `CI=true pnpm install`. [Task 1]
- Symptom: sandboxed setup gives `ENOTFOUND registry.npmjs.org`, Prisma-cache `EPERM`, or generic `Schema engine error`. Cause: restricted network, `~/.cache/prisma`, or local Docker/PostgreSQL access. Fix: rerun the affected command with the necessary approved access; do not call setup complete until containers, migration, seed, API logs, and HTTP response all pass. [Task 1]

# Task Group: /Users/tualek/ohochat / Meta Business AI Messenger handover, onboarding, and ClickUp handoff

scope: Evidence-first OHO-1215/OHO-1634 work on Meta Business AI contracts versus observed POC, Facebook Page onboarding, runtime ownership/reducer safety, and stakeholder/ClickUp handoff.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=use for Meta Business AI / Facebook Messenger handover work; re-verify live payloads, code, logs, and external-card persistence before treating observed behavior, an HTTP response, or a diagram as a universal contract or completed outcome.

## Task 1: Create Facebook Page onboarding runbook and synchronize OHO-1634; success

### rollout_summary_files

- rollout_summaries/2026-08-03T07-01-28-EQdm-meta_business_ai_facebook_page_onboarding_clickup_handoff.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T14-01-28-019fc66d-6db1-7253-a396-dfde3105523c.jsonl, updated_at=2026-08-05T03:30:55+00:00, thread_id=019fc66d-6db1-7253-a396-dfde3105523c, success; runbook and ClickUp persistence verified)

### keywords

- OHO-1634, Facebook Page onboarding, not_started, configured, verified, messaging_handovers, Conversation Routing, default app, pass_thread_control, send_first, HUMAN_AGENT, GET union POST GET verify, ClickUp

## Task 2: Implement narrowly scoped Smartchat unread/unresponded badge fix for four QA cases; success

### rollout_summary_files

- rollout_summaries/2026-08-04T09-26-31-tqzG-smartchat_four_qa_badge_fix_scoped_validation.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T16-26-31-019fcc18-966f-75c1-8bb6-3c8b98c927f4.jsonl, updated_at=2026-08-05T03:16:07+00:00, thread_id=019fcc18-966f-75c1-8bb6-3c8b98c927f4, success; focused API/Mongo/web contract validation)

### keywords

- Smartchat, QA-case-1, QA-case-2, QA-case-3, QA-case-4, emit-chat-session-event.js, includeUnreadState, unread_by, is_unresponded, getEligibleMemberIds, group-chat, 46 tests, 28 tests, 135 tests

## Task 3: Diagnose UAT Facebook-login consent and App ID history; partial

### rollout_summary_files

- rollout_summaries/2026-08-04T11-11-11-39xm-uat_facebook_login_consent_meta_app_change_history.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-11-11-019fcc78-6964-7c40-b51c-34e9b65b8d10.jsonl, updated_at=2026-08-04T11:26:49+00:00, thread_id=019fcc78-6964-7c40-b51c-34e9b65b8d10, partial; environment change dated, Meta-side switch unverified)

### keywords

- FACEBOOK_APP_ID, Facebook Login for Business, UAT, staging-4, production, Nuxt build-time config, Cloud Run revision, web-app--uat-00082-8tn, DOTENV, config_id, is_business_login

## Task 4: Review 3-box Meta Business AI flow; rework before implementation contract

### rollout_summary_files

- rollout_summaries/2026-08-07T06-58-36-zLcc-meta_business_ai_3_boxes_documentation_review.md (cwd=/Users/tualek/Documents/Codex/2026-08-07/referenced-chatgpt-conversation-this-is-an, rollout_path=/Users/tualek/.codex/sessions/2026/08/07/rollout-2026-08-07T13-58-36-019fdb04-3fd5-7162-baaf-6899542d9a88.jsonl, updated_at=2026-08-07T07:05:16+00:00, thread_id=019fdb04-3fd5-7162-baaf-6899542d9a88, rework; source traced in oho-webhook/oho-api/oho-web-app)

### keywords

- meta-biz-ai-flow-3-boxes, previous_owner_app_id, new_owner_app_id, shouldBlockFacebookBotSend, reactivation=requested, runtime-event.class.js, conditional atomic update, stale-event rejection, conceptual view

## Task 5: Review POC and create source-separated Meta communication material; rework before implementation

### rollout_summary_files

- rollout_summaries/2026-08-03T18-11-52-TXSz-meta_business_ai_doc_split_clickup_update_blocked.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T01-11-52-019fc8d3-33e3-7132-b93a-a21e3685223b.jsonl, updated_at=2026-08-03T18:11:52+00:00, thread_id=019fc8d3-33e3-7132-b93a-a21e3685223b, success; source matrix and communication pack)
- rollout_summaries/2026-08-02T17-35-03-puSA-meta_business_ai_poc_second_opinion_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T00-35-03-019fc38b-2163-7081-8ab6-b42248952f08.jsonl, updated_at=2026-08-02T20:11:49+00:00, thread_id=019fc38b-2163-7081-8ab6-b42248952f08, rework; detailed Thai source review)

### keywords

- OHO-1215, official contract, observed POC, coming soon, source matrix, standby, messaging, ai_generated, hop_context, thread_owner, queue ordering, gcloud logging

## User preferences

- when reviewing Meta Business AI work, the user asked: “Answer entirely in Thai” and requested a detailed problem/evidence/severity/recommendation structure -> respond in Thai with detailed, source-cited findings rather than a terse summary. [Task 4]
- when evidence is incomplete, the user said “Do not fabricate log output” -> separate verified source facts, document/payload evidence, `no data`, and `Not run: <reason>`; a credential failure or timeout is not no data. [Task 1][Task 4]
- when asked what Facebook Page onboarding is necessary -> cover both Oho-controlled setup and Page-admin Meta configuration, and distinguish `configured` from `verified`. [Task 1]
- when the user said “ตอนนี้อยากให้ครอบคลุมแค่เคสที่ QA ตีแก้มา 4 case” -> keep implementation focused on reported QA scenarios; defer broad refactor/optimization. [Task 2]
- when the user asked to compare `prod`, `staging-4`, and `uat` -> compare deployed environment configuration and browser requests before editing code. [Task 3]
- when the user asked “update description ในการ์ด” and include related files -> make the external update, then verify the saved card after reload; a repo draft is not completion. [Task 1]

## Reusable knowledge

- Required Facebook Page onboarding gates: identity mapping; Page token/permissions; HTTPS webhook/signature verification; subscriptions `messages`, `message_echoes`, `message_deliveries`, `message_reads`, `messaging_postbacks`, `messaging_referrals`, `messaging_handovers`, `standby`; Conversation Routing/default app; Business AI activation; takeover configuration; fresh-message E2E. Use `GET → union → POST → GET verify`; never replace existing subscription fields. [Task 1]
- Return-to-AI requires positive fresh runtime evidence after `pass_thread_control`. HTTP 200, a Messenger banner, one `standby` signal, or a `thread_owner` snapshot is insufficient. For tested silent takeover, retain a `send_first` + `HUMAN_AGENT` fallback. [Task 1]
- ClickUp OHO-1634 was verified after reload with canonical `04`/`05`/`06` files and matching SHA-256; use custom task ID `OHO-1634` if an internal/workspace combination returns `Team not authorized`, and inspect tail sections when connector reads truncate a long description. [Task 1]
- The four-case patch keeps group chat unresponded-only; contact/Smartchat opts into per-member unread via `includeUnreadState: true`. `buildAttentionEventUnreadPayload` gates `unread_by` and `is_unresponded` independently; both off returns `{}` without eligible-member lookup. [Task 2]
- Facebook login source is shared; `FACEBOOK_APP_ID` is baked into the Nuxt client at build time. Changing only Cloud Run runtime variables is insufficient: update GitLab `DOTENV`, rebuild/deploy, then route traffic to the revision. Cloud Run revision history can prove the deployed App ID date, not when Meta changed an app's Login-for-Business setting. [Task 3]
- The 3-box diagram is conceptual until a canonical runtime-state contract models requested/confirmed/unconfirmed/failed. Preserve previous/new owner app IDs, reject stale events with conditional atomic updates, and block bot sends while return-to-AI is pending. [Task 4]
- Keep delivery authority, agent identity, and latest event as separate state dimensions. `standby` versus `messaging`, `thread_owner`, or `hop_context` alone is not a binary AI/OHO-owner test; canonicalize/dedupe control events before queue/state transition and branch controls before message transformation. [Task 5]
- For stakeholder material, keep official/current, coming-soon/planned, observed POC, and questions for Meta separate; do not use POC answers as an implementation contract. [Task 5]

## Failures and how to do differently

- Symptom: control events are treated as immediate ownership confirmation. Cause: API only passes `control_event_type`, reducer lacks direction and stale-event guards. Fix: include owner direction/target, use transition states, and enforce conditional writes. [Task 4]
- Symptom: a flag-off Smartchat change claims zero runtime impact. Cause: the after-hook still does one contact `findOne()` and flag lookup. Fix: call it a deferred optimization; do not claim behavior absent beyond disabled writes/lookups/emits. Browser E2E was not run. [Task 2]
- Symptom: post-login consent is asserted from an unauthenticated browser. Fix: require an authenticated Meta session or captured request; navigation timeouts should be checked by current URL/title before declaring failure. [Task 3]
- Symptom: Meta docs conflict or live checks return 429/cache miss. Fix: preserve explicit clarification questions and mark live comparison unverified instead of silently selecting a universal contract. [Task 1][Task 4]

# Task Group: /Users/tualek/ohochat / ClickUp ticket lookup and Meta MVP estimation

scope: Assignee-scoped ClickUp date queries and evidence-bound OHO-1634 planning estimates.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse the ClickUp lookup sequence for the current user and the MVP scope map only after re-querying live task data; estimates are planning inputs, not commitments.

## Task 1: Find the current user's latest due-date ticket; success

### rollout_summary_files

- rollout_summaries/2026-08-04T11-45-02-h9iX-clickup_latest_due_date_assigned_ticket.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-45-02-019fcc97-697a-70b0-a137-64ad27e07903.jsonl, updated_at=2026-08-04T11:48:17+00:00, thread_id=019fcc97-697a-70b0-a137-64ad27e07903, success)

### keywords

- clickup_resolve_assignees, ClickUp, assignees, due_date, Asia/Bangkok, OHO-1215, 113526352, clickup_get_task

## Task 2: Correct assignee filtering and estimate OHO-1634 Meta Business AI MVP; partial

### rollout_summary_files

- rollout_summaries/2026-08-04T12-00-04-U5UC-clickup_assignee_filter_and_meta_business_ai_estimate.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-00-04-019fcca5-2c2f-7bb1-ad67-039a286e19da.jsonl, updated_at=2026-08-05T04:00:09+00:00, thread_id=019fcca5-2c2f-7bb1-ad67-039a286e19da, partial; planning estimate, not runtime validated)

### keywords

- เอาแค่ assign ของฉันสิ, OHO-1634, expected string received number, ClickUp server error, 15-20 working days, 5-7 days, webhook canonicalization, Cloud Tasks canary

## User preferences

- when listing ClickUp tickets for a date, the user corrected: “เอาแค่ assign ของฉันสิ” -> filter to the current user's assignee before presenting results unless all tickets are explicitly requested. [Task 2]
- when asking which assigned ticket has the latest due date -> give the top result, ticket ID, title, due date, status, and link in concise Thai rather than dumping every ticket. [Task 1]

## Reusable knowledge

- Resolve `me` rather than guessing: `clickup_resolve_assignees({assignees:["me"]})` returned user ID `113526352`. Search results may omit due dates, so fetch task summaries, use `due_date` rather than `dateUpdated`, convert to Asia/Bangkok, then sort. [Task 1]
- Assignee filtering can reject a numeric ID with `expected string, received number` and a string retry can return `ClickUp server error`; fall back to per-task verification of candidate tasks. [Task 2]
- OHO-1634 MVP estimate was 15–20 working days (plan 20), limited POC demo 5–7. Scope includes canonicalization, queue/state/dedup, bot/scheduled-send safety, subscriptions, UI, QA, observability, canary; it lacks Meta runtime/Cloud Tasks validation. [Task 2]

## Failures and how to do differently

- Do not return all date-matched tickets before applying assignee scope. [Task 2]
- Do not present a planning estimate as a verified delivery commitment, or use internal task ID `90182460598` when `OHO-1634` is the working custom ID. [Task 2]

# Task Group: /Users/tualek/ohochat / Stream Chat credentials and Cloud Run multi-tenancy

scope: Secure per-business Stream Chat credential resolution without duplicating Cloud Run.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse architecture only after confirming tenancy, authorization, Stream account model, and compliance/isolation requirements.

## Task 1: Design per-business Stream credential resolution; success

### rollout_summary_files

- rollout_summaries/2026-08-04T12-04-39-FePe-dynamic_stream_credentials_cloud_run_multitenancy.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-04-39-019fcca9-5c19-7c82-9846-631245488d38.jsonl, updated_at=2026-08-04T12:07:11+00:00, thread_id=019fcca9-5c19-7c82-9846-631245488d38, success; architecture guidance)

### keywords

- Stream Chat, business_id, Secret Manager, pinned secret version, MongoDB mapping, Cloud Run, Firebase Remote Config, api_secret, user token, TTL, LRU, global singleton

## User preferences

- when the user clarified “มันเป็น secreat เลยเพราะต้องทำ multi account streamchat แยกตาม business” -> keep `api_secret` server-only and resolve credentials per authorized business, never through frontend config. [Task 1]

## Reusable knowledge

- Use `business_id → MongoDB mapping → Secret Manager pinned version → backend Stream client/token → frontend apiKey + userToken`. Cache clients by connection/business and secret version with TTL/LRU; rotate by adding a secret version and updating the mapping, not `latest`. [Task 1]
- One Cloud Run service can serve multiple Stream accounts. Separate services are for infrastructure/compliance isolation (service accounts, networking, scaling, deployment, operational boundaries), not credential selection alone. [Task 1]

## Failures and how to do differently

- Never put per-business Stream secrets in Firebase Remote Config, frontend runtime config, or a global Cloud Run env variable; do not trust arbitrary request-body `business_id` or use one global Stream client across businesses. [Task 1]

# Task Group: /Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www / Canva section addition and PDF export

scope: Append Thai foreign-worker content to an existing Canva deck while preserving its style, with a separate importable/PDF fallback.
applies_to: cwd=/Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www; reuse_rule=reuse the Canva access/fallback sequence, but re-inspect the live design and confirm page insertion before claiming the deck changed.

## Task 1: Add a new Canva section; partial, no insertion completed

### rollout_summary_files

- rollout_summaries/2026-08-09T04-06-11-vKu8-canva_section_addition_and_pdf_export.md (cwd=/Users/tualek/Documents/Codex/2026-08-09/10-52-jeam-smk-https-www, rollout_path=/Users/tualek/.codex/sessions/2026/08/09/rollout-2026-08-09T11-06-11-019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc.jsonl, updated_at=2026-08-09T07:19:28+00:00, thread_id=019fe4b3-1cdd-7b82-a02e-9bbf8aba17dc, partial; PDF exported, no Canva page inserted)

### keywords

- Canva, DAGsRNjn95Y, Add page, Chrome extension, All changes saved, foreign-worker, 60 pages, 1920x1080, e-workpermit-detailed-workflow-section-v7-identity-visa.pdf

## User preferences

- when adding content to a presentation, the user asked for “ใน section ใหม่ต่อจากอันเดิม” and to inspect the original style -> append after existing content, retain visual continuity, and do not alter unrelated pages. [Task 1]
- when direct insertion is blocked, the user accepted a separate file for later import -> provide an importable standalone section rather than stopping. [Task 1]

## Reusable knowledge

- Design `DAGsRNjn95Y` has 60 editable 1920×1080 pages; use pages 57–60 as style references. The logged-in Chrome extension exposed the existing editor tab; prefer it over the in-app browser, which produced a blank login path. [Task 1]
- A 13-page Thai PDF was exported at `outputs/pdf/e-workpermit-detailed-workflow-section-v7-identity-visa.pdf`. [Task 1]

## Failures and how to do differently

- An editing transaction is not completion: the API did not provide a validated add-page operation and the transaction was cancelled. Use the visible native Add page/copy-page flow in the claimed existing editor, or clearly leave import/copy for the user. [Task 1]

# Task Group: /Users/tualek/ohochat/backoffice-v2 / UI design audit and dark-mode implementation planning

scope: Create a detailed, plan-only UI/UX and dark-mode implementation plan from source plus rendered viewport evidence; use for backoffice-v2 layout, responsive-shell, theme-token, accessibility, or visual-audit planning.
applies_to: cwd=/Users/tualek/ohochat/backoffice-v2; reuse_rule=reuse the audit sequence and design findings as a baseline only after re-checking the live branch, authenticated data routes, and concurrent workspace changes; this rollout did not implement or fully validate the plan.

## Task 1: Audit backoffice-v2 UI and create a detailed dark-mode implementation plan, success

### rollout_summary_files

- rollout_summaries/2026-08-04T04-50-48-0WTj-backoffice_v2_ui_design_dark_mode_plan.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T11-50-48-019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd.jsonl, updated_at=2026-08-04T05:01:22+00:00, thread_id=019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd, plan-only source and visual audit; Markdown formatting verified)

### keywords

- backoffice-v2, ui-audit, dark-mode, ui-design-dark-mode-plan.md, responsive-layout, AppLayout.tsx, SubMenu.tsx, globals.css, semantic-tokens, PageShell, Playwright, jwt malformed, prettier

## User preferences

- when the user asks “ทำเป็น plan อย่างละเอียด” and “สร้าง md plan มาเลย” including dark mode -> deliver an implementation-ready document with design specs, file references, rollout phases, tests, and acceptance criteria, not just a problem list. [Task 1]
- when the user asks to assess padding/margin and visual quality from the real UI -> inspect source alongside rendered screenshots and viewport checks. [Task 1]
- when the task is plan-only -> do not change implementation or commit without a separate instruction. [Task 1]

## Reusable knowledge

- The created plan is `/Users/tualek/ohochat/backoffice-v2/ui-design-dark-mode-plan.md`; it specifies a 4px spacing scale, typography roles, responsive shell, shared page patterns, semantic dark tokens, page-by-page work, visual matrix, accessibility, acceptance criteria, and eight phases with commit boundaries. [Task 1]
- In the reviewed baseline, `src/styles/globals.css:37-66` has light semantic tokens but no `.dark`, `color-scheme`, `theme-color`, or pre-paint theme bootstrap. It also has global heading sizes (`h1=40`, `h2=36`, `h3=24`) and `div:focus { outline: none }`; move typography to role-based styling and repair focus handling. [Task 1]
- `AppLayout.tsx` uses `p-10` and `SubMenu.tsx` a fixed `w-60`; at 1024px, rail 64px + submenu 240px + main padding 40px squeeze the business content/table. Use a collapsible or overlay submenu for 1024–1279px. [Task 1]
- Migrate light-only coupling (`bg-white`, `text-black-*`, `border-black-*`, hardcoded hex/rgba, `transition-all`) from business, payment, external-message, JERA, and dashboard through semantic surface/status/chart tokens and shared primitives before feature-page dark-mode work. The plan's theme contract is `light`/`dark`/`system`, `localStorage` key `oho-backoffice-theme`, class `dark` on `<html>`, `color-scheme`, meta `theme-color`, and `light` default for existing users. [Task 1]
- Visual smoke checks used `bash /Users/tualek/.codex/skills/playwright/scripts/playwright_cli.sh`; calling that wrapper directly caused `Permission denied`. [Task 1]

## Failures and how to do differently

- Symptom: dummy-cookie authenticated routes return `jwt malformed`. Cause: local API authentication is not valid. Fix/pivot: report only shell, navigation, empty/loading, and layout evidence; do not claim data-driven behavior passed. [Task 1]
- Symptom: source shifts while the dev server is running. Cause: another process/session changes files concurrently. Fix/pivot: check timestamps and re-check source line references immediately before summarizing. [Task 1]
- Symptom: a planning rollout is presented as fully validated. Cause: only the Markdown plan's Prettier check passed; full lint/typecheck/test/build were not run. Fix/pivot: explicitly say `Not run` rather than extending the formatting result to application validation. [Task 1]

# Task Group: /Users/tualek/retourapac / ReTour APAC form/dashboard documentation and prior-artifact search

scope: Locate previously created ReTour form-access/dashboard-use artifacts across the workspace, Claude history, and Drive; route to the verified documentation when a deck is not recovered.
applies_to: cwd=/Users/tualek/retourapac; reuse_rule=reuse the search order and documentation pointers for similar ReTour artifact requests, but report a deck as not found rather than nonexistent unless the live repository, Claude project history, and Drive search are repeated.

## Task 1: Locate existing form/dashboard slides; no matching deck verified, documentation and prior Claude session identified

### rollout_summary_files

- rollout_summaries/2026-08-04T01-19-33-sccm-find_retour_form_dashboard_slides.md (cwd=/Users/tualek/retourapac, rollout_path=/Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T08-19-33-019fca5a-c19e-7761-966a-95f4e7276aae.jsonl, updated_at=2026-08-04T01:21:08+00:00, thread_id=019fca5a-c19e-7761-966a-95f4e7276aae, partial; no deck recovered)

### keywords

- ReTour, slides, dashboard, submission-form, Google Drive, Claude session, ai-title, last-prompt, apps-script/README.md, dashboard-plan.md

## User preferences

- when the user asks “ฉันน่าจะเคยมีทำ slide ของ step การเปิดปุ่ม form และการใช้ dashboard ช่วยหา slide ให่หน่อยเคยทำไว้ใน claude” -> search both Claude history and the workspace/Drive for the prior artifact before proposing to recreate it. [Task 1]

## Reusable knowledge

- No ReTour-specific `.pptx`, `.ppt`, Google Slides URL, or matching deck was found in `/Users/tualek/retourapac` or the searched Google Drive presentation results. The practical replacement sources are `/Users/tualek/retourapac/apps-script/README.md` (setup, form webhook flow, dashboard roles, daily use) and `/Users/tualek/retourapac/dashboard-plan.md` (test-only form access and dashboard behavior). [Task 1]
- The relevant prior Claude session is `/Users/tualek/.claude/projects/-Users-tualek-retourapac/f39934f0-c004-4206-853a-18ffda63f30b.jsonl`, titled “สร้าง dashboard สำหรับ review และ approve forms”; the master dashboard sheet is `https://docs.google.com/spreadsheets/d/1ktQ8F00uR4rLJiawR964bSYcNILl7pb0O8NhMwCA4u4/edit`. [Task 1]

## Failures and how to do differently

- Symptom: broad `rg` over Claude JSONL produces heavily truncated output. Cause: large session histories swamp the result. Fix/pivot: search the relevant Claude project directory first, inspect metadata such as `ai-title` and `last-prompt`, then use exact artifact extensions and focused terms. [Task 1]
- Symptom: no deck is recovered. Fix/pivot: present the result as “not found,” not proof it never existed; offer a new deck from the README and dashboard plan only if requested. [Task 1]

# Task Group: /Users/tualek/Documents/Codex/2026-08-03/r / Cursor ai-main rules and symlink integration

scope: Runtime-aware audit of Cursor loading ai-main-managed skills, commands, and workspace rules, plus recoverable cleanup of a conflicting home-level rule source.
applies_to: cwd=/Users/tualek/Documents/Codex/2026-08-03/r; reuse_rule=reuse the audit sequence for Cursor and ai-main integration, but re-check the live Cursor version, runtime state, symlink targets, registered workspaces, and any cached sessions before treating this snapshot as current.

## Task 1: Audit Cursor integration; runtime confirmed ai-main skills, commands, and workspace rules were loaded

### rollout_summary_files

- rollout_summaries/2026-08-03T06-25-10-otHf-audit_and_fix_cursor_ai_main_rules_symlinks.md (cwd=/Users/tualek/Documents/Codex/2026-08-03/r, rollout_path=/Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T13-25-10-019fc64c-3291-73a0-9abc-8400c6838b3d.jsonl, updated_at=2026-08-03T06:38:46+00:00, thread_id=019fc64c-3291-73a0-9abc-8400c6838b3d, success; Cursor 3.14.7 runtime-state evidence)

### keywords

- Cursor, ai-main, ~/.cursor/skills, ~/.cursor/commands, AGENTS.md, CLAUDE.md, always_applied_workspace_rule, aimain list, symlink, cursor-agent

## Task 2: Remove stale conflicting `/Users/tualek/AGENTS.md`; backup preserved and workspace fleet stayed healthy

### rollout_summary_files

- rollout_summaries/2026-08-03T06-25-10-otHf-audit_and_fix_cursor_ai_main_rules_symlinks.md (cwd=/Users/tualek/Documents/Codex/2026-08-03/r, rollout_path=/Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T13-25-10-019fc64c-3291-73a0-9abc-8400c6838b3d.jsonl, updated_at=2026-08-03T06:38:46+00:00, thread_id=019fc64c-3291-73a0-9abc-8400c6838b3d, success; stale rule moved to recoverable backup)

### keywords

- /Users/tualek/AGENTS.md, stale-home-backup-20260803, workspace rules, Cursor cached rules, reload window, new chat, aimain list

## User preferences

- when asking whether Cursor still used the ai-main rules and symlinks -> verify actual runtime loading, not only filesystem presence. [Task 1]
- when the user said “จัดการให้หน่อย” about the stale conflicting rule -> make the scoped corrective change, preserve a recoverable backup, and avoid touching unrelated dirty work in `ai-main`. [Task 2]

## Reusable knowledge

- In the verified Cursor 3.14.7 snapshot, `~/.cursor/skills/` had 22 valid symlinks to `/Users/tualek/ai-main`, `~/.cursor/commands/worklog.md` pointed to the ai-main command, and runtime state loaded workspace `AGENTS.md`/`CLAUDE.md` as `always_applied_workspace_rule`. No `~/.cursor/rules/` directory did not prevent workspace rules from loading. [Task 1]
- `ai-main/bin/aimain list` reported all 11 registered workspaces `ok`; ai-main deploys the repo-specific compiled `AGENTS.md`, with `CLAUDE.md` and `GEMINI.md` aliases. Use the runtime state/logs as the stronger loading check and `aimain list` as fleet-health evidence. [Task 1]
- A home-level `/Users/tualek/AGENTS.md` can be loaded in addition to ai-main workspace rules and conflict with repo conventions. The verified cleanup moved it to `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`; original absence, backup existence, intact workspace files, and all-workspaces-`ok` were checked. Existing Cursor sessions may cache rules, so reload the window or use a new chat after rule-file changes. [Task 2]

## Failures and how to do differently

- Symptom: `rtk find` is used for compound predicates/actions. Cause: it does not support that form. Fix/pivot: use native `find` for symlink and file predicates. [Task 1]
- Symptom: `cursor agent --help` cannot run because `cursor-agent` is absent and network installation fails. Fix/pivot: record the CLI limitation and inspect Cursor runtime state/logs instead; do not claim CLI verification. [Task 1]
- Symptom: fixing a global rule risks unrelated repository churn. Fix/pivot: move only the identified stale rule to a named backup and leave dirty `ai-main` worktree changes untouched. [Task 2]

# Task Group: /Users/tualek/ohochat/docs/react-migration / backoffice React migration-plan source review

scope: Repository-scoped, read-only validation of `backoffice-react-v2-plan.md` against the live Nuxt/Vue backoffice source; use before implementation or plan approval.
applies_to: cwd=/Users/tualek/ohochat/docs/react-migration; reuse_rule=the plan lives here but factual contracts come from `/Users/tualek/ohochat/oho-backoffice` at the pinned revision; re-inventory after any checkout/SHA change.

## Task 1: Review the original backoffice React migration plan against the actual repository; rework before implementation

### rollout_summary_files

- rollout_summaries/2026-07-31T16-52-16-hvzY-review_backoffice_react_migration_plan.md (cwd=/Users/tualek/ohochat/docs/react-migration, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T23-52-16-019fb917-4170-7273-a018-fe437807752a.jsonl, updated_at=2026-07-31T16:57:58+00:00, thread_id=019fb917-4170-7273-a018-fe437807752a, success; baseline `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1`)

### keywords

- backoffice-react-v2-plan.md, oho-backoffice, Nuxt2, Vue2, TanStack Router, Cloud Run, auth_user_token, auth_created_token_at, external-message-apps, external-message-whitelist, path-based-cutover, Intl.NumberFormat

## User preferences

- when the user specified “Scope is strictly oho-backoffice only” and “do not edit the plan file or any other files” -> keep reviews repository-scoped and strictly read-only. [Task 1]
- when the user asked for plan-section/phase organization, quoted references, concrete adjustments, and a prioritized top 3–5 -> report evidence-first by phase with actionable fixes and a short priority list. [Task 1]
- when the user said not to guess repo structure/tooling -> inspect actual route, API, auth, dependency, and deployment sources before asserting a gap. [Task 1]

## Reusable knowledge

- Generate and compare route/menu/page inventories instead of trusting a hand-written route list. The plan omitted active `/external-message-apps` and `/external-message-whitelist`; include them in feature structure, mutation tests, smoke tests, and cutover sequence. [Task 1]
- Derive DTOs and examples from `oho-backoffice/api/endpoint.js`, auth actions, and representative pages. The real contract uses `/backoffice/business`, `/backoffice/authentication-user`, `_id`, `is_disabled`, and `is_deleted`, not simplified `/businesses`, `id`, or `status`. [Task 1]
- Treat cookie migration as an explicit parity/security contract: preserve `auth_user_token`, `auth_user_id`, `auth_created_token_at`, codec, host/domain/path, SameSite/Secure, expiry, and removal attributes. Existing writes are host-only with `maxAge`; remove only on confirmed 401/403, not transient network/5xx bootstrap failures. [Task 1]
- Preserve legacy query contracts during gradual cutover. Existing menu/list links use `is_disabled`, `is_deleted`, payment values, and other parameters, so proposed `q`/`page`/`status=active|inactive` is not automatically compatible. [Task 1]
- LB path routing cannot catch Nuxt `<nuxt-link>`/`$router.push()` client-side navigation. Maintain a React/Nuxt route-ownership manifest, hard-navigate across ownership boundaries, and test both directions plus browser history. Decide Cloud Run/build-per-env versus runtime config in Phase 0 because it changes Dockerfile, nginx, CI, promotion, and rollback. [Task 1]
- Make test and parity gates executable: Vitest/RTL/Playwright, controlled staging fixtures, lint/typecheck/unit/build CI, per-route E2E for mutations/uploads/destructive actions/recovery, numeral formatting golden tests, and browser error reporting/source maps/release dashboards. Classify commented socket/window-focus/mobile/widget calls as active, dead, or intentionally removed before porting. [Task 1]

## Failures and how to do differently

- Symptom: a migration plan looks complete but misses production behavior -> generate route/menu/page and dependency usage inventories at the actual pinned SHA. [Task 1]
- Symptom: generic React examples and cutover diagrams look plausible but drift from runtime -> trace API/auth contracts and client-side navigation directly from source, then test legacy→React and React→legacy paths. [Task 1]
- Symptom: Phase 5 looks short while observation windows are 2–3 days per path -> require exact/nested LB matchers, calendar duration, IaC, rollback drills, decommission exit criteria, and browser observability before accepting the timeline. [Task 1]

# Task Group: /Users/tualek/ai-main / memory architecture, Obsidian cold memory, and caveman compression

scope: Decide whether ai-main/Codex memory, Obsidian, or caveman reduces token/context usage; use for memory-path and response-compression questions on this macOS setup.
applies_to: cwd=/Users/tualek/ai-main; reuse_rule=re-check configured vault paths and current prompt-profile docs before changing memory tooling; path availability and measured prompt sizes are time-specific.

## Task 1: Compare Obsidian memory with ai-main/Codex memory; success

### rollout_summary_files

- rollout_summaries/2026-08-11T13-56-05-3WLH-ai_main_obsidian_caveman_token_context_analysis.md (cwd=/Users/tualek/ai-main, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T20-56-05-019ff11b-e580-7052-b2d7-ee32d28d724d.jsonl, updated_at=2026-08-11T14:09:31+00:00, thread_id=019ff11b-e580-7052-b2d7-ee32d28d724d, success; installed paths and ai-main setup inspected)

### keywords

- ai-main, Obsidian, cold memory, AGENTS.md, prompt profiles, full, lean, min, /mnt/d/Obsidian Vault/AI Research/, memory/SHARED.md, knowledge/<repo>.md

## Task 2: Verify caveman behavior and select compression level; success

### rollout_summary_files

- rollout_summaries/2026-08-11T13-56-05-3WLH-ai_main_obsidian_caveman_token_context_analysis.md (cwd=/Users/tualek/ai-main, rollout_path=/Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T20-56-05-019ff11b-e580-7052-b2d7-ee32d28d724d.jsonl, updated_at=2026-08-11T14:09:31+00:00, thread_id=019ff11b-e580-7052-b2d7-ee32d28d724d, success; caveman behavior and `/caveman full` recorded)

### keywords

- caveman, /caveman full, /caveman lite, /caveman ultra, /caveman off, response compression, generated response, system prompt, conversation history

## User preferences

- when comparing memory/token options, the user wanted a practical evidence-based check of what is actually installed and whether it truly saves tokens/context -> inspect configured paths, skill files, repository structure, and prompt sizes before recommending change. [Task 1]
- when the user explicitly invoked `/caveman full` -> keep responses compressed at full level until `/caveman off`, `normal mode`, or session end. [Task 2]

## Reusable knowledge

- ai-main already has per-repo knowledge, shared cross-tool memory, `full`/`lean`/`min` prompt profiles, and guard scripts; on 2026-08-11 its Codex `AGENTS.md` measured 12,897 bytes / 1,836 words and README documented a 4,000-token ceiling for `full`. [Task 1]
- Treat Obsidian as cold memory: retrieve only relevant notes/excerpts, never load the whole vault. It adds organization and multi-AI portability more than direct token savings; duplicating it with ai-main/Codex memory creates stale/conflicting context. [Task 1]
- The configured Obsidian skill path `/mnt/d/Obsidian Vault/AI Research/` was absent on this macOS setup, so verify/mount or change that WSL-oriented path before relying on the skill. [Task 1]
- Caveman is a response-format prompt skill, not automatic context retrieval or system-prompt reduction. It can shorten generated answers and later history, but not already-loaded instructions, source code, or tool output. [Task 2]

## Failures and how to do differently

- Symptom: an installed Obsidian skill is assumed usable. Cause: its configured vault path does not exist on the current OS. Fix: filesystem-check the path before recommending or invoking it. [Task 1]
- Symptom: “65% savings” is reported as measured for this Thai workflow. Cause: it was only the skill documentation's claim. Fix: distinguish documented claims from observed token measurements. [Task 2]

# Task Group: /Users/tualek/ai-main / workspace-linking deployment and design review

scope: Read-only review and architecture decisions for registry-driven deployment of generated workspace `AGENTS.md` and aliases in the ai-main daily-driver fleet.
applies_to: cwd=/Users/tualek/ai-main; reuse_rule=use for `bin/aimain`, `workspaces.json`, deploy/link/unlink/verify/doctor changes; static review does not prove dynamic round-trip behavior.

## Task 1: Review shipped registry-driven workspace linking; deployment false-success and verification gaps found

### rollout_summary_files

- rollout_summaries/2026-07-31T17-07-42-OOQ2-ai_main_workspace_linking_review_and_design_adjudication.md (cwd=/Users/tualek/ai-main, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-07-42-019fb925-627a-7253-bc76-6715214f2a22.jsonl, updated_at=2026-07-31T17:26:31+00:00, thread_id=019fb925-627a-7253-bc76-6715214f2a22, success; static read-only review)

### keywords

- bin/aimain, config/workspaces.json, deploy_one, deploy_all, cmd_unlink, git-path info/exclude, scripts/verify.sh, install.sh, scripts/sync.sh, AGENTS.md, doctor

## Task 2: Adjudicate workspace files, tiers, and enforcement; smaller single-user architecture preferred

### rollout_summary_files

- rollout_summaries/2026-07-31T17-07-42-OOQ2-ai_main_workspace_linking_review_and_design_adjudication.md (cwd=/Users/tualek/ai-main, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-07-42-019fb925-627a-7253-bc76-6715214f2a22.jsonl, updated_at=2026-07-31T17:26:31+00:00, thread_id=019fb925-627a-7253-bc76-6715214f2a22, success; design adjudication)

### keywords

- AGENTS.md, CLAUDE.md, GEMINI.md, exact-target symlink, prompt budgets, full=3200, lean=1400, minimal=500, generic knowledge, glab PATH shim, Git hooks

## User preferences

- when reviewing ai-main, the user required “READ-ONLY” and said not to run `link`, `unlink`, `install.sh`, or `verify.sh` because they can write filesystem state -> distinguish static evidence from dynamic verification and do not run mutating commands without authorization. [Task 1]
- when the user asked for worst-first, line-referenced real-world bugs in a daily-use fleet with launchd redeploys every six hours -> prioritize silent failure, false success, data loss, rollback hazards, and false greens over cosmetic issues. [Task 1]

## Reusable knowledge

- `bin/aimain:215-224` suppresses every `deploy_one` failure with `|| true`, so `install.sh:345-351` and `scripts/sync.sh:56-58` can report successful redeployment after a workspace deployment fails. Batch deployment must aggregate errors and return nonzero. [Task 1]
- Exclude-path handling is correctly linked-worktree-aware at `bin/aimain:164`: `git -C "$ws" rev-parse --git-path info/exclude`; do not repeat the disproven `--git-dir` claim. But `cmd_unlink` never removes the five added, broad unanchored exclude entries, so link/unlink is not a clean round trip. [Task 1]
- `scripts/verify.sh:197-210` skips missing directories and warns on missing knowledge files; generated-marker-only checks can pass incomplete imports. Required registry and knowledge failures should fail verification, while optional/nonexistent paths need an explicit category. [Task 1]
- Avoid pre-deployment state mutation: `bin/aimain:229-255` records a registry entry before deployment, and `--force` can bypass the first tracked-file guard while `deploy_one` still refuses tracked `AGENTS.md`. Validate first or roll back registry changes on failure; ordinary deploy should refuse unmanaged handwritten instructions unless force is explicit. [Task 1]
- For this single-user setup, prefer a readable real `AGENTS.md` with exact-target `CLAUDE.md`/`GEMINI.md` aliases over cache-only symlinks. Keep the current marker/exact-target ownership heuristic; defer a separate state ledger until shared-worktree lifecycle needs justify it. [Task 2]
- Use prompt budgets `full=3200`, `lean=1400`, `minimal=500`; fail compilation on overrun but retain last-known-good generated output in live deployment. Keep the lightweight registry CLI/generic fallback/guards/tier compiler/stronger verification, and defer broad adapters/cache-state/task-contract layers. Plain Git hooks plus a `glab` PATH shim are sufficient for current tool use. [Task 2]

## Failures and how to do differently

- Symptom: static inspection seems green -> do not claim `verify.sh` or link/unlink passed. Dynamic validation requires a disposable workspace, and static evidence already proves incomplete unlink cleanup. [Task 1]
- Symptom: deployment fails after registry mutation -> deployment state and registry become inconsistent. Fix with atomic deployment/registry changes or rollback; make `doctor` return nonzero for attachment/alias drift, not only Git-leak status. [Task 1]

# Task Group: /Users/tualek/ohochat/backoffice-v2 / React migration architecture review
scope: Time-boxed, read-only architecture review of the migrated React admin app; use before scaling multi-person feature work, not as a legacy parity audit.
applies_to: cwd=/Users/tualek/ohochat/backoffice-v2; reuse_rule=reuse the sampling and boundary checks for this React checkout, but do not treat its snapshot findings as a current Git state and honor an explicit time-box or stated baseline results.

## Task 1: Review feature-based architecture and scale readiness; viable structure, fix boundary enforcement before multi-person development

### rollout_summary_files

- rollout_summaries/2026-08-01T15-20-59-jg2H-react_backoffice_architecture_review.md (cwd=/Users/tualek/ohochat/backoffice-v2, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T22-20-59-019fbdea-0a3f-7ed2-a3b3-fddd0046094f.jsonl, updated_at=2026-08-01T15:23:11+00:00, thread_id=019fbdea-0a3f-7ed2-a3b3-fddd0046094f, time-boxed sample; fix-then-ship)

### keywords

- backoffice-v2, react-migration, feature-based, ChannelTable, PaymentDialog, query-keys, shared/lib, shared/utils, barrels, circular-dependency, eslint.config.js

## User preferences

- when the user says “TIME-BOX ... อย่า audit ทุกไฟล์” and “ตอบ 5 ข้อ สั้นๆ ตรงประเด็น ห้ามเขียนยาว” -> use targeted sampling, preserve the five requested answers, and do not rerun stated baseline checks unless needed to answer the review. [Task 1]
- when legacy is reference only for design parity while backend/URL contracts “ห้ามเปลี่ยน” and old quirks may change only if recorded -> separate architectural findings from parity/contract assumptions. [Task 1]

## Reusable knowledge

- The feature-based structure is suitable for this admin CRUD app: routes are thin, pages use hooks, API I/O is separate, and pure domain logic lives in `lib`; it does not need a folder-level rewrite. [Task 1]
- Convention is clear: `shared/lib` is I/O/external-bound code, `shared/utils` is pure functions, and features use `lib/` rather than a second `utils/` directory. [Task 1]
- Sampled boundary violations: `ChannelTable.tsx:123-133` and `PaymentDialog.tsx:131-151` call `useQuery`/raw APIs from render components. Before the team scales, move that I/O into hooks, choose one query-key-factory location, reduce 258/232-line public barrels, and add CI checks for cycles plus relative cross-feature imports. [Task 1]
- Alias-path ESLint rules enforce barrel imports but miss `../../other-feature/...`; `business` composes JERA, payment, and sales-order, so reverse imports are a practical circular-dependency risk. [Task 1]

## Failures and how to do differently

- Symptom: layer enforcement looks complete because the folder layout and ESLint exist. Cause: the rules miss relative cross-feature imports and components can still import feature API directly. Fix/pivot: sample actual call paths and search components for direct `features/*/api` use before approving scale readiness. [Task 1]
- Symptom: Git status/log is used as architecture-review proof in this snapshot. Cause: the cwd is not a Git repository. Fix/pivot: rely on sampled source evidence and disclose that stated test/lint/typecheck/format/build results (696 tests) were not rerun within the time-box. [Task 1]

# Task Group: /Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing / JERA login feature-flag read-only review
scope: Read-only review of the uncommitted JERA login Remote Config feature-flag diff, including comments-only scope checks, cold-start semantics, Feathers hook behavior, and targeted Node 20 Jest validation.
applies_to: cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing; reuse_rule=reuse the review protocol for similar `oho-api` JERA login feature-flag changes, but treat the verified implementation, diff hash, test counts, and branch state as checkout-specific and re-inspect the live tracked and untracked diff.

## Task 1: Review comments-only cleanup then final JERA login feature-flag diff; final verdict no ship-blocking issues

### rollout_summary_files

- rollout_summaries/2026-07-30T09-25-01-qjNc-final_read_only_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-25-02-019fb257-6da8-7681-aa63-4c62263ee116.jsonl, updated_at=2026-07-30T09:33:14+00:00, thread_id=019fb257-6da8-7681-aa63-4c62263ee116, final live-diff review: 2 suites / 14 tests passed; no ship blockers)
- rollout_summaries/2026-07-30T09-13-25-kdFe-review_comment_cleanup_jera_tab.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-25-019fb24c-cc6f-7c03-b144-34394eac4620.jsonl, updated_at=2026-07-30T09:22:45+00:00, thread_id=019fb24c-cc6f-7c03-b144-34394eac4620, earlier review found comments-only scope drift and worktree movement)
- rollout_summaries/2026-07-30T09-05-06-mY16-oho_api_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-06-019fb245-30e8-7533-a6c3-ba67f1a607a4.jsonl, updated_at=2026-07-30T09:14:18+00:00, thread_id=019fb245-30e8-7533-a6c3-ba67f1a607a4, earlier live review: cold-start P1 was closed; 13 targeted tests passed)
- rollout_summaries/2026-07-30T08-42-56-lECv-oho_api_jera_login_feature_flags_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-42-56-019fb230-e359-7f60-893d-3467569eb66b.jsonl, updated_at=2026-07-30T08:50:25+00:00, thread_id=019fb230-e359-7f60-893d-3467569eb66b, initial review found the cold-start authoritative-false blocker later fixed)

### keywords

- JERA, git diff, read-only-review, comments-only, firebase-remote-config, getLoginFeatureFlags, configLoaded, cold-start, TTL-boundary, addFeatureFlagsToResult, Feathers-hooks, isJeraFeatureEnabled, Jest, Node-20, EPERM, worktree-drift

## Task 2: Cross-repo JERA tab race-fix review; API hook wiring and fail-soft behavior initially blocked ship

### rollout_summary_files

- rollout_summaries/2026-07-30T06-47-30-iE0E-cross_repo_jera_tab_fix_review_ship_blockers.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T13-47-30-019fb1c7-36c8-7a02-92cc-6ab6c74fcc58.jsonl, updated_at=2026-07-30T06:56:14+00:00, thread_id=019fb1c7-36c8-7a02-92cc-6ab6c74fcc58, earlier live diff; API blockers were later fixed)

### keywords

- JERA, MaxPanel, feature_flags, Firebase Remote Config, service.hooks(hooks), addFeatureFlagsToResult, Promise.all, contact_id, immediate, Vuex, EPERM

## User preferences

- when the user says “Review-only (do not edit files, read-only)” or requires removal of any temporary symlink -> do not edit, stage, commit, or leave filesystem artifacts; confirm final `git status`. [Task 1]
- when the user says to run `git diff` yourself and not trust a prior-round summary -> independently inspect the live tracked and untracked diff, line-numbered final files, whole-repo dead references, and every claimed fix; pin final status/diff when the worktree is active. [Task 1]
- when the user asks for an explicit verdict, exact `file:line` evidence, and real pass/fail counts -> lead with ship blockers or `NONE FOUND`, keep numbered answers concise, and separate non-blocking nits and environment limits from code failures. [Task 1]
- when the user asks whether removed `e70f8a8a` contact-change refetch behavior was reintroduced -> trace the current watcher/call paths, not merely matching text; judge each watcher test by whether reverting production code would still pass. [Task 2]

## Reusable knowledge

- For the JERA login contract, presence of `feature_flags` is authoritative client-side. A cold start or Remote Config outage must omit unloaded keys, not return confidently false values: failed fetch leaves `cachedTemplate` null, `getBooleanWithState()` returns `configLoaded: false`, and `getLoginFeatureFlags()` excludes those entries. [Task 1]
- `getLoginFeatureFlags()` evaluates the four flags as `[key, usesBusinessSignal]` pairs and reuses the same key for Remote Config evaluation and returned object names (`src/firebase-remote-config.js:147-175`). `addFeatureFlagsToResult` is auxiliary/fail-soft: it catches/logs Remote Config errors, leaves `feature_flags` unset, and returns the login context. [Task 1]
- Independent `Date.now()` calls in `getCachedServerTemplate()` can straddle a TTL boundary; partial `configLoaded` output is possible. The regression test must control the relevant calls rather than assert all checks always resolve together. [Task 1]
- The final review found zero `isJeraFeatureEnabled` references; the hook module exports only Feathers lifecycle keys. Under Node `v20.20.2`, both targeted specs passed: 2 suites, 14 tests, 0 failures; `git diff --check` was clean. [Task 1]
- `service.hooks(hooks)` treats every enumerable top-level export as a hook namespace. A helper such as `addFeatureFlagsToResult` exported alongside `before/after/error` makes Feathers reject service registration; test the registration path, not just a directly imported helper. Feature-flag enrichment is auxiliary: per-flag rejection must fail soft rather than let `Promise.all` abort login. [Task 2]
- MaxPanel's reactive `immediate: true` flag watcher covers initial and late `false → true`; focus retry should require flag enabled, no active fetch, and prior error. Direct watcher-handler tests cover branches but not Vuex reactivity, visibility propagation, or concurrent triggers. [Task 2]

## Failures and how to do differently

- Symptom: a requested comments-only cleanup appears behaviorally equivalent. Cause: executable tuple/consumer changes or test behavior were bundled with comment edits. Fix/pivot: compare normalized code/AST as well as prose, flag executable scope drift, then stabilize the worktree and retest the exact final snapshot. [Task 1]
- Symptom: a TTL comment says all four checks “always resolve configLoaded together.” Cause: independent clock reads can cross the TTL boundary. Fix/pivot: retain partial-loading semantics and test them deterministically; use named timing constants and avoid depending on private array order. [Task 1]
- Symptom: Jest fails with `EPERM` before tests execute. Cause: the restricted sandbox blocks haste/transform cache writes. Fix/pivot: report an environment limitation rather than a code failure; use a narrowly isolated cache-write workaround only when necessary and disclose it. [Task 1]
- Symptom: server cold-start default false becomes API-authoritative and browser true is later filtered out. Cause: overwrite protection also suppresses recovery. Fix/pivot: omit unloaded flags rather than asserting false; verify both precedence and transient-failure recovery. [Task 2]

# Task Group: /Users/tualek/ohochat/oho-backoffice / Nuxt-to-React migration-plan review
scope: Evidence-first, read-only review of the Backoffice React v2 plan; use to verify parity, inventory, URL/state, navigation cutover, and execution-contract claims before migration work.
applies_to: cwd=/Users/tualek/ohochat/oho-backoffice with plan=/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md; reuse_rule=reuse the review checklist for revisions of this plan, but pin the live SHA and respect any explicit time/file limits before expanding the audit.

## Task 1: Round-2 audit of the revised plan; evidence gathering found stale inventory and unresolved contracts but did not complete the required verdict

### rollout_summary_files

- rollout_summaries/2026-07-31T17-56-21-UeF9-round_2_react_migration_plan_review_partial.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-56-21-019fb951-ea5f-7483-bc82-456377b2d2df.jsonl, updated_at=2026-07-31T18:07:44+00:00, thread_id=019fb951-ea5f-7483-bc82-456377b2d2df, incomplete requested 18-item audit)

### keywords

- react-migration, Nuxt2, React 19, sha-mismatch, 2f01fc94, 27d67415, active-menu, Zod passthrough, TanStack Router, MIGRATED_PATHS, Element UI, v-clipboard

## Task 2: Time-boxed plan review; no Phase 0 blocker, but resolve state/navigation, observability, and cutover contradictions before implementation

### rollout_summary_files

- rollout_summaries/2026-07-31T18-36-00-Lk1s-backoffice_react_v2_plan_time_boxed_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T01-36-00-019fb976-370c-7e03-b35f-7520e84e70a2.jsonl, updated_at=2026-07-31T18:37:38+00:00, thread_id=019fb976-370c-7e03-b35f-7520e84e70a2, scoped five-file review; NEEDS-FIX before implementation)

### keywords

- shadcn, Radix, visual parity, bizActiveTab, /business/$id?tab=API, Sentry, GCP Error Reporting, raw location.search, refetchOnWindowFocus, cutover

## Task 3: Round-2 revised-plan audit found a material baseline mismatch, unowned shared state, and omitted contracts; rollout ended without a verdict

### rollout_summary_files

- rollout_summaries/2026-07-31T17-45-44-dIut-round_2_backoffice_react_migration_plan_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-45-44-019fb948-34df-78c3-acf3-404943218769.jsonl, updated_at=2026-07-31T17:55:34+00:00, thread_id=019fb948-34df-78c3-acf3-404943218769, incomplete adversarial review; not an approval)

### keywords

- react-migration, 2f01fc94, v1.62.0, 27d6741, external-message-apps, store/modules/dashboard.js, x-jera-api-key, query-string serialization, jquery, export-to-csv

## User preferences

- when the user requires “SHA check result first,” all 18 pass/fail fixes, labeled scrutiny answers a-e, and a final verdict -> follow that exact order and finish synthesis; do not stop after evidence collection. [Task 1]
- when the user says “อ่านเฉพาะไฟล์ ... ห้าม re-audit repo ... ทั้งหมด” with an 8-minute limit -> honor the narrow scope, answer five numbered points concisely, and state `APPROVE`/`NEEDS-FIX`. [Task 2]
- when React migration is locked and “visual parity” plus a settled stack are non-negotiable -> test compliance and unresolved contracts rather than reopening the strategic choice. [Task 1][Task 2]
- when the user explicitly required a read-only review, full plan reading first, source-grounded `file:line` evidence, scrutiny answers, and a plain final verdict -> keep the review read-only, distinguish claims from verification, and put the verdict at both top and bottom. [Task 3]

## Reusable knowledge

- Pin the SHA before treating a plan inventory as verified: the live `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1` differed from the plan's `27d674...` baseline; live inventory was 35 components, not 34, and `v-clipboard` was stale because callers use `navigator.clipboard.writeText`. [Task 1]
- Raw query-string active-menu matching is not automatically preserved by Zod passthrough/TanStack Router normalization. Either retain raw `location.search` (removing only `page`) for legacy matching or use canonical order-independent comparison, with reordered/unknown-key tests. [Task 1][Task 2]
- `MIGRATED_PATHS` must cover every internal link and programmatic navigation, including child-path flips. Endpoint constants are not a request-contract inventory; audit method + path + query + body at call sites. [Task 1]
- shadcn copy-in source/Radix primitives can support visual parity, but Element UI's tables, date range/sidebar, upload, select, dialog, pagination, and loading behavior need bespoke wrappers plus screenshot/interaction gates. The 15–25 engineer-day design estimate was an unvalidated review estimate, not measured evidence. [Task 1][Task 2]
- Resolve the direct contracts before implementation: `bizActiveTab` URL contradiction, Sentry versus GCP Error Reporting, incomplete/dynamic navigation inventory, cookie/restricted-role/GCP validation, and the unsettled query refetch behavior. [Task 1][Task 2]
- The `27d6741` baseline predates the two external-message pages: regenerate the plan inventory at live `2f01fc94`/`v1.62.0` instead of accepting “12 routes verified @ baseline.” Current source had 12 page routes and 35 Vue components. [Task 3]
- State ownership is not settled while `store/modules/dashboard.js` values (`time_period`, `channels`, `checked_channels`) and cross-route `business`, `partners`, and `api_keys` caches have no final homes. Include `/external-message-apps` mutations and JERA full-sync POST with `x-jera-api-key` in the contract/E2E inventory. [Task 3]
- Element theme CSS is about 500 KB; shadcn/Radix visual parity is a substantive design-system effort. Treat the 2–4 engineer-week core re-skin estimate as approximate and make staffing/parallelism plus a design-system contingency explicit. [Task 3]

## Failures and how to do differently

- Symptom: a detailed review has strong findings but no usable decision. Cause: time was consumed collecting evidence and the requested pass/fail list, scrutiny answers, and verdict were not synthesized. Fix/pivot: reserve time for the exact deliverable and distinguish bounded review from a full audit. [Task 1]
- Symptom: an external recommendation or effort estimate is treated as a repository fact. Cause: exploratory research/proposal replaced source evidence. Fix/pivot: cite plan section plus live file:line for acceptance claims and label estimates approximate. [Task 1][Task 2]
- Symptom: a revision changelog or baseline claim is accepted as verification. Cause: live SHA/tree, imports, state consumers, and network calls were not compared. Fix/pivot: verify each against source; reserve enough time for the requested claim table and final APPROVE/rejection verdict. [Task 3]

# Task Group: /Users/tualek/ohochat/oho-web-app / Firebase Remote Config multi-tab and session-cache review
scope: Read-only design and live-diff review of web Firebase Remote Config business flags, shared SDK storage, session-cache isolation, and listener ordering; use for JERA/browser flag authority or per-tab cache changes.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app and /Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing; reuse_rule=reuse the source-inspection and cache-safety rules for this SDK/version family, but re-check installed SDK behavior, the current worktree, and whether server login flags remain authoritative.

## Task 1: Analyze same-origin multi-tab Remote Config cache collision; browser fetch path was not safe to mirror from mobile

### rollout_summary_files

- rollout_summaries/2026-07-30T08-10-45-wXG9-firebase_remote_config_multitab_race_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-10-45-019fb213-6e6a-7ca2-9032-29a514b9a891.jsonl, updated_at=2026-07-30T08:16:29+00:00, thread_id=019fb213-6e6a-7ca2-9032-29a514b9a891, source-grounded multi-tab design verdict)

### keywords

- Firebase Remote Config, @firebase/remote-config@0.8.0, firebase_remote_config, IndexedDB, custom_signals, last_successful_fetch_response, minimumFetchIntervalMillis, onConfigUpdate, custom signals, multi-tab, feature_flags_api_keys, JERA

## Task 2: Iterate cache-hit signal ordering and comments-only review; final targeted browser test passed

### rollout_summary_files

- rollout_summaries/2026-07-30T09-13-04-OoVw-firebase_remote_config_comment_trimming_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-13-04-019fb24c-796b-7f70-87ac-e3cbecc0fb7e.jsonl, updated_at=2026-07-30T09:21:40+00:00, thread_id=019fb24c-796b-7f70-87ac-e3cbecc0fb7e, AST-identical comment trim; 1 suite / 9 tests passed)
- rollout_summaries/2026-07-30T09-07-45-YIjD-firebase_remote_config_cache_hit_rereview.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-07-45-019fb247-9cdc-76a3-a098-2b88906c3dc1.jsonl, updated_at=2026-07-30T09:16:07+00:00, thread_id=019fb247-9cdc-76a3-a098-2b88906c3dc1, final signal-ordering review; 9 tests passed)
- rollout_summaries/2026-07-30T09-05-32-HGYT-firebase_remote_config_review_partial_jest_blocked.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T16-05-32-019fb245-9645-7471-8e1c-d06b902e573f.jsonl, updated_at=2026-07-30T09:07:28+00:00, thread_id=019fb245-9645-7471-8e1c-d06b902e573f, partial re-review superseded by the successful final run)
- rollout_summaries/2026-07-30T08-47-57-M3ng-firebase_remote_config_tab_cache_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/jera-tab-is-missing, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T15-47-57-019fb235-7d01-7910-8c06-037d382b4d1e.jsonl, updated_at=2026-07-30T08:56:35+00:00, thread_id=019fb235-7d01-7910-8c06-037d382b4d1e, earlier review found cross-tab blockers; signal-ordering fix later verified)

### keywords

- plugins/firebase-remote-config.js, sessionStorage, business_id, setCustomSignals, invocationCallOrder, onConfigUpdate, activate, degradedToSharedCache, Accepted residual risk, executable AST identical, Jest, NODE_PATH, EPERM

## User preferences

- when the user requires “Design consultation only. Do NOT modify any files” or “Review-only” -> keep the checkout strictly read-only and do not stage, commit, or leave dependency artifacts. [Task 1][Task 2]
- when the user demands every SDK claim be actual source/typings or documented-architecture reasoning, with a direct verdict in a fixed order -> inspect installed SDK paths/typings, label source versus documentation, and give the concrete recommendation rather than generic pros/cons. [Task 1]
- when the user says accepted risks are not to be re-litigated -> distinguish accepted residual risk from a regression; re-raise it only if current code worsens it or loses a mitigation. [Task 2]

## Reusable knowledge

- In installed `@firebase/remote-config@0.8.0`, IndexedDB `firebase_remote_config` records are keyed by app/name/namespace/record key, not custom-signal values. `active_config`, `last_successful_fetch_response`, and `custom_signals` are shared per app/namespace; timestamp-only freshness permits a tab for business A to use a recently evaluated business-B blob. [Task 1]
- API bootstrap is the primary authority: login supplies evaluated flags and Vuex records API keys as authoritative, filtering later browser Remote Config values via `feature_flags_api_keys`. The safer design recommendation was to remove automatic browser initialization/custom-signal/fetch/activate fallback after rollout verification, while retaining synchronous getters, E2E overrides, API bootstrap, and fail-closed defaults. [Task 1]
- Do not port Flutter's interval reset: `clearRemoteConfigCache()` sets `Duration.zero`, fetches, and never restores the initial 12-hour interval. `onConfigUpdate` exists in JS typings/runtime but uses cache age zero and still shares storage, so it does not create business isolation. [Task 1]
- For the reviewed per-tab session cache, await `setCustomSignals()` before every cache-hit return or listener registration; the final test asserts its `invocationCallOrder` before `onConfigUpdate`. `sessionStorage` is tab-scoped, but it cannot make a shared SDK response safe by itself. [Task 2]
- `fetchAndActivate()` / `activate()` are non-atomic against shared IndexedDB response writes, and SDK signal-storage failures are swallowed. Preserve the documented `degradedToSharedCache` boundary and never label a cache business-safe merely because activation returned successfully. [Task 2]
- A true comments-only check should compare executable AST/normalized code. The final cleanup had `executable AST identical=true`; inspect untracked tests with `git diff --no-index /dev/null test/plugins/firebase-remote-config.spec.js`. [Task 2]

## Failures and how to do differently

- Symptom: a cache hit or real-time callback stores wrong-business flags under the current `business_id`. Cause: listener registration/fetch used previously persisted shared custom signals, or `activate()` reread another tab's shared response. Fix/pivot: establish current signals before every listener/cache branch, treat successful fetch/activation as insufficient proof of business isolation, and prefer server-authoritative flags. [Task 1][Task 2]
- Symptom: direct Jest fails before collection with temp haste/transform `EPERM`. Cause: restricted sandbox cache/coverage writes. Fix/pivot: report infrastructure separately; when allowed, use main-checkout dependencies via `NODE_PATH` and suppress persistence only, then report the actual executed suite/test count. [Task 2]
- Symptom: a “comments-only” cleanup hides behavior changes or a requested `git diff` omits a new test. Cause: HEAD includes earlier implementation and untracked files are excluded. Fix/pivot: use AST comparison for the claimed cleanup and `git diff --no-index` for untracked files. [Task 2]

# Task Group: /Users/tualek/ohochat / unread-unresponded optimization report verification
scope: Read-only, source-first verification of an unread/unresponded performance report across `oho-api` and `oho-web-app`; use when a report proposes query, cache, socket, or Vuex optimization and every verdict must be independently line-cited.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app with /Users/tualek/ohochat/oho-api; reuse_rule=reuse the review protocol for similar cross-repo performance-report audits, but re-inspect the live files and exact revision before treating these source-only findings or proposal verdicts as current.

## Task 1: Verify unread/unresponded optimization report against live API and web code; partial claim confirmation, NO-SHIP as-is

### rollout_summary_files

- rollout_summaries/2026-07-29T11-58-23-dnwJ-unread_unresponded_report_verification_request.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-58-23-019fadbd-7acb-76b2-8d60-108475540831.jsonl, updated_at=2026-07-29T11:58:28+00:00, thread_id=019fadbd-7acb-76b2-8d60-108475540831, request only; no inspection results)
- rollout_summaries/2026-07-29T11-59-38-K1iF-unread_unresponded_optimization_report_verification.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/29/rollout-2026-07-29T18-59-38-019fadbe-9f4b-7e81-955d-a4ab24c396a9.jsonl, updated_at=2026-07-29T12:13:38+00:00, thread_id=019fadbe-9f4b-7e81-955d-a4ab24c396a9, source-only verification; final NO-SHIP as-is)

### keywords

- unread-unresponded-optimize-review.md, O1-O14, countDocuments, maxTimeMS, emitChatSessionStatusUpdatedEvent, Redlock, Stream, badge-count-cache, channel-eligible-members, getContactChatById, contact_default, read-only, file:line

- Related skill: skills/oho-badge-cache-review/SKILL.md

## User preferences

- when verifying a report, the user required “Every claim you make must cite an actual file path and line number I read in this session” -> open and independently re-verify every cited source line; do not promote report assertions into facts. [Task 1]
- when the user said “Read-only review. Do not modify, stage, or commit” -> preserve repository state throughout the audit. [Task 1]
- when the user requested claim verdicts, missed findings, ranked `O1–O14` opinion, then an impact-column audit, and said “Be direct and concise” -> follow that exact output order without padding. [Task 1]

## Reusable knowledge

- The completed audit found group `countDocuments` and `$facet.metadata.$count` have no cardinality cap/cache but do have `maxTimeMS` and a 75s service timeout: say bounded-by-time, not literally unbounded. It also found `emitChatSessionStatusUpdatedEvent` performs a populated snapshot plus audience resolution before the feature-flag check, so flag-off still pays most emitter cost. [Task 1]
- Customer delivery happens before member after-hooks; clear writes/emitters precede Stream persistence inside Redlock. A clear-write error can therefore return an error after customer delivery while the message is absent from Stream. Bulk send also returns `{ok:true}` before detached platform handlers settle; both semantics blocked ship in the reviewed revision. [Task 1]
- Keep socket and fallback claims precise: Socket.IO emits once with `io.to(channelNames).emit()`, although room construction/delivery scale with eligible members; only qualifying fallback realtime events call heavyweight `getContactChatById`, which has no debounce/cancellation/in-flight coalescing. [Task 1]
- The stated API tree was effectively the target branch minus `bbe0ac735`, while the web app matched the target branch. No benchmark, explain, production cardinality, or latency telemetry was run; all findings are structural/source-only. [Task 1]

## Failures and how to do differently

- Symptom: `countDocuments` is called “unbounded,” every socket event is said to fetch, or Remote Config is said to block page open. Cause: result-cardinality, event qualification, and fire-and-forget behavior were conflated. Fix/pivot: distinguish time bounds from result caps, qualifying fallback events from in-list/stale events, and possible network activity from page-open blocking. [Task 1]
- Symptom: a proposal is approved as a quick optimization. Cause: it silently changes ordering, legacy field-absence semantics, or authoritative reconciliation. Fix/pivot: do not use raw fire-and-forget emits, a simple merged update removing `$exists`, off-list skip-fetch, or timestamp-only O12 optimization; treat O10/O14 as one Remote Config authority/refresh design. [Task 1]

# Task Group: /Users/tualek/Documents/Codex/2026-07-25/new-chat / Thai event planning and Google Docs export
scope: Create one ready-to-use Thai ceremony flow/script and export it as a native Google Docs document; use when the user wants a consolidated ceremonial program, short speaking script, and verified document import.
applies_to: cwd=/Users/tualek/Documents/Codex/2026-07-25/new-chat; reuse_rule=reuse the document-building and import verification workflow for similar Thai event documents, but treat the event sequence, royal names, file path, and document ID as task-specific.

## Task 1: จัดทำ flow และสคริปต์พิธีการ แล้วส่งออกเป็น Google Docs สำเร็จ

### rollout_summary_files

- rollout_summaries/2026-07-25T10-22-14-ZNOx-thai_event_flow_google_docs_export.md (cwd=/Users/tualek/Documents/Codex/2026-07-25/new-chat, rollout_path=/Users/tualek/.codex/sessions/2026/07/25/rollout-2026-07-25T17-22-14-019f98cc-014a-72d2-94c9-0a10127e2259.jsonl, updated_at=2026-07-25T10:38:58+00:00, thread_id=019f98cc-014a-72d2-94c9-0a10127e2259, native Google Docs import succeeded; text and 16×3 table structure were checked)

### keywords

- Thai, event-flow, ceremony-script, Google Docs, Google Drive, python-docx, google_docs_title_sanitize.py, native_google_docs, table-import, 16×3, สคริปต์พิธีการ, รวมทั้งหมดรวบเดียว

## User preferences

- เมื่อผู้ใช้ขอ “แทรกชื่อองค์ภาและพระพันปีชื่อเต็มพร้อมบทเข้าไว้อาลัย” -> งานพิธีการควรใช้พระนามเต็มและเขียนบทนำเข้าสู่ช่วงถวายความอาลัยโดยตรง. [Task 1]
- เมื่อผู้ใช้ขอ “บทพูดให้คุณแดนด้วยสั้นๆ” -> สคริปต์ของผู้กล่าวขอบคุณควรกระชับ ใช้เวลาประมาณ 1 นาที. [Task 1]
- เมื่อผู้ใช้ขอ “รวมทั้งหมดรวบเดียว” -> ส่งมอบเอกสาร/คำตอบฉบับรวมเดียวในตารางที่พร้อมใช้งาน ไม่แยกส่วนให้ผู้ใช้ประกอบเอง. [Task 1]
- เมื่อผู้ใช้ขอ “export เป็น googl docs ให้หน่อย” -> สร้าง Google Docs native ส่งลิงก์ และตรวจว่าข้อความกับตารางนำเข้าครบ. [Task 1]

## Reusable knowledge

- Workflow ที่ใช้ได้: สร้าง DOCX ด้วย `python-docx` → รัน `google_docs_title_sanitize.py` → import ผ่าน Google Drive ด้วย `upload_mode: "native_google_docs"` → ตรวจ `_get_document_text` และ `_get_document_tables`. [Task 1]
- ช่วงไว้อาลัยใน flow นี้ใช้ไฟนิ่งโทนสุภาพ ปิดเพลง งดเสียงปรบมือ; เพลงสนุกและไฟสีสันเริ่มหลังคำว่า “ณ บัดนี้”. [Task 1]
- Import ที่ยืนยันสำเร็จมี `converted:true`, `mimeType:application/vnd.google-apps.document`; ตรวจข้อความ พระนามเต็ม สคริปต์ ตารางเวลา และตาราง 16 แถว × 3 คอลัมน์แล้ว. [Task 1]

## Failures and how to do differently

- Symptom: local DOCX render ดูเหมือนตรวจแล้วแต่แสดงอักษรไทยไม่สมบูรณ์. Cause: ข้อจำกัดการ render ฟอนต์ไทยยังคงอยู่แม้เปลี่ยนฟอนต์และกำหนด `SAL_FONTPATH`. Fix/pivot: รายงาน visual QA ว่าจำกัด และอย่าอ้าง pixel-level verification หากยังไม่ได้ตรวจ glyph โดยอิสระ. [Task 1]
- Symptom: import สำเร็จแต่ถูกอ้างว่าเห็นหน้าตาใน Google Docs แล้ว. Cause: หลักฐานยืนยันได้เพียงข้อความและโครงสร้างผ่าน connector. Fix/pivot: แยก content/table verification ออกจาก visual QA โดยตรง. [Task 1]

# Task Group: /Users/tualek/ohochat / send-message and webhook source audits
scope: Read-only, source-first audit memory for outbound `oho-api` send paths and inbound `oho-webhook` receipt/worker chains; use for latency, locking, retry, duplicate, silent-drop, early-ack, or sibling-route divergence reviews.
applies_to: cwd=/Users/tualek/ohochat/oho-api + /Users/tualek/ohochat/oho-webhook; reuse_rule=reuse for similar static audits across these two repos, but pin the exact branch/SHA and retrace hooks, retries, and queue configuration before treating a finding as current.

## Task 1: Blind audit outbound sends, webhook receipt/workers, and sibling divergences; multiple latency and correctness risks found

### rollout_summary_files

- rollout_summaries/2026-07-22T15-59-56-ExfV-blind_audit_send_message_webhook_oho_api_webhook.md (cwd=/Users/tualek/ohochat/oho-webhook, rollout_path=/Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-59-56-019f8a8e-191c-7740-8373-583d8f41643f.jsonl, updated_at=2026-07-22T16:09:45+00:00, thread_id=019f8a8e-191c-7740-8373-583d8f41643f, source-only audit of outbound, receipt, worker, retry/dedup, and sibling send paths)

### keywords

- member-send-message, Facebook webhook, LINE webhook, Cloud Tasks, Redis dedup, retry-backoff, axios timeout, Stream Chat, bulk send, partner/send-message, contact-send-message, bot-send-message, inform-message, silent drop, duplicate message

## Task 2: Verify `member-send-message` locking/retries/timeouts/reference_id and early-ack redesign risks

### rollout_summary_files

- rollout_summaries/2026-07-22T15-15-41-t20F-oho_api_member_send_message_locking_retry_review.md (cwd=/Users/tualek/ohochat/oho-webhook, rollout_path=/Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-15-41-019f8a65-96f5-7a71-a99e-19040bdcad19.jsonl, updated_at=2026-07-22T15:22:38+00:00, thread_id=019f8a65-96f5-7a71-a99e-19040bdcad19, exact line-cited verification against pinned oho-api snapshot)

### keywords

- member-send-message, redlock, contact:$1:chat_session, LOCK_MS, LOCK_EXTEND_GAP_MS, retry-backoff, status 429, createAxiosApi, callWithStreamChatRetry, reference_id, early-ack, socket-reconcile

## User preferences

- when the user says `Independent BLIND audit` and `Do NOT read any *.md report/plan files` -> trace source only; do not let existing reports or plans contaminate the audit. [Task 1]
- when the user asks to `Exhaustively inventory` and `Before finalizing, grep for every awaited call` -> finish with an async-primitive completeness sweep, not a narrative-only review. [Task 1]
- when the user says `precision matters — every verdict must cite exact file:line evidence from the real code, not inference` and `Do not modify any code` -> keep the audit read-only and every verdict source-cited. [Task 2]
- when the user asks for an early-ack/socket-reconcile redesign review -> provide claim verdicts and a separate risk/mitigation section; trace correlation IDs end-to-end rather than assuming `reference_id` reaches Stream. [Task 2]
- when comparing sibling send paths, the user asked for `DIVERGENCE` and `concrete risk or benign` -> organize by route/file and emphasize sequencing/await placement over shared helper names. [Task 1]

## Reusable knowledge

- `member-send-message` takes `contact:$1:chat_session` before platform calls and releases it only in after/error hooks. Long platform or Stream work therefore occupies the same lock used by member/bot assignment, member response, and close-chat actions. [Task 1][Task 2]
- The lock is not extended every 200ms: the timer is 200ms but extension happens only near expiry (`LOCK_MS=3000`, `LOCK_EXTEND_GAP_MS=1000`). [Task 2]
- `createAxiosApi()` supplies a 60s default even when the LINE call site has no explicit timeout. `callWithStreamChatRetry()` makes six attempts with 5s/10s/20s/40s/80s delays (155s backoff); account for serial messages, not only per-message latency. [Task 1][Task 2]
- Facebook/Instagram/LINE 429 retry predicates contain dead later `else if (status === 429)` branches because the initial condition already returns false. [Task 1][Task 2]
- `reference_id` is validated and returned for API correlation but is not forwarded into the Stream payload in the reviewed snapshot. [Task 2]
- Facebook dedup is non-atomic Redis `get` then `setEx`; concurrent workers can both pass, while a retry that reuses its dedup key can be silently dropped. Facebook worker errors can become HTTP 200 to complete Cloud Tasks. [Task 1]
- `send-oho-webhook-events` is intentionally detached, 3s-timeout, observability-only work; separate it from awaited customer-visible path dependencies. [Task 1]
- Do not merge similarly named routes: `bulk` returns `{ok:true}` before all sends settle and lacks the main lock; `partner/send-message` does not re-check contact/business match; legacy `partner-send-message` only writes Stream; `contact-send-message` updates contact state before Stream and swallows Stream failures. [Task 1]

## Failures and how to do differently

- Symptom: retry behavior is inferred from helper names or a claimed 429 branch. Cause: predicate control flow makes the later 429 code unreachable. Fix/pivot: read the full predicate and calculate effective attempts, timeout, backoff, and serial accumulation. [Task 1][Task 2]
- Symptom: an early ACK or 200 response is assumed safe. Cause: queue completion, detached work, and swallowed errors have different durability/customer-visible semantics. Fix/pivot: trace ACK timing, awaits, error conversion, retry/dedup namespace, and commit order end to end. [Task 1]
- Symptom: a refactor reduces lock time by moving work to background. Cause: it may detach hard state/Stream dependencies or lose correlation/reconciliation correctness. Fix/pivot: classify each hook as hard dependency, safely backgroundable, or observability-only before changing hook order. [Task 2]
- Symptom: sibling send routes are treated as equivalent. Cause: route names and shared helpers hide different lock, validation, retry, and failure semantics. Fix/pivot: inventory each route/service and compare deltas against `member-send-message`. [Task 1]

# Task Group: /Users/tualek/ohochat/oho-backoffice / external-message admin UI review
scope: Read-only review memory for `oho-backoffice` external-message whitelist and app-catalog work, especially GitLab MR diffs, async-state/race correctness, Element UI behavior, and admin data-safety boundaries.
applies_to: cwd=/Users/tualek/ohochat/oho-backoffice; reuse_rule=reuse for similar review-only admin UI checks in this checkout, but re-check the exact worktree or MR head, framework behavior, and API contract before treating any finding as still open.

## Task 1: Review MR !32 external-message catalog/whitelist UI, two correctness blockers and two async-state risks found

### rollout_summary_files

- rollout_summaries/2026-07-20T02-21-10-WqUb-oho_backoffice_mr32_external_message_code_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/20/rollout-2026-07-20T09-21-10-019f7d53-c7cc-7ea2-9fb1-76d2f5ace193.jsonl, updated_at=2026-07-20T02:28:26+00:00, thread_id=019f7d53-c7cc-7ea2-9fb1-76d2f5ace193, GitLab MR review found late-save baseline corruption, page-reset stale rows, dialog-token drift, and debounced-search stale-response risk)

### keywords

- glab, merge request 32, code review, external-message, whitelist, pagination, request_seq, race condition, prettier, git diff --check, nuxt2, element-ui

## Task 2: Read-only UI/UX review of external-message whitelist/app catalog screens, root cause and data-safety findings

### rollout_summary_files

- rollout_summaries/2026-07-14T07-38-59-v0i2-oho_backoffice_external_message_ui_review.md (cwd=/Users/tualek/ohochat/oho-backoffice, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T14-38-59-019f5f90-99ef-79c1-9da8-c8468ab76236.jsonl, updated_at=2026-07-14T07:43:25+00:00, thread_id=019f5f90-99ef-79c1-9da8-c8468ab76236, line-cited review established Element UI arrow behavior and mock cascade/orphan risks)

### keywords

- vue2, nuxt2, element-ui, el-select, remote filterable, dropdown arrow, cascade delete, whitelist, app catalog, mock API, line-cited review

## User preferences

- when the user says `read-only, do NOT edit any files`, `Do NOT edit any files -- this is review only`, or asks `review mr นี้ให้หน่อย` -> inspect without editing, staging, committing, or drifting into implementation. [Task 1][Task 2]
- when the user requires every correctness claim to cite actual lines and wants severity-ranked findings -> report evidence-first, blocker-oriented, and omit speculative issues. [Task 1][Task 2]
- when the task is a GitLab MR review in this repo -> use the live MR metadata/diff, not a paraphrased summary, and keep the output merge-oriented with P1/P2-style findings. [Task 1]
- when the user specifies `root-cause first` and then High/Medium/Low findings with concrete suggested fixes -> preserve that severity ordering and actionable output shape. [Task 2]
- when the user asks to grep the wider repo for other `filterable remote` usages -> check wider repo usage before claiming a pattern or divergence. [Task 2]

## Reusable knowledge

- `glab mr view 32 -F json` and `glab mr diff 32` were reliable sources for `oho-backoffice` GitLab MR review, and `git diff --check` is a useful quick sanity check even when functional races remain. `prettier --check` can still catch formatting drift separately. [Task 1]
- This feature area is highly race-prone: business switching, save, page refresh, dialog open/close, and debounced search each need their own request-identity or snapshot guard. Do not treat one existing `request_seq` guard as blanket coverage. [Task 1]
- `fetchAllExternalMessageApps()` walks every page because the API wrapper only supports paginated reads. It is used for whole-catalog validation, so Save/dirty-baseline updates must be serialized against that async fetch and tied to the initiating business/request sequence. [Task 1]
- In `pages/external-message-whitelist.vue`, changing business or resetting `app_page = 1` is not sufficient by itself; the visible page-1 list must be refetched or stale rows can remain on screen. [Task 1]
- The edit flow intentionally keeps `app_id` immutable to avoid orphaning existing whitelists, which matches the earlier mock-model data-integrity warning. [Task 1][Task 2]
- Element UI `el-select` with `remote && filterable` intentionally omits the default arrow; no repo CSS override was found. The mock backend models `external_message_apps` and `business_external_app_whitelist`, cascades app deletion, and does not propagate mutable `app_id` edits to existing whitelist rows. [Task 2]

## Failures and how to do differently

- Symptom: a late whitelist save corrupts the newly selected business baseline. Cause: `saved_app_ids` from an older save overwrites `loaded_app_ids` after the user switches business. Fix/pivot: bind save completion to the business/dialog state that initiated it before mutating clean-baseline state. [Task 1]
- Symptom: the pager shows page 1 while stale rows from another page remain visible. Cause: code resets `app_page = 1` without refetching page 1 data. Fix/pivot: treat page reset as its own fetch boundary and verify the reload follows the state change. [Task 1]
- Symptom: business switching, save, or rapid page/search loading applies an older response. Cause: UI state mutations are not tied to the initiating business, dialog, or request sequence. Fix/pivot: snapshot context before the first await and discard stale completion before updating rows or clean baselines. [Task 1]
- Symptom: a missing dropdown arrow looks like a CSS bug. Cause: Element UI hides the suffix icon for `remote && filterable`. Fix/pivot: inspect component source before blaming styling. [Task 2]
- Symptom: whitelist/admin mockups appear safe because the UI has warning text. Cause: the data model still allows cascade delete and `app_id` rename orphaning. Fix/pivot: inspect the mock service/data layer, not only page copy. [Task 2]

# Task Group: /Users/tualek/ohochat / cross-repo unread-unresponded deploy-gate reviews
scope: Read-only cross-repo review memory for unread/unresponded fixes spanning `oho-api`, `oho-websocket`, and `oho-web-app`; use for deploy-gate audits, MR review follow-ups, or "is this actually fixed?" checks where write gates, realtime broadcasts, and frontend counters must align.
applies_to: cwd=/Users/tualek/ohochat; reuse_rule=reuse for similar cross-repo review-only audits across these repos, but always re-check live `git status` / `git diff` in each repo and current commit semantics before treating any finding as still open.

## Task 1: Cross-repo review of MR !1285 unread/unresponded changes, exact MR head still had websocket blocker plus frontend/backend drift risks

### rollout_summary_files

- rollout_summaries/2026-07-15T10-24-15-fwAy-mr1285_unread_unresponded_cross_repo_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T17-24-15-019f654e-423f-7483-bdd6-494aba0e6b12.jsonl, updated_at=2026-07-15T10:56:47+00:00, thread_id=019f654e-423f-7483-bdd6-494aba0e6b12, exact-MR audit rebased on prior review docs; backend clear broadcasts looked improved but websocket `message.read` and frontend state sync were still not deploy-safe)

### keywords

- cross-repo review, unread, unresponded, mr-1285, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, emitEligibilityScopedUnrespondedUpdate, message.read, businessChannel, Remote Config, optimistic-flag-count-tracker, exact file:line

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 2: Cross-repo deploy-gate review of round-2 unread/unresponded fixes, websocket looked clean but frontend and bulk-send risks remained

### rollout_summary_files

- rollout_summaries/2026-07-15T01-16-06-ttm9-cross_repo_unread_unresponded_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T08-16-06-019f6358-6a26-7531-ab13-b4360a1b5799.jsonl, updated_at=2026-07-15T01:29:28+00:00, thread_id=019f6358-6a26-7531-ab13-b4360a1b5799, round-2 deploy-gate pass verified live diffs in all three repos and found frontend pagination/rollback drift plus `oho-api` mixed-success timestamp collateral risk)

### keywords

- deploy gate, git diff, git status, unread, unresponded, bulk.class.js, getLastStreamMessageTimestamp, instagram parity, channel-eligible-members, single-flight, optimistic-flag-count-tracker, markRoomRead, last_read, pagination, Vue 2 reactivity

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 3: Cross-repo deploy-gate review of realtime badge fixes, improvements landed but security and rollback risks remained

### rollout_summary_files

- rollout_summaries/2026-07-14T18-31-25-OSyU-oho_unread_unresponded_cross_repo_deploy_gate_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T01-31-25-019f61e5-e958-75d1-ae40-e7dc4ffd3d5c.jsonl, updated_at=2026-07-14T18:42:39+00:00, thread_id=019f61e5-e958-75d1-ae40-e7dc4ffd3d5c, stricter deploy-gate pass verified real repo state first and found bulk-send timestamp, websocket cache, and frontend rollback/counter edge cases)

### keywords

- deploy gate, git diff, git status, unread, unresponded, modifiedCount, channel-eligible-members, Firebase Remote Config, feature_flags_api_keys, checked_channels, Conversation.vue, optimistic-flag-count-tracker, bulk.class.js, get-last-stream-message-timestamp

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## Task 4: Cross-repo review of MR !1285 unread/unresponded changes, websocket blocker plus frontend/backend drift risks

### rollout_summary_files

- rollout_summaries/2026-07-14T15-18-52-8PEC-mr1285_cross_repo_unread_unresponded_review.md (cwd=/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T22-18-52-019f6135-9fb1-7b72-b968-52241fd501a2.jsonl, updated_at=2026-07-14T15:35:19+00:00, thread_id=019f6135-9fb1-7b72-b968-52241fd501a2, read-only review across `oho-api`, `oho-websocket`, and `oho-web-app` found a websocket `message.read` blocker and frontend Remote Config / optimistic-counter drift risks)

### keywords

- cross-repo review, unread, unresponded, mr-1285, message.read, buildCustomerMessageUnreadPayload, buildClearUnreadUnrespondedPayload, emitEligibilityScopedUnrespondedUpdate, businessChannel, Remote Config, optimistic-flag-count-tracker, groupchat

- Related skill: skills/oho-cross-repo-unread-review/SKILL.md

## User preferences

- when the user says `Do NOT trust the summary below as fact — run git diff / git status yourself in each repo and verify every claim against the actual diff.` -> pin the real repo/worktree state first and treat summaries as suspect until the live diff matches them. [Task 2][Task 3]
- when the user says `read plan.md` / prior review docs first and `do not re-flag findings already documented as fixed there` -> rebase on prior review history and avoid duplicate findings. [Task 1][Task 4]
- when the user says `Do NOT edit, stage, commit, or run any command that mutates files or git state.` or `do not modify any files` -> keep similar cross-repo reviews strictly read-only. [Task 1][Task 2][Task 3][Task 4]
- when the user wants `structured findings report, ranked by severity` with exact `file:line` evidence and a one-line verdict -> stay compact, judgmental, and evidence-first instead of exploratory. [Task 1][Task 2][Task 3][Task 4]
- when the user asks to `cover all 3 repos` and separate findings by repo/axis -> keep repo boundaries explicit instead of collapsing backend, websocket, and frontend into one verdict. [Task 1]
- when the user asks to check Instagram shape parity or whether a new test would still fail if the fix were reverted -> inspect both platform paths independently and mentally revert the fix before trusting a new regression test. [Task 2]
- when the user asks whether a websocket or frontend port is `actually faithful` -> compare semantics and state transitions, not just line similarity. [Task 2][Task 3][Task 4]
- when the user asks for a complete flag/write/broadcast audit or to check pagination/performance implications -> trace UI mutations from socket events, authoritative fetch reconciliation, and append paths too, not just backend writes. [Task 1][Task 2][Task 3][Task 4]

## Reusable knowledge

- The durable contract across these reviews is: SET writes are flag-gated, CLEAR writes are unconditional, and realtime broadcasts are flag-gated. Use that split when auditing each repo so a correct write-path change does not hide an incorrect broadcast-path gate. [Task 1][Task 2][Task 3][Task 4]
- For this task family, the high-value trace is end to end: payload source -> guard -> DB write result -> broadcast audience/result -> frontend merge/filter logic. The reviews repeatedly found partially correct fixes that only became visible when the whole chain was traced. [Task 1][Task 2][Task 3][Task 4]
- In `oho-api`, `buildCustomerMessageUnreadPayload()` is the SET-side source of truth for `unread_by` and `is_unresponded:true`, while `buildClearUnreadUnrespondedPayload()` intentionally stays unconditional to avoid flag-toggle stuck state. [Task 1][Task 4]
- The 2026-07-15 exact-MR review verified the four newly fixed contact clear broadcast call sites (`notify`, `inform-message`, `broadcast`, `bulk`) all route into `emitContactUnrespondedStatusUpdatedEvent()` / `emitEligibilityScopedUnrespondedUpdate()`. [Task 1]
- The latest `oho-api` bulk-send review verified Facebook and Instagram reply services share the same `response.data` success / `GeneralError` failure contract, and the new mixed-success Facebook test calls `getLastStreamMessageTimestamp()` on both the merged payload and the successful-only payload. [Task 2]
- In `oho-websocket`, `message.read` is the websocket-side CLEAR site. The exact-MR audit found it still flag-gated the `$pull unread_by` clear and missed the ordering guard; the later deploy-gate pass verified a newer version moved the `$pull` first, kept `new:true` plus `.select('business_id updated_at').lean()`, and used `modifiedCount > 0` to suppress no-op broadcasts, though downstream consumers can still drop emitted `updated_at` as stale. [Task 1][Task 2][Task 3][Task 4]
- Group broadcast scoping moved from whole-business rooms toward eligible-member channels. The latest deploy-gate pass verified `channel-eligible-members.js` is now fresh-query plus single-flight dedup and fail-closed on unknown eligibility; older whole-business-room findings are still relevant when auditing earlier MR revisions. [Task 1][Task 2][Task 3][Task 4]
- The frontend guidance changed across these rollouts: the earlier cross-repo reviews found browser Remote Config could overwrite API-authenticated flags, while the later deploy-gate review validated the fix via `feature_flags_api_keys` plus `plugins/firebase-remote-config.js:52-56` making browser updates non-authoritative for API-owned keys. [Task 1][Task 3][Task 4]
- `utils/optimistic-flag-count-tracker.js` now records every increment in its Set and deletes on every decrement; round-2 fixed one known offscreen double-count path, but correctness still depends on seeding or reconciling those Sets from authoritative fetches on every full replacement and pagination append path. [Task 1][Task 2][Task 3]
- `Conversation.vue` now uses a function-local `did_decrement_unread_count` flag, which removes one rollback leak, but `markRead()` still needs its optimistic `last_read` cursor unwound on failure or retries can skip the needed unread decrement. [Task 2]

## Failures and how to do differently

- Symptom: a review inherits wrong assumptions from a written summary. Cause: the claimed fix set and the live worktree or exact MR head diverge. Fix/pivot: always inspect the actual diff in every repo before trusting summary text or prior conclusions, and be explicit about which revision was reviewed. [Task 1][Task 2][Task 3][Task 4]
- Symptom: a fix looks faithful because the ported code resembles another repo. Cause: semantic differences hide in guards, timestamps, payload fields, or audience selection. Fix/pivot: compare behavior contracts, not line similarity, especially for websocket ports and frontend consumers. [Task 1][Task 2][Task 3][Task 4]
- Symptom: websocket audience scoping gets reviewed against stale assumptions. Cause: the helper changed across rounds from whole-business rooms to channel-eligible paths, then from cache-sensitive logic to fresh-query single-flight logic. Fix/pivot: inspect the current `channel-eligible-members.js` and broadcast target before reasoning about overreach, revocation risk, or QPS/load tradeoffs. [Task 1][Task 2][Task 3][Task 4]
- Symptom: bulk-send clear logic looks fixed once it skips the all-fail case. Cause: the clear guard is correct only partially if `lastMessageTimestamp` still comes from merged payloads that include failed deliveries, or if only one platform path is regression-tested. Fix/pivot: trace the timestamp source as carefully as the boolean success guard and check Facebook/Instagram parity separately. [Task 2][Task 3]
- Symptom: unread badge drift seems resolved after a Set-based tracker patch. Cause: reconciliation may only cover full-list replacement while append pagination and `last_read` rollback paths still drift. Fix/pivot: inspect `set*List` and `add*List` mutations together, and verify failure rollback unwinds both counters and cursor state. [Task 1][Task 2][Task 3]
- Symptom: validation sounds stronger than it is because syntax checks passed. Cause: `git diff --check`, `node --check`, or wiring-only tests do not prove behavior; sandboxed read-only runs can also block Jest temp writes. Fix/pivot: report those checks as shallow confidence only and say explicitly when deeper behavioral proof could not run. [Task 1][Task 2][Task 3][Task 4]

# Task Group: /Users/tualek/ohochat/oho-api / unread-unresponded code reviews
scope: Review-only memory for `oho-api` unread/unresponded diffs, especially query composition, flag-off contract checks, service boot safety, coverage-loss judgment, and review reporting style; use when the user asks whether backend changes are okay, not when they ask for direct implementation.
applies_to: cwd=/Users/tualek/ohochat/oho-api; reuse_rule=reuse for similar code reviews in this repo or nearby search-hook work, but re-verify exact query shape, failing tests, and worktree-specific files before treating any blocker as still open.

## Task 8: Adversarial review of rev.2 unread/unresponded one-sprint refactor plan; NEEDS-CHANGES before dark state dual-write

### rollout_summary_files

- rollout_summaries/2026-07-31T08-15-01-Mjxm-rev2_unread_unresponded_refactor_plan_adversarial_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T15-15-01-019fb73d-b08e-7d42-947c-493c374ac7c0.jsonl, updated_at=2026-07-31T08:25:23+00:00, thread_id=019fb73d-b08e-7d42-947c-493c374ac7c0, production-enablement backlog and explicit Track B cut-line)

### keywords

- unread-unresponded, contact_chat_states, dark-write, dark-verify, buildCountBaseQuery, feature-flags, eligible-members, last_contact_date, OHO-1272, applyClearUnreadUnrespondedWrites, Atlas Search, production-canary, Track A, Track B

## Task 9: Audit direct one-sprint `contact_chat_states` cutover; NO-SHIP until ordering, search/count, and cross-repo writers are designed

### rollout_summary_files

- rollout_summaries/2026-07-31T07-43-22-cSLQ-no_ship_contact_chat_states_refactor_plan_audit.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-43-22-019fb720-b89a-7483-ad06-486d9c12dd1e.jsonl, updated_at=2026-07-31T07:53:55+00:00, thread_id=019fb720-b89a-7483-ad06-486d9c12dd1e, pinned `origin/develop` cross-repo audit; NO-SHIP)
- rollout_summaries/2026-07-31T07-42-00-B5iQ-read_only_review_contact_chat_states_refactor_plan.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-42-00-019fb71f-7572-71d1-b82a-670541b3921c.jsonl, updated_at=2026-07-31T07:51:34+00:00, thread_id=019fb71f-7572-71d1-b82a-670541b3921c, independent local-develop audit; NO-SHIP)

### keywords

- contact_chat_states, unread_by, is_unresponded, last_contact_date, last_active_at, Atlas Search, storedSource, buildCountBaseQuery, sale visibility, mark-read, oho-websocket, entity_type, NO-SHIP

## Task 7: Final OHO-1272 badge-cache single-flight timeout/write verification, ship in the reviewed worktree

### rollout_summary_files

- rollout_summaries/2026-07-29T17-36-04-EvVz-oho_1272_final_single_flight_timeout_verification.md (cwd=/Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge, rollout_path=/Users/tualek/.codex/sessions/2026/07/30/rollout-2026-07-30T00-36-04-019faef2-a12e-78c2-b951-01d71a1deffd.jsonl, updated_at=2026-07-29T18:06:31+00:00, thread_id=019faef2-a12e-78c2-b951-01d71a1deffd, static/spec verification plus Promise probe; VERDICT: ship)

### keywords

- oho-1272, badge-count-cache, single-flight, staggered-GET, Promise.race, Bluebird, wall-clock-timeout, expired, stale-cache-write, Jest, getOrComputeBadgeCount

- Related skill: skills/oho-badge-cache-review/SKILL.md

## Task 1: Review an 8s Redis cache for unread/unresponded badge counts, key isolation checked but stale-write/stampede risks remained

### rollout_summary_files

- rollout_summaries/2026-07-15T07-12-24-BMSu-oho_api_badge_count_redis_cache_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T14-12-24-019f649e-9cc4-7813-bcca-a102cb1b4a2a.jsonl, updated_at=2026-07-15T07:21:36+00:00, thread_id=019f649e-9cc4-7813-bcca-a102cb1b4a2a, scope/key isolation and `0` hit semantics checked; Redis late-write and miss-stampede risks remained)

### keywords

- oho-api, unread, unresponded, badge-count-cache, computeBadgeCounts, cacheService, raceCommandTimeout, Redis, offline_queue, single-flight, stampede, Bluebird, ObjectId, EPERM, Jest haste map

## Task 2: Review uncommitted `oho-api` unread/unresponded diff, one boot-time regression

### rollout_summary_files

- rollout_summaries/2026-07-15T09-05-53-eBHL-oho_api_uncommitted_review_startup_blocker_and_behavior_pres.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-05-53-019f6506-8353-7c13-9dda-4d97fcfab9ad.jsonl, updated_at=2026-07-15T09:18:31+00:00, thread_id=019f6506-8353-7c13-9dda-4d97fcfab9ad, live-diff read-only review confirmed a Feathers startup blocker while the other targeted refactors preserved behavior)

### keywords

- oho-api, unread, unresponded, read-only review, uncommitted diff, service.hooks(hooks), invalid hook type, contact-send-message, getContactSendMessagePreviewText, paginate.max, getMessagePreviewText, checkJs

## User preferences

- when the user says `do NOT modify files` or `This is a REVIEW ONLY task. Do not edit any files.` -> keep similar `oho-api` reviews strictly read-only. [Task 1][Task 2]
- when the user asks for `findings ranked by severity with file:line references` and an `overall verdict` -> provide concise, judgmental, evidence-backed output with an explicit ship/needs-fix/block recommendation. [Task 1][Task 2]
- when a final concurrency re-review asks for `ship`/`no-ship`, event-loop ordering, Promise interop, and test timing -> inspect current files and regression tests directly; prove the claimed race rather than trusting the fix description. [Task 7]
- when the user says `run git status/git diff` and `verify with actual code inspection (not assumption)` -> inspect the live repo state first, not summaries or stale worktree assumptions. [Task 2]
- when the user calls out pre-existing failing suites that must not be blamed on the diff -> separate environment/repo noise from a diff-caused regression. [Task 2]
- when the user emphasized `correctness bugs (especially cross-member cache poisoning)` -> prioritize scope isolation, member identity, and stale-data correctness before style or minor test coverage. [Task 1]
- when the user asks for an “Adversarial review round 2” with “verdict ... numbered findings with file:line evidence ... prioritized 2-week backlog with explicit cut-line” -> challenge scope aggressively, pin revisions, and finish with a hard production-enablement boundary rather than rubber-stamping a revised plan. [Task 8]
- when the user asks for `SHIP / NEEDS-CHANGES / NO-SHIP`, all eight concerns, cross-repo writers, and omitted work -> trace SET -> ordering guard -> storage -> realtime -> search/count/filter and enumerate direct writers, rather than reviewing only the proposed schema. [Task 9]

## Reusable knowledge

- `computeBadgeCounts` is called by contact chat search and group search with `countBaseQuery`, `countMemberId`, and a label. `buildCountBaseQuery()` preserves business/tab/channel/sale-visibility scope while typed unread/unresponded fields are stripped, and `unread_by: countMemberId` makes member scope part of the cache filter. [Task 1]
- `getCachedBadgeCount()` treats numeric `0` as a hit and `undefined` as a miss; the reviewed TTL is numeric Redis seconds. `src/index.js` sets `global.Promise = require('bluebird')`, so production settlement inspection differs from native Jest promises. [Task 1]
- `service.hooks(hooks)` is only safe when the hooks module exports exactly lifecycle namespaces; any extra enumerable export becomes an invalid Feathers hook type, which is why `contact-send-message.service.js` booted incorrectly while `notify.service.js` stayed safe. [Task 2]
- `config/default.json` sets `paginate.max` to `50`; the reviewed dynamic max preserved that behavior. `getMessagePreviewText()` safely ignores non-string `data.label` from `qs.parse` and falls back to `message.text` / `กดปุ่ม`; `allowJs: true` with `checkJs: false` does not typecheck JS callers. [Task 2]
- In the OHO-1272 worktree, `getOrComputeBadgeCount` synchronously registers the complete cache-read-plus-compute lifecycle before its first await. A local `expired` flag is set before timeout rejection and checked immediately before `setCachedBadgeCount`; `Promise.race(...).finally(...)` clears the timer and deletes the flight on every settlement path. This closes staggered-GET admission and late-success stale-write races. [Task 7]
- The reviewed specs cover concurrent one-read/one-compute, pending-GET joining, timeout then fresh retry, and a first computation resolving after timeout without overwriting the second flight's cached `7`. Production uses Bluebird as `global.Promise`; a focused probe confirmed native async promise assimilation and `.finally()`. [Task 7]
- `buildCountBaseQuery()` preserves tab/search filters such as status, assignment, starred, tags, and visibility after stripping pagination/meta and badge filters. A state collection containing only business/channel/spam/unread fields cannot reproduce present badge counts without a contract change or join/mirror design. [Task 8]
- Existing unread feature flags gate customer payload/eligible-member resolution, but CLEAR and mark-read stay unconditional by design. A dark write needs its own per-business kill switch, timeout/maxTimeMS, fail-soft behavior, metrics, repair path, and canary; it must not run simply because customer-facing flags are off. [Task 8]
- `last_contact_date` alone does not order cross-collection writes. Use a monotonic event timestamp/sequence plus conditional updates that reject older events; backfill must not overwrite newer live state. [Task 8]
- API-only badge endpoints do not improve performance until web stops requesting inline counts. Land/rebase OHO-1272 clear-write consolidation before Track B because the worktree overlaps current `origin/develop` in six relevant files. [Task 8]
- A direct state-collection cutover needs both `last_contact_date` (customer-message ordering) and `last_active_at` (activity ordering), explicit initialization, and conditional writes. State-first page-of-20 cannot preserve existing keyword, sale-visibility, permission, tag/assignment, and count contracts without joining/filtering before pagination or mirroring a deliberately complete state surface. [Task 9]
- Atlas Search applies typed unread filters against storedSource before lookup; `buildCountBaseQuery()` leaves contact-side filters for `countDocuments`. Group paths and `oho-api` plus `oho-websocket` mark-read writers are separate migration surfaces. Preserve the contract: SET is flag-gated, CLEAR is unconditional, broadcasts are flag-gated. [Task 9]

## Failures and how to do differently

- Symptom: a short-TTL Redis cache times out but a stale value appears later. Cause: `raceCommandTimeout()` does not cancel the command and Redis 3.x has `enable_offline_queue` on by default, so a timed-out `SETEX` may replay after reconnect. Fix/pivot: treat `timeout does not cancel command + offline queue enabled` as a serious bounded-staleness risk; distinguish it from key-isolation concerns. [Task 1]
- Symptom: cache mitigation still recreates DB load on concurrent misses. Cause: no single-flight/distributed lock around `computeBadgeCounts`. Fix/pivot: audit miss burst/stampede behavior separately from TTL and correctness. [Task 1]
- Symptom: a timeout rejects joiners but a late compute still writes stale cache state, or staggered callers each enter Redis/compute. Cause: lifecycle registration occurred after an await, or a wall-clock timeout was mistaken for cancellation. Fix/pivot: synchronously install the entire flight before Redis I/O, bound it independently of Mongo `maxTimeMS`, and gate every post-compute side effect on flight-local expiration. [Task 7]
- Symptom: cache specs look sufficient but hide boundary failures. Cause: `badge-count-cache` is mocked, so orchestration tests do not exercise serialization or Redis behavior. Fix/pivot: inspect the real helper boundary and use targeted runtime probes; `ObjectId` stringification was verified not to be the collision source. [Task 1]
- Symptom: removing a helper export looks like safe cleanup but the service fails at boot. Cause: whole-module hook registration sees an extra export as an invalid hook type. Fix/pivot: inspect `service.hooks(hooks)` bootstrap semantics before approving hook-module cleanup. [Task 2]
- Symptom: sandboxed Jest failures are misattributed to the diff. Cause: duplicate-worktree mocks and haste-map write `EPERM`; repo-wide typecheck may also contain unrelated errors. Fix/pivot: report the exact blocker and use static tracing/targeted probes rather than claim behavioral proof. [Task 1][Task 2]
- Symptom: a final review claims the full suite passed. Cause: known Node 24/config incompatibility and pre-existing TypeScript errors prevented independent Jest/tsc runs. Fix/pivot: describe the OHO-1272 result as static/spec verification plus focused Promise probe, not full-suite validation. [Task 7]
- Symptom: Track B dual-write is scheduled as a one-sprint default. Cause: no prerequisite measurement of eligible-member distribution, document/index size, or SET latency; its proposed state cannot satisfy the existing badge contract. Fix/pivot: first land OHO-1272, decide historical semantics, build dry-run-default/resumable migration tooling, verify Atlas indexes with `explain()`, then measure/canary existing storage before approving the design. [Task 8]
- Symptom: dark verification uses snapshot `diff = 0`, or Track A ships API-only. Cause: dual writes interleave/fail-soft and the web still triggers inline count work. Fix/pivot: compare normalized semantics with mismatch-age grace windows, repair and repeated scans; ship a minimal web consumer that disables inline counts or drop Track A. [Task 8]
- Symptom: the plan says writers are centralized or emitters receive the updated state. Cause: many paths use `updateOne`/discard results and emitters re-query. Fix/pivot: enumerate every direct model write and return-value contract; synchronize cross-repo mark-read, model/index, cleanup, and transaction behavior before canary. [Task 9]

# Task Group: /Users/tualek/ohochat/oho-web-app / realtime unread-unresponded badge review
scope: Read-only review memory for frontend unread/unresponded badge diffs in `oho-web-app`, especially contract checks against `oho-websocket`, Vue 2 reactivity boundaries, and merge-safety of optimistic/realtime counter updates.
applies_to: cwd=/Users/tualek/ohochat/oho-web-app; reuse_rule=reuse for similar review-only work in this checkout when a frontend badge/count diff depends on sibling backend event payloads, but re-read the current frontend diff and backend commit before reusing any conclusion.

## Task 1: Review frontend increment/decrement badge logic for realtime unread/unresponded updates, not merge-safe

### rollout_summary_files

- rollout_summaries/2026-07-14T08-22-37-rN8j-oho_web_app_unread_unresponded_realtime_badge_review.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T15-22-37-019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df.jsonl, updated_at=2026-07-14T08:33:02+00:00, thread_id=019f5fb8-8b4a-73e3-b83a-8ce3e0fba9df, review-only diff check against `oho-websocket@9141805` found sender-role and unread-state blockers)

### keywords

- code-review, smartchat, groupchat, unread_count, unresponded_count, is_read_by_me, is_unresponded, Vuex, realtime, websocket, oho-websocket@9141805, stale-event-guard, optimistic decrement, Vue 2 reactivity

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 2: Iterative adversarial review of OHO-1272 Vue 2/Vuex realtime badge fix, final re-review found four defects

### rollout_summary_files

- rollout_summaries/2026-07-24T07-49-15-1jYz-vue2_realtime_badge_recheck_four_issues.md (cwd=/Users/tualek/ohochat/oho-web-app, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T14-49-15-019f9319-959c-7630-8f42-e17b70c0d6ef.jsonl, updated_at=2026-07-24T07:53:27+00:00, thread_id=019f9319-959c-7630-8f42-e17b70c0d6ef, narrowly scoped re-review found synthetic-timestamp, pre-fetch aggregate, new-room, and stale-unresponded defects)
- rollout_summaries/2026-07-24T06-35-36-jLZD-oho_1272_realtime_badge_read_only_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-35-36-019f92d6-2878-7423-a00f-1e523deebd71.jsonl, updated_at=2026-07-24T06:40:00+00:00, thread_id=019f92d6-2878-7423-a00f-1e523deebd71, earlier narrow review found fetched-row badge overwrite and no-op dispatch distinction)
- rollout_summaries/2026-07-24T06-02-46-CTIY-realtime_badge_fix_adversarial_review_partial.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T13-02-46-019f92b8-19b7-75b3-bdd9-8d9231dfb910.jsonl, updated_at=2026-07-24T06:05:35+00:00, thread_id=019f92b8-19b7-75b3-bdd9-8d9231dfb910, partial review of the same worktree; branch mismatch and unfinished verdict limit confidence)

### keywords

- Vue2, Vuex, OHO-1272, smartchat.js, websocket.js, RoomList.vue, refreshChatRoomBadgeRealtime, handleSmartchatRealtimeUpdate, DEFAULT_UPDATE_FIELDS, optimistic-flag-count-tracker, unread_count, unresponded_count, last_contact_date, already_read_locally, triggerFilteredListRefetch, is_show_reload_chat_list_btn

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 3: Final GitLab MR !872 merge review; earlier raw-field blockers fixed and MR was mergeable

### rollout_summary_files

- rollout_summaries/2026-07-31T07-28-26-vltS-mr872_realtime_badge_final_merge_review.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-28-26-019fb713-0b24-7323-941a-c766d20f9d78.jsonl, updated_at=2026-07-31T07:56:34+00:00, thread_id=019fb713-0b24-7323-941a-c766d20f9d78, final head mergeable; 2 focused suites / 79 tests passed)

### keywords

- MR-872, 8150150f, smartchat, refreshChatRoomBadgeRealtime, DEFAULT_UPDATE_FIELDS, is_read_by_me, is_unresponded, feature-flags, open-room, markRoomRead, GitLab mergeable, websocket, Node-22, Jest

- Related skill: skills/oho-smartchat-debugging/SKILL.md

## Task 4: Second-round OHO-1272 verification; correctness fixes landed but formatting and a vacuous test required NO-SHIP

### rollout_summary_files

- rollout_summaries/2026-07-31T06-05-37-BMns-oho_1272_second_round_realtime_badge_review.md (cwd=/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T13-05-37-019fb6c7-39c5-7110-9c61-b4878f375e66.jsonl, updated_at=2026-07-31T06:35:27+00:00, thread_id=019fb6c7-39c5-7110-9c61-b4878f375e66, earlier worktree state; NO-SHIP pending formatting and meaningful visibility test)
- rollout_summaries/2026-07-31T04-16-20-SFMO-cross_repo_review_mr872_mr1291_realtime_badge_blockers.md (cwd=/Users/tualek/ohochat, rollout_path=/Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T11-16-20-019fb663-2d39-79b3-9364-4845f05664c6.jsonl, updated_at=2026-07-31T04:25:57+00:00, thread_id=019fb663-2d39-79b3-9364-4845f05664c6, earlier MR heads; !872 blocked, !1291 code-mergeable)

### keywords

- OHO-1272, MR-872, MR-1291, addRealtimeContactToList, equal-timestamp, is_unresponded, unread_count, unresponded_count, Prettier, visibility test, EPERM, oho_created_at

## User preferences

- when the user says `This is a review-only request. Do not fix anything, do not edit any files. Only report findings.` -> stay read-only and avoid proposing or applying patches unless explicitly asked. [Task 1]
- when the user says `Ground every claim in the actual diff content and the actual oho-websocket commit 9141805 content that you read yourself` -> cite exact file/line/field evidence and separate verified facts from inference. [Task 1]
- when the user wants findings grouped by severity and a one-line merge verdict -> preserve that compact review shape instead of drifting into a generic essay. [Task 1]
- when the user says `read ONLY these, do not explore the repo broadly` and asks for `yes/no verdict + file:line evidence` -> stay within the named files/line ranges, perform an adversarial defect search, and end with a compact, line-cited verdict. [Task 2]
- when the user says “Read the actual files, do not guess” and asks for “real defects, not style nits” -> inspect the live named worktree, focus on correctness, and do not substitute a summary for source evidence. [Task 2]
- when the user asks whether an MR can merge and asks for another check -> re-fetch GitLab metadata and re-review the latest exact head; use GitLab or an isolated clean worktree rather than touching a dirty main checkout. [Task 3]
- when the user requests a decisive UAT gate and test-by-test assessment -> report exact suite/test counts and causality; distinguish a direct branch test from component/integration proof and unrelated full-suite failures from changed-code failures. [Task 4]

## Reusable knowledge

- Backend commit `9141805` in `oho-websocket` emits `is_read_by_me:false` and `is_unresponded:true` on customer message events when the stale-event guard passes; `message.read` only `$pull`s `unread_by` and does not emit `is_read_by_me:true`. [Task 1]
- `store/modules/groupchat.js` already defines `unread_count` and `unresponded_count` in initial state, but `store/modules/smartchat.js` `contact_list` initial/reset shapes do not include those fields, so creating them later can hit a Vue 2 reactivity gap during reset/load windows. [Task 1]
- `components/Smartchat/Conversation.vue` already sets `room.is_unresponded = false` before decrementing in the optimistic unresponded flow, which is why that path avoids a duplicate decrement when the realtime event lands. [Task 1]
- `components/Smartchat/RoomList.vue` treats missing or legacy `is_read_by_me` as read in the list fallback, which explains the reviewed diff's asymmetry (`is_unresponded === true` vs `is_read_by_me !== false`) for already-known rows. [Task 1]
- `RoomList.room_list()` prioritizes the current-room false branch, then `state.read[my_id]` timestamp comparison, then presence of `state.read`, and only finally `is_read_by_me` fallback (`RoomList.vue:161-177`). A backend row with `state.read` therefore cannot reliably become unread merely by injecting `is_read_by_me:false`. [Task 2]
- `last_contact_date = new Date().toISOString()` is not valid realtime ordering metadata: a delayed inbound event can be newer than the local read cursor even when the real message was already read, producing false unread in `smartchat.js:730-733,836-860` and `RoomList.vue:163-165`. Use the real message timestamp/version or authoritative reconciliation. [Task 2]
- New-room aggregate transitions occur before the post-event API fetch (`smartchat.js:779,813-860` before `915-927`), so final fetched `is_read_by_me` / `is_unresponded` cannot correct the counters. Calculate deltas only after final data is known. [Task 2]
- New-room insertion can be skipped under `is_show_reload_chat_list_btn` or incomplete ascending pagination, while only active filtered lists refetch (`smartchat.js:966-994`); failed/empty fetches also leave incomplete socket-only rows (`904-931`). Queue/retry or authoritatively refetch rather than treating either path as a valid insertion. [Task 2]
- `is_unresponded:true` injection for existing rooms has no causal ordering; a stale inbound event can reassert it after a bot/member reply cleared it. Require event ordering/version metadata or authoritative reconciliation. Feature flags are independently gated, so this is shared-event handling rather than a flag-combination hole. [Task 2]
- `handleSmartchatRealtimeUpdate` finds rows by `_id` and then applies `_.pick(event_message, options.update_fields)`; `refreshChatRoomBadgeRealtime` must map `contact_id` to `_id` and pass `DEFAULT_UPDATE_FIELDS` so injected `is_unresponded` / `is_read_by_me` survive. The Set tracker makes repeated existing-room transitions idempotent, but it does not protect a later fetch merge. [Task 2]
- For a new room, `res.data[0]` can overwrite injected badge fields after counts and reconciliation Sets were already updated (`smartchat.js:927-940` in the earlier review). Preserve/reapply final badge fields, or compute both row state and aggregate transitions only after the authoritative fetch. [Task 2]
- `refreshChatRoomBadgeRealtime` spreads raw socket payloads before `handleSmartchatRealtimeUpdate` applies `DEFAULT_UPDATE_FIELDS`; feature gates must remove raw `is_unresponded` / `is_read_by_me`, not merely skip synthesized fields. For open rooms, remove `is_read_by_me` when `!is_unread_enabled || is_open_room`, because `Conversation.vue` `markRoomRead` owns open-room read state. [Task 3]
- MR !872's final reviewed state was `8150150f4fc9955cb7816288c90e511ff28a28b8` directly on `develop` `897245556ae6062ba6146996d527e212e5d334ce`: mergeable, conflict-free, zero divergence, discussions resolved; Node 22 focused smartchat/websocket suites passed 79 tests. This is snapshot-specific; no pipeline or manual QA was available. [Task 3]
- Equal-timestamp handling must strip raw `event_message.is_unresponded` after the payload spread while retaining `is_read_by_me:false` and `last_contact_date`; merely not synthesizing the field is insufficient. `addRealtimeContactToList` should synchronously dedupe, pop the capped tail, insert by sort direction, and reconcile its Set in one mutation. [Task 4]
- In the earlier !872 head, optimistic aggregate transitions preceded the authoritative fallback merge, equal timestamps were dropped by `<=` before unread injection, and concurrent missing-room fetches could blindly insert duplicates. Reconcile final fetched rows/counts, separate status freshness from message unread freshness, and single-flight/dedupe by contact. `oho_created_at` in !1291 was additive but also flowed into push payloads. [Task 4]

## Failures and how to do differently

- Symptom: the frontend diff looks symmetric but is not merge-safe. Cause: the backend `message.new` emission path in `oho-websocket@9141805` did not prove any sender-role guard, so the frontend cannot assume every emitted payload represents a customer-message increment case. Fix/pivot: verify producer-side contract fields before approving consumer-side counter logic. [Task 1]
- Symptom: unread counters still drift after local mark-read plus realtime updates. Cause: `markRoomRead()` decrements unread locally but does not synchronize `room.is_read_by_me`, so the later realtime transition logic can miss or double-handle unread state. Fix/pivot: trace optimistic local state and websocket transition state together, not as separate concerns. [Task 1]
- Symptom: counters are wrong when a room is not currently loaded. Cause: the increment path treats missing prior row state as already represented in the aggregate. Fix/pivot: require proof of previous aggregate membership before incrementing or skipping an adjustment. [Task 1]
- Symptom: a room falsely becomes unread after a delayed socket event. Cause: client `now` is substituted for the message's real timestamp and defeats the local-read comparison. Fix/pivot: preserve causal message ordering or discard/reconcile stale synthetic badge fields; do not equate synthetic time with socket ordering metadata. [Task 2]
- Symptom: aggregate counters and new-room visibility drift despite a successful fetch. Cause: deltas run before authoritative fetch, insertion can be blocked without a recovery path, and failed fetches insert incomplete data. Fix/pivot: fetch final row state before counting, and queue/retry/refetch every blocked or incomplete new-room path. [Task 2]
- Symptom: an optimized formatter wrapper says clean, or a negative visibility test passes. Cause: the wrapper is a proxy false positive, or another predicate already blocks insertion. Fix/pivot: run `./node_modules/.bin/prettier --check` directly and configure available menus (for example `['all']`) so the test actually isolates visibility. [Task 4]
- Symptom: unresponded returns after it was cleared. Cause: stale inbound events have no ordering guard. Fix/pivot: gate merges on version/order or reconcile against authoritative state. [Task 2]
- Symptom: a review is called an approval although the named branch was not checked out or the review ended before a verdict. Cause: the live worktree differed (`tk-sprint-2615/develop` rather than the requested branch) and the partial pass did not complete all six checks. Fix/pivot: verify branch/base before review and explicitly label conclusions as live-diff-only or incomplete. [Task 2]
- Symptom: disabled features or an open room receive false raw badge state even though synthetic-field gates look correct. Cause: raw socket fields were already in the spread payload; the first fix did not strip `is_read_by_me:false` for open rooms. Fix/pivot: test raw fields in optimistic and fallback paths, with flags disabled and open-room behavior, before approving. [Task 3]
- Symptom: passing focused tests are treated as full merge approval. Cause: GitLab conflicts/pipeline/manual QA were not checked. Fix/pivot: report exact MR merge metadata and disclose missing pipeline/manual QA separately from source/test evidence. [Task 3]

# Task Group: /Users/tualek/ohochat/script-oho / migrate-unread.ts correctness review
scope: Read-only correctness-review memory for `unread-unresponded/migrate-unread.ts`, especially whether `unread_by` / `is_unresponded` can be reconstructed safely, what checkpoint/cleanup guarantees actually exist, and what migration plan is honest enough to ship.
applies_to: cwd=/Users/tualek/ohochat/script-oho; reuse_rule=reuse for similar source-audit, production-readiness, or operational questions in this checkout when the user wants evidence-first analysis of `migrate-unread.ts` plus `oho-api@master`, but re-check the live file and master-branch source because line numbers, indexes, and invariants can drift.

## Task 1: Decide the final production plan, backfill `unread_by` only and leave `is_unresponded` absent

### rollout_summary_files

- rollout_summaries/2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl, updated_at=2026-07-21T10:51:30+00:00, thread_id=019f8442-2665-7082-a710-f24709dca055, final read-only pass converged to Option A and a single ordered rollout plan)

### keywords

- migrate-unread, unread_by, is_unresponded, option A, final plan, explain preflight, hint, checkpoint v3, residual IDs, fail-closed CLI, per-tenant rollout, oho-api@master

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 2: Review proposed `--mode=catchup`, exact reconstruction not safe from current live inputs

### rollout_summary_files

- rollout_summaries/2026-07-21T09-46-47-Fnuo-script_oho_catchup_adversarial_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl, updated_at=2026-07-21T09:58:39+00:00, thread_id=019f8412-1e0f-7e93-b5dd-807abd10d7d0, adversarial review rejected ship-ready exact-repair framing for catchup)

### keywords

- catchup, --mode=catchup, since watermark, classifyIsUnresponded, last_contact_date, last_active_at, Stream read state, eligible members, guardMisses, overCap, streamMissing, best effort, exact repair

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 3: Decide index and paging strategy, keep contact path minimal and fail closed on explain

### rollout_summary_files

- rollout_summaries/2026-07-21T10-39-15-ce7r-migrate_unread_final_review_option_a_no_unresponded_backfill.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T17-39-15-019f8442-2665-7082-a710-f24709dca055.jsonl, updated_at=2026-07-21T10:51:30+00:00, thread_id=019f8442-2665-7082-a710-f24709dca055, chose existing contact index plus one minimal group index with explain-based preflight)
- rollout_summaries/2026-07-21T09-46-47-Fnuo-script_oho_catchup_adversarial_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T16-46-47-019f8412-1e0f-7e93-b5dd-807abd10d7d0.jsonl, updated_at=2026-07-21T09:58:39+00:00, thread_id=019f8412-1e0f-7e93-b5dd-807abd10d7d0, earlier adversarial pass established that `_id` paging and `maxTimeMS` alone are not a scale guarantee)

### keywords

- pagedFind, _id sort, idx_business_id_v1, chat-session index, explain, hint, COLLSCAN, blocking sort, maxTimeMS, 5-6M, migration preflight

## Task 4: Adversarially verify flag ordering and migration hazards, flag-on-first refuted without write-prep gating

### rollout_summary_files

- rollout_summaries/2026-07-21T08-19-36-jN8a-unread_migration_flag_ordering_adversarial_review.md (cwd=/Users/tualek/ohochat/oho-api, rollout_path=/Users/tualek/.codex/sessions/2026/07/21/rollout-2026-07-21T15-19-37-019f83c2-4d93-7f91-b205-955f99879506.jsonl, updated_at=2026-07-21T08:28:49+00:00, thread_id=019f83c2-4d93-7f91-b205-955f99879506, adversarial source audit of 13 claims, safe ordering, missed hazards, and hardening priorities)

### keywords

- migrate-unread.ts, flag-on-first, flag || field-exists, read_by, unread_by, last_contact_date, secondaryPreferred, checkpoint, status file, analyze-business-size, monitor-migrate-unread, oho-api@master

- Related skill: skills/script-oho-migrate-unread-review/SKILL.md

## Task 6: Review checkpoint semantics versus cleanup-read-by assumptions, cleanup can trust incomplete proof

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed checkpoint membership is coarser than "Stream-verified" comments imply)

### keywords

- migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, INCLUDE_PARTIAL, runLegacyReadByReconcilePass, skippedNoChannel, partial, completed, loadCheckpoint, backfillCompleted, verified, checkpoint safety

## Task 7: Review cleanup cutoff parity, cleanup lacks the 90-day bound used elsewhere

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed cleanup query omits `last_active_at` cutoff even though backfill/reconcile apply it)

### keywords

- readByCutoffDate, DAYS, last_active_at, cleanup-read-by, runReadByToUnreadByPass, runLegacyReadByReconcilePass, resolveBusinessIds, MAX_DOCS_PER_BIZ, filter parity, HAS_LEGACY_READ_BY

## Task 8: Review crash/resume safety and totals refactor, buildTotals wiring confirmed with checkpoint caveats

### rollout_summary_files

- rollout_summaries/2026-07-14T03-59-16-pwqA-migrate_unread_checkpoint_cleanup_correctness_review.md (cwd=/Users/tualek/ohochat/script-oho, rollout_path=/Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T10-59-16-019f5ec7-6f0f-7e72-a7b6-720887ff0ac8.jsonl, updated_at=2026-07-14T04:02:56+00:00, thread_id=019f5ec7-6f0f-7e72-a7b6-720887ff0ac8, confirmed `buildTotals()` coverage and exposed non-atomic checkpoint writes)

### keywords

- CHECKPOINT_SUFFIX, STATUS_FILE, saveCheckpoint, saveStatus, buildTotals, temp-file rename, crash-safety, loadCheckpoint, processedCount, cleanup mode, resume

## User preferences

- when the user says `Design review, READ-ONLY, adversarial. Do NOT edit files. Do NOT run the migration or anything that connects to a database. Do NOT commit or switch branches.` -> keep similar migration reviews strictly non-invasive and evidence-first. [Task 2]
- when the user says `Adversarial code review, READ-ONLY` and `Do not trust the draft findings file's claims at face value` -> independently re-derive from source rather than agreeing with a draft. [Task 4]
- when the user asks for `file:line evidence` for every answer and says `If evidence is not in the repo, say "cannot verify from repo" rather than guessing` -> default to line-cited proof, and keep uncertainty explicit instead of smoothing it over. [Task 1][Task 2]
- when the user says `do not soften now — but the deliverable this time is ONE DECIDED PLAN, not another catalogue of concerns` -> converge to one choice once the source audit is complete; do not hand back an open-ended concern list. [Task 1]
- when the central question is whether it is safe to run the migration before enabling flags -> answer with a concrete protocol and test proposed mitigations such as `flag || field-exists` against actual write and read/count paths. [Task 4]
- when the user says `If you must assume, name the assumption` -> separate evidence from assumptions explicitly in migration plans and rollout advice. [Task 1]
- when the user says `Trace the actual filter/gating logic, not the comments` and asks for line citations -> treat comments as non-binding, ground every behavioral claim in source lines/snippets, and do not smooth over gaps with intent-based reasoning. [Task 6][Task 7]
- when the user asks for `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` per item or `Answer EACH question below` -> keep the review tightly structured, question-by-question, and map each verdict to exact code lines. [Task 2][Task 6]

## Reusable knowledge

- The July 2026 source audits converged on Option A: `unread_by` is reconstructible from Stream read state plus current eligible-member lookup, but historical `is_unresponded` is not reconstructible honestly from Mongo state alone, so the safe plan is to leave `is_unresponded` absent rather than infer it. [Task 1][Task 2]
- `oho-api@master:src/utils/build-customer-message-unread-payload.ts:24-38` is the SET-side source of truth: `unread_by` is only written when unread is enabled and eligible members are known, and `is_unresponded` is only written when unresponded is enabled. Several CLEAR paths remain unconditional when the field exists. [Task 1][Task 2]
- Do not call clear writes unguarded: they are flag-ungated, but reviewed clear paths still use `last_contact_date` / event timestamp ordering and field-existence guards. The larger flag-order blocker is Step 0 legacy `read_by` conversion, which can rewrite `unread_by` from stale legacy state after live writes. [Task 4]
- Safer rollout framing is write-preparation first, then public unread/unresponded reads only after the tenant backfill is proven correct. `flag || field-exists` does not solve the ordering race once fields exist, and a long-running tenant pass is not an atomic “migrate then flip within minutes” boundary. [Task 4]
- `chat_status` is not a reliable historical reply classifier, and the inbox send path advances `last_active_at` without clearing `is_unresponded`; any rollout that enables historical unresponded behavior must either accept that asymmetry or change API behavior first. [Task 1]
- The proposed catchup recomputes from current eligibility and Stream state rather than a historical event ledger. That means it can only be framed as best-effort rebaseline, not exact repair, especially when permissions changed during the window or some CLEAR paths did not move `last_contact_date` / `last_active_at`. [Task 2]
- Catchup’s current write guard checks only `_id`, `last_contact_date`, and `last_active_at`; group `is_unresponded` is not repaired there, and aggregate completion counters (`guardMisses`, `overCap`, `streamMissing`) are weaker than identity-based residual verification. [Task 2][Task 3]
- For migration execution, `pagedFind()` currently does `_id` keyset pagination without `hint()` / `explain()`. Contacts can reuse `idx_business_id_v1` for tenant-scoped `_id` scans, but group sessions need one minimal `_id`-ordered migration index, and execution should fail closed if explain shows `COLLSCAN` or blocking sort. [Task 1][Task 3]
- The CLI is already fail-closed: `.env.<env>` selection, matching `--confirm`, and explicit `--execute` are required. Production rollout should stay per-tenant, verify explain/index readiness first, then migrate and enable flags immediately after each tenant pass. [Task 1]
- Cleanup is gated by current checkpoint membership only, and the checkpoint file stores only `{ completed: [...] }`, with no durable proof about reconcile coverage, skipped unresolved channels, or whether a business was verified under the current semantic config. [Task 6][Task 8]
- `INCLUDE_PARTIAL` is opt-in only (`INCLUDE_STREAM && process.env.INCLUDE_PARTIAL === "true"`), and `runLegacyReadByReconcilePass()` only runs inside that branch. A business can still become checkpoint-complete without legacy Stream verification because `partial` means budget exhaustion only and checkpointing checks only `!isDryRun && !result.partial`. [Task 6][Task 8]
- Step 0a/0b and legacy reconcile both apply `last_active_at: { $gte: readByCutoffDate }` when a cutoff exists, but cleanup does not carry any date window. It filters only by business, current complete channel IDs, and `HAS_LEGACY_READ_BY`. [Task 7]
- Cleanup mode reads checkpoint membership only and does not itself write checkpoint/status files, so it cannot overwrite backfill state by itself. `CHECKPOINT_SUFFIX` isolates `-explicit-target`, `-gate-${GATE_FILTER}`, and default runs, but not cutoff/stream/partial semantics. `saveStatus()` uses a temp-file rename, while `saveCheckpoint()` writes directly and `loadCheckpoint()` degrades parse errors into an empty set. [Task 8]
- `buildTotals()` is the single totals builder now: both `saveStatus()` call sites use it, and no third hand-built totals literal remained. `processedCount++` happens before checkpoint eligibility is decided, so status can show business progress that has not been durably checkpointed. [Task 8]
- `secondaryPreferred` reads can make a guarded write appear not to have happened while the business is still checkpointed. Cleanup re-resolves current complete channels, analyzer coverage differs from migration (`mock_seed_key` exclusion), and monitor/report step schemas drift; treat these artifacts as separate, fallible signals. [Task 4]

## Failures and how to do differently

- Symptom: a migration plan keeps circling around heuristics for `is_unresponded`. Cause: the repo does not preserve a true historical reply ledger, and timestamp/classifier guesses overstate what can be reconstructed. Fix/pivot: leave `is_unresponded` absent and delete the migration paths rather than ship a heuristic classifier. [Task 1][Task 2]
- Symptom: a catchup proposal sounds exact because it uses current Stream read state plus guards. Cause: eligibility, timestamp changes, and CLEAR paths are not historically invertible from current live inputs. Fix/pivot: frame catchup as best effort or residual-repair only, not as ship-ready exact repair. [Task 2]
- Symptom: `maxTimeMS` or heartbeat logging is treated as proof the migration scales to 5-6M docs. Cause: timeouts and metrics are failure shields, not plan quality. Fix/pivot: inspect real index compatibility, require explain-based preflight, and fail closed on `COLLSCAN` / blocking sort. [Task 2][Task 3]
- Symptom: migration completion looks good because residual counts net to zero. Cause: aggregate counters can cancel unrelated documents and hide over-cap / skipped identities. Fix/pivot: use exact-ID residuals and retry tracking instead of numeric-only done criteria. [Task 1][Task 2][Task 3]
- Symptom: migration ordering is justified only by field decay or by “clear writes are ungated.” Cause: this ignores ordering guards, Step 0 stale legacy rewrites, live write races, and read/count exposure while a tenant is half-migrated. Fix/pivot: trace both write and read/count paths, separate write-prep from public rollout, and do not claim production facts such as index presence without an artifact. [Task 4]
- Symptom: comments say a business is "verified" or cleanup is "safe to drop". Cause: the code does not persist any proof beyond membership in `completed`. Fix/pivot: inspect what the code actually stores and what cleanup consumes before accepting safety claims. [Task 6]
- Symptom: cleanup appears to mirror backfill/reconcile scope. Cause: the file comments suggest full-population behavior, but the actual queries diverge and cleanup omits the `last_active_at` cutoff. Fix/pivot: compare query objects and cutoff propagation across every related pass. [Task 7]
- Symptom: future resume logic assumes checkpoint files are durable and config-specific. Cause: checkpoint writes are non-atomic and the suffix key omits semantic dimensions such as cutoff/stream/partial choices. Fix/pivot: treat checkpoint correctness and resume safety as separate review items, not as implied by shared file names alone. [Task 8]

# Task Group: /Users/tualek/life / monthly finance baseline from ad-hoc notes
scope: Current personal-finance baseline figures and planning rules preserved only by authoritative ad-hoc notes after rollout-backed memory was pruned.
applies_to: cwd=/Users/tualek/life; reuse_rule=reuse for monthly cash-flow planning only when the user is still using the 2026-05-12 baseline, and treat older deleted rollout-derived finance guidance as stale unless the user reconfirms it.

## Task 1: Consolidate the latest monthly finance baseline from authoritative ad-hoc notes, success

### rollout_summary_files

- extensions/ad_hoc/notes/20260512-164155-finance-utilities-tuition-baseline.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-164155-finance-utilities-tuition-baseline.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)
- extensions/ad_hoc/notes/20260512-161531-finance-expense-baseline.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-161531-finance-expense-baseline.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)
- extensions/ad_hoc/notes/20260512-162222-paynext-usage-note.md (cwd=/Users/tualek/life, rollout_path=extensions/ad_hoc/notes/20260512-162222-paynext-usage-note.md, updated_at=2026-05-12, extension=ad_hoc authoritative note only)

### keywords

- finance baseline, net salary 37950, wife monthly support, tuition saving, water electric, utilities 4500, Paynext 3300, Promise, XU credit card, food transport, monthly shortfall

## User preferences

- when planning monthly cash flow, the user confirmed `Do not include wife monthly support as income` -> keep the baseline conservative and count only the user-controlled salary cash flow. [Task 1] [ad-hoc note]
- when planning monthly cash flow, the user confirmed `Include tuition saving in the monthly plan` and `Include water/electric as a monthly expense` -> do not treat tuition or utilities as optional side notes. [Task 1] [ad-hoc note]
- when cash is tight, the user wants `Paynext 3,300/month` treated as part of the expense baseline, but also remembered as a temporary bridge for fuel, food, and 7-Eleven purchases. [Task 1] [ad-hoc note]

## Reusable knowledge

- The latest confirmed probation-pay baseline is gross `40,000` (`38,500` salary + `1,500` WFH), with deductions `850` social security plus `3%` withholding tax, for net salary estimate `37,950/month`. [Task 1] [ad-hoc note]
- The confirmed monthly expense list currently includes: rent `11,000`; Promise `4,170`; phone `1,400`; XU/credit card `10,799`; Coway `399`; LG sub `3,300`; AIA `1,510`; Thunder `600`; Shopee Pay Later `310`; Finnix `600`; TikTok paylater `2,400`; Paynext `3,300`; food/transport `9,700`; tuition saving `5,875`. [Task 1] [ad-hoc note]
- Total monthly expenses are `51,664` with tuition saving and Paynext, or `45,789` without tuition saving but still with Paynext. [Task 1] [ad-hoc note]
- Water/electric should be budgeted around `4,300-4,500`, with an upper planning cap around `5,000/month`. [Task 1] [ad-hoc note]
- With utilities plus tuition saving included, the current monthly baseline becomes `55,964-56,664`, which implies a shortfall around `18,014-18,714/month` against the `37,950` net salary baseline. [Task 1] [ad-hoc note]

## Failures and how to do differently

- Do not reuse older finance memories that excluded utilities, counted wife support as income, or used stale salary math; the surviving authoritative baseline is the 2026-05-12 ad-hoc note set. [Task 1] [ad-hoc note]
- Do not treat Paynext only as debt repayment or only as spending flexibility. In this memory set it is both a recurring `3,300/month` obligation and a short-term cash substitute when fuel or food must still be covered. [Task 1] [ad-hoc note]
- Do not present a monthly plan as balanced unless utilities and tuition saving are included explicitly; the authoritative notes say the baseline remains materially short even before any new discretionary spending. [Task 1] [ad-hoc note]
