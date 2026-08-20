thread_id: 019fef19-a05e-7773-9301-06b8ab7c9e37
updated_at: 2026-08-14T06:34:08+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-34-21-019fef19-a05e-7773-9301-06b8ab7c9e37.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI plan review, correction, and implementation handoff remained partial

Rollout context: งานใน `/Users/tualek/ohochat` ครอบคลุม `oho-api`, `oho-webhook` และเอกสาร `docs/meta-business-ai/plan-fix-meta-ai-profile.md` โดยผู้ใช้ขอให้ตรวจแผน Meta Business AI และภายหลังแก้ความเข้าใจเรื่อง `ai_generated` พร้อมขอให้อัปเดตแผนให้พร้อมทำงาน

## Task 1: Review and narrow the Meta Business AI plan

Outcome: partial

Preference signals:

- ผู้ใช้แก้ว่า `ai_generated` “เป็น field ที่ webhook จาก meta ส่งมาถ้า meta ai เป็นคนตอบ” -> ในงานต่อไปต้องถือ `message.ai_generated === true` เป็น incoming Meta author signal อย่างเคร่งครัด ห้ามสร้างหรืออนุมานจาก `app_id`, `metadata`, `standby` หรือ `messaging`
- ผู้ใช้ต้องการแผนที่ “พร้อมทำงาน” และยอมรับการลด scope -> แยก MVP ที่จำเป็นออกจาก state machine, Redis/Cloud Tasks, migration ใหญ่ และ TypeScript conversion แทนการรวมทุกอย่างใน migration เดียว
- งาน Meta Business AI ควรตอบภาษาไทยแบบ source-cited และแยก verified facts, observed behavior, proposed design และ runtime/UAT ที่ยังไม่ตรวจ

Key steps:

- Trace source จริงใน `oho-api` และ `oho-webhook` รวม Stream identity, webhook classification, authority guard, takeover/return และ dedup
- พบว่าแผนเดิมใหญ่เกินไปและมีความเสี่ยง: existing contacts อาจขาด `@meta-ai`, async Redis/queued authority writes อาจ stale, schema ไม่ตรง reducer, effects ไม่มี executor, และการลบ `isMetaBusinessAiGeneratedEvent` จะทำให้ AI echo กับ human Page Inbox ปะปน
- อัปเดตแผนให้เหลือ Facebook-only MVP: strict `ai_generated`, lazy Stream identity พร้อม inbox fallback, explicit `meta_business_ai_enabled`, standby persistence-before-block, existing takeover/return flow และ E2E validation
- ภายหลังมี implementation correction pass ที่เพิ่ม activation wiring, whitelist exception, handoff gating, dedup lease coverage และอัปเดต plan status เป็น local implementation complete แต่ runtime/UAT ยัง pending

Failures and how to do differently:

- แผนเดิมเสนอ cold provisioning/backfill, `meta_ai_profile`, Redis cache, Cloud Tasks, reducer และ cleanup หลายชุดพร้อมกัน -> ควรเริ่มจาก smallest contract ที่แก้ identity/guard เท่านั้น
- การใช้ `ai_generated` เป็นตัวบอก thread ownership เป็นความหมายผิด -> ใช้บอกผู้เขียนข้อความเท่านั้น; authority ต้องมาจาก explicit observation/control flow
- การบอกว่า focused tests ทำให้พร้อม merge/canary เกินจริง -> ต้องคงรายการ unverified สำหรับ real payload replay, terminal Mongo/Stream state, real Graph, Redis, canary และ rollback
- Standards review หลัง implementation ยังพบ P1: disabled channel ยังมี activation snapshot writes, authority persistence ซ้ำใน `upsert.hooks.js` และ `upsert.class.js`, Redis lease 300 วินาทีไม่มี renewal, และ bulk broadcast ยังไม่มี per-recipient authority guard

Reusable knowledge:

- `message.ai_generated === true` เป็น strict per-message author evidence; AI และ Business Suite human อาจใช้ app ID เดียวกัน แต่ human echo ไม่มี field นี้
- `standby` เป็นหลักฐานว่าแอปอื่นอาจถือ delivery ไม่ใช่หลักฐานว่าเป็น Meta Business AI
- Stream AI sender คือ `${businessId}@meta-ai`; ถ้า lazy ensure ล้มเหลวให้ fallback `${businessId}@inbox` แต่ต้อง preserve `ai_generated: true`
- Automation send guard ใช้ primary Mongo read แบบ tenant-scoped และ fail closed เมื่ออ่าน authoritative contact ไม่ได้
- Facebook webhook canonicalizes ทั้ง `messaging[]` และ `standby[]`; dedup ใช้ claim lease + token/CAS completion/release แต่ lease fixed 300s ยังต้องมี policy/coverage เพิ่ม

References:

- Plan: `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- Payload evidence: `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19`
- MVP checklist: `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- Webhook identity: `oho-webhook/src/controllers/facebook/meta-business-ai.ts`
- Stream identity: `oho-api/src/services/member-send-message/inbox/inbox.hooks.js`, `oho-api/src/utils/meta-business-ai-stream.js`
- Authority/guard: `oho-api/src/services/contact/upsert/upsert.hooks.js`, `oho-api/src/utils/meta-business-ai-automation-guard.js`
- Relevant validation: webhook 3 focused suites / 24 tests passed in one run; later reported 5 suites / 46 tests and API 10 suites / 50 tests, but `upsert.class.spec.js` separately failed under Node 24 due `config` calling missing `Utils.isRegExp`; `git diff --check` passed
- Final standards verdict: rework before ship; no runtime/UAT/canary proof

## Task 2: Preserve the user’s workflow rule

Outcome: success

Preference signals:

- User invoked `ponytail full`; assistant acknowledged “ลบก่อนเพิ่ม, reuse ก่อนสร้าง, diff เล็กสุดที่แก้ root cause” -> future code work should minimize diff, reuse existing paths, and avoid broad refactors unless explicitly requested.

Reusable knowledge:

- The rollout ended with `ponytail full` enabled; this is a workflow constraint for subsequent implementation tasks, not evidence that the Meta feature itself is production-ready.
