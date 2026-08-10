thread_id: 019fdb04-3fd5-7162-baaf-6899542d9a88
updated_at: 2026-08-07T07:05:16+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/07/rollout-2026-08-07T13-58-36-019fdb04-3fd5-7162-baaf-6899542d9a88.jsonl
cwd: /Users/tualek/Documents/Codex/2026-08-07/referenced-chatgpt-conversation-this-is-an

# รีวิวเอกสาร Meta Business AI flow 3-boxes พบต้อง rework ก่อนใช้เป็น implementation contract

Rollout context: รีวิวแบบ read-only ใน `/Users/tualek/ohochat` โดยเทียบ `meta-biz-ai-flow-3-boxes-2026-08-07.md` กับ flow diagrams, HANDOFF, POC/source matrix และ source จริงใน `oho-webhook`, `oho-api`, `oho-web-app`. ไม่ได้แก้ไฟล์หรือรัน test suite; การตรวจ official Meta URLs แบบสดทำไม่ได้เพราะ 429/cache miss จึงระบุเป็น Not verified.

## Task 1: ตรวจความครบถ้วนและความสอดคล้องของเอกสาร 3-boxes

Outcome: success

Preference signals:
- ผู้ใช้ขอให้ประเมิน completeness, missing sections, inconsistencies, architectural gaps และ concrete recommendations -> งาน review ควรให้ findings แบบ severity-ranked พร้อมหลักฐาน path/line และข้อเสนอแก้ไขที่ทำได้จริง
- บริบทเดิมกำหนด read-only และห้าม fabricate evidence -> ต้องแยก verified source facts, observed POC, proposed design และ Not verified อย่างชัดเจน
- งาน Meta Business AI ควรตอบภาษาไทยแบบละเอียดและอ้างแหล่งที่มา ไม่สรุปว่า HTTP 200 หรือ observation เดียวคือ success

Key steps:
- ตรวจ inventory เอกสารใน `docs/meta-business-ai/` และอ่านไฟล์ 3-boxes กับ technical deep-dive
- Trace reducer, webhook canonicalization/dedup, takeover/return-to-AI API, bot guard และ UI state จริง
- เทียบ flow ย่อกับ POC ที่พบว่า self-handoff ไม่ deterministic, `thread_owner` ใช้เป็น passive owner oracle ไม่ได้ และ event อาจ duplicate/out-of-order
- ตรวจ official Meta URLs สด แต่ได้รับ 429/cache miss จึงไม่ใช้ยืนยัน contract ปัจจุบัน

Failures and how to do differently:
- 3-boxes แสดงหลาย transition เป็นผลลัพธ์ทันที ทั้งที่ระบบจริงต้องผ่าน requested/confirmed/unconfirmed/failed และรอ webhook signal -> ใช้ 3-boxes เป็น conceptual view เท่านั้น และมี canonical runtime-state contract แยกต่างหาก
- ไม่ควรสรุป `take_thread_control` ทุกชนิดว่าเป็น OHO takeover เพราะ reducer ยังไม่ใช้ previous/new owner app IDs แยกทิศทาง
- ไม่ควรให้ bot guard อาศัยเพียง `observed_authority`; ต้องบล็อกช่วง return-to-AI pending ด้วย
- ไม่ควรเรียก state ว่า monotonic หาก implementation ยังเป็น read-modify-write ที่ไม่มี conditional atomic update/stale-event rejection

Reusable knowledge:
- P0: webhook ส่งเข้า API เพียง `control_event_type` และไม่ได้ส่ง `previous_owner_app_id`/`new_owner_app_id`; reducer จึงอาจตีความ Axon take เป็น human takeover และ return-to-AI ยอมรับ `meta_human`/`external_app` เป็น confirmation ผิดความหมาย
- P0: `shouldBlockFacebookBotSend` บล็อกเฉพาะ `meta_or_other` หรือ page kill switch; เมื่อ `pass_thread_control` บันทึก `reactivation=requested` แต่ authority เดิมเป็น `oho`, scheduled/direct bot อาจยังส่งได้
- P0: task plan กำหนด monotonic reducer แต่ `runtime-event.class.js` โหลด state แล้วเขียน object ทั้งก้อน และ reducer ไม่ reject event เก่า จึงเสี่ยง cross-queue reorder/lost update
- P1: เอกสารย่อขัดกับหลักฐาน POC ในเรื่อง self-handoff, `ai_generated:true` ทุกข้อความ, idle แล้ว AI ยึดคืน และการปฏิบัติต่อ `unknown`
- P1: `HANDOFF.md` และ queue design มีสถานะล้าหลัง source ที่มี commits วันที่ 6 ส.ค. 2026; ยังไม่มี index/status matrix สำหรับ official, observed, proposed, implemented และ verified E2E
- P2: ยังขาด data lifecycle สำหรับข้อความ preview/AI ล่าสุด และ operational thresholds, dashboard owner, alert destination, rollback authority

References:
- `docs/meta-business-ai/meta-biz-ai-flow-3-boxes-2026-08-07.md:51-59,71-73,98,110,117,158-160`
- `docs/meta-business-ai/oho-poc-observed-behavior-2026-08-04.md:35-46,86-142`
- `docs/meta-business-ai/01-meta-docs-vs-oho-poc-2026-08-04.md:20-35,108-120`
- `oho-webhook/src/controllers/facebook/handler.ts:898-914,939-962`
- `oho-api/src/utils/meta-business-ai.js:191-205,250-326`
- `oho-api/src/services/contact/meta-business-ai/runtime-event/runtime-event.class.js:17-46`
- `oho-api/src/services/contact/meta-business-ai/return-to-ai/return-to-ai.class.js:48-69`
- Official URL check: Conversation Routing/Webhooks returned `429 Too Many Requests` or `Cache miss`; live comparison remains Not verified

Final verdict: `rework`; biggest blocker is that the documentation and reducer confirm ownership transitions without knowing control direction/target.
