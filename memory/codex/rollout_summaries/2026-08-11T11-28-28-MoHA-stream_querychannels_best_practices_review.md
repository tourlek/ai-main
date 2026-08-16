thread_id: 019ff094-bfe0-7330-b67d-5c37089d39fe
updated_at: 2026-08-14T09:31:07+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T18-28-28-019ff094-bfe0-7330-b67d-5c37089d39fe.jsonl
cwd: /Users/tualek/ohochat

# Traced Stream Chat `queryChannels` usage and documented best-practice gaps

Rollout context: In `/Users/tualek/ohochat`, the user first asked where `queryChannel`/`queryChannels` is used, then asked whether `docs/queryChannels.md` needed updates, challenged the claim that webapp had no direct Stream calls, and finally requested an official GetStream best-practices review saved as Markdown.

## Task 1: Locate `queryChannels` call sites

Outcome: success

Key steps:
- Searched the workspace and separated active production calls, scripts/CLI, tests, docs, and false positives.
- Active backend calls:
  - `oho-api/src/services/contact/chat-search/chat-search.class.js:46`, used by `/contact/chat/search`.
  - `oho-api/src/services/chat-session/group/search/search.class.js:28`, used by `/chat-session/group/search`.
- Active mobile call:
  - `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:331`, invoked from `chat_list_controller.dart:915`.
- Operational calls include `migrate-unread.ts:716`, `probe-stream-authority.ts:355`, and CLI repair scripts at `fix-chat-room-attachment.js:307` and `fix-contact.js:74`.
- `facebook.hooks.js:372` is inside a comment block and is not runtime code; Flutter test verifications are not production calls.

Preference signals:
- The user asked specifically where `queryChannel` is used and later asked what must be updated in `docs/queryChannels.md`, indicating they value exhaustive call-site tracing with active/dead-code distinctions rather than a simple text search.

## Task 2: Correct the webapp/network-path analysis and update documentation scope

Outcome: success

Failures and how to do differently:
- The initial conclusion that the webapp did not call Stream directly was too broad because it only searched application-level `queryChannels` calls. The user corrected this by pointing out `chat-proxy-singapore.stream-io-api.com` traffic.
- Source tracing then verified that `oho-web-app/components/Smartchat/Conversation.vue:1517-1525` constructs `StreamChat`, sets the proxy base URL, and calls `connectUser`; `watchChannel()` calls `channel.watch()` at `1595`, and message pagination calls `channel.query()` at `2460`.
- The installed web SDK defaults `recoverStateOnReconnect: true`; its reconnect recovery calls `queryChannels({ cid: { $in: activeChannels }}, { last_message_at: -1 }, { limit: 30 })`, producing `POST /channels` against the proxy. `channel.watch()`/`channel.query()` instead use `/channels/{type}/{id}/query`.
- Future investigations must distinguish SDK-generated network calls from application source calls and identify the HTTP path/method, not infer from method-name search alone.

Reusable knowledge:
- Backend contact search skips Stream sync when the feature flag is enabled, `$limit === 0`, or the database result is empty; group search also has early-return cases such as unresolved starred scope. Documentation should not say “every request” without these conditions.
- A useful documentation correction is: webapp does not directly call `client.queryChannels()` in its application source, but the browser Stream SDK can call it automatically during connection recovery; the webapp also directly invokes `channel.watch()` and `channel.query()`.

## Task 3: Review GetStream best practices and create Markdown report

Outcome: success

Key steps:
- Retrieved the official GetStream Query Channels Markdown and compared its guidance with `oho-api`, `oho-web-app`, `oho-flutter-mobile`, and operational scripts.
- Created and reviewed `/Users/tualek/ohochat/queryChannels-best-practices-review.md` (186 lines). No application code was changed, tested, staged, or committed.

Findings recorded in the report:
- Backend validation allows `$limit` up to 50 while Stream documents a maximum of 30. Smartchat and Groupchat pass the request limit directly to Stream; recommended fix is batching internally while preserving endpoint behavior.
- Smartchat uses selective `cid` filtering and `message_limit: 1`, but both backend calls pass `{}` for sort.
- Groupchat uses `{ type: 'group', id: { $in: ids } }`; the report recommends CID filtering (`group:${id}`), while marking the performance conclusion as an inference without Dashboard evidence.
- Flutter batches 10 channels and avoids an additional `watch()` call after pre-connect, but uses `id` only, ignores the `type` argument, omits sort, and requests `messageLimit: 100`; payload reduction requires measuring first-render behavior.
- Web reconnect uses CID, `last_message_at`, and limit 30 correctly, but SDK `activeChannels` entries may remain after `stopWatching()`, creating a source-backed risk if more than 30 rooms accumulate.
- Operational scripts are explicitly separated from production hot paths; `facebook.hooks.js` remains excluded because it is commented out.

References:
- [1] `oho-api/src/services/contact/chat-search/chat-search.class.js:35-71`
- [2] `oho-api/src/services/chat-session/group/search/search.class.js:24-47`
- [3] `oho-flutter-mobile/lib/core/services/stream_chat_service.dart:317-350`
- [4] `oho-web-app/components/Smartchat/Conversation.vue:1516-1597,2458-2465`
- [5] `oho-web-app/node_modules/stream-chat/src/client.ts:1242-1255,1402-1437` (SDK version/source varies by installed package; report records the observed paths)
- [6] Official source: `https://getstream.io/chat/docs/react-native/query-channels.md`
- [7] Created artifact: `/Users/tualek/ohochat/queryChannels-best-practices-review.md`
