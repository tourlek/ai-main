# @local/dsh-guard-bridge

ก่อน DSH รัน tool `bash` (และ `clickup_*`, `create_worktree`) ปลั๊กอินนี้เรียก `~/ai-main/core/hooks/guard.sh` (ตัวเดียวกับที่ `~/.claude/hooks/guard.sh` symlink ไป) แล้วแปลงคำตอบเป็น decision ของ DSH

| guard.sh | DSH |
|---|---|
| เงียบ / allow | ผ่าน (`next()`) |
| deny "never allowed" | `deny` |
| deny "needs the user's explicit" / "needs a preview" / "must branch from origin/master" | `ask` (การ์ดขออนุมัติ) |
| deny อื่น ๆ | `deny` |
| guard พัง/timeout | `deny` เฉพาะ git push/commit, glab mr; นอกนั้นผ่าน |

ไม่ส่ง `transcript_path` จึงไม่มี "ข้อความล่าสุดของ user" กฎที่ต้องขออนุมัติ (รวมคำ `allow-worktree`) เลยกลายเป็นการ์ด ask ทุกครั้ง
`create_worktree` ถูกตรวจเป็น `git worktree add wt <base>`: `from` ที่เป็น `origin/master` ตรงตัวผ่านเงียบ, base อื่น (รวม HEAD) ได้การ์ด ask

ปิด: ตั้ง `enabled: false` ใน config ของ `guard-bridge` หรือลบแถวใน `cordis.patch.yml`
ทดสอบ: `node test.mjs`
