thread_id: 019fcca5-2c2f-7bb1-ad67-039a286e19da
updated_at: 2026-08-05T04:00:09+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T19-00-04-019fcca5-2c2f-7bb1-ad67-039a286e19da.jsonl
cwd: /Users/tualek/ohochat

# ClickUp ticket filtering and Meta Business AI MVP estimation

Rollout context: Work was performed from `/Users/tualek/ohochat` using ClickUp tools and repository inspection.

## Task 1: Find tickets due 14 Aug 2026

Outcome: success

Preference signals:
- The user corrected the initial broad result with: “เอาแค่ assign ของฉันสิ” -> when listing tickets for a date, filter to the current user's assignee by default unless the user explicitly asks for all tickets.

Key steps:
- ClickUp search for the exact date returned 16 tasks, including one archived task.
- Direct task inspection identified the user as `Tualek[Full Stack]`, ClickUp user ID `113526352`.
- Search filtering by numeric assignee ID failed validation; string ID was accepted by schema but returned a server error, so the already-found candidate tasks were checked individually with `get_task`.
- Verified 5 matching active tickets assigned to the user, all due 14 Aug 2026.

Failures and how to do differently:
- The first response reported all 16 tickets instead of filtering by assignee. Apply the assignee filter before presenting results.
- ClickUp `assignees` validation expected strings, not numbers: error was `expected string, received number`. A string retry still produced `ClickUp server error`; fall back to per-task verification when necessary.

Reusable knowledge:
- User's ClickUp identity in this workflow is `Tualek[Full Stack]` / `sitthiporn@oho.chat` / ID `113526352`.
- Verified tickets: OHO-1811, OHO-1824, OHO-1820, OHO-1828, and OHO-1804.

## Task 2: Estimate OHO-1634 Meta Business AI implementation

Outcome: partial

Preference signals:
- The user asked for an estimate for ticket OHO-1634, but the assistant had to clarify that the ticket describes an MVP rather than MCP. Similar ambiguity should be called out before estimating.

Key steps:
- Retrieved OHO-1634 (`[DEV] POC BizAI take control`) with detailed description, attachments, and comments.
- Inspected relevant repositories and found current Facebook webhook handling routes `messaging` and `standby` through the same path; no existing `meta-ai` queue or `messaging_handovers` subscription was found in the inspected files.
- Confirmed human sending already uses the `HUMAN_AGENT` tag.
- Estimated production MVP at 15–20 working days for one developer, with 20 days recommended for ticket planning; a limited POC demo was estimated at 5–7 days.

Failures and how to do differently:
- The initial task lookup using numeric ID `90182460598` failed with `Team not authorized`; using custom ID `OHO-1634` succeeded.
- The estimate was not validated by a Meta runtime/integration test or Cloud Tasks canary, so it should be presented as a planning estimate, not a verified delivery commitment.

Reusable knowledge:
- OHO-1634 spans webhook canonicalization, queue separation, ownership/state tracking, deduplication, bot and scheduled-send safety, subscriptions, Smartchat UI, takeover/return-to-AI flows, QA, observability, and canary rollout.
- Relevant inspected paths include `oho-webhook/src/controllers/facebook/helper.ts`, `oho-webhook/src/helpers/cloud_tasks.api.ts`, `oho-api/src/utils/facebook/request-page-subscribed-app.js`, and `oho-api/src/services/member-send-message/member-send-message.hooks.js`.
- API success alone does not prove return-to-AI behavior; verify fresh post-action runtime evidence such as `ai_generated`, `hop_context`, ownership/control events, and actual AI response.
