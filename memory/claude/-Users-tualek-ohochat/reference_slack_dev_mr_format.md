---
name: slack-dev-merge-request-format
description: "Message format for asking review in Slack #dev-merge-request (header, card, link lines, @Tong mention)"
metadata:
  node_type: memory
  type: reference
  originSessionId: 1bafac66-a1a6-4d47-aa57-3c56239c8ff4
  modified: 2026-10-15T07:53:42.856Z
---

Format ที่ห้อง dev-merge-request ใช้ (user ยืนยันแล้ว):

```
[repo1, repo2]: <conventional title> (OHO-xxxx)
card: https://app.clickup.com/t/90182460598/OHO-xxxx
link: https://gitlab.boonmeelab.com/oho/<repo>/-/merge_requests/<n>
@Tong (Sr. Fullstack) <หมายเหตุสั้นๆ ถ้ามี>
```

- หลาย repo: `link [webhook]:` / `link [api]:` แยกบรรทัด
- header ใช้ชื่อ repo ใน `[ ]` (เช่น core-api, oho-webhook, oho-api, web-socket)
- ถ้า user สั่ง ไม่ใส่ MR ของ repo ไหน (เช่น web-app) ก็ตัดทั้ง header และ link

**Why:** user ให้ใช้ pattern เดียวกับข้อความเดิมในห้อง ไม่ใช่ format ที่ AI คิดเอง
**How to apply:** ร่างเป็น draft ให้ user ก่อน ห้ามส่งเอง; Slack connector ใน session อาจยังไม่ authorize
