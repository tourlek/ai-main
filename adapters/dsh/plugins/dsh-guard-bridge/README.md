# @local/dsh-guard-bridge

ก่อน DSH รัน tool `bash` (และ `clickup_*`) ปลั๊กอินนี้เรียก `~/ai-main/core/hooks/guard.sh` (ตัวเดียวกับที่ `~/.claude/hooks/guard.sh` symlink ไป) แล้วแปลงคำตอบเป็น decision ของ DSH

| guard.sh | DSH |
|---|---|
| เงียบ / allow | ผ่าน (`next()`) |
| deny "never allowed" / "must branch from origin/master" | `deny` |
| deny "needs the user's explicit" / "needs a preview" | `ask` (การ์ดขออนุมัติ) |
| deny อื่น ๆ | `deny` |
| guard พัง/timeout | `deny` เฉพาะ git push/commit, glab mr; นอกนั้นผ่าน |

ไม่ส่ง `transcript_path` จึงไม่มี "ข้อความล่าสุดของ user" กฎที่ต้องขออนุมัติเลยกลายเป็นการ์ด ask ทุกครั้ง

ปิด: ตั้ง `enabled: false` ใน config ของ `guard-bridge` หรือลบแถวใน `cordis.patch.yml`
ทดสอบ: `node test.mjs`
