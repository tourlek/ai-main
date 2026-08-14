thread_id: 019ff927-ae16-79f0-a3ae-eaee875badce
updated_at: 2026-08-13T03:30:22+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-25-55-019ff927-ae16-79f0-a3ae-eaee875badce.jsonl
cwd: /Users/tualek/ohochat

# วิเคราะห์ cronjob ที่เกี่ยวกับ LINE และแยกหน้าที่ของแต่ละระบบ

Rollout context: ผู้ใช้ถามว่า cronjob ที่ตรวจ `platform: line` ทำอะไรบ้าง โดยเฉพาะตรวจ webhook หรือ access token หรือไม่ ใน workspace `/Users/tualek/ohochat` มีทั้ง `oho-api`, `oho-cronjob` และ `oho-webhook` จึงต้องแยก logic ที่ชื่อคล้ายกันออกจากกัน

## Task 1: ตรวจ `validate-business-integration-status` ใน oho-api

Outcome: success

Preference signals:
- ผู้ใช้ต้องการคำตอบเชิง trace จาก cronjob ไปยัง service/API และแยกให้ชัดว่าตรวจ token, webhook หรือการประมวลผลจริง -> งานลักษณะนี้ควรอ่าน source และสรุปเป็นรายการตรวจสอบ ไม่ตอบจากชื่อ cronjob อย่างเดียว
- ผู้ใช้ถามแบบเจาะจงว่า “logic เช็ค webhook หรือ access token หรอ” -> ควรตอบทั้งสิ่งที่ตรวจและสิ่งที่ไม่ได้ตรวจ

Key steps:
- ค้นพบ endpoint `POST /cronjob/validate-business-integration-status` ใน `oho-api`; `oho-cronjob` checkout ปัจจุบันแทบไม่มี implementation ของงานนี้
- อ่าน hooks ซึ่งเลือก active businesses (`is_disabled: false`) และ channels ที่ `connection_status: complete`, จำกัดอย่างละ 2,000 รายการ และประมวลผล concurrency 2
- อ่าน `validateLineConnectionStatus()` และ class ที่เขียนผลด้วย `channelModel.bulkWrite()`

Reusable knowledge:
- LINE validation เรียก `GET https://api.line.me/v2/bot/info` ด้วย channel access token เพื่อตรวจว่า token ใช้งานได้
- จากนั้นเรียก `GET https://api.line.me/v2/bot/channel/webhook/endpoint` ด้วย token เดิม เพื่อตรวจ `data.active` และ endpoint
- endpoint ที่คาดหวังคือ `channel.line.webhook_endpoint` หรือ fallback `${webhook_endpoint}/line/webhook/${businessId}`; เปรียบเทียบหลัง trim trailing `/` จากค่าที่ LINE ส่งกลับ
- ถ้า webhook inactive หรือ URL ไม่ตรง จะตั้ง `connection_status: incomplete` และบันทึก `line.is_webhook_active` / `line.is_webhook_endpoint_valid`
- ถ้า API error ที่ไม่ใช่ HTTP 429 จะตั้ง `is_access_token_valid: false` และ `connection_status: incomplete`; HTTP 429 จะ skip channel โดยไม่เปลี่ยนสถานะ
- cronjob นี้ไม่เรียก LINE webhook test API, ไม่ส่งข้อความจริง, ไม่ตรวจ queue/Stream Chat, ไม่ตรวจ channel secret และไม่มี auto-recovery; รอบถัดไปเลือกเฉพาะ channel ที่ยัง complete
- มี ambiguity: webhook-info failure หลัง bot-info สำเร็จถูกบันทึกเป็น token invalid แม้สาเหตุอาจเป็น network หรือ LINE API อื่นล้มเหลว

References:
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:210-305`
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.hooks.js:13-36, 354-370`
- `oho-api/src/services/cronjob/validate-business-integration-status/validate-business-integration-status.class.js:10-22`
- `oho-api/docs/modules/cronjob.md:196-214`

## Task 2: ตรวจ synthetic LINE messaging health ใน oho-cronjob

Outcome: success

Key steps:
- ตรวจ remote `origin/develop` ของ `oho-cronjob` ที่ SHA `50f5149` และพบ Firebase HTTPS function `check_line_messaging_health`
- Trace flow จาก function ไปยัง Firestore, OHO webhook และ Stream Chat

Reusable knowledge:
- Function สร้าง synthetic LINE webhook payload แล้ว POST ตรงไปยัง OHO `/line/webhook/{businessId}` พร้อม `x-line-signature`
- เมื่อได้ HTTP 200 จะบันทึกข้อความลง Firestore, รอ 30 วินาที, query Stream Chat และค้นหาข้อความเดียวกัน
- ถ้าข้อความตรงกันจะบันทึก `healthy`; ถ้าไม่ตรงกันหรือเกิด error จะบันทึก `unhealthy` และแจ้ง Slack เมื่อสถานะเปลี่ยน
- แม้ config มี field channel access token แต่ code ของ health check ไม่ได้นำไปเรียก LINE Platform API ดังนั้นงานนี้ไม่ตรวจ token และไม่ได้จำลองเส้นทาง `LINE Platform → OHO`
- receiver ฝั่ง `oho-webhook` ส่ง signature ไปให้ `oho-api` ตรวจผ่าน `/business/:businessId/line/verify-signature`; แต่ signature mismatch ใน `verify-signature.class.js` ถูก log แล้ว return `{ ok: true }` แทนการ reject จึงยังไม่ใช่หลักฐานว่า signature validation ผ่านจริง
- HTTP 200 จาก webhook ไม่พอพิสูจน์ว่างานสำเร็จ ต้องดู terminal state เช่น Stream Chat หรือ source-message metrics

Failures and how to do differently:
- `rtk find` รองรับ compound predicates ไม่ครบและแจ้งให้ใช้ `find` ตรง ๆ; ค้นไฟล์ด้วย `rg --files | rg` แทนได้
- การตรวจ remote ครั้งแรกติด network/DNS แต่การ rerun พร้อมสิทธิ์ network สำเร็จ; หากต้องยืนยัน branch ล่าสุดควรแยกผล local checkout กับ remote fetch ให้ชัด
- ยังไม่ได้ตรวจ live Cloud Scheduler/Firebase deployment จึงยืนยันความถี่หรือ job ที่เปิดใช้งานจริงไม่ได้

References:
- `oho-cronjob:functions/service/check-oho-line-messaging-health/check-oho-line-messaging-health-service.js:17-153`
- `oho-cronjob:functions/utils/send-oho-webook.js:11-30`
- `oho-cronjob:functions/service/check-oho-line-messaging-health/check-oho-line-messaging-health.js:2-8`
- `oho-webhook/src/controllers/line/line.controller.ts:38-210`
- `oho-webhook/src/controllers/line/handler.ts:93-108, 1186-1257`
- `oho-api/src/services/business/line/verify-signature/verify-signature.class.js:12-61`

สรุปสุดท้าย: `validate-business-integration-status` ตรวจ LINE access token + webhook active + webhook URL ต่อ channel; `check_line_messaging_health` ตรวจ OHO webhook ingestion ไปจนถึง Stream Chat แบบ synthetic; ยังไม่มีงานใดพิสูจน์ end-to-end จาก LINE Platform จริงจนถึง Stream Chat และพบ credential แบบ raw ใน tracked config ซึ่งควร rotate/remove โดยไม่แสดงหรือคัดลอกค่า
