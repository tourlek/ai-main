thread_id: 019fead6-e1dd-77a1-84ca-e7b90cfc6323
updated_at: 2026-08-10T17:19:20+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T15-42-58-019fead6-e1dd-77a1-84ca-e7b90cfc6323.jsonl
cwd: /Users/tualek/ohochat

# Scoped Meta Business AI review and implementation across oho-api/oho-webhook

Rollout context: ผู้ใช้ต้องการ recheck MVP บน branch `tk-sprint-2616/feature/oho-1802-meta-biz-ai` โดยเน้นเฉพาะ Facebook Meta Business AI, ไม่แตะ web-app หรือช่องทางอื่น, อ่านความเสี่ยงด้าน message loss/performance ก่อนลงมือ และห้าม commit โดยไม่ได้สั่ง

## Task 1: Review branch topology and existing Meta Business AI implementation

Outcome: success

Preference signals:
- ผู้ใช้ขอให้ “review แล้วทำ plan ขึ้นมาอย่างละเอียด” และให้คำนึงถึง worst case เช่น “ข้อความไม่เข้าหรอ ? หรือ performance drop” -> งานลักษณะนี้ควร trace runtime path จริง, แยก reliability/performance/security และให้ severity พร้อมหลักฐาน
- ผู้ใช้ย้ำให้ scope แคบเฉพาะ feature Meta Business AI และไม่กระทบ flow เดิม -> ต้องหลีกเลี่ยง broad refactor และ non-Facebook changes
- ผู้ใช้ระบุว่า `ai_generated === true` เป็นหลักฐาน authoritative แม้ไม่มี `app_id`; `app_id` เป็นเพียง optional metadata -> ห้ามใช้ `app_id` หรือ sender classification เป็นเงื่อนไขบังคับ

Key steps:
- ตรวจพบ branch ref ในทั้งสอง repo ชี้ commit เดียวกับ staging จึงต้องใช้ reflog/commit topology pin งานจริง: `oho-api` commit `afccdd74e`, `oho-webhook` commit `c3dbadd`.
- Review พบ implementation เดิมใหญ่เกิน MVP และมี blockers สำคัญ: messaging recovery ไม่คืน authority, Take/Pass เขียน state ก่อน Graph สำเร็จ, ขาด business scoping, dedup lease ไม่มี ownership token, control-event dedup ไม่รวม timestamp, `ai_generated` ถูกผูกกับ app ID, และมี synchronous DB work เพิ่มใน hot path.

Failures and how to do differently:
- GitLab MR lookup ใช้งานไม่ได้เพราะ DNS sandbox (`dial tcp: lookup gitlab.boonmeelab.com: no such host`); ใช้ local refs, reflog, commit stats และ source trace แทน และไม่อ้าง MR ที่ยังตรวจไม่ได้.
- อย่าถือ conceptual diagram หรือ POC เป็น implementation contract จนกว่าจะ trace parser, queue, persistence และ send guard จริง.

Reusable knowledge:
- `oho-api` commit `afccdd74e` เพิ่ม 1,739 lines/32 files; `oho-webhook` commit `c3dbadd` เพิ่ม 891 insertions/197 deletionsใน 10 files ก่อน rework.
- Webhook canonicalization flatten `entry.messaging[]`/`entry.standby[]` เป็น canonical event และใส่ `__ohoChannel`; `message.ai_generated` อยู่ภายใน event ที่มาจาก `standby`.
- Worst-case เดิมคือ contact ค้าง `other` แล้ว bot ถูก block ถาวรหลังกลับ `messaging`, Graph failure ทำให้ state ค้าง blocked, หรือ event/dedup race ทำให้ duplicate/message loss.

References:
- `/Users/tualek/ohochat/oho-api` — `afccdd74e8b1f1ca82f6d530ec5561e6d312d7eb`
- `/Users/tualek/ohochat/oho-webhook` — `c3dbadd3d4ed8eedc7f0a3c4938d87fdcc0bc994`
- `oho-webhook/src/controllers/facebook/helper.ts:1532-1561`
- `oho-webhook/src/controllers/facebook/handler.ts:873-937,2159-2187`

## Task 2: Implement narrowly scoped fixes with Luna max

Outcome: partial

Preference signals:
- ผู้ใช้แก้ไขเมื่อ agent เลือก model ผิด: “ฉันบอกให้ใช้ 5.6 Luna max” -> เมื่อผู้ใช้ระบุ model ชัดเจน ห้ามเลือก model ใกล้เคียงเอง; ต้องหยุดและแจ้งหาก model ไม่พร้อม
- ผู้ใช้สั่ง “แก้ issue แค่ scope ที่เป็น feature meta business ai ก่อน” -> จำกัดการแก้เฉพาะ Facebook Meta Business AI และไม่ cleanup unrelated dirty worktree.
- ผู้ใช้กำหนด contract: `standby + message.ai_generated === true` คือ Meta Business AI; ไม่มี `app_id` ก็ยังต้องจัดเป็น AI -> identity logic ต้องยึด signal นี้เพียงพอ.

Key steps:
- หลังผู้ใช้กด Go ใน environment ที่สลับ model แล้ว จึงมอบหมาย agent Luna max โดยไม่ commit/stage/reset.
- แก้ authority เป็น top-level `facebook_delivery_authority` (`oho|other`) พร้อม timestamp; `standby` ให้ `other`, customer `messaging` คืน `oho` เฉพาะเมื่อ state เดิมเป็น `other`.
- จำกัด Take/Return ด้วย `business_id`, Facebook contact/channel และย้าย persistence หลัง Graph success; Graph failure ไม่เปลี่ยน authority.
- เพิ่ม conditional primary update และ skip duplicate authority writes.
- เพิ่ม Redis pending lease พร้อม claim token และ Lua/CAS สำหรับ complete/release.
- ใช้ `ai_generated === true` จาก canonical standby event เป็น identity หลัก และให้ Stream ใช้ `${businessId}@meta-ai`, fallback เป็น `${businessId}@inbox`.
- คืน default `standby` subscription เพื่อไม่กระทบ Instagram.
- เพิ่ม primary safety read สำหรับ automated Facebook sends และ fail-closed เมื่อไม่พบ contact บน primary.

Validation:
- API focused tests: 4 suites / 17 tests passed.
- Webhook focused tests: 3 suites / 17 tests passed.
- API build compiled 1,567 files successfully.
- Webhook TypeScript/build passed.
- `git diff --check` passed in both repos.
- Redis test emitted local connection warnings (`EPERM 127.0.0.1:6379`) but Jest exited 0.

Failures and how to do differently:
- ยังไม่ได้รัน full suite, production E2E, load test หรือ production verification -> ห้ามสรุปว่า ready to merge/canary จาก focused tests เท่านั้น.
- Campaign guard ยัง filter authority ครั้งเดียวก่อน batch จึงมี TOCTOU window หาก authority เปลี่ยนระหว่างส่ง.
- Automated Facebook send paths อ่าน primary ทุกครั้ง เป็น safety trade-off ที่ต้องวัด p95/primary load ก่อน rollout.
- Worktree ยัง dirty และมีไฟล์เดิม/ไฟล์ใหม่จำนวนมาก; ต้องแยก pre-existing changes จาก delta ของรอบนี้ก่อน commit.

References:
- `oho-webhook/src/controllers/facebook/meta-business-ai.ts:20-95`
- `oho-webhook/src/controllers/facebook/handler.ts:966-989,1140-1165,1230-1415`
- `oho-webhook/src/services/redis.service.ts:1-20,230-305`
- `oho-api/src/services/contact/meta-business-ai/shared.js:5-75`
- `oho-api/src/services/contact/meta-business-ai/takeover/takeover.class.js`
- `oho-api/src/services/contact/meta-business-ai/return-to-ai/return-to-ai.class.js`
- `oho-api/src/utils/meta-business-ai-automation-guard.js`
- Test commands: `./node_modules/.bin/jest --runTestsByPath ... --runInBand --forceExit`; `npm run build`

