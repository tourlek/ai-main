thread_id: 019ffa4b-53d6-7f53-ab12-aac360e69732
updated_at: 2026-08-13T08:54:13+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T15-44-28-019ffa4b-53d6-7f53-ab12-aac360e69732.jsonl
cwd: /Users/tualek/ohochat

# Diagnosed Thaimetal LINE rich-menu button events and why Oho Chat shows “กดปุ่ม”

Rollout context: Read-only investigation in `/Users/tualek/ohochat` using source tracing and GCP production logs for business `6a422c6fae5398680bf7d837`.

## Task 1: Trace LINE rich-menu/postback event and assess whether it can be ignored

Outcome: success

Key steps:
- Confirmed the production event is LINE `type: "postback"`, not a normal text message.
- Found a representative event at `2026-08-13T08:35:42Z` with only `postback.data: "แคตตาล็อค"`; it had no `displayText` or label.
- Historical logs from Aug 12–13 showed the same shape for multiple payloads, including `แคตตาล็อค`, `ผลงานและการออกแบบประตู-หน้าต่าง`, `ข้อควรรู้ก่อนติดตั้งประตู-หน้าต่าง`, and `ตัวแทนจำหน่ายอลูมิเนียมเส้นไทยเม็ททอล`.
- Traced the processing chain: LINE event → `transformEventMessageToOhoFormat` → `/contact-send-message` → Stream/notification preview.
- Verified Oho falls back to `กดปุ่ม` when postback text/label is missing.

Reusable knowledge:
- `oho-webhook/src/controllers/line/helper.ts:127-133` converts any `entry.postback` to `{ type: 'postback', text: label, data }`, where `label` is parsed from `postback.data`.
- `oho-webhook/src/controllers/line/handler.ts:691-708` syncs the transformed postback to `/contact-send-message` before further pattern handling.
- `oho-api/src/utils/message-converter/youpin-to-stream.js:296-301` uses `message.text || 'กดปุ่ม'`.
- `oho-api/src/services/contact-send-message/contact-send-message.hooks.js:386-399` similarly uses `data.label || text || 'กดปุ่ม'` for preview/notification.
- `oho-webhook/src/controllers/line/handler.ts:206-214` ignores only postbacks that do not resolve to an `art_id` or `arp_id` for auto-reply detection; this does not prevent the message from being synced first.
- GCP project/account context was `oho-platform` / `sitthiporn@oho.chat`; broad searches must be narrowed because output is noisy and large.

Failures and how to do differently:
- Initial Logging query using `jsonPayload` as a bare field failed with `INVALID_ARGUMENT: Cannot match a nested type 'jsonPayload'`; use a concrete nested field such as `jsonPayload.message` or `SEARCH(...)`.
- `gcloud` initially hit local permissions for `~/.config/gcloud`; the same query succeeded with elevated permission. Avoid storing credentials or raw signed headers/tokens.
- Do not ignore all LINE postbacks: Oho-managed postbacks such as `art_id=...&label=สมัครงาน` are used for Auto Reply Triggers.

Conclusion: The event can be suppressed, but only with a business-scoped and payload-scoped rule. The cleanest solution for buttons that only open an external system is to use a LINE URI action instead of postback. If postback is required, use a namespace such as `external_action=thaimetal_catalog` and ignore only that namespace for this business. Adding `label=แคตตาล็อค` improves the displayed text but does not suppress the event.
