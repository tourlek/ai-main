---
name: project-react-migration-pilot
description: React migration ทำ micro frontend embed ก่อน — pilot อยู่ที่ worktree oho-web-app-react-embed (branch test/react-embed-pilot) + React app oho-web-app-react-v2
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a527b12-296d-4b11-be68-3b28cde7ea06
---

การ migrate `oho-web-app` → React (plan: `oho-web-app-react-v2-plan.md`) เริ่มด้วย **micro frontend embed** (Phase 0.5): เอาหน้า React แปะใน Nuxt2 ผ่าน iframe same-origin ให้ผู้ใช้ไม่รู้สึกว่าเปลี่ยนเว็บ — Nuxt ถือ layout/sidebar, React render เฉพาะ content แล้วค่อย path-based cutover ทีหลัง

Pilot มี 2 ฝั่ง (ชื่อ dir กับ branch ไม่ตรงกัน ระวังหาไม่เจอ):
- Nuxt host: worktree `/Users/tualek/ohochat/oho-web-app-react-embed` บน branch `test/react-embed-pilot` — `api/react-proxy.js` (serverMiddleware proxy `/business/:bizId/broadcast-test*` → Vite :5173), menu item ใน `store/modules/menu.js`, stub page `broadcast-test.vue` (force reload)
- React remote: `/Users/tualek/ohochat/oho-web-app-react-v2/` (Vite + React 19 + TanStack + Zustand)

หน้าแรกที่ embed คือ broadcast (path ทดลอง `/broadcast-test` แยกจาก `/broadcast` จริง)
