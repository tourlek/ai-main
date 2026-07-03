---
name: feedback_commit_no_coauthor
description: ไม่ใส่ Co-Authored-By trailer ใน commit message
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 36732e3b-7142-4b07-930d-5bab498a5c41
---

ไม่ต้องใส่ `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` ใน commit message ทุกครั้ง

**Why:** user ไม่ต้องการให้ระบุชื่อ Claude ใน git history

**How to apply:** ตัด trailer นี้ออกจาก commit message เสมอ ไม่ว่าจะ commit ไฟล์ไหนหรือ repo ไหน
