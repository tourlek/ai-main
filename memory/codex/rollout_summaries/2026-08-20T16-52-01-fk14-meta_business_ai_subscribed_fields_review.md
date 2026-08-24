thread_id: 01a02016-3517-7881-bd17-46c9326b74aa
updated_at: 2026-08-20T16:54:41+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/20/rollout-2026-08-20T23-52-01-01a02016-3517-7881-bd17-46c9326b74aa.jsonl
cwd: /Users/tualek/ohochat

# ตรวจสอบ subscribed_fields สำหรับ Meta Business AI

Rollout context: ผู้ใช้ถามว่า `docs/meta-business-ai` และรายการ Page `subscribed_fields` ปัจจุบันขาด field ใดหรือไม่ ใน repo `/Users/tualek/ohochat`.

## Task 1: ตรวจสอบ Facebook Page subscription fields

Outcome: success

Preference signals:
- ผู้ใช้ถามเป็นภาษาไทยและต้องการคำตอบตรงประเด็นจากเอกสาร/โค้ด -> งานลักษณะนี้ควรตอบภาษาไทย พร้อมแยกสิ่งที่เป็น contract ของ MVP กับ field ที่เป็น optional หรือ legacy

Key steps:
- ตรวจเอกสาร `docs/meta-business-ai/HANDOFF.md`, MVP checklist, POC notes และ implementation ใน `oho-api/src/utils/facebook/request-page-subscribed-app.js`.
- ตรวจพบ base fields 7 รายการ: `messages`, `messaging_postbacks`, `messaging_referrals`, `message_echoes`, `message_reads`, `standby`, `feed`.
- ตรวจพบว่า Facebook mode เพิ่ม `messaging_handovers` เป็น field ที่จำเป็นสำหรับ handover flow.
- เปรียบเทียบกับ test page baseline 13 fields และพบว่า “13 fields” เป็น baseline ของเพจทดสอบ ไม่ใช่ minimum contract ที่ต้องเติมทุก field.
- ค้นข้อมูล Meta Webhooks ผ่าน Postman API Network หลัง direct developers.facebook.com เปิดไม่ได้จาก rate limit.

Reusable knowledge:
- สำหรับ Meta Business AI MVP รายการที่ผู้ใช้ให้มาครบ field สำคัญแล้วเมื่อมี `standby` และเพิ่ม `messaging_handovers`; จากรายการ 8 fields ที่ส่งมา ขาดอย่างน้อย `messaging_handovers`.
- `message_deliveries` เป็น delivery observability แบบ optional ตาม MVP checklist ไม่ใช่ staging acceptance gate; เพิ่มได้หากต้องการ receipt/monitoring แต่ไม่ใช่ข้อบังคับของ flow นี้.
- `feed` ไม่เกี่ยวกับ Meta Business AI โดยตรง แต่ควรเก็บไว้หาก feature เดิมของ OHO ใช้งานอยู่.
- ห้ามเติม fields อื่นเพียงเพื่อให้ครบตัวเลข 13; 13 เป็น baseline ของ test page และ customer pages อาจมีชุด field ต่างกัน.
- Page subscription ต้องทำแบบ GET current fields → union กับ required fields → POST → GET verify; ห้าม replace ชุดเดิม เพราะเคยมี flow อื่น clobber subscriptions จน `message_echoes`/`standby` หาย.

Failures and how to do differently:
- `git status` ล้มเหลวเพราะ rollout root `/Users/tualek/ohochat` ไม่ใช่ git repository โดยตรง; repo จริงอยู่ใน subdirectories จึงไม่ควรใช้ผลนี้สรุปสถานะงาน.
- Direct Meta documentation fetch ถูกตอบ `429 Too Many Requests`; ข้อสรุป official-source ใน rollout อาศัยผลค้นจาก Postman API Network และเอกสาร repo ไม่ควรอ้างว่า direct page ถูกเปิดตรวจสำเร็จ.

References:
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:10-18` — base 7 fields.
- `oho-api/src/utils/facebook/request-page-subscribed-app.js:70-74` — union existing fields and add `messaging_handovers` only in `mode === 'facebook'`.
- `docs/meta-business-ai/HANDOFF.md:15` — customer pages had 7 fields and lacked `messaging_handovers`.
- `docs/meta-business-ai/HANDOFF.md:116` — test page had 13 fields including `messaging_handovers`.
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md:45,49-56` — `message_deliveries` optional; remaining canary verification checklist.
