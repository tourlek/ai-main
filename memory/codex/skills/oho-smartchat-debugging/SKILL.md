---
name: oho-smartchat-debugging
description: Debug OHO Smartchat/groupchat list, search, highlight, duplicate-message, sale-owner visibility, and performance issues in oho-web-app with related oho-api chat-search checks.
argument-hint: "[issue, ticket, or symptom]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO Smartchat Debugging

## When to Use

Use this when the task involves `/Users/tualek/ohochat/oho-web-app` Smartchat or groupchat behavior, especially:

- Chat list ordering, filtered-list re-entry, search/highlight behavior, TK-3100, or TK-4190.
- Sale-owner or visibility mismatches, including “คุณไม่ใช่พนักงานขายลูกค้าแชทนี้”.
- Duplicate-message filtering, dummy bubbles, TikTok-related resend prevention, `mid:bid`, `reference_id`, or `is_dummy`.
- Smartchat performance questions around `populate`, `contact_default`, `contact/chat/search`, or Stream `queryChannels`.

Do not use this for JERA-specific contact-link/API-key tasks unless the symptom is inside Smartchat rendering; use `skills/oho-jera-integration-debugging/SKILL.md` for JERA integration.

## Inputs and Context to Gather

1. Identify whether the user wants:
   - code review only,
   - diagnosis/explanation,
   - direct patch,
   - branch/history analysis.
2. Confirm the repo root before git/file commands:
   - web app: `/Users/tualek/ohochat/oho-web-app`
   - API chat-search: `/Users/tualek/ohochat/oho-api`
3. If the user provides two payloads, compare the concrete fields first: `sale_owner`, `assignee`, `assign_to`, `chat_room_id`, current member id, search/filter state, and platform.
4. If the user narrows scope to frontend-only or code-only, stop crossing into backend/tests/docs unless they re-open scope.

## Procedure

1. Search the smallest relevant surface first:
   - visibility: `plugins/contact.js`, `components/Smartchat/RoomPlaceholder.vue`, `pages/business/_biz_id/smartchat/index.vue`
   - backend list truth: `oho-api/src/services/contact/chat-search/*`
   - search/highlight: `useSmartchatSearch.ts`, `useSmartchatRoomList.ts`, `RoomList.vue`, `RoomListItem.vue`, `utils/committed-search.js`, `utils/smartchat-highlight.js`
   - duplicate/dummy: `components/Smartchat/Conversation.vue`, `plugins/message-helper.js`, `plugins/bubble-helper.js`, `api/endpoint.js`
2. For list-vs-open sale-owner bugs:
   - explain the frontend `visibility` result and backend list inclusion separately.
   - if the user says they are no longer sale owner, prioritize backend truth: inspect stored `sale_owner.member_id` and sale-owner mutation flow before proposing UI-only fixes.
3. For filtered/search re-entry bugs:
   - check whether current mode is filtered/search mode.
   - preserve normal TK-3100 `unshift` behavior for the latest-activity list.
   - for sort-aware normal mode, `sort_chat_list === 1` should append with `addContactListData`; other modes prepend with `addContactListDataFromHead`.
   - use/refetch `filtered_list_refetch_fn` only for filtered mode and clear callbacks on teardown.
   - validate both realtime/websocket paths and `profile-saved` paths.
4. For search/highlight work:
   - highlight should use committed search keyword, not live typing input.
   - audit direct `RoomListItem` consumers such as `ModalBulkMessage.vue` and decide explicitly whether they are in scope.
   - keep smartchat-specific whitespace/highlight logic out of shared `plugins/regex.js` unless the user explicitly accepts broader impact.
   - if the search-field dropdown disappears, check `is_optimized_search_enabled`, `rt_chat_list_search_optimization`, and Firebase remote config before blaming the refactor.
5. For duplicate-message/TikTok questions:
   - state if there is no TikTok-only branch.
   - trace shared Smartchat send/render flow: `member-send-message`, `filterDuplicate()`, `mid:bid`, dummy `reference_id`, and `appendOrReplaceDummyMessage()`.
6. For performance questions:
   - separate Mongo query, populate, Stream `queryChannels`, response size, and detail re-fetch.
   - identify whether `query_params.contact_default` is being used where a lighter list payload would suffice.

## Efficiency Plan

- Use `rg` with exact terms from the user: `sale_owner`, `RoomPlaceholder`, `filterDuplicate`, `is_dummy`, `reference_id`, `addContactListDataFromHead`, `filtered_list_refetch_fn`, `contact_default`, `rt_chat_list_search_optimization`.
- For history questions, use targeted git commands in `/Users/tualek/ohochat/oho-web-app`, such as `git blame -L ...` and `git show <sha> -- <files>`.
- Do not use repo tests as decisive proof when the user says tests are not trustworthy; rely on code paths, history, and targeted manual reasoning.
- If the user asks for “แบบคนหน่อย” / “เข้าใจง่าย ๆ”, close with a plain-language cause/effect summary after the technical evidence.

## Pitfalls and Fixes

- Symptom: room appears in list but opens with “คุณไม่ใช่พนักงานขายลูกค้าแชทนี้”. Likely cause: backend still sent the room while frontend visibility rejects it, often due to stored `sale_owner` truth or shape mismatch. Fix: inspect backend `contact/chat/search` filters and the raw contact document, not only UI rendering.
- Symptom: filtered room returns at top or wrong order after profile save/search refresh. Likely cause: TK-3100 normal-list `unshift` behavior being reused for filtered results. Fix: API refetch in filtered mode; preserve normal-list path.
- Symptom: oldest-sort room still jumps to the top on realtime insert. Likely cause: normal mode still uses `addContactListDataFromHead` when `sort_chat_list === 1`. Fix: append with `addContactListData` for oldest-sort mode.
- Symptom: search highlight changes while typing before Enter. Likely cause: component reads live `input_search`. Fix: pass committed `active_search_keyword`.
- Symptom: one list consumer behaves differently from another after a highlight refactor. Likely cause: `RoomListItem` consumer scope was assumed rather than verified. Fix: check direct consumers like `ModalBulkMessage.vue` separately and keep excluded consumers untouched.
- Symptom: Smartchat search-field dropdown missing. Likely cause: feature flag/runtime config false. Fix: check optimized-search flag and Firebase remote config.
- Symptom: duplicate bubbles after send. Likely cause: dummy replacement mismatch or missing `reference_id`. Fix: inspect `is_dummy`, response handling, `appendOrReplaceDummyMessage()`, and bubble-helper matching.
- Symptom: performance blamed only on `populate`. Likely cause: combined DB query, populate, Stream lookup, and room-detail refetch. Fix: measure or reason about each stage separately.

## Verification Checklist

- The answer names whether the symptom is frontend visibility, backend list inclusion, search state, duplicate render, or performance.
- If code was changed, both the primary path and the related alternate path are checked, for example websocket and `profile-saved`.
- If the bug involves ordering, verification covers both filtered/search mode and normal oldest-sort mode.
- Scope matches the user’s request: review-only stays review-only; frontend-only stays frontend-only unless the user approves backend work.
- Any history claim cites commit SHA or `git blame/show` evidence.
- If no timing/profile data was captured, performance conclusions are labeled structural rather than measured.
