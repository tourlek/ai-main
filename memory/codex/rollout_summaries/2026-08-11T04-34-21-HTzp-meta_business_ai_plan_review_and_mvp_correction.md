thread_id: 019fef19-a05e-7773-9301-06b8ab7c9e37
updated_at: 2026-08-11T14:18:06+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/11/rollout-2026-08-11T11-34-21-019fef19-a05e-7773-9301-06b8ab7c9e37.jsonl
cwd: /Users/tualek/ohochat

# Meta Business AI plan review and implementation correction

Rollout context: งานใน `/Users/tualek/ohochat` ตรวจและปรับแผน `docs/meta-business-ai/plan-fix-meta-ai-profile.md` พร้อม implementation ใน `oho-api`/`oho-webhook` โดยต้อง preserve dirty worktree และไม่ commit/push/stage.

## Task 1: Review and rewrite Meta Business AI plan

Outcome: partial

Preference signals:
- ผู้ใช้แก้ชัดเจนว่า `ai_generated` “เป็น field ที่ webhook จาก Meta ส่งมา ถ้า Meta AI เป็นคนตอบ” -> ห้ามเขียนว่า OHO สร้างหรือ infer field นี้เอง; ต้อง preserve strict `message.ai_generated === true` และใช้เป็น author identity เท่านั้น ไม่ใช่ activation หรือ thread ownership.
- ผู้ใช้ต้องการ plan ที่ “พร้อมทำงาน” -> plan ควรระบุ scope, non-goals, file boundaries, phase order, tests, rollout, rollback และแยก local validation ออกจาก runtime/UAT verification.

Key steps:
- Review เดิมพบว่าแผนกว้างเกินไป โดยรวม schema/state-machine, Redis, Cloud Tasks, Stream provisioning, TypeScript conversion และ webhook cleanup ใน migration เดียว.
- Trace source จริงพบว่า `ai_generated` มากับ Meta webhook ทั้ง `messaging` และ `standby`; `app_id`, `metadata`, `hop_context` หรือ channel ไม่ใช่ตัวแทน author ที่เชื่อถือได้.
- ปรับ plan ให้เน้น explicit per-Facebook-channel `meta_business_ai_enabled`, strict incoming `ai_generated`, lazy Stream identity `@meta-ai` พร้อม `@inbox` fallback, standby persistence-before-block และ existing take/return controls.
- ตัด `meta_ai_profile`, cold provisioning/backfill, Redis/Cloud Tasks state migration, send-first/HUMAN_AGENT fallback และ UI ออกจาก scope.

Failures and how to do differently:
- แผนเดิมสรุป performance improvement และ schema migration โดยยังไม่มี baseline หรือ concurrency contract; future plans ต้องแยก correctness migration จาก optimization และไม่เรียกพร้อม production จนกว่าจะมี runtime evidence.
- การตีความ `ai_generated` ต้องไม่สับสนกับ authority: AI-authored message เป็นหลักฐานผู้เขียนข้อความ ไม่ใช่หลักฐานว่า AI ถือ thread.

Reusable knowledge:
- Captured payloads แสดง AI echo มี `message.ai_generated: true`; Business Suite human echo ใช้ app ID เดียวกันได้แต่ไม่มี field นี้.
- `standby` เป็นสัญญาณว่า app อื่นอาจถือ delivery ไม่ใช่หลักฐานว่าเป็น Meta Business AI.
- Stream sender contract: AI ใช้ `${businessId}@meta-ai`; ถ้า provisioning ล้มเหลว fallback เป็น `${businessId}@inbox` แต่ต้องคง `ai_generated: true`.

References:
- Plan: `/Users/tualek/ohochat/docs/meta-business-ai/plan-fix-meta-ai-profile.md`
- Payload evidence: `docs/meta-business-ai/meta-biz-ai-payload-samples.md:6-19,45-55`
- Implemented-plan status later recorded local tests as API 10 suites/50 tests and webhook 5 suites/46 tests, but live/UAT remained unverified.

## Task 2: Implement approved MVP corrections and review result

Outcome: partial

Preference signals:
- ผู้ใช้/approved contract ต้องการแก้เฉพาะ Facebook Meta Business AI, preserve existing dirty changes, no commit/push/reset/revert/delete/stage, และไม่แตะ `oho-web-app`.
- ผู้ใช้ต้องการ evidence จริง ไม่ถือ focused tests หรือ HTTP 200 เป็น runtime/canary proof.

Key steps:
- เพิ่ม explicit channel activation `meta_business_ai_enabled` default false และส่ง context ผ่าน webhook → contact upsert → automation/control paths.
- ใช้ strict `ai_generated === true`, ย้าย external-app whitelist check หลัง Facebook/page/contact validation และ allow เฉพาะ narrow AI exception.
- ทำ standby message persistence ก่อน suppress chatbot/ARP/greeting/fallback/referral/scheduled automation.
- คง existing Accept/Close control flow, tenant-scope Graph calls, persist authority only after Graph success, และเก็บ lazy Stream ensure/fallback.
- เพิ่ม/restore canonical event, dedup lease claim/complete/release/retry tests; focused webhook tests ผ่าน 3 suites/24 tests ในรอบตรวจท้าย และ API guard/control ผ่าน 2 suites/13 tests. `git diff --check` ผ่านทั้งสอง repo.

Failures and how to do differently:
- Final standards review ยังพบ blocker ก่อน merge: disabled channels ยังมี traffic-driven contact activation write; authority persistence/evidence logic ซ้ำใน `upsert.hooks.js` และ `upsert.class.js`; Redis lease 300 วินาทีไม่มี renewal; `checkDuplicate()` และ deprecated Redis methods ยัง dead; bulk broadcast มี `skipped_authority_count` แต่ raw sender ไม่มี guard/producer.
- `upsert.class.spec.js` รันไม่ได้บน Node 24 เพราะ dependency `config` เรียก `Utils.isRegExp`; ต้องแยก environment failure จาก code verification และไม่อ้าง suite นี้ว่าผ่าน.
- Redis focused tests ใช้ mock และพบ warning/connection failure local (`EPERM` localhost:6379); ยังไม่มี real Redis CAS/expiry integration evidence.
- ต้องแก้โดยเอา contact snapshot write ที่ไม่จำเป็นออก, รวม authority updater เป็น implementation เดียว, กำหนด lease renewal/max processing policy, ตัด dead dedup/broadcast surface หรือประกาศ scope ชัดเจน แล้ว rerun tests.

Reusable knowledge:
- Automation guard อ่าน Mongo primary แบบ tenant-scoped และ fail-closed เมื่อ contact หายหรือ query error; `if (!guard.blocked) return context` ไม่ bypass เพราะ query error จะ throw ก่อน.
- Campaign/broadcast raw sender ยังอยู่นอก per-contact guard และมี batch snapshot race; ต้อง explicitly gate campaigns หรือเพิ่ม send-time authority check ก่อน production.
- Focused tests/builds ไม่ใช่หลักฐานของ live Meta replay, terminal Mongo/Stream state, Graph take/return, canary, rollback หรือ performance.

References:
- `oho-api/src/services/contact/upsert/upsert.hooks.js:184-390` — duplicated activation/authority/evidence persistence.
- `oho-api/src/services/contact/upsert/upsert.class.js:51-248` — duplicate-create fallback duplication.
- `oho-webhook/src/controllers/facebook/block.ts:289-321` and `src/services/redis.service.ts:224-303` — fixed 300s lease and token CAS.
- `oho-api/src/services/broadcast/send-message/facebook/facebook.class.js:48-72,130-141` — raw bulk send and dead `skipped_authority_count`.
- Final verdict from review: `rework แล้วค่อย ship`; no runtime/UAT approval.
