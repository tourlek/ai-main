thread_id: 019fc66d-6db1-7253-a396-dfde3105523c
updated_at: 2026-08-05T03:30:55+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T14-01-28-019fc66d-6db1-7253-a396-dfde3105523c.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI Facebook Page onboarding runbook and ClickUp handoff completed

Rollout context: In `/Users/tualek/ohochat`, the user asked for the Facebook Page onboarding requirements needed for the Meta Business AI MVP. Work separated Meta-documented behavior, observed POC behavior, and unresolved Meta dependencies, then updated local implementation docs and ClickUp OHO-1634.

## Task 1: Create Facebook Page onboarding runbook

Outcome: success

Preference signals:
- The user asked what onboarding is necessary, so similar work should proactively cover both Oho-side automation and Page-admin Meta configuration rather than only API setup.
- The rollout explicitly avoided claiming readiness until a fresh-message E2E path `AI → Oho → AI` succeeds; future onboarding guidance should distinguish `configured` from `verified`.
- Evidence was kept source-separated: official Meta contract, observed POC, and “Pending Meta confirmation”; future reports should preserve that boundary and avoid presenting observed behavior as a universal Meta contract.

Key steps:
- Added `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md` covering Page prerequisites, Meta app setup, permissions/App Review, token issuance, webhook verification, Page subscriptions, Conversation Routing/default app, Business AI activation, thread-control tests, production acceptance criteria, rollback, and questions for Meta.
- Added explicit readiness states: `not_started`, `blocked`, `configured`, `verified`, `rolled_back`.
- Required token/permission health, webhook delivery, union-safe subscription migration, standby and send-time bot guards, Business AI confirmation, routing readiness, takeover setup, and fresh-message E2E before production enablement.
- Documented that Unified Onboarding and Business AI eligibility/status APIs lack a complete public contract, so onboarding remains interim/manual per Page.

Failures and how to do differently:
- Public/partner documentation contains conflicts around `messaging_handovers` naming, Conversation Routing compatibility, Business AI-specific take control, `ai_generated`, App IDs, and endpoint forms. Keep these as explicit Meta clarification items instead of silently choosing one contract.
- Browser/research agent timed out during portions of research, but the local onboarding document and cited sources were completed; do not infer missing research output beyond what was written and verified.

Reusable knowledge:
- Required onboarding gates include identity mapping (`business_id`, `channel_id`, `page_id`, environment), Page access token and permissions, HTTPS webhook/signature validation, required subscriptions (`messages`, `message_echoes`, `message_deliveries`, `message_reads`, `messaging_postbacks`, `messaging_referrals`, `messaging_handovers`, `standby`), Conversation Routing/default app, Business AI activation, takeover configuration, and E2E verification.
- Use `GET → union → POST → GET verify` for Page subscriptions; never replace existing fields.
- `take_thread_control` readiness depends on Conversation Routing/default-app configuration for the tested setup; provide a `send_first` human takeover fallback when silent take is unavailable.
- `pass_thread_control`/HTTP 200, Messenger banners, a single `standby` signal, or one `thread_owner` snapshot are not sufficient proof of successful return-to-AI; require a positive fresh runtime signal.
- Rollback must stop Oho outbound while retaining webhook ingestion, halt automated control calls, restore routing/default-app configuration, and only unsubscribe the app as a final approved step.

References:
- `docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md`
- `docs/meta-business-ai/04-mvp-implementation-solutions-2026-08-04.md:407` — onboarding gate
- `docs/meta-business-ai/05-mvp-implementation-task-plan-2026-08-04.md:43` — T0 onboarding task
- Official sources cited in the runbook include Messenger Platform Overview/Get Started, Conversation Routing, Messenger Webhooks, App Review, Page `subscribed_apps`, and Meta Business Agent announcement.

## Task 2: Update ClickUp OHO-1634 with onboarding artifacts

Outcome: success

Preference signals:
- The user expects external artifacts to be updated, not merely drafted locally. Future ClickUp work should verify the saved card after reload and treat repo-only changes as incomplete.

Key steps:
- Uploaded the updated `04`, updated `05`, and new `06` files to OHO-1634.
- Updated the card description to “Canonical 6 files,” added the Facebook Page onboarding gate, linked the onboarding runbook, and included T0 in the task plan.
- Removed old duplicate `04` and `05` attachments.
- Reload verification confirmed canonical content, onboarding gate, T0, MVP plan, Definition of Done, related documents, new `06`, and no old attachment IDs.
- Local and ClickUp attachment SHA-256 values matched for all three files.

Failures and how to do differently:
- The ClickUp API initially returned `Team not authorized` when given an incorrect workspace/task combination; using `task_id: "OHO-1634"` succeeded.
- Reading a long ClickUp description returned truncated content; restore/verify the full description from the source file and inspect the tail sections after reload.

Reusable knowledge:
- ClickUp task identifier that worked: `OHO-1634` (returned internal task ID `86eyce35p`).
- Final attachment verification found 10 total attachments, with the canonical new files present and old `04`/`05` IDs absent.
- The external ClickUp update is part of completion and must be rechecked after reload.

References:
- ClickUp task: `https://app.clickup.com/t/86eyce35p`
- New attachment filenames: `04-mvp-implementation-solutions-2026-08-04.md`, `05-mvp-implementation-task-plan-2026-08-04.md`, `06-facebook-page-onboarding-2026-08-05.md`
- Verified local SHA-256: `ecc49375c80d8b58009d217636853c0175c724b86cf61aaae787624908c20cb6`, `c9e661efdc9d9b17e39657de07b8a0a89801b2a6e705bd985bf08bb0c017804d`, `84e2284f82fd5e0ce0d3d23482bc9cd9328d7b2301fcddf90f2bce68def84a19`
