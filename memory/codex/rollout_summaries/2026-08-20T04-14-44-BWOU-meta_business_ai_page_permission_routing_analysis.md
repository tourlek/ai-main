thread_id: 01a01d60-e36c-7140-9da6-1c95bb416e54
updated_at: 2026-08-20T04:21:01+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T11-14-44-01a01d60-e36c-7140-9da6-1c95bb416e54.jsonl
cwd: /Users/tualek/ohochat

# วิเคราะห์ UX/API สำหรับ Meta Business AI และ Facebook Page ที่เชื่อมต่อแล้ว

Rollout context: ตรวจ PDF `[External] Business AI Integration Guide for Messaging Partners - v4.pdf`, source codeใน `/Users/tualek/ohochat` และค้นหาเอกสาร Meta เพื่อแยก Facebook permissions, webhook subscriptions, Conversation Routing และ Business AI onboarding

## Task 1: ตรวจ requirement และความเป็นไปได้ของ flow

Outcome: success

Preference signals:
- ผู้ใช้ถามถึงกรณี “เชื่อมต่อช่องทางไปแล้ว มีปุ่มเพื่อขอสิทธิ์การเข้าถึงเพิ่มเติม” -> ควรเสนอ flow สำหรับ Page เดิมโดยไม่บังคับ reconnect ใหม่ทั้งช่องทาง
- ผู้ใช้ต้องการคำตอบเชิงเอกสาร/UX ที่แยกประเด็นชัดเจน -> ควรตอบเป็นภาษาไทยและแยก permissions, subscriptions, routing และ Business AI activation ไม่รวมเป็นขั้นตอนเดียว

Key steps:
- อ่าน PDF 18 หน้าและพบว่าเอกสารระบุ `Business AI opt-in checkbox` ในหน้าสุดท้ายของ flow เชื่อมต่อเดิม ไม่ใช่ permission dialog โดยตรง
- ตรวจ code พบ OAuth reissue flow อยู่แล้วใน `oho-web-app/pages/business/_biz_id/setting/integration.vue` แต่ปุ่ม reconnect ปัจจุบันแสดงเฉพาะ channel ที่ `connection_status === 'incomplete'`
- ตรวจ `request-page-subscribed-app.js` พบ create flow ส่ง `messages`, `message_echoes`, `message_reads`, `messaging_handovers`, `standby` และ fields อื่น ๆ ไปยัง `/{PAGE_ID}/subscribed_apps`
- ตรวจ Facebook patch flow พบว่า reissue อัปเดต token แต่ไม่ได้เรียก subscribe endpoint ซ้ำ
- ตรวจ Meta references พบ `subscribed_apps` ใช้ Page access token และเปลี่ยน webhook subscriptions ไม่ใช่ Default routing app

Failures and how to do differently:
- Live Facebook settings checks ไม่สำเร็จ: หนึ่ง URL ตอบ temporary block และอีก URL ถูก robots denied; จึงไม่ควรอ้างว่าได้ตรวจ Page จริงหรือยืนยัน routing configuration แล้ว
- Meta developer docs บางหน้าตอบ 429/ไม่พร้อมใช้งาน; แยก verified code/document facts ออกจาก pending Meta confirmation

Reusable knowledge:
- Flow ที่เหมาะสม: Page ใหม่ -> OAuth permissions เดิม -> หน้ายืนยันสุดท้ายเพิ่ม Business AI opt-in -> ตรวจ `GET /{PAGE_ID}/business_ai` -> หาก `not_configured` ให้ Page admin ทำ onboarding ผ่าน Meta Business Suite
- Page เดิมควรมีปุ่มแยก `ขอสิทธิ์ Facebook เพิ่ม` สำหรับ OAuth/token กับ `ตั้งค่า Business AI` สำหรับ activation/routing; OAuth ใหม่อย่างเดียวไม่เปิด Business AI หรือเปลี่ยน Default routing
- `standby` ต้องเปิดทั้ง app-level (`POST /{APP_ID}/subscriptions`) และ page-level (`POST /{PAGE_ID}/subscribed_apps`); page-level ต้องส่ง fields ชุดเต็มเพราะอาจแทนที่ชุดเดิม
- ยังไม่มีหลักฐาน public API ที่ยืนยันว่า OHO สามารถตั้ง `Default routing app` แทน Page admin ได้โดยตรง ควรให้ admin ตั้งค่าใน Meta UI แล้วมีปุ่มตรวจสอบซ้ำ

References:
- `/Users/tualek/ohochat/docs/meta-business-ai/[External] Business AI Integration Guide for Messaging Partners - v4.pdf` — PDF requirement
- `/Users/tualek/ohochat/oho-web-app/pages/business/_biz_id/setting/integration.vue:1463-1495` — OAuth reissue flow
- `/Users/tualek/ohochat/oho-api/src/utils/facebook/request-page-subscribed-app.js:8-24` — page webhook subscription
- `/Users/tualek/ohochat/oho-api/src/services/channel/facebook/facebook.hooks.js:458-487` — create vs patch hook behavior
- `/Users/tualek/ohochat/docs/meta-business-ai/06-facebook-page-onboarding-2026-08-05.md` — onboarding checklist and verification gates
