---
name: feedback-ask-when-spec-inaccessible
description: "When a ClickUp card or external spec can't be accessed, tell the user upfront before guessing API details"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3a9e0f27-1f7e-43d4-8d9f-0316fa3ebdbf
---

ถ้าเข้า ClickUp card / API spec ไม่ได้ ให้บอกผู้ใช้ก่อนว่าเข้าไม่ถึง spec ส่วนใด แทนที่จะเดา body format, URL path, หรือ field mapping เอง

**Why:** ครั้งที่เกิดขึ้น: card OHO-643 — เข้า ClickUp ไม่ได้รอบแรก แล้วเดา platform_id = channel._id และ URL path ผิด (ขาด /omnichannel/api/v1/) เพราะไม่ได้เห็น curl spec จริง ผู้ใช้ต้องมาแก้ทีหลัง

**How to apply:** เมื่อ ClickUp, Notion, หรือ external spec อ่านไม่ได้ → บอก user ว่า "เข้าไม่ถึง spec ส่วน X, ช่วย paste curl / body format มาได้ไหม" ก่อน implement
