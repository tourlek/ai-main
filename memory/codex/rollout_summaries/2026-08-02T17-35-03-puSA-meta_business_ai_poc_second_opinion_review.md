thread_id: 019fc38b-2163-7081-8ab6-b42248952f08
updated_at: 2026-08-02T20:11:49+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T00-35-03-019fc38b-2163-7081-8ab6-b42248952f08.jsonl
cwd: /Users/tualek/ohochat

# รีวิวเชิงหลักฐาน Meta Business AI POC (OHO-1215) เสร็จสิ้น โดยสรุปว่ายังต้อง rework ก่อน implementation

Rollout context: ทำงานแบบ read-only ใน `/Users/tualek/ohochat` อ่านเอกสาร Markdown ทั้งหมดใน `docs/meta-business-ai/`, extract PDF official guide ได้ครบ 15 หน้าโดยใช้ `pypdf` หลัง Poppler ใช้ไม่ได้, trace โค้ดใน `oho-webhook` worktree และ `oho-api`, และพยายามตรวจ prod logs ด้วย gcloud ตาม checklist ผู้ใช้กำหนดให้รายงานเป็นภาษาไทยแบบละเอียด พร้อมหลักฐานและแยก verified / docs evidence / not run อย่างชัดเจน

## Task 1: Second-opinion review ของคำตอบ POC 6 ข้อ

Outcome: success

Preference signals:
- ผู้ใช้กำชับว่า “Answer entirely in Thai” และขอรายงาน “ละเอียด” พร้อมโครงสร้างปัญหา/หลักฐาน/ความรุนแรง/ข้อเสนอแนะ -> งานลักษณะนี้ควรตอบภาษาไทยแบบละเอียด ไม่สรุปสั้น
- ผู้ใช้กำหนดว่า “Every claim ... must cite a specific source” และ “Do not fabricate log output” -> ต้องอ้าง file/line/finding/sample หรือผล query จริงทุกข้อ และระบุ no data/not run เมื่อหลักฐานไม่พอ
- ผู้ใช้กำหนด read-only และห้ามแก้ไฟล์/commit -> ควรตรวจสถานะ repo และหลีกเลี่ยงการแก้ไข แม้พบปัญหา

Key steps:
- ตรวจเอกสารหลัก `meta-biz-ai-poc-6-answers.md`, findings 1–50, payload samples, queue design, handoffs, plan, adoption report และ official PDF
- Trace `oho-webhook` ที่ `handler.ts:857–875`, `945–992`, `1242–1274`, `1612–1632`, `1940–1960`; `helper.ts:1317–1343`, `1465–1541`; `facebook.controller.ts:124–168`; และ subscription code `oho-api/src/utils/facebook/request-page-subscribed-app.js:7–25`
- Verdict ต่อ 6 ข้อ: ข้อ 1 overclaim เพราะ replay ยังไม่ผ่าน POC; ข้อ 2 wrong semantics เพราะ observational flag แปลได้แค่ recently observed; ข้อ 3 binary owner model ไม่ถูก; ข้อ 4 เป็น eventual/best-effort ไม่ใช่ direct handoff detection; ข้อ 5 ถูกเฉพาะ scope payload ที่พบแต่ reason taxonomy ยังเป็น observation; ข้อ 6 หลักการ standby gate ถูกแต่ต้องมี send-time guard และ cancellation ของงานที่ schedule ไว้
- ตรวจ design risks: cross-queue reordering, stale poll results, room flapping, duplicate webhook deliveries, mixed `entry[]`, control event ถูกแปลงเป็น unsupported message, subscription drift และ replay race
- ตรวจ Perplexity rebuttal: generic Handover Protocol อาจถูก แต่ rebuttal ต้องจำกัด scope เป็น observed Axon rollout/เพจที่ทดสอบ ไม่ควรยกระดับเป็น universal contract

Failures and how to do differently:
- gcloud query แบบทั้งเดือนค้างและถูกยกเลิก; ใน continuation ผู้ใช้กำหนดให้ใช้ time-boxed slices, `--limit`, และ timeout 90 วินาที
- หลัง credential หมดอายุ gcloud refresh ล้มด้วย `Unable to create private file ... credentials.db: Operation not permitted`; ห้ามตีความเป็น no data ให้รายงาน `Not run: credential refresh ถูก sandbox ปฏิเสธ`
- การตรวจ public Meta docs ผ่านเว็บล้มเหลว (`Failed to fetch`/URL unsafe); ใช้ official PDF local ได้ แต่ต้องระบุว่า live public-doc comparison ยังไม่ verified
- PDF ไม่มี Poppler (`pdfinfo`/`pdftotext` not found) แต่ `pypdf` และ `pdfplumber` ใช้ได้ จึง extract PDF ได้แบบ text-only

Reusable knowledge:
- Official PDF ระบุ Business AI App ID `622851382610562`, `ai_generated:true`, standby channel, `HUMAN_AGENT` takeover และ `pass_thread_control` reactivation แต่ prod evidence ขัด/ต่างหลายจุด จึงต้องแยก official expected contract จาก observed runtime
- Payload sample 3 แสดง AI echo ที่มาทาง `messaging` พร้อม `hop_context.app_id=388207815496149`; ดังนั้น `standby`/`messaging` ไม่ใช่ตัวตัดสิน AI/OHO แบบ binary
- `hop_context.is_ai_thread_owner` ไม่สม่ำเสมอ: design doc ระบุ scan 113/796 requests และ AI echoes 25 รายการไม่มี hop; finding เก่าที่บอกว่ามาทุกข้อความควรถูกแก้
- sample 7 แสดง `take_thread_control` พร้อม `previous_owner_app_id=388207815496149`, `new_owner_app_id=928891643393937`, metadata `axon_take_thread_control`, timestamp เป็นวินาที และ duplicate 4 deliveries
- sample 6 มี read channel switch หลัง AI farewell; `entry.time` ต่างประมาณ 3.69 วินาที แต่ event timestamp ต่างประมาณ 2.13 วินาที จึงควรระบุ clock ให้ชัดและไม่สรุป “~4s” เป็น universal
- โค้ดปัจจุบันอ่าน queue classification จาก `entry[0]`/event แรก และ enqueue request ทั้งก้อน; mixed entries หรือหลาย tenant/event ใน request อาจถูกจัด queue ผิด
- read event ถูก return ที่ `handler.ts:973–992` ก่อน bot path; การเพิ่ม standby flag อย่างเดียวไม่ทำให้ read receipt เปลี่ยน ownership state
- control event ไม่มี `message` แต่เข้า `handleEventMessaging`; transformer fallback สร้าง unsupported text จึงต้อง branch control event ก่อน message transform
- fallback bot ถูก schedule ผ่าน `/schedule-reply-trigger` และ direct send ผ่าน `/bot-send-message`/`/bot-send-message/notify`; ingress gate ไม่พอ ต้องตรวจ owner ตอน send จริง

References:
- `docs/meta-business-ai/meta-biz-ai-poc-6-answers.md:7–121`
- `docs/meta-business-ai/meta-biz-ai-poc-result.md:93–105, 163–177, 187–229, 235–254, 308–331`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:53–93`
- `docs/meta-business-ai/meta-biz-ai-queue-routing-design.md:48–85`
- Official PDF: `docs/meta-business-ai/[External] Business AI Integration Guide for Messaging Partners.pdf` (15 pages extracted with `pypdf`)
- Trace SHA: `oho-webhook/.claude-worktrees/meta-business-ai` at `1886ac7604cb1cb1630b38324a57417c169c1ac0`
- Direct log query that completed with empty output: `resource.type="cloud_run_revision" AND resource.labels.service_name="webhook--production" AND jsonPayload.message:"pass_thread_control" --freshness=24h --limit=100` -> no data found for approximately the last 24 hours available at query time

Final verdict from delivered report: `rework before implementation`; primary blocker is conflating delivery authority, agent identity, and latest event into one owner state.
