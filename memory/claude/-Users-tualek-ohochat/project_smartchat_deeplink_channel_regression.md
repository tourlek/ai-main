---
name: project-smartchat-deeplink-channel-regression
description: oho-web-app v1.113.0 broke smartchat deep-link/refresh room open for channel-restricted members by removing channel_id from the direct contact fetch
metadata: 
  node_type: memory
  type: project
  originSessionId: 7c7e2c18-731d-4c5d-8161-9cec015dbd7c
---

Incident 2026-07-16 (Sabuy Express, business `665d2673fdb64ed457e39e60`): channel-restricted members (`channel_permission.is_allowed_all: false`, e.g. member "TEAM - Syd to Thai" `69e1936e622574d34a600dde`) could not open a chat room via deep-link / backoffice link / page refresh — blank room (`SmartchatRoomPlaceholder`). Searching for the room in the list still worked; admins (`is_allowed_all: true`, e.g. Oho Beam) were unaffected.

**Root cause**: oho-web-app commit `2692b732` (tualek/sitthiporn, authored 2026-06-22 "fix: bypass channel filter on direct contact fetch and auto-include channel in list"), which **shipped to prod only in v1.113.0 on 2026-07-15 evening** (not in v1.112.0). It removed `...generateChannelIdQueryParam(checked_channels)` from `fetchAndSetCurrentContact` (`composables/smartchat/useSmartchatRoomList.ts`). The list/search fetch (`getContactParams`) still sends `channel_id`, so search works; the single-contact fetch no longer does.

**Mechanism**: backend `oho-api` hook `validateMemberChannelPermission` (`src/hooks/validate-member-channel-permission.js`, old — Rapee 2025-06-16 `bf8ddfac6`) forces `context.params.query.$limit = 0` (→ empty `data`) when the member is not `is_allowed_all` AND `channel_id` is absent/empty. No channel_id on the direct fetch → `$limit=0` → empty → deep-link relies solely on this fetch (room not in the cold-loaded list) → `current_contact` stays null → placeholder. The commit's own "auto-include channel" code never runs because the fetch returns empty first. Diagnostic log line: frontend `[fetchAndSetCurrentContact] empty response` (logName `oho-web-app.production/stdout`, resource.type `global`, NOT core-api container logs).

**Fix direction (not yet applied — awaiting user)**: on the direct fetch, send the member's full allowed channels (not just `checked_channels`) so a restricted member still passes the backend gate; keeps the commit's intent (open a room whose channel isn't currently selected) without tripping `$limit=0`. Frontend-only change preferred over touching Rapee's backend security gate.

Related: [[project_unread_by_refactor]], [[reference_gcp_logging_console]], [[reference_release_process]].
