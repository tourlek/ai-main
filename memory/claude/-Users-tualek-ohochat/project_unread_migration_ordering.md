---
name: project-unread-migration-ordering
description: "unread/unresponded migration — flag ปิดตอน migrate เสมอ, ห้ามแตะ oho-api, ลำดับคือ migrate → เปิด flag → recap"
metadata: 
  node_type: memory
  type: project
  originSessionId: a5bb68ae-46ea-4cbb-849f-418902b975a9
  modified: 2026-07-21T10:46:10.922Z
---

การ rollout `unread_by` / `is_unresponded` ของ oho มีข้อจำกัดที่ user ล็อกไว้แล้ว ห้ามเสนอทางเลือกอื่นซ้ำ

- **flag ต้องปิดตอนรัน migration เสมอ** เปิดหลังรันเสร็จเท่านั้น (user ยืนยัน 3 ครั้ง)
- **ห้ามแก้ `oho-api`** งานทั้งหมดอยู่ใน `script-oho` — ข้อเสนอแยก write-prep flag ออกจาก public read flag ถูกปฏิเสธแล้ว
- ลำดับเป้าหมายคือ **migrate (flag ปิด) → เปิด flag ราย business → รัน recap** แล้วต้องได้สถานะถูกต้อง
- ห้ามเสนอ "เปิด flag ก่อนแล้วค่อย migrate" และห้ามรื้อ `catchup` mode ที่ถอดออกไปแล้วกลับมา

**Why:** เป็นการตัดสินใจเชิงธุรกิจ/ops ของ user ไม่ใช่ข้อจำกัดทางเทคนิค การเสนอสลับลำดับซ้ำทำให้เสียเวลาและ agent ไปวิเคราะห์ทางที่ถูกปฏิเสธแล้ว

**How to apply:** ออกแบบ recap ให้ซ่อมสถานะหลังเปิด flag ได้แทนการเลี่ยง decay ด้วยการสลับลำดับ ดู [[project-unread-by-refactor]] สำหรับบริบท incident เดิม

ห้ามรันอะไรที่ต่อ DB จนกว่า user จะสั่งชัดเจน — subagent เคยหลุดไปต่อ staging-4 มาแล้วหนึ่งครั้ง
