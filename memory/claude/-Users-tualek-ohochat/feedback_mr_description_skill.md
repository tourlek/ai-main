---
name: mr-description-use-skill-and-house-pattern
description: "Before creating/updating any GitLab MR, invoke the gitlab-mr-description skill and copy the Thai house pattern from the user's recent merged MRs"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 46e58185-1b26-4082-b35a-20816e38e388
  modified: 2026-10-19T03:33:17.421Z
---

ก่อนเปิดหรืออัปเดต MR ทุกครั้งต้องเรียก skill `gitlab-mr-description` และดู MR ที่ merge แล้วของ user (`glab api "projects/oho%2Foho-api/merge_requests?scope=created_by_me&state=merged&per_page=3"`) แล้วเขียนตาม pattern เดียวกัน: ภาษาไทย, หัวข้อ สรุป / ClickUp / สิ่งที่เปลี่ยน / การทดสอบ / ความเสี่ยง / Rollout / หมายเหตุสำหรับ reviewer, บรรทัด "สถานะ: ..." ท้ายสรุป, ไม่มี footer AI.

**Why:** OHO-7084 !1316 ผมเขียน description อังกฤษเอง ข้ามหัวข้อบ้าน user ต้องทักและให้แก้ทีหลัง

**How to apply:** อย่าเขียน mr.md จากความจำ เรียก skill ก่อนร่าง; ถ้า draft ให้ระบุในหัวข้อสถานะ. guard ให้ `glab mr create/update` ต้องมีคำสั่ง MR ชัดๆ ในข้อความล่าสุดของ user; เขียน mr.md ด้วย Write แยกจากคำสั่ง glab (heredoc ใน command เดียวกันจะไม่ถูกรันถ้า guard บล็อก). Related: [[feedback_mr_link_only]].
