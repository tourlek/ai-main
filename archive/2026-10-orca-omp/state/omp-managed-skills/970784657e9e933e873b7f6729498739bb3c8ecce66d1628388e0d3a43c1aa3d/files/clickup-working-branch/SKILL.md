---
name: clickup-working-branch
description: แตก working branch จากการ์ด ClickUp ใบแม่ ชื่อ prefix/oho-number-slug จาก master/main ที่ fetch สด push ขึ้น branch ตัวเองเท่านั้น
---

# Working Branch from ClickUp Card

แตก working branch จากการ์ด ClickUp ใบแม่ (เช่น OHO-3446) branch เดียวต่อการ์ด ไม่แตกตาม subcard

## When

ใช้เมื่อ user สั่งแตก branch จากการ์ด (`แตก branch ให้หน่อย`, `เปิด branch OHO-xxxx`, URL `app.clickup.com/t/...`) หรือก่อนเริ่มงานบนการ์ดที่ยังไม่มี branch

## Inputs

- Card ref: `OHO-xxxx` หรือ URL `app.clickup.com/t/<task-id>` / `app.clickup.com/t/<team-id>/OHO-xxxx`
- Target repo: ถามเมื่อกำกวม (เช่น `oho-web-app`, `oho-api`) ห้ามเดาข้าม repo เอง
- Prefix: `feature` (default) / `fix` / `hotfix` / `chore` ถามเมื่อไม่ชัดจากชื่อการ์ด (`[Dev FE]` ไม่ใช่ prefix)
- Slug: ท่อนท้ายชื่อ branch ถามเมื่อชื่อการ์ดเป็นไทยล้วนหรือยาวเกิน

## Procedure

1. **Resolve card** — token อยู่ใน `~/.config/clickup/env` (`export CLICKUP_TOKEN=...`) ห้าม print token เช็คแค่ `${#CLICKUP_TOKEN}`:
   ```bash
   source ~/.config/clickup/env 2>/dev/null
   curl -s -H "Authorization: $CLICKUP_TOKEN" \
     "https://api.clickup.com/api/v2/task/OHO-3446?custom_task_ids=true&team_id=90182460598" \
     | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['id'], d['custom_id'], d['name'])"
   ```
   `app.clickup.com` เปิดผ่าน `read` ไม่ได้ (login wall) ต้องใช้ API เสมอ
2. **Branch name** — ฟอร์แมต `<prefix>/oho-<number>-<slug>` (oho ตัวเล็กตาม convention เดิม เช่น `feature/oho-1171-add-metadata-of-message-send-to-streamchat`):
   - `<number>` จาก `custom_id` (OHO-3446 → `oho-3446`)
   - `<slug>` จากชื่อการ์ด: lowercase, `a-z0-9` เท่านั้น, ช่องว่าง/ขีด → `-`, ตัดไทยทิ้ง, ยาวสุด ~5 คำ (เช่น `Refactor API เส้น channel` → `channel`)
   - ชื่อไทยล้วนจนเหลือ slug ว่าง → ถาม user ก่อน ไม่เดาเอง
3. **Detect base** — ห้าม hardcode `master`:
   ```bash
   git -C <repo> symbolic-ref refs/remotes/origin/HEAD 2>/dev/null # → origin/master หรือ origin/main
   ```
   fallback `master` (ยกเว้น `oho-developer-api` ที่ default เป็น `main`)
4. **Preflight** ใน target repo ก่อนแตก:
   ```bash
   git -C <repo> status -sb | head -5
   git -C <repo> branch --show-current
   ```
   tree สกปรก → ถามก่อน (stash / commit / เปลี่ยน worktree) ห้ามทิ้งงาน user เงียบๆ; branch ชื่อซ้ำมีอยู่แล้ว → ถามว่าจะ checkout ต่อหรือตั้งชื่อใหม่
5. **Create from base** — fetch ก่อนเสมอ แตกจาก base ที่สด ไม่ใช่จาก branch ปัจจุบัน:
   ```bash
   git -C <repo> fetch origin <base>
   git -C <repo> checkout -b <new-branch> origin/<base>
   ```
   ห้ามแตกจาก subcard/branch ค้าง (`checkout -b` จาก branch ปัจจุบันโดยไม่ระบุ base คือผิด)
6. **Parallel sessions** — ถ้า user ขอทำขนาน ใช้ worktree แทน checkout ตรง:
   ```bash
   git -C <repo> worktree add .claude-worktrees/<slug> -b <new-branch> origin/<base>
   ```
7. **Push** — ครั้งแรกตั้ง upstream ไป branch ตัวเองเท่านั้น ห้ามแตะ base (repo rule: never push `master`/`main` ตรง):
   ```bash
   git -C <repo> push -u origin <new-branch>
   ```
   verify: `git branch --show-current` ต้องเป็น branch ใหม่ ไม่ใช่ base

## Verify before reply

- `git -C <repo> branch --show-current` ตรงชื่อใหม่
- `git -C <repo> log --oneline origin/<base>..HEAD` ว่าง (ยังไม่มี commit หลงจาก branch เก่า)
- `git -C <repo> status -sb` สะอาด

## Reply

บรรทัดเดียว: repo + ชื่อ branch + base + ลิงก์การ์ด ไม่ต้องเล่า step

## Non-goals

- ไม่แตก branch ต่อ subcard (OHO-3468…3473 ทำงานบน branch การ์ดแม่เดียวกัน)
- ไม่ commit/push โค้ด ไม่เปิด MR ไม่ยุ่ง `time_estimate`/body การ์ด (งานของ `clickup-subtask-breakdown`)
