thread_id: 019f650a-4163-70e3-b3ce-6fa49d681272
updated_at: 2026-07-15T09:20:54+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-09-58-019f650a-4163-70e3-b3ce-6fa49d681272.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/tk-sprint-2613/oho-1018-unrespone

# Read-only review of uncommitted `oho-api` MR !1285 unread/unresponded changes found one boot-time regression plus several coverage risks.

Rollout context: The user asked for a strict read-only review of uncommitted changes on branch `feature/tk-sprint-2613/oho-1018-unrespone` in `/Users/tualek/ohochat/oho-api`, with explicit instructions to run live `git status`/`git diff` and ignore `.claude/worktrees`. They wanted a compact, findings-first report with exact `file:line` evidence, no file edits, and direct answers to specific questions about runtime regressions, hook exports, Feathers hook semantics, preview-text typing, coverage loss, and `paginate.max`.

## Task 1: Live diff review of unread/unresponded changes

Outcome: partial

Preference signals:
- The user explicitly required: “This is a READ-ONLY REVIEW. Do not edit any code or files.” -> future similar reviews should stay strictly read-only.
- The user required exact verification: “Run git status/git diff… verify with actual code inspection (not assumption)” -> future review work should start from live repo state, not summaries.
- The user wanted the final report in a tight structure: `CONFIRMED REGRESSIONS`, `RISKS / NEEDS-HUMAN-JUDGMENT`, `VERDICT ON QUALITY`, `CONCRETE SUGGESTIONS` -> future review responses should be compact, judgmental, and sectioned.
- The user asked for direct yes/no style answers about safety, regressions, and improvement quality -> future reviews should avoid hedging and keep claims anchored to evidence.

Key steps:
- Verified the live branch and diff from `/Users/tualek/ohochat/oho-api`.
- Traced `computeBadgeCounts()` callers and confirmed there are only two runtime callers, both in JWT-protected search flows that inject `business_id` before the count query.
- Checked Feathers hook registration semantics against installed `@feathersjs/commons` / `@feathersjs/feathers` code and reproduced the hook-type validation behavior via SWC/Feathers inspection.
- Inspected the `get-message-preview-text.ts` change against actual message-converter output (`qs.parse` postback payloads).
- Compared deleted specs against remaining test coverage, including model default tests and write-path hook tests.
- Verified `config/default.json` still sets `paginate.max` to 50.

Failures and how to do differently:
- The coverage side of the review is limited by the sandbox: targeted Jest could not run because the repo contains duplicate manual mocks under multiple `.claude/worktrees`, and Jest also hit a permission error writing its haste map. Future reviews in this environment should treat behavioral test execution as best-effort and report the exact environment blocker.
- Removing private hook exports is only safe when the service registration path does not pass the whole hooks namespace into Feathers; in this rollout, one service still did and boot failed. Future reviews should check service bootstrap, not just local call sites.

Reusable knowledge:
- `computeBadgeCounts()` now guards on `countBaseQuery.business_id != null`, not mere truthiness, to avoid cross-business counting on api-key paths where `buildCountBaseQuery()` can return `{}`.
- `config/default.json` sets `paginate.max` to `50`; the new dynamic max in group search resolves to the same value.
- `getMessagePreviewText()` now intentionally treats non-string `data.label` as invalid and falls back to `message.text` / generic label; the only real non-string shape comes from malformed or duplicated query-string parsing.
- `service.hooks(hooks)` is only equivalent to `{ before, after, error }` when the module exports exactly hook namespaces; any extra enumerable export becomes an invalid hook type.

References:
- `src/utils/compute-badge-counts.ts:96-102`
- `src/services/contact/chat-search/chat-search.hooks.js:40-44, 78-80, 189-205`
- `src/services/chat-session/group/search/search.hooks.js:26-44, 111-157`
- `src/services/bot-send-message/notify/notify.service.js:15`
- `src/services/contact-send-message/contact-send-message.service.js:12`
- `src/utils/get-message-preview-text.ts:19-25`
- `src/utils/get-message-preview-text.spec.ts:44-52`
- `config/default.json:6-9`

## Task 2: Coverage and regression judgment

Outcome: partial

Preference signals:
- The user asked whether deleted specs still had coverage elsewhere or whether “real test coverage was lost” -> future reviews should compare deleted assertions against concrete surviving tests, not just count files.
- The user asked for “concrete improvements only where clearly warranted” -> future responses should suggest fixes only when there is actual evidence of a gap.

Key steps:
- Matched deleted model specs against surviving schema lines and existing tests.
- Matched deleted hook specs for bot/broadcast/inform/notify/member/contact/group-member paths against surviving coverage.
- Compared `is-unresponded.spec.ts` before/after and noted it now imports the shared helper twice under different aliases, which does not prove the pipeline wiring itself.
- Ran focused searches for remaining assertions around `unread_by`, `is_unresponded`, and the preview wrapper.

Failures and how to do differently:
- Many deleted tests were not fully redundant: there is still a gap where direct write-path coverage for several hook pipelines was removed and not replaced by equivalent pipeline-level tests.
- The existing shared-helper specs prove payload shape, but they do not replace hook-registration / service-boot assertions for the concrete service files.

Reusable knowledge:
- `contact.model.js` and `chat-session.model.js` now both express an “absence contract” via `default: undefined` for `unread_by` and `is_unresponded`.
- The deleted `contact.model.spec.ts` / `chat-session.model.spec.ts` had been the only tests directly proving that absence contract via `toObject()` on new documents.
- The deleted hook specs covered distinct branches such as guarded clears, fallback-message exclusions, `$lte` ordering checks, and emitter wiring; those assertions are not all recreated elsewhere.

References:
- `src/models/contact.model.js:223-235`
- `src/models/chat-session.model.js:78-90`
- `src/services/contact/helper-hook/prepare-close-case-contact-update-data.ts:38-49, 70-87`
- `src/services/contact/close-chat/is-unresponded.spec.ts:36-40, 62-112`
- `src/services/member-send-message/bulk/bulk.class.spec.js:552-681`
- `src/services/bot-send-message/broadcast/broadcast.hooks.spec.js:502-508`
- `src/services/bot-send-message/inform-message/inform-message.hooks.spec.js:291-297`

## Task 3: Final review verdict and suggestions

Outcome: partial

Preference signals:
- The user wanted the verdict to say whether the changes are “genuine improvements” and whether the comment sweep / un-export / spec deletions are net-positive or net-negative -> future similar reviews should give an explicit quality judgment, not just findings.
- The user asked for concrete suggestions only where clearly warranted -> future advice should be surgical.

Key steps:
- Cross-checked the runtime bug, coverage gaps, and config/guard behavior against the live diff.
- Separated the one confirmed blocker from the broader quality risks.
- Kept the final report tight and evidence-based.

Failures and how to do differently:
- The report needs to distinguish “good cleanup” from “unsafe cleanup”: the comment sweep and the un-export changes mostly improve encapsulation and reduce noise, but the deletion of tests without replacement is the part that makes the overall change set not yet production-safe.

Reusable knowledge:
- The biggest actual runtime issue in the reviewed diff was not the business_id guard, max-query-limit change, or preview-text typing; it was a service boot failure caused by passing an exported helper along with hook namespaces into Feathers.
- `notify.service.js` is safe because `notify.hooks.js` exports only `before`, `after`, and `error`; `contact-send-message.service.js` is unsafe because `contact-send-message.hooks.js` still exports `getContactSendMessagePreviewText`.

References:
- `src/services/contact-send-message/contact-send-message.hooks.js:497, 523-580`
- `src/services/contact-send-message/contact-send-message.service.js:12`
- `node_modules/@feathersjs/commons/src/hooks.ts:163-167`
- `src/services/chat-session/group/search/search.hooks.js:41-44`
- `src/utils/compute-badge-counts.spec.ts:110-123`
- `src/utils/build-clear-unread-unresponded-payload.spec.ts:36-63`

Overall verdict from the rollout: one confirmed boot-time regression, otherwise the business_id guard and preview-text typing looked safe; coverage loss from deleted specs is the main quality risk, so the change set was not yet a clean net-positive until tests are restored or replaced.
