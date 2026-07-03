---
name: feedback-no-coauthored
description: "ห้ามใส่ Co-Authored-By: Claude ใน commit message ทุก repo"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b9376a67-2ab7-4b83-bc48-e257e34887e5
---

ห้ามใส่ `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` ใน commit message ไม่ว่าจะ repo ไหน

**Why:** user บอกไว้แล้ว ไม่ต้องการให้มี attribution นี้ใน git history

**How to apply:** ตอน commit ให้ใช้แค่ prefix + subject (+ body ถ้าจำเป็น) เท่านั้น ไม่ต้อง append Co-Authored-By ต่อท้าย
