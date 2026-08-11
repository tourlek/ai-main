thread_id: 019febf6-d717-7103-a1de-872be9834c91
updated_at: 2026-08-11T03:33:02+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T20-57-30-019febf6-d717-7103-a1de-872be9834c91.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI MVP review, simplification, and follow-up correction

Rollout context: Read/review-and-edit work across `/Users/tualek/ohochat/oho-api`, `/Users/tualek/ohochat/oho-webhook`, and related web-app/docs. The user requested a detailed performance and worst-case review, initially prioritizing API/webhook and deferring web-app design. The implementation was simplified from a large runtime-state/feature-flag design to a Facebook-only minimal integration.

## Task 1: Review and reduce Meta Business AI MVP

Outcome: partial

Preference signals:

- The user asked to “recheck” existing MVP work and explicitly worried about new fields affecting performance, webhook delivery, and failure modes such as messages not arriving or performance dropping. Similar reviews should inspect the full actual runtime path, DB writes/reads, queue/dedup behavior, and worst-case failure—not only the diff.
- The user wanted API/webhook handled first while web-app waits for design. Similar planning should keep backend/webhook scope separate from UI scope.
- Prior review context indicates the user prefers Thai, detailed severity/evidence/recommendation structure, and explicit separation of verified facts, observed behavior, proposed design, and unverified evidence.

Key steps:

- The named branch resolved to the same/staging SHAs rather than a normal branch diff: `oho-api afccdd74e`, `oho-webhook c3dbadd`; reflogs showed feature commits `feat: add Meta Business AI takeover, reactivation, and handoff runtime` and `feat: observe Meta Business AI handoff and authority on facebook webhooks`.
- Reviewed the original implementation: roughly 1,739 added lines/32 files in API and 891 additions/197 deletions in webhook, including runtime state, reducers, channel/contact fields, bot guards, canonical events, and onboarding subscriptions.
- Identified major original risks: ownership direction was not reliably known; `standby`/`messaging` were easy to overinterpret; state persistence was read-modify-write without robust stale-event rejection; return-to-AI pending could leave bot sends unblocked; and broad hot-path changes could add DB/Redis/API load.
- Reworked toward a minimal design: Facebook-only, always-on backend behavior; `standby` means another app may own delivery but is not proof of Meta Business AI; customer messages are persisted before automation is suppressed; authority is stored in top-level `facebook_delivery_authority` fields with timestamp ordering; primary Mongo reads and 5-second timeout are used for safety guards; unknown/observation failure behavior is fail-closed for automation where appropriate; web-app remains deferred.
- Added/updated canonical event ordering and per-event Redis dedup leases, Facebook subscription verification including `messaging_handovers`, service-account trust checks for observation writes, separate `${businessId}@meta-ai` Stream identity with fallback, and takeover/return APIs that remain pending until webhook confirmation.
- Validated API and webhook builds, focused tests, formatting, and `git diff --check`. Full integration/E2E validation was not completed.

Failures and how to do differently:

- The initial design was over-scoped and retained competing runtime models. Prefer the minimal authority-observation contract unless product requirements explicitly need richer state/UI.
- A 300-second Redis lease has no owner token/CAS; a slow worker can race a reclaimed worker and duplicate or delete another claim. Fix before canary.
- Broadcast filtering is only a batch snapshot; authority may change before direct Graph sends. Add per-recipient send-time checks or gate campaigns.
- Real captured payload replay and terminal Mongo/Stream verification were not run. HTTP 200 and unit tests are insufficient for webhook success.
- Legacy `meta_business_ai.observed_authority` compatibility remains and needs volume measurement/backfill/expiry before removal.

Reusable knowledge:

- `oho-webhook` acks/handles webhook processing separately from terminal persistence; verify datastore and Stream state, not HTTP response alone.
- `standby` is generic “other app” evidence, not definitive Meta Business AI identity; `ai_generated` labels an echo author, not thread ownership.
- Facebook authority observation should be timestamp-conditional, use primary reads for final automated-send guards, and preserve customer-message durability even if optional observation or automation fails.
- Remaining blockers were documented in `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md` as B1–B5: real payload proof, dedup ownership token, campaign race, legacy state migration, and isolated coverage.

References:

- `/Users/tualek/ohochat/docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- `/Users/tualek/ohochat/oho-api/src/services/contact/upsert/upsert.hooks.js`
- `/Users/tualek/ohochat/oho-api/src/services/contact/meta-business-ai/shared.js`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/handler.ts`
- `/Users/tualek/ohochat/oho-webhook/src/controllers/facebook/helper.ts`
- `oho-api`: `npm run build` passed; `git diff --check` passed.
- `oho-webhook`: build and focused tests passed; canonical/integration suites had baseline Jest parser/config failures.

## Task 2: Correct claim that no feature flag remained

Outcome: fail

Preference signals:

- After the assistant said “ไม่มี feature flag แล้ว,” the user immediately challenged: “บอกว่าไม่มี feature flag แล้วทำไมยังมี ใน firebase config” -> when claiming a cross-repo removal, search every relevant repo and layer, including web-app, shared Firebase config, docs, tests, and generated/legacy worktrees; distinguish “removed from API/webhook runtime” from “removed everywhere.”
- The user expects contradictions to be acknowledged directly rather than explained away.

Key steps:

- A workspace-wide search found `rt_meta_business_ai_enabled` still present in web-app code: `oho-web-app/store/index.js`, `oho-web-app/plugins/firebase-remote-config.js`, and multiple Smartchat components that gate UI actions and badges.
- The same search found legacy documentation references, web-app utility logic, API config for `FACEBOOK_META_BUSINESS_AI_APP_ID`, takeover/return services, and compatibility state.
- Therefore, the accurate statement is: the flag was removed from the `oho-api` and `oho-webhook` backend runtime paths, but it was not removed globally; web-app still uses it and docs/legacy code still reference it.

Failures and how to do differently:

- Do not report “no feature flag” based only on backend searches. State scope precisely: “no backend RC lookup remains” versus “no repository-wide flag remains.”
- Before finalizing removal claims, run a workspace-wide search such as `rg -n -i "meta[_-]?business[_-]?ai|rt_meta_business_ai|business_ai"` excluding dependencies/generated output, then classify each hit as active runtime, UI, config, docs, test, or legacy compatibility.

Reusable knowledge:

- Active web-app flag references observed include `rt_meta_business_ai_enabled: false` in store/plugin config and checks in `Conversation.vue`, `RoomHeader.vue`, `SendMessageDisabled.vue`, and `utils/meta-business-ai.js`.
- The backend still has Meta Business AI domain code for Stream labeling and takeover/return endpoints, even though the backend Remote Config feature gate was removed.

References:

- `oho-web-app/store/index.js:52`
- `oho-web-app/plugins/firebase-remote-config.js:23`
- `oho-web-app/components/Smartchat/Conversation.vue:1000-1006,3789-3839`
- `oho-web-app/components/Smartchat/RoomHeader.vue:118-130`
- `oho-web-app/components/Smartchat/SendMessageDisabled.vue:263-273`
- Search command: `rg -n -i "meta[_-]?business[_-]?ai|rt_meta_business_ai|business_ai" . --glob '!node_modules/**' --glob '!dist/**' --glob '!coverage/**' --glob '!.claude-worktrees/**' --glob '!*.lock'`
