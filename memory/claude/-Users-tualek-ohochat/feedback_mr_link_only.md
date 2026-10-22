---
name: mr-link-only-when-attaching
description: เวลา user สั่งเอา MR ไปใส่ที่ไหน (ClickUp comment ฯลฯ) ให้แนบลิงก์ MR เฉยๆ ไม่ต้องเขียนคำอธิบายเพิ่ม และไม่ต้องเสนอร่าง Slack
metadata:
  node_type: memory
  type: feedback
  originSessionId: bf5426a2-2425-453d-ba95-d8d4b51a2cec
  modified: 2026-10-16T07:14:37.428Z
---

เมื่อ user สั่งให้เอา MR ไปใส่ที่ไหน (เช่น comment ใน card ClickUp) ให้แนบลิงก์ MR อย่างเดียว

**Why:** ตอน OHO-1902 ผม comment พร้อมคำอธิบายและรายการ "ยังไม่ได้ตรวจ" ยาว user บอกว่าแนบลิงก์เฉยๆ ก็พอ และปฏิเสธการร่าง Slack

**How to apply:** ไม่ต่อข้อความอื่นท้ายลิงก์ ไม่ถามเรื่องร่าง Slack เว้นแต่ user ขอเอง ดู [[reference_slack_dev_mr_format]] เมื่อ user ขอร่างเท่านั้น
