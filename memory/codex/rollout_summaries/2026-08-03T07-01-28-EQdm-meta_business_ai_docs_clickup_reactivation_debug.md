thread_id: 019fc66d-6db1-7253-a396-dfde3105523c
updated_at: 2026-08-03T18:26:26+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T14-01-28-019fc66d-6db1-7253-a396-dfde3105523c.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI documentation, ClickUp handoff, and reactivation debugging

Rollout context: งานใน `/Users/tualek/ohochat` ครอบคลุมการแยกเอกสาร Meta Business AI ออกจากผล POC, ระบุรายการ coming soon/planned, จัดทำเอกสารส่ง Meta, อัปเดต ClickUp OHO-1634 และวิเคราะห์อาการ `take_thread_control`/`pass_thread_control` เมื่อมี default app

## Task 1: จัดทำเอกสารเปรียบเทียบ Meta กับ Oho POC

Outcome: success

Preference signals:
- ผู้ใช้ต้องการเอกสารที่ “เอาไปสื่อสารกับทาง meta ได้เลย” -> ควรแยก official contract, observed POC และข้อสงสัยที่ต้องถาม Meta อย่างชัดเจน
- งานรีวิวลักษณะนี้ควรตอบภาษาไทยแบบละเอียดและไม่ยกระดับ observation เป็น universal contract ตามความต้องการเดิมของผู้ใช้

Key steps:
- ตรวจเอกสารเดิมใน `docs/meta-business-ai/`, official Meta PDF 15 หน้า, payload samples และผล live verification
- สร้างไฟล์ canonical 3 ฉบับ:
  - `docs/meta-business-ai/01-meta-docs-vs-oho-poc-2026-08-04.md` — ตารางเทียบ Meta document กับ POC และ implementation boundary
  - `docs/meta-business-ai/02-meta-coming-soon-2026-08-04.md` — Eligibility API, Unified Onboarding และ Business AI Take Thread Control API
  - `docs/meta-business-ai/03-questions-for-meta-2026-08-04.md` — คำถามภาษาอังกฤษ 18 ข้อ พร้อม requested artifacts และ definition of done
- เอกสารระบุว่า `622851382610562` ใช้เป็น reactivation target ได้จาก POC แต่ `thread_owner`, channel, farewell text และ observed flags ไม่ควรใช้เป็น owner contract

Reusable knowledge:
- ต้องแยก delivery authority, agent identity และ latest event time เป็นคนละ state dimension
- `take_thread_control` ไม่มี `message` จึงไม่ควรสร้าง chat bubble หรือ bot trigger
- `take_thread_control` เคยถูกส่งซ้ำ 4 ครั้ง และ timestamp ของ control event เป็นวินาที ขณะที่ message event เป็นมิลลิวินาที ต้อง normalize/dedupe
- ingress standby gate ไม่พอ เพราะ scheduled/direct bot sends ยังอาจทำงาน ต้องมี send-time guard และ cancellation
- `release_thread_control` คืน conversation สู่ idle/default app ไม่ใช่การคืนให้ Business AI; การคืนให้ AI ใช้ `pass_thread_control` ไป `622851382610562` แต่ API success ไม่เท่ากับ AI เริ่มตอบทันที

## Task 2: อัปเดต ClickUp OHO-1634

Outcome: success

Key steps:
- เข้าการ์ด `https://app.clickup.com/t/90182460598/OHO-1634` ได้สำเร็จหลัง retry login
- อัปโหลด canonical files 3 ไฟล์สำเร็จ; attachments เพิ่มจาก 10 เป็น 13
- เพิ่มหัวข้อ `Canonical 3 files` ใน description พร้อมชื่อและหน้าที่ของไฟล์
- reload แล้วตรวจยืนยันว่า description และไฟล์ทั้ง 3 ยังอยู่ครบ

Failures and how to do differently:
- ClickUp ครั้งแรกกด Continue แล้วกลับหน้า Login; retry ผ่านหน้าเดิมจึงสำเร็จ
- การอัปโหลดด้วย `locator.setInputFiles` ใช้ไม่ได้ใน browser runtime; ต้องใช้ file chooser flow (`waitForEvent("filechooser")` แล้ว `chooser.setFiles(...)`)
- การตรวจ description ทันทีหลังแก้ครั้งแรกให้ผล false เพราะยังไม่รอ/โหลด state; หลังรอและ reload จึงยืนยัน persistence ได้

References:
- `docs/meta-business-ai/01-meta-docs-vs-oho-poc-2026-08-04.md` (72 lines)
- `docs/meta-business-ai/02-meta-coming-soon-2026-08-04.md` (80 lines)
- `docs/meta-business-ai/03-questions-for-meta-2026-08-04.md` (143 lines)
- ClickUp task `OHO-1634`
- Verification: `persistedCanonicalSection: true`, `persistedFiles: true`, attachment links count 1 ต่อไฟล์

## Task 3: วิเคราะห์อาการ default app และการคืนห้องให้ AI

Outcome: partial

Preference signals:
- ผู้ใช้ยืนยันเชิง product ว่า “ถ้ากดส่งแชทกลับให้ AI แปลว่า AI ต้องกลับมาทำงานทันที” -> UX ไม่ควรแสดง success จาก HTTP 200 เพียงอย่างเดียว แต่ต้องรอ positive runtime evidence หรือแสดงสถานะ unknown/timeout

Key steps:
- เทียบอาการล่าสุดกับผล POC เดิมและ official guide
- แยก generic thread control ออกจาก Business AI activation
- สรุปว่า silent `take_thread_control` ไม่มี user message เป็นพฤติกรรมปกติของ API; หลัง take แล้ว AI เงียบได้เพราะ authority ย้ายมา Oho
- ระบุว่า `release_thread_control` ไม่ใช่ return-to-AI mechanism และ default app เป็น prerequisite ของ generic take path แต่ยังไม่พิสูจน์ว่าเป็นสาเหตุเดียวของ reactivation failure

Failures and how to do differently:
- Public Meta docs refresh ล้มเหลวด้วย HTTP 429/cache miss/URL safety จึงอ้างอิง local official PDF และ POC เดิมแทน
- ยังไม่มี live sequence ล่าสุดที่เก็บ HTTP response และ webhook หลังแต่ละ call จึงยังสรุป root cause ของ pass ล่าสุดไม่ได้
- ต้องทำ controlled sequence: take พร้อม metadata → ส่งข้อความและเก็บ webhook → pass ไป `622851382610562` → รอ 5–10 วินาที → ส่งข้อความใหม่ → ตรวจ channel, `ai_generated`, `hop_context` และ control events

Reusable knowledge:
- Success criteria ของ “คืนให้ AI” ควรเป็น `standby` พร้อม AI echo ที่มี `ai_generated:true`; UI banner “You're chatting with an AI agent” เป็นเพียง observation
- หลัง pass หากกลับ `standby` แต่ไม่มี AI echo ให้จัดเป็น AI eligibility/response-policy หรือ lifecycle gap ไม่ใช่สรุปว่า default app ผิดทันที
- หากยังอยู่ `messaging` ให้ตรวจว่า pass เปลี่ยน routing จริงหรือไม่
- Official/POC evidence ระบุว่า AI อาจไม่ตอบทุกข้อความ และอาจ bounce กลับเมื่อมี unresolved context หรือเพิ่งมี manual response
