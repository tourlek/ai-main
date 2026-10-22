# @local/dsh-rtk-bridge

เขียนคำสั่ง bash ใหม่ด้วย engine ตัวเดียวกับที่ Claude Code ใช้ (`rtk hook claude`) ก่อน DSH spawn command — ทำให้ rule ใน `~/.agents/AGENTS.md` ("ใช้ rtk โดย default") เป็นจริงใน DSH โดยไม่ต้องพึ่ง hook ของ Claude Code ซึ่ง DSH ไม่มี

## ทำไมไม่ใช้ `tools/pre-execute`

เพราะ pre-execute เป็น gate ที่ตอบได้แค่ allow/deny/ask และ registry ส่ง `exec.arguments` แบบ `deepFreeze` มาให้ listener (`dsh-tools/lib/index.js` → `createExecution`) — แก้ command ไม่ได้ ปลั๊กอินนี้จึงแตะ seam ที่ command string กลายเป็น argv จริง คือ `shell.execute(spec)` ของ `@deepseek-ai/dsh-shell` (`dsh-bash-local` ใช้ `spec.command` สร้าง `bash -c`)

ทุก path ของ tool `bash` ผ่าน `ctx.shell.execute` ทั้ง foreground, `run_in_background` และ promote-on-timeout จึงครอบคลุมทั้งหมด

## พฤติกรรม

| กรณี | ผล |
|---|---|
| rtk ตอบ `updatedInput.command` | spawn คำสั่งที่เขียนใหม่ (เช่น `rtk git status`), field อื่นของ spec คงเดิม |
| rtk เงียบ (คำสั่งไม่คุ้ม rewrite) | รันตามเดิม |
| rtk ไม่มี / error / timeout / output เพี้ยน / workdir หาย | รันตามเดิม (fail-open) |

fail-open เป็นการตั้งใจ: bridge นี้เป็น optimisation ไม่ใช่ policy — ตัว deny/ask ยังเป็นของ `dsh-guard-bridge` (guard.sh) และไม่ถูกกระทบเพราะ rewrite เกิดหลัง guard ตัดสินไปแล้ว

rtk เองกันการ rewrite ซ้ำ: คำสั่งที่ขึ้นต้นด้วย `rtk` แล้วจะถูกปล่อยผ่าน (มี test ยืนยัน) ต้นทุนคือ subprocess ~35ms ต่อหนึ่ง bash call

## Config

```yaml
config: { rtkPath: rtk, timeoutMs: 1500 }
```

- `rtkPath` — รองรับ `~`; ค่าเริ่มต้น `rtk` (ผ่าน PATH ที่เติม `/opt/homebrew/bin` ให้เหมือน guard-bridge)
- `timeoutMs` — เพดานเวลารอ rtk ต่อคำสั่ง; เกินแล้วรันคำสั่งเดิม
- `enabled: false` — ปิดbridge (ไม่ wrap อะไรเลย)

ปิดชั่วคราวโดยไม่ deploy: ลบ `@local/dsh-rtk-bridge` ออกจาก `dsh.profile.bundles` ในprofile `package.json` แล้วรีสตาร์ท DSH

## ที่ยังไม่ปิด

- session log ยังบันทึก arguments ที่ model ส่งมา (คำสั่งเดิม) ไม่ใช่คำสั่งที่รันจริง — อ่าน log แล้วอย่าสับสนว่า `rtk ...` คือสิ่งที่ model เขียน
- job label ของ `run_in_background` ก็เป็นคำสั่งเดิมด้วยเหตุผลเดียวกัน
- `pwsh` ใช้ `ctx.shell` ตัวเดียวกัน จึงถูกส่งเข้า rtk ด้วย; rtk ปล่อยคำสั่งที่จำไม่ได้ผ่านอยู่แล้ว แต่ถ้าเจอปัญหาให้ปิด bridge
- service method ถูก wrap แบบ monkey patch (ไม่มี extension point สำหรับ rewrite argument ใน DSH 0.2.1-rc.2); ถ้า DSH เปลี่ยนชื่อ/รูป `execute(spec)` ต้องแก้ `index.js` ตาม — `test.mjs` จะจับได้ทันทีเพราะรันกับ shell stub

ทดสอบ: `node test.mjs` (ใช้ `rtk` จริงถ้าอยู่ใน PATH, ถ้าไม่มีจะ SKIP แล้วยังผ่านด้วย stub)
