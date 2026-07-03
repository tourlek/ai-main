---
name: feedback-stay-on-named-cause
description: ตอน investigate incident ที่มีหลายสาเหตุ ให้ทำเฉพาะสาเหตุที่ user ระบุ ห้าม implement fix ของสาเหตุอื่นที่เจอระหว่างทาง
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8fbb4fc0-10ad-4197-bbcc-00e564b499a4
---

ระหว่าง investigate incident webhook (2026-07) user สั่ง "โฟกัสสาเหตุที่ 1" (core-api errors) แต่ Claude ไป implement fix ของสาเหตุอื่น (LINE dedup, ARP timeout) ที่เจอระหว่างทาง — user ถาม "แต่ฉันอยากแก้สาเหตุ 1 ทำไมทำข้อ 4 ละ" แล้วภายหลัง **ตั้งใจ discard งานนั้นทิ้งทั้งหมด** ("ตั้งใจ discard เพราะไม่ใช่ scope ฉัน")

**Why:** งานนอก scope ถึงจะถูกต้องทางเทคนิคก็เป็นงานเสียเปล่า — user แบ่ง scope กับทีม สาเหตุอื่นอาจเป็นของคนอื่น

**How to apply:** เจอบั๊กอื่นระหว่าง investigate ให้บันทึกลงรายงาน/แจ้งเฉยๆ พอ ห้ามลงมือแก้จนกว่า user สั่งชัดเจนว่าสาเหตุนั้นอยู่ใน scope ของเขา
