---
name: feedback_never_push_master
description: ห้าม push ไป master branch ทุก repo ใน ohochat โดยเด็ดขาด ไม่มีข้อยกเว้น
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 8107f848-61e8-4e40-a020-9c0cd6d98125
---

ห้าม `git push origin master` หรือ push ใด ๆ ที่ target master branch ทุก repo ใน `/Users/tualek/ohochat/` โดยเด็ดขาด

**Why:** user เคยเผลอให้ Claude commit ลง main repo ที่ checked out อยู่บน master แล้ว push ขึ้น origin/master โดยไม่ตั้งใจ ทำให้ 43 commits ของ feature branch ขึ้น master เหตุการณ์นี้เกิด June 2026

**How to apply:**
- ถ้าจะ commit ให้ตรวจก่อนเสมอว่า branch ปัจจุบันไม่ใช่ master (`git branch --show-current`)
- ถ้าพบว่า repo checked out อยู่บน master ให้หยุดและแจ้ง user ก่อน อย่า commit
- ห้ามแนะนำหรือรัน `git push origin master` ไม่ว่ากรณีใด รวมถึง force-push ต้องให้ user confirm เสมอ
- ใช้ worktree หรือ feature branch เสมอสำหรับงาน development
