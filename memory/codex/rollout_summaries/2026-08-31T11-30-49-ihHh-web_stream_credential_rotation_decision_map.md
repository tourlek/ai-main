thread_id: 01a05796-1807-7993-9bd1-5d0a87e4b8cf
updated_at: 2026-08-31T11:41:48+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/31/rollout-2026-08-31T18-30-49-01a05796-1807-7993-9bd1-5d0a87e4b8cf.jsonl
cwd: /Users/tualek/ohochat

# Web app credential-rotation decision review was narrowed into a question-to-answer map

Rollout context: The user supplied seven unresolved web/mobile architecture questions, then narrowed scope to the web app and requested an easy-to-understand mapping of each question to its answer. Investigation was read-only in `/Users/tualek/ohochat`.

## Task 1: Investigate web Stream credentials, business switching, and Remote Config ordering

Outcome: success

Preference signals:

- After receiving a combined web/mobile answer, the user said “focus คำตอบของ web app พอ” -> future responses should explicitly scope the answer to web when requested, rather than continuing to cover mobile.
- The user asked “เอาคำตอบ map กับคำถามให้หน่อย” -> present architecture decisions in a direct question-to-answer table, preserving the original numbering and wording.
- The user asked for benefits “แบบเข้าใจง่าย” and checked whether the flow could use await instead of fire-and-forget -> explain async design in plain language with a short sequence diagram/flow before technical detail.
- The user accepted the use of a decision-oriented summary without creating tracker tickets; when the route is already clear and the work is consultation-only, avoid unnecessary issue/map artifacts.

Key steps:

- Inspected `plugins/firebase-remote-config.js`, `components/Smartchat/Conversation.vue`, `components/SwitchBusiness.vue`, Vuex flag mutations, and related web call sites.
- Traced the Stream client creation and business-switch route, then searched the web codebase for `tokenProvider`, `credential_version`, and `key_fingerprint`.
- Confirmed the current web implementation and separated verified current behavior from proposed future contract.

Reusable knowledge:

- Web Remote Config is client-only and deliberately fire-and-forget after hydration. `fetchAndActivate` has a 10-second timeout; awaiting the whole Nuxt plugin could block hydration and risk SSR/client mismatch. If new Stream credentials must precede client creation, await only the login/bootstrap credential flow, not Firebase Remote Config.
- Current web Stream setup uses `$config.stream_key` and `oho_member.streamToken` directly in `Conversation.vue:initStream()`. There is no `tokenProvider`, `credential_version`, or `key_fingerprint` in the web implementation.
- `Conversation.vue:handleInitStreamChat()` only calls `initStream()` when `!this.stream_client`; therefore an in-memory SPA business switch would reuse the existing client unless explicit teardown/rebuild is added.
- The current normal business-switch flow in `SwitchBusiness.vue` writes `oho_current_biz` and calls `window.location.replace('/business/{id}/smartchat?status=me')`. The full reload resets Vuex, so `stream_client` starts null and a new Stream client is created. This is true for the current reload flow, not for a future no-reload switch.
- The proposed web contract is bootstrap/login returning `stream_key`, `stream_token`, `credential_version`, and optionally `key_fingerprint`. The initial flow should be `await bootstrap/login -> receive credentials/version -> create Stream client`.
- If socket/polling announces a credential version change, web should await a fresh bootstrap, compare version/fingerprint, then have an owner outside the SDK perform `disconnectUser -> create new StreamChat client -> connectUser`. Do not expect throwing from an SDK callback to rebuild the client automatically.
- `key_fingerprint` is an optional but useful integrity signal: compare it before connecting and emit telemetry on mismatch; never log tokens or private credentials.

Failures and how to do differently:

- The first answer mixed web and mobile, requiring the user to narrow scope. Future answers should honor the requested platform immediately.
- The user had to ask again whether `credential_version` was actually answered. In future, explicitly label each original question as “current state” and “recommended contract,” especially when the current answer is “it does not exist.”
- Avoid saying the proposed contract is already implemented. The repository evidence proves only the current static key/token flow; bootstrap version/fingerprint transport remains a design recommendation.

References:

- `/Users/tualek/ohochat/oho-web-app/plugins/firebase-remote-config.js:85-89` — fire-and-forget Remote Config initialization.
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:1516-1526` — creates `StreamChat`, uses `$config.stream_key` and `oho_member.streamToken`, then stores the client.
- `/Users/tualek/ohochat/oho-web-app/components/Smartchat/Conversation.vue:1531-1547` — `if (!this.stream_client) await this.initStream()` guard.
- `/Users/tualek/ohochat/oho-web-app/components/SwitchBusiness.vue:202-216` — cookie update and `window.location.replace` business switch.
- `/Users/tualek/ohochat/oho-web-app/store/index.js:103-125` — API-authoritative feature flags prevent later browser Remote Config from overwriting API values.
- Final user-requested mapping: 01 fire-and-forget, 02 client recreation on switch, 04 token mismatch/rebuild, 05 credential version transport, 07 fingerprint recommendation.
