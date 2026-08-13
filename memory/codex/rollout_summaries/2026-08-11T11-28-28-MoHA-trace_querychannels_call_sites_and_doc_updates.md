thread_id: 019ff094-bfe0-7330-b67d-5c37089d39fe
updated_at: 2026-08-11T18:47:31+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-28-28-019ff094-bfe0-7330-b67d-5c37089d39fe.jsonl
cwd: /Users/tualek/ohochat

# Traced active Stream Chat `queryChannels` call sites and checked `docs/queryChannels.md` coverage

Rollout context: Repository `/Users/tualek/ohochat`; user first asked where Stream Chat `queryChannel` is used, then asked which additional points need updating based on `docs/queryChannels.md`.

## Task 1: Locate `queryChannels` usages

Outcome: success

Preference signals:
- The user asked a concise repository-oriented question in Thai; the agent appropriately searched the workspace first, then separated active runtime calls from scripts, tests, comments, and false positives. Similar requests should return file paths, line numbers, and call-flow context rather than only raw grep output.

Key steps:
- Searched all non-git files for `queryChannel` and then narrowed to actual `.queryChannels(` calls.
- Inspected surrounding implementations and callers in API, web, Flutter, CLI, and migration code.
- Confirmed the singular variable `queryChannel` in export code is unrelated to Stream Chat.

Reusable knowledge:
- Active production backend calls:
  - `oho-api/src/services/contact/chat-search/chat-search.class.js:46`, reached via `GET /contact/chat/search`; queries messaging CIDs and merges Stream state into contact results.
  - `oho-api/src/services/chat-session/group/search/search.class.js:28`, reached via `GET /chat-session/group/search`; queries group channels and merges state.
- Active mobile call:
  - `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:331`, called by `oho-flutter-mobile/lib/modules/home/controllers/chat_list_controller.dart:915`; preconnects channels in chunks of 10 with `messageLimit: 100`.
- Manual/script calls:
  - `script-oho/unread-unresponded/migrate-unread.ts:716`
  - `script-oho/unread-unresponded/probe-stream-authority.ts:355`
  - `oho-cli/lib/fix/fix-chat-room-attachment.js:307`
  - `oho-cli/lib/fix/fix-contact.js:74`
- `oho-api/src/services/conversations/facebook/facebook.hooks.js:372` is inside a block comment (`/* ... */`) and is not executed.
- Flutter test verifications are mocks, not production calls.

Failures and how to do differently:
- A broad search includes incident docs, variable names, commented-out code, tests, and historical plans. Always follow with `rg '\.queryChannels\\('` limited to source/runtime directories and inspect comment boundaries before labeling a call active.

References:
- `oho-api/src/services/contact/chat-search/chat-search.class.js:46-68`
- `oho-api/src/services/chat-session/group/search/search.class.js:28-47`
- `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:323-344`
- `oho-flutter-mobile/lib/modules/home/controllers/chat_list_controller.dart:915`

## Task 2: Determine updates needed for `docs/queryChannels.md`

Outcome: success

Preference signals:
- The user asked whether more points needed updating, prompting comparison of documentation against active code and exact early-return conditions. Similar documentation reviews should distinguish scope (web hot path vs all system callers) and call out statements that are too broad.

Key steps:
- Read `docs/queryChannels.md` and mapped its two web endpoints to web services/composables and backend implementations.
- Verified the document covers the main Smartchat and Groupchat web flows, including list refreshes, filters, search, sort, pagination, room opening, reconnect, and realtime fallback requests.
- Inspected backend guards that prevent `queryChannels` from running.

Reusable knowledge:
- If scope is web `queryChannels` traffic, the only active production backend hot-path implementations to change are the two search classes above; frontend callers converge on those endpoints.
- The documentation should not say these endpoints call Stream on “every” request without qualification. Backend skips Stream when:
  - Smartchat `query.$limit === 0`.
  - Groupchat `query.$limit === 0`.
  - Mongo/search results are empty.
  - Smartchat feature flag `feature_flag.skip_stream_channel_sync` is enabled; it throws internally and uses mock state.
  - Groupchat starred scope cannot resolve to an `_id`; it returns deterministic zero badges before search.
- If documenting all system calls, add Flutter as a separate direct production caller and list CLI/migration scripts as non-hot-path callers. The commented Facebook hook needs no update.
- `Conversation.vue` uses `channel.watch()` for live conversation behavior and does not use these search endpoints.

Failures and how to do differently:
- An initial command ran `git status` from `/Users/tualek/ohochat` and failed because the repository metadata is under a subdirectory; later inspection from `/Users/tualek/ohochat/oho-api` worked. Use the relevant project subdirectory for git commands.
- Do not update every frontend caller when the intended change is backend Stream querying; update the two backend implementations unless the goal is specifically UI request reduction.

References:
- `docs/queryChannels.md:68-70` — overly broad “ทุกครั้ง” summary to qualify.
- `oho-api/src/services/contact/chat-search/chat-search.class.js:41-63,113-147,158-162`
- `oho-api/src/services/chat-session/group/search/search.class.js:69-84,116-138`
- `oho-web-app/services/contact-api-service.js:30-66`
- `oho-web-app/services/groupchat-api-service.js:13-58`
- `oho-web-app/composables/smartchat/useSmartchatRoomList.ts:172-276,369-527`
- `oho-web-app/store/modules/smartchat.js:774-1115`
- `oho-web-app/store/modules/groupchat.js:318`

