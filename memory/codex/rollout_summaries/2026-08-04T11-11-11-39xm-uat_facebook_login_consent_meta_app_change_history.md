thread_id: 019fcc78-6964-7c40-b51c-34e9b65b8d10
updated_at: 2026-08-04T11:26:49+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T18-11-11-019fcc78-6964-7c40-b51c-34e9b65b8d10.jsonl
cwd: /Users/tualek/ohochat

# Facebook login consent issue traced to UAT environment and Meta configuration

Rollout context: The user reported that Facebook login sends a consent request in production and staging-4 but not UAT. Investigation covered `oho-web-app`, `oho-api`, deployed Cloud Run revisions, browser OAuth behavior, and Meta documentation. No source code was changed.

## Task 1: Diagnose UAT Facebook consent difference

Outcome: partial

Preference signals:
- The user wanted the issue investigated across `prod`, `staging-4`, and `uat`, with emphasis on why only UAT differs. Future debugging should compare deployed environment contracts and runtime behavior before editing code.
- The user later clarified that UAT uses Facebook Login for Business and asked how to switch it back, indicating they value identifying configuration ownership and concrete rollback steps rather than speculative code changes.

Key steps:
- Traced the frontend flow: `components/LoginCard.vue` calls `this.$auth.loginWith("facebook")`; `plugins/fb-auth.js` uses `process.env.FACEBOOK_APP_ID` and requests `public_profile,email`; the callback posts to `/authentication-user`.
- Confirmed no consent-specific endpoint or differing Facebook auth code path exists in the searched web/API sources.
- Compared deployed runtime configuration and OAuth behavior:
  - UAT frontend bundle: Facebook App ID `1092549003000749`.
  - Production frontend bundle: App ID `388207815496149`.
  - Staging-4 OAuth flow used App ID `1121209881887696`; Cloud Run runtime metadata separately showed `906298295642485`, revealing a build-time/runtime configuration mismatch there.
- Confirmed UAT’s OAuth request was standard OAuth: no `config_id` and `is_business_login=0` were observed in the request flow, so the current web source is not invoking Facebook Login for Business directly.
- Confirmed UAT traffic was 100% on revision `web-app--uat--26a0dd06--v1-115-0`; newer revision `9d797cbb` was ready but not receiving traffic.

Failures and how to do differently:
- Browser testing could reach the Meta login page but could not validate the post-login consent request because no Facebook session was available. Treat the exact consent behavior as unverified until tested with an authenticated account or captured request.
- A staging-4 navigation initially timed out, but the tab was still at the expected login URL; use current URL/title checks after navigation timeouts instead of assuming navigation failed.

Reusable knowledge:
- Facebook App ID is baked into the Nuxt client during `npm run build`; changing only Cloud Run runtime environment variables does not update the frontend OAuth client ID. Update the environment source, rebuild, deploy, and route traffic to the new revision.
- The login source is shared across environments; environment-specific behavior is primarily controlled by `FACEBOOK_APP_ID` and Meta App settings.
- Cloud Run deploys use GitLab `DOTENV` content during Docker build via `_DOTENV`; `.gitlab-ci.yml` then only updates `NODE_ENV`/`APP_ENV` at deploy time.

References:
- `/Users/tualek/ohochat/oho-web-app/components/LoginCard.vue:259-264`
- `/Users/tualek/ohochat/oho-web-app/plugins/fb-auth.js:19-25`
- `/Users/tualek/ohochat/oho-web-app/nuxt.config.js:44-51`
- UAT traffic: `web-app--uat--26a0dd06--v1-115-0` at 100%; newer `web-app--uat--9d797cbb--v1-115-1` not routed.

## Task 2: Determine when UAT changed Facebook App ID / Business Login status

Outcome: partial

Preference signals:
- The user asked, “เช็คได้ไหมว่าถูกเปลี่ยนไปตอนไหนเพราะไม่มีให้กดเปลี่ยน” and requested read-only verification. Future agents should distinguish the date of an environment App ID change from the date of a Meta app type switch, and avoid claiming the latter without Meta audit evidence.

Key steps:
- Listed UAT Cloud Run revisions and extracted the baked `FACEBOOK_APP_ID` over time.
- Found the last revision using App ID `265344702138419` on 2026-03-06.
- Found the first revision using App ID `1092549003000749`: `web-app--uat-00082-8tn`, created 2026-03-17 16:56:06 UTC (2026-03-17 23:56 Thailand time).
- Cloud Logging identified the change as `google.cloud.run.v1.Services.ReplaceService`, performed by `rapee@oho.chat` through `cloud-console`; the revision’s image was deployed by digest and contained the new App ID.
- Meta documentation confirmed: an existing app switched to Facebook Login for Business can roll back via `Facebook Login for Business → Settings → Switch to Facebook Login` only within 30 days; newly created Business Type apps cannot switch back.
- Meta dashboard access was blocked by a login page, so the actual Meta app creation/switch audit history was not inspected.

Failures and how to do differently:
- GitLab audit API query returned 404, so the Cloud Run audit trail was the reliable source for the environment change.
- The Cloud Run replace-service request did not expose the environment variables directly, but the created revision metadata did; use revision inspection for the effective deployed value.
- Do not conclude that the Meta app was switched on 2026-03-17: that date proves when UAT began using the App ID, not when Meta Login for Business was enabled.

Reusable knowledge:
- Cloud Run revision history can establish when a frontend began using a particular baked OAuth App ID.
- Relevant commands:
  - `gcloud run revisions list --service=web-app--uat --region=asia-southeast1 ...`
  - `gcloud run revisions describe web-app--uat-00082-8tn --region=asia-southeast1 ...`
  - `gcloud logging read 'timestamp>=... AND protoPayload.resourceName:"web-app--uat"' --project=oho-platform`

References:
- First new-ID revision: `web-app--uat-00082-8tn`
- Creation time: `2026-03-17T16:56:06.462906Z`
- Creator: `rapee@oho.chat`
- Cloud Console audit event: `2026-03-17T16:56:05.742293Z`, `google.cloud.run.v1.Services.ReplaceService`
- Meta documentation: `https://developers.facebook.com/documentation/facebook-login/facebook-login-for-business`
- Final state: Meta dashboard tab left open for user authentication; investigation remained incomplete pending login and Meta activity/settings inspection.
