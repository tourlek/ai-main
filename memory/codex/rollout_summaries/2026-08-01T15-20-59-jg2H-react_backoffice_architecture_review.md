thread_id: 019fbdea-0a3f-7ed2-a3b3-fddd0046094f
updated_at: 2026-08-01T15:23:11+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T22-20-59-019fbdea-0a3f-7ed2-a3b3-fddd0046094f.jsonl
cwd: /Users/tualek/ohochat/backoffice-v2

# รีวิวโครงสร้าง React migration แบบ time-box

Rollout context: ผู้ใช้ขอ outsider review ของ `/Users/tualek/ohochat/backoffice-v2` เทียบกับแผน migration โดยให้ sample เฉพาะ `payment`, `business`, routes, ESLint และ query keys; ไม่ต้อง rerun baseline 696 tests เพราะผู้ใช้ระบุว่า test/lint/typecheck/format/build ผ่านแล้ว

## Task 1: รีวิว architecture และความพร้อม scale

Outcome: success

Preference signals:
- ผู้ใช้กำหนดชัดว่า “ตอบ 5 ข้อ สั้นๆ ตรงประเด็น ห้ามเขียนยาว” และล็อก scope เป็น structure review ไม่ใช่ parity audit -> งาน review ควรยึด time-box/sample-based และไม่ audit ทุกไฟล์
- ผู้ใช้ระบุว่า legacy เป็น reference เฉพาะ design parity, backend/URL contract ห้ามเปลี่ยน, quirk เดิมแก้ได้แต่ต้องจด -> ในการรีวิวควรแยก architectural finding ออกจาก contract/parity assumptions

Key steps:
- อ่าน plan sections 6, 8, 9 และตรวจ ESLint feature-isolation rules
- Sampled `features/payment`, `features/business`, route files, barrels และ query-key definitions
- พบ layer separation จริงในเส้นหลัก: routes บาง, pages ใช้ hooks, API แยกจาก query orchestration, pure domain logic อยู่ใน `lib`
- ตรวจพบว่า component ไม่ได้ render-only ทุกจุด: `ChannelTable` และ `PaymentDialog` เรียก `useQuery`/raw API เอง; `PaymentDetailPage` ทำ validation และ mutation orchestration
- ตรวจขนาด barrel: `business/index.ts` 258 บรรทัด, `payment/index.ts` 232 บรรทัด; component ใหญ่ เช่น `PaymentDialog` 659, `PaymentDetailPage` 664, `BusinessDetailPage` 632 บรรทัด

Failures and how to do differently:
- Git metadata ใช้ไม่ได้จาก cwd ที่ไม่ใช่ git repository; ไม่ควรใช้ git status/log เป็นหลักฐาน architecture ใน repo snapshot นี้
- shell glob บางคำสั่งพัง (`zsh: no matches found`, unmatched quote) และ output หลายชุดถูก truncate; ควรใช้ quoted globs/แยกคำสั่งและเก็บเฉพาะหลักฐานที่จำเป็น

Reusable knowledge:
- โครงสร้าง feature-based เหมาะกับ admin CRUD ขนาดนี้ และไม่จำเป็นต้องรื้อ architecture
- `shared/lib` = I/O/external-bound code; `shared/utils` = pure functions; feature-level ใช้ `lib/` เดียว ถือว่าตัดสินใจชัดและลดความสับสน
- Query keys ไม่มี namespace collision ที่เห็นจาก sample แต่ convention กระจายหลายที่: payment อยู่ `hooks/query-keys.ts`, business อยู่ `lib/query-keys.ts` และ `api/*`, JERA/external-message อยู่ `api/query-keys.ts`
- ESLint บังคับ cross-feature barrel import ได้สำหรับ alias paths แต่ตรวจ relative cross-feature imports ที่ไต่ directory ไม่ได้ และยังไม่มี circular-dependency/dependency-direction gate
- `business` เป็น composition hub ที่ import JERA, payment และ sales-order; หาก feature เหล่านี้ย้อน import business จะเสี่ยง circular dependency
- Public barrels ใหญ่เกินไป เพิ่ม coupling และโอกาส cycle; ควร export เฉพาะ route/cross-feature consumers ที่ใช้จริง
- Verdict จาก review: `fix-then-ship` สำหรับทีมหลายคน โดยแก้ 4 เรื่องก่อน: ย้าย I/O จาก `ChannelTable`/`PaymentDialog` ไป hooks, กำหนดตำแหน่ง query-key factory เดียว, ลด barrels, เพิ่ม CI ตรวจ cycle และ relative cross-feature imports

References:
- Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`, sections 6.1-6.3, 6.2 `lib` vs `utils`, 8, 9
- `src/features/business/components/ChannelTable.tsx:123-133` — component สร้าง `useQuery` และเรียก `getLineWebhook`
- `src/features/payment/components/PaymentDialog.tsx:131-151` — component เรียก `useQuery` และ `getSubscriptionPlans`/channel-fee API
- `src/features/payment/components/PaymentDetailPage.tsx:157-184` — validation และ mutation orchestration ใน component
- `src/app/routes/_authenticated/business.tsx:26-50` — route บางและส่ง URL state เข้า feature
- `src/features/business/components/BusinessPage.tsx:98-138` — page ใช้ hooks/pure helpers
- `eslint.config.js:235-238` — relative cross-feature imports ไม่สามารถตรวจด้วย glob ปัจจุบัน
- `src/features/business/index.ts` 258 lines; `src/features/payment/index.ts` 232 lines
- Baseline ที่ผู้ใช้ระบุ: 696 tests ผ่าน, lint/typecheck/format/build ผ่าน; agent ไม่ได้ rerun ภายใน time-box
