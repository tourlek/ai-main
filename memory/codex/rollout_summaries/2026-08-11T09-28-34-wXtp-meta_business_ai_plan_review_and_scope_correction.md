thread_id: 019ff026-fc80-7881-8a12-5ba2c15991bb
updated_at: 2026-08-11T10:24:33+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T16-28-34-019ff026-fc80-7881-8a12-5ba2c15991bb.jsonl
cwd: /Users/tualek/ohochat

# รีวิวและปรับแผน Meta Business AI ให้สอดคล้องกับ contract จริง

Rollout context: ทำงานใน `/Users/tualek/ohochat` โดย review แผน `docs/meta-business-ai/plan-fix-meta-ai-profile.md` เทียบกับ source ปัจจุบันใน `oho-api`/`oho-webhook` และหลักฐาน payload จริง จากนั้นแก้ plan และโค้ดใน worktree ให้ลด scope และไม่ตีความ `ai_generated` ผิดความหมาย

## Task 1: Review แผน Meta Business AI

Outcome: success

Preference signals:
- ผู้ใช้ต้องการให้แก้แผนให้ “พร้อมทำงาน” และยืนยันว่า `ai_generated` เป็น field จาก Meta webhook เมื่อ Meta AI เป็นผู้ตอบ -> งานลักษณะนี้ควรยึด source contract ที่ผู้ใช้ยืนยันและแยก author identity ออกจาก delivery authority อย่างชัดเจน
- บริบทเดิมของงาน Meta ต้องตอบภาษาไทยแบบละเอียด มีหลักฐาน path/line และห้าม fabricate evidence

Key steps:
- ตรวจ plan เดิมที่รวม schema refactor, state machine, cold-path provisioning, Redis/Cloud Tasks, webhook cleanup และ TypeScript conversion ไว้ใน migration เดียว
- Trace source จริงพบว่า `ai_generated === true` เป็น per-message author signal; ไม่ใช่ Page activation หรือ thread ownership
- พบว่า repo ยังไม่มี source ที่เชื่อถือได้สำหรับยืนยันว่า Page เปิด Meta Business AI; `standby`, `hop_context`, `app_id`, `metadata`, `thread_owner` และ `subscribed_apps` ใช้ยืนยัน activation ไม่ได้เพียงลำพัง
- พบความเสี่ยงเดิม: existing contacts/memberships, authority guard race, API caller spoofing, deleted legacy schema, duplicated authority-update logic และการใช้ exact handoff text เป็น activation

Failures and how to do differently:
- แผนเดิมใหญ่เกิน scope และสรุป performance benefit โดยไม่มี baseline -> แยก sender identity/author labeling ออกจาก authority, activation, state-machine และ performance optimization
- ห้ามใช้ `ai_generated` หรือ `standby` เพื่อเขียน authority หรือเปิด Meta take/return side effects
- ห้ามลบ legacy `meta_business_ai` schema/validators โดยไม่มี migration/backfill/volume verification
- ห้ามถือว่า Graph HTTP success เป็น terminal ownership confirmation; ต้องรอ runtime signal และตรวจ terminal state

Reusable knowledge:
- `message.ai_generated === true` มาจาก Meta webhook และควร preserve ใน Stream message; OHO ไม่ควรสร้างหรือ infer field จาก `app_id`, metadata หรือ channel
- AI echo ทั้ง `messaging[]` และ `standby[]` ใช้ sender `${businessId}@meta-ai`; human Business Suite echo ที่ไม่มี field นี้ใช้ `${businessId}@inbox`
- `ai_generated` ระบุผู้เขียน message เท่านั้น ไม่ได้บอกว่าใครถือ delivery authority
- จนกว่าจะมี activation/eligibility source จริง Meta-specific standby blocking, Meta Graph take/return และ Meta-specific send guard ต้องถูกปิด/blocked โดยตั้งใจ

References:
- `docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- `docs/meta-business-ai/07-mvp-implementation-checklist-2026-08-10.md`
- `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19,37-49`
- `docs/meta-business-ai/meta-official-coming-soon-2026-08-04.md:9-15,29-31`
- `oho-webhook/src/controllers/facebook/meta-business-ai.ts`
- `oho-webhook/src/controllers/facebook/handler.ts`
- `oho-api/src/utils/meta-business-ai.js`

## Task 2: ปรับแผนและโค้ดตาม contract

Outcome: partial

Preference signals:
- ผู้ใช้แก้โดยตรงว่า `ai_generated` เป็น field ที่ Meta ส่งมา -> ต้อง preserve incoming boolean แบบ strict และไม่สร้าง metadata เองเพื่อใช้เป็น authority

Key steps:
- เขียน plan ใหม่ให้มี explicit activation gate, non-goals, phases, acceptance checklist, rollback และ Definition of Done
- ตัด `meta_ai_profile`, Redis, Cloud Tasks, state-machine migration, cold provisioning, broad TypeScript conversion และ UI work ออกจาก MVP
- เพิ่ม/ปรับการตรวจ strict `ai_generated` สำหรับ Facebook `messaging`/`standby` และ non-Facebook negative case
- ปิด activation helper ให้คืน `false` จนกว่าจะมี source จริง; ป้องกัน Meta take/return และ Meta-specific automation side effects
- คืน generic standby queue behavior และนำ broadcast recipient filtering ที่เกิน scope ออก
- คง legacy schema compatibility เพื่อไม่ทำลายข้อมูล/patch เดิม

Validation:
- API focused tests ผ่าน 5 suites / 31 tests
- Webhook focused test ผ่าน 1 suite / 17 tests
- API และ webhook build ผ่าน
- `git diff --check` ผ่านทั้งสอง repo
- Full type-check ยัง fail จากปัญหาที่มีอยู่เดิมใน `config`, search converter และ partner specs
- ยังไม่ได้ทำ real UAT หรือ terminal Mongo/Stream replay

Failures and how to do differently:
- งานยังไม่พร้อม ship เพราะยังไม่มี activation source ที่พิสูจน์ได้ และยังไม่ได้ replay payload จริงตรวจ Mongo/Stream terminal state
- Worktree มี uncommitted changes จำนวนมากจากงานก่อนหน้า; ต้องแยก diff ของ rollout นี้ก่อน commit และคืน deleted canonical/dedup tests หากเป็นส่วนของ change จริง
- ห้ามอ้างว่า “พร้อม deploy” จาก unit tests/build เท่านั้น

References:
- Plan ที่แก้: `docs/meta-business-ai/plan-fix-meta-ai-profile.md:3`
- Activation seam: `oho-api/src/utils/meta-business-ai.js:42-50,339-346`
- Meta author detection: `oho-webhook/src/controllers/facebook/meta-business-ai.ts:34-39`
- Focused API command: `npm test -- --runInBand --coverage=false src/services/contact/meta-business-ai/control-hooks.spec.js src/utils/meta-business-ai.spec.js src/utils/meta-business-ai-automation-guard.spec.js src/services/member-send-message/inbox/inbox.hooks.spec.js src/utils/meta-business-ai-stream.spec.js`
- Focused webhook command: `npm test -- --runInBand --forceExit --coverage=false __tests__/facebook-meta-business-ai.test.ts`
- Exact result: API `31 passed`; webhook `17 passed`; both builds passed

Verdict: แผนถูกปรับให้ปลอดภัยและแคบลงแล้ว แต่ implementation ยัง `blocked` จนกว่าจะมี activation/eligibility source และ real terminal replay verification
