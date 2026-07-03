---
name: project-realtime-transport-split
description: Oho chat realtime ใช้ 3 transport แยกกัน — debug realtime/chat-list/notif ต้องรู้ว่าฟีเจอร์ไหนวิ่งช่องไหน
metadata: 
  node_type: memory
  type: project
  originSessionId: ed04f12f-d87d-4291-80c8-7146dd7b2098
---

Oho chat realtime แยกเป็น **3 transport อิสระ** (สำคัญตอน debug — อาการจะชี้ช่องที่ล่มได้ทันที):

- **ส่ง/รับข้อความ** → HTTP REST → `core-api--production`
- **chat list realtime + notification** → oho **socket.io** → `websocket--production` (Cloud Run, asia-southeast1) + Redis pub/sub adapter (`redis-core-api--production--2`, Memorystore BASIC). โค้ด client: `oho-web-app/store/modules/websocket.js` (`oho_socket`)
- **ข้อความในห้องแชท (in-room)** → **GetStream SDK ตรง** → `chat-proxy-singapore.stream-io-api.com` ไม่ผ่าน oho เลย โค้ด: `oho-web-app/components/Smartchat/Conversation.vue` (`new StreamChat()` → `connectUser()` → `channel.watch()`)

ดังนั้นถ้า "ส่งรับได้ + เข้าห้องอัปเดตได้ แต่ chat list ไม่ขยับ + ไม่มี noti" = **oho socket.io push ล่มอย่างเดียว** (core-api กับ GetStream ปกติ) mobile error "ไม่พบการเชื่อมต่ออินเทอร์เน็ต" = detect oho socket หลุด ไม่ใช่เน็ตผู้ใช้

จุดเปราะ server-side: `oho-api/src/socket.io.js:129-131` — `subClient = pubClient.duplicate()` ไม่มี error/reconnect handler → pub/sub หลุดแบบเงียบ ไม่มี log/metric ("connected but deaf"). ยังใช้ `socket.io-redis@6` (deprecated) + `redis@3`. Incident 2026-05-29 (chat list ล่ม noon–5pm ICT) สอบแล้ว server/Redis box-metrics เขียวหมด root cause point-of-failure ภายใน socket.io push ยังระบุไม่ได้จาก server telemetry — ต้องดู client RUM (Grafana Faro `oho-web-app/plugins/grafana-faro.client.js`). รายงานเต็มที่ `ohochat/incident-websocket-2026-05-29.{md,html}`
