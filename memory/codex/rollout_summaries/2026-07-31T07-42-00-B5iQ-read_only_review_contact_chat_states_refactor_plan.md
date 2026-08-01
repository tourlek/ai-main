thread_id: 019fb71f-7572-71d1-b82a-670541b3921c
updated_at: 2026-07-31T07:51:34+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T14-42-00-019fb71f-7572-71d1-b82a-670541b3921c.jsonl
cwd: /Users/tualek/ohochat

# Read-only review rejected the one-sprint state-collection refactor

Rollout context: Audited `/Users/tualek/ohochat/oho-api` local `develop` at `fadce85370eb42828570b91edb1649b401a424a1` (behind `origin/develop` by two commits unrelated to this review), plus `oho-websocket`, `oho-cronjob`, and `oho-developer-api`. No files were modified. The requested output was a concise, line-cited verdict over eight plan claims.

## Task 1: Validate `contact_chat_states` refactor plan

Outcome: success

Preference signals:
- The user explicitly required “READ-ONLY — do not modify any files,” every finding to cite actual `file:line` evidence, and a verdict-first numbered format. Future similar reviews should preserve repository state, independently inspect code rather than trust plan claims, and report compact evidence-first findings.

Key findings:
- Verdict was `NO-SHIP`.
- The existing `$lte` race guard updates `last_contact_date` and unread state atomically on the contact/session document (`contact-send-message.hooks.js:230-239`; group equivalent `group/contact-user/send-message.class.js:25-37`). A separate state document needs its own ordering timestamp and atomic/synchronized write semantics; otherwise stale or partial writes can resurrect state.
- `last_active_at` and `last_contact_date` are distinct. `last_active_at` is independently updated by many workflows (`update-contact-last-active-at.js:12-14`, spam flow, assignments, replies, group actions), so using it as a state-collection pagination driver requires broad synchronization beyond the two central unread builders.
- Close-case writes can join the existing transaction only if the new model uses the same Mongoose connection and receives `{session}`. Existing code passes the session through `prepare-close-case-contact-update-data.ts:61-69` and both case classes.
- Realtime emitter claims are false as written. `emitChatSessionStatusUpdatedEvent` re-queries and heavily populates the contact (`emit-chat-session-event.js:47-120`); eligibility-scoped emitters also re-query source models (`:248-289`). Several write sites discard update results, so “no extra query” requires an explicit emitter redesign.
- Atlas Search keyword paths apply unread filters against stored source before `$lookup` and pagination (`chat-session/utils/search-query-converter.ts:149-195`; contact pipelines in `search-payload-original.js:123-138` and optimized pipeline `search-payload-optimized.js:317-332`). A two-step state-ID page cannot preserve keyword filtering, authorization, and correct pagination without joining/filtering before page boundaries.
- Sale visibility and channel permission are authorization filters, not optional filters. Paging states first can produce short or incorrect pages (`shared-hooks.js:373-404, 557-601`; `validate-member-channel-permission.js:17-28`).
- Existing `buildCountBaseQuery` strips only pagination and unread fields (`build-count-base-query.ts:17-21`), while count queries retain contact-only filters and are executed directly against the selected model (`compute-badge-counts.ts:78-95`). The count path therefore needs mirrored fields or a join.
- Group handling is materially different: chat sessions use `type: messaging|group` (`chat-session.model.js:31-36`), separate collection/index shapes (`:128-153`), and distinct group write/read paths. A shared state discriminator should not collide with the existing domain `type`; identity must also prevent cross-collection `_id` collisions.
- Cross-repo mark-read paths were found in both `oho-api/src/webhook/stream.js:137-150` and `oho-websocket/src/webhook/stream.js:169-199`. Websocket has its own strict mirror models (`models/contact.model.js:14-17`, `models/chat-session.model.js:16-19`). No production matches were found in `oho-cronjob` or `oho-developer-api`.
- The actual mutation surface includes multiple SET and clear handlers, bulk writes, group writes, both websocket/API mark-read paths, realtime assumptions, model/index changes, deletion cleanup, Atlas Search indexes/pipelines, and authorization/count behavior. The plan’s “repoint two builders” framing materially understates scope; ten working days is not realistic for a safe direct cutover.

Failures and how to do differently:
- Do not treat `last_active_at` as equivalent to `last_contact_date`.
- Do not page state IDs before applying contact keyword, sale-visibility, and permission filters.
- Do not assume update results are available to emitters; trace every emitter’s actual query/context inputs.
- Do not approve direct cutover based only on flags being off; stale canary data, cross-repo writes, Atlas storedSource, and deletion/orphan paths still matter.

Reusable knowledge:
- For this codebase, the durable review trace is payload builder -> timestamp guard -> DB mutation result -> realtime audience/payload -> search/count/read decoration -> websocket mark-read. Reviews should inspect all contributors to `last_active_at` and both contact/group models.
- Existing contract: SET writes are feature-flagged, CLEAR writes are unconditional, and realtime broadcasts are feature-flagged. Any refactor must preserve this split.

References:
- Plan: `/Users/tualek/ohochat/docs/unread-unresponded/unread-unresponded-consolidated-refactor-plan.md:99-228`.
- Main verdict: `NO-SHIP`.
- Source revision: `oho-api develop` `fadce85370eb42828570b91edb1649b401a424a1`.
- Cross-repo grep found no production field matches in `oho-cronjob` or `oho-developer-api`.
