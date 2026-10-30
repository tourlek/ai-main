# @local/dsh-session-title-tool

เพิ่ม tool `set_session_title` ให้ model เปลี่ยนชื่อ session ของตัวเอง (session ที่เรียกเท่านั้น ไม่รับ session id) ผ่าน `ctx.sessionTitle.rename` ของ DSH skill `clickup-card` ใช้ตั้งชื่อ `OHO-xxxx [<stage>] <card name>`

- title ถูก trim, ห้ามว่าง, ยาวไม่เกิน 120 ตัวอักษร (นับ code point)
- ชื่อที่ตั้งเป็น user-sourced จึง pin ไว้ automatic titling จะไม่ทับอีก
- ไม่มี dependency (ห้ามใส่ `@deepseek-ai/*` เพราะ copy ที่สองทำ tool call พังทั้ง profile)

ปิด: ตั้ง `enabled: false` ใน config ของแถว `session-title-tool` (patch row) หรือเอาออกจาก `dsh.profile.bundles`
ทดสอบ: `node test.mjs`
