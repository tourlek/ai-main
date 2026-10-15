---
name: worktree-base-master
description: สร้าง worktree ใหม่ต้องแตกจาก origin/master เสมอ ไม่ใช่ develop หรือ staging branch
metadata:
  node_type: memory
  type: feedback
  originSessionId: ffe639f5-a338-480a-bbcd-1f23455d1609
  modified: 2026-10-14T07:53:56.231Z
---

เวลาสร้าง worktree ใหม่ (orca CLI หรือ git) ให้แตกจาก `origin/master` เสมอ ใช้ `--base-branch origin/master` และ fetch ก่อน

**Why:** user แก้ตรง ๆ หลังผมเลือก `origin/develop` เองตอนสร้าง worktree ของ OHO-8384 (2026-10-14)

**How to apply:** ไม่ต้องถาม base branch อีก ใช้ master ทุกครั้ง; ต้อง `push -u` ให้ branch track ตัวเอง ดู [[feedback_worktree_branch_self_tracking]] และห้าม push ลง master ดู [[feedback_never_push_master]]
