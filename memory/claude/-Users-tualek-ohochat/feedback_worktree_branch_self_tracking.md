---
name: feedback_worktree_branch_self_tracking
description: สร้าง working branch จาก master ต้องตั้ง upstream ให้ track branch ตัวเอง (push -u) ไม่ใช่ origin/master
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e09208f3-facf-4303-8b26-c1c18904dc1b
  modified: 2026-07-24T04:31:12.204Z
---

เวลาสั่งสร้าง working branch แตกจาก master แล้วทำ worktree: upstream/ref-tracking ของ branch ต้องชี้ที่ **ตัว working branch เองบน origin** ไม่ใช่ `origin/master`.

**Why:** repo ohochat (oho-web-app, oho-api) เปิด `autoSetupMerge` — `git branch <br> origin/master` จะ auto-track `origin/master` ให้ ซึ่งผิด. ถ้าปล่อยไว้ คำสั่ง default-target (`git push`, `pull`, `--set-upstream-to`) จะเผลอยิงไป/ดึงจาก master (เชื่อมโยง [[project_unread_migration_ordering]] และ lesson git implicit-target).

**How to apply:** ต่อ repo — `git fetch origin master` → `git branch <br> origin/master` → `git push -u origin <br>` (ทับ upstream ให้เป็น origin/<br>) → `git worktree add .claude-worktrees/<slug> <br>` → verify `git -C <wt> rev-parse --abbrev-ref HEAD@{upstream}` = `origin/<br>`. worktree วางใต้ `.claude-worktrees/` (มีอยู่แล้วทั้ง 2 repo). ใช้ explicit branch arg เสมอ + เช็ค `git branch --show-current` ก่อนเขียน ref เพราะ user รันหลาย AI tool สลับ branch.

**User ยืนยัน (OHO-1272 setup):** push -u ให้ branch ใหม่ track ตัวเองบน origin = โอเค, คง remote branch ไว้ได้. `git push -u origin <newbranch>` สร้าง ref `origin/<newbranch>` แยกที่ commit เดียวกับ master — **ไม่แตะ/ไม่ขยับ master**. ถ้า user อยากได้ local-only จริงๆ ใช้ `git branch --no-track` (ไม่มี upstream, ไม่ต้อง push) แทน.
