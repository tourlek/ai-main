thread_id: 019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd
updated_at: 2026-08-04T05:01:22+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/04/rollout-2026-08-04T11-50-48-019fcb1c-2b9b-7740-9cf8-6ca8be40c1cd.jsonl
cwd: /Users/tualek/ohochat

# สร้างแผนปรับ UI และ Dark Mode สำหรับ backoffice-v2 สำเร็จ

Rollout context: ผู้ใช้ขอ audit `backoffice-v2` เรื่อง UI design, layout, padding/margin และ dark mode พร้อมแผนละเอียดในไฟล์ Markdown โดยรอบนี้ไม่แก้ implementation

## Task 1: Audit UI และสร้าง implementation plan

Outcome: success

Preference signals:
- ผู้ใช้ขอให้ “ทำเป็น plan อย่างละเอียด” และ “สร้าง md plan มาเลย” พร้อมระบุให้รวม dark mode -> ในงานลักษณะนี้ควรส่งมอบเอกสารที่ลงมือทำต่อได้จริง ไม่ใช่เพียงรายการข้อสังเกต
- ผู้ใช้ต้องการตรวจความสวยงาม การจัดวาง padding/margin และ responsive จาก UI จริง -> ควรตรวจทั้ง source และ rendered UI ด้วย visual smoke check
- แผนต้องไม่แก้ implementation รอบนี้ -> ควรแยก audit/plan ออกจากการลงมือแก้โค้ดอย่างชัดเจน

Key steps:
- อ่าน Web Interface Guidelines ล่าสุดจาก Vercel และใช้เป็นเกณฑ์ด้าน accessibility, focus, forms, motion, typography, responsive layout และ dark mode
- ตรวจ source ของ `globals.css`, app shell, sidenav/submenu, shared UI primitives และหน้า business/payment/external-message/JERA/dashboard
- เปิด local Vite app และใช้ Playwright ตรวจ `/login` ที่ 1440×900 และ 390×844 รวมถึง `/business` ที่ 1440×900 และ 1024×768
- พบปัญหาหลักจาก visual check: business ที่ 1024px ถูกบีบจาก rail 64px + submenu 240px + main padding 40px, toolbar/filter hierarchy ไม่ชัด และ login มี title/padding ใหญ่บน mobile
- สร้าง `/Users/tualek/ohochat/backoffice-v2/ui-design-dark-mode-plan.md` ความยาวประมาณ 890 บรรทัด ครอบคลุม design foundation, semantic tokens, responsive shell, page-by-page migration, dark mode, phases, tests, risks และ acceptance criteria
- รัน Prettier check; ครั้งแรกไม่ผ่านเพราะ formatting จากไฟล์ใหม่ จากนั้นรัน `pnpm exec prettier --write` และตรวจซ้ำผ่าน

Failures and how to do differently:
- Authenticated visual routes ใช้ cookie จำลอง และ local API ตอบ `jwt malformed`; จึงยืนยันได้เฉพาะ shell, navigation, empty/loading และ layout ไม่ควรอ้างว่า data-driven behavior ผ่าน
- Playwright wrapper ต้องเรียกผ่าน `bash` เพราะเรียก script ตรง ๆ ได้ `Permission denied`
- ระหว่าง dev server มี process/session อื่นแก้ source หลายไฟล์พร้อมกัน; agent ไม่ได้แก้ไฟล์เหล่านั้น และ re-check timestamp/source ก่อนสรุป
- ยังไม่ได้รัน full lint/typecheck/test/build เพราะงานนี้เป็นการสร้าง plan และมี concurrent workspace changes

Reusable knowledge:
- ปัจจุบันมี light semantic tokens ใน `src/styles/globals.css:37-66` แต่ยังไม่มี `.dark`, `color-scheme`, `theme-color` หรือ pre-paint theme bootstrap
- `globals.css` ยังมี global heading sizing (`h1=40`, `h2=36`, `h3=24`) และ `div:focus { outline: none }`; แผนกำหนดให้ย้าย typography ไปตาม role และแก้ focus handling
- `AppLayout.tsx` ใช้ main padding `p-10` และ `SubMenu.tsx` ใช้ `w-60` ตายตัว; แผนกำหนด responsive shell และ collapsible/overlay submenu สำหรับ 1024–1279px
- หลาย feature ยังใช้ `bg-white`, `text-black-*`, `border-black-*`, hardcoded hex/rgba และ `transition-all`; ต้อง migrate ไป semantic surface/status/chart tokens ก่อนหรือระหว่างทำ dark mode
- แผนกำหนด theme 3 ค่า `light`, `dark`, `system`, ใช้ `localStorage` key `oho-backoffice-theme`, class `dark` บน `<html>`, `color-scheme`, meta theme-color และ default `light` สำหรับผู้ใช้เดิม
- แผนกำหนด shared patterns `PageShell`, `PageHeader`, `FilterPanel`, `ResultToolbar`, `DataTableShell` และ 8 implementation phases พร้อม commit boundaries

References:
- Plan: `/Users/tualek/ohochat/backoffice-v2/ui-design-dark-mode-plan.md`
- Source: `src/styles/globals.css`, `src/shared/components/layout/AppLayout.tsx`, `Sidenav.tsx`, `SubMenu.tsx`
- Key page: `src/features/business/components/BusinessPage.tsx`
- Visual artifacts: `output/playwright/login-desktop.png`, `login-mobile.png`, `business-desktop.png`, `business-1024.png`
- Exact verification: `pnpm exec prettier --check ui-design-dark-mode-plan.md` -> `All matched files use Prettier code style!`
- Limitation: local API error `jwt malformed`
