thread_id: 01a01df6-bec3-7252-86b4-5299037a5b66
updated_at: 2026-08-20T16:22:16+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T13-58-25-01a01df6-bec3-7252-86b4-5299037a5b66.jsonl
cwd: /Users/tualek/ohochat

# Meta Developer Tools MCP setup followed by Meta Business AI fixes and staging verification

Rollout context: Work was performed from `/Users/tualek/ohochat`; the thread began with configuring Meta Developer Tools MCP for Codex, then continued into a separate Meta Business AI bug fix, commits in `oho-api` and `oho-webhook`, and a live staging check.

## Task 1: Configure Meta Developer Tools MCP

Outcome: partial

Preference signals:
- The user asked directly: “set mcp devtools meta ให้ใช้งานได้หน่อย” -> configure the local Codex host, authenticate it, and verify an actual tool call rather than only editing config.

Key steps:
- Confirmed Codex MCP configuration is `/Users/tualek/.codex/config.toml` and Meta’s remote endpoint is `https://mcp.facebook.com/devtools`.
- Found an existing `meta_developer_tools` entry and removed the duplicate `devtools` entry, leaving one enabled server.
- Completed OAuth successfully: `Successfully logged in to MCP server 'meta_developer_tools'.`
- A read-only discovery probe failed during MCP handshake with `unexpected server response: expect accepted or json, got Sse(None), when process initialized notification response`.

Failures and how to do differently:
- Configuration and OAuth succeeding does not prove tool usability. The actual Codex probe failed because Meta’s endpoint returned an SSE-shaped response where Codex expected accepted/JSON during the initialized notification.
- This is consistent with a known Codex/official Meta MCP interoperability issue; do not report the MCP as fully working until `devtools_discovery` or another read-only tool succeeds.

Reusable knowledge:
- Codex MCP config supports Streamable HTTP via `[mcp_servers.<name>] url = "..."`; OAuth is initiated with `codex mcp login <name>`.
- Meta Developer Tools MCP is remote and OAuth-based; no App Secret belongs in config.
- Codex CLI version observed: `codex-cli 0.146.0`.

References:
- `/Users/tualek/.codex/config.toml`
- `[mcp_servers.meta_developer_tools]`
- `url = "https://mcp.facebook.com/devtools"`
- `codex mcp list`
- `codex mcp login meta_developer_tools`
- Failure: `expect accepted or json, got Sse(None)`

## Task 2: Fix Meta Business AI contact flow and logging

Outcome: success

Preference signals:
- The user questioned unnecessary scope: “ไฟล์ deploy กับ gitlab ci นายแก้ไขทำไมเอาออไว้เหมือนเดิมได้ไหม” -> preserve pre-existing dirty deploy/CI changes and modify only files required for the requested bug.
- The user clarified the core issue: “ก่อนน่านั้น ทำไมถึงแก้ตรง logger ... แล้วไม่ต้องแก้ oho api หรอ” -> explain root-cause fixes separately from observability-only logging changes and identify which repo must deploy.
- The user explicitly requested: “commit ให้หน่อย ทั้งสอง repo” -> commit the relevant source/test changes separately per repository, without staging unrelated files.

Key steps:
- Identified the root cause: webhook `/contact/upsert` passed Meta Business AI authority fields into `oho-api` `/contact.create`, but `contact.hooks.js` Joi validation rejected them.
- Added validation for `meta_business_ai_enabled`, `facebook_delivery_authority`, `facebook_delivery_authority_observed_at`, and `facebook_meta_business_ai_observed_at`.
- Added a regression test proving those fields pass contact creation validation.
- Treated expected missing-contact `read` event 404s as ignorable in Facebook webhook handling.
- Normalized Cloud Logging messages to one line and disabled console logging for environment names matching `staging`, `uat`, `production`, including `staging-1`.
- Restored unrelated changes in `oho-webhook/.gitlab-ci.yml` and `deploy.sh` so those files had no diff.
- Focused validation passed: `oho-api` contact/upsert tests 11 passed using a compatibility shim for legacy dependencies under Node 26; webhook build passed; Facebook-focused tests 21 passed; Prettier and `git diff --check` passed.
- Created commits without staging untracked `.codegraph/`, worktrees, or `plan.md`:
  - `oho-api`: `b687a89d` — `fix: complete Meta Business AI contact flow`
  - `oho-webhook`: `a4196c8` — `fix: harden Facebook webhook handling`

Failures and how to do differently:
- An initial patch attempt failed because the expected source context did not match; the agent re-read the exact lines and applied smaller patches successfully.
- Running the core Jest command normally scanned `.claude/worktrees` and failed before tests because of duplicate mocks and removed Node utility APIs (`Utils.isRegExp`, `Utils.isDate`). Restrict Jest roots and use the compatibility shim when reproducing these tests on Node 26.
- Do not modify deploy/CI files merely to propagate environment variables when the user did not request deployment configuration changes.

Reusable knowledge:
- The actual Meta Business AI contract crosses repo boundaries: webhook constructs the fields, `oho-api` validates and persists them. Both repos are needed for the fix.
- Logging changes are independent observability improvements; they do not fix the API contract failure.

References:
- `oho-api/src/services/contact/contact.hooks.js`
- `oho-api/src/services/contact/contact.hooks.spec.js`
- `oho-api/src/logger.js`
- `oho-webhook/src/controllers/facebook/handler.ts`
- `oho-webhook/src/helpers/logger.ts`
- `b687a89d`, `a4196c8`

## Task 3: Verify live staging message flow

Outcome: partial

Key steps:
- Live checks targeted `webhook--staging-1` and `core-api--staging-1` using Cloud Run and Cloud Logging.
- Core revision `core-api--staging-1--b687a89d--6203b324--v2-27-1` was observed handling `/contact/upsert` and messaging-related requests with repeated HTTP 201/200 responses.
- Webhook logs showed recent Facebook activity and HTTP 200 responses.
- No recent core errors were found in the first 20-minute query; later targeted checks showed one core ERROR at `2026-08-20T16:19:01Z` and one older webhook ERROR at `2026-08-20T16:14:57Z`, but their messages were not fully retrieved before interruption.
- No `member-send-message/inbox` records appeared in the queried window, so the evidence did not conclusively prove that the inbound message reached Stream/member-message processing.

Failures and how to do differently:
- The user interrupted the rollout before the final live verdict. Do not claim “everything is normal.”
- Cloud Run describe/logging commands initially hit sandbox restrictions because `gcloud` needed to write credential/log cache files; read-only elevated execution worked.
- A complete verification should correlate one unique test message across webhook receipt, `/contact/upsert`, contact/message persistence, `/member-send-message/inbox` or Stream write, and the exact error payloads.

References:
- Services: `webhook--staging-1`, `core-api--staging-1`
- Revision: `core-api--staging-1--b687a89d--6203b324--v2-27-1`
- Observed statuses: `/contact/upsert` 201; messaging requests 200/201; webhook response 200
- Remaining errors: `2026-08-20T16:19:01.388Z` core, `2026-08-20T16:14:57.069Z` webhook
