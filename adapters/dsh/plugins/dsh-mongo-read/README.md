# @local/dsh-mongo-read

เพิ่ม tool `mongo_read` ให้ agent อ่าน MongoDB ได้แบบ read-only โดย secret มาจาก `bwsr` ทาง env ของ child process เท่านั้น

- op ที่อนุญาต: `find`, `countDocuments`, `aggregate` — op อื่นถูก reject ก่อน spawn
- `$out` / `$merge` ถูกบล็อกที่ความลึกใดก็ได้ของ pipeline (ไล่เข้า `$facet`, `$lookup.pipeline`, `$unionWith`, accumulator expression) error บอก path ที่เจอ
- ทุกครั้งใส่ `limit` (default 20, cap 200) และ `maxTimeMS` (default 5000, cap 15000) ให้เอง ค่าที่เกิน cap ถูก clamp แล้วบอกใน `note`; `aggregate` ต่อ `$limit` ท้าย pipeline ให้ และปิด `allowDiskUse` เพื่อให้ pipeline หนัก fail เร็ว ไม่ไป spill disk บน prod
- `find` เรียกตาม signature ของ mongosh 2.x คือ `find(query, projection, options)` — `limit`/`batchSize`/`maxTimeMS`/`sort` อยู่ใน argument ที่สาม (เคยพลาดจุดนี้ทำให้ไม่ได้ limit และได้แค่ `_id`)
- ผลลัพธ์ถูก emit ด้วย `EJSON.stringify(..., { relaxed: true })` → `ObjectId` มาเป็น `{"$oid": "..."}`, `Date` เป็น `{"$date": "..."}` เอาไปใช้เป็น filter ต่อได้
- output ถูกตัดตาม byte cap (default 24 KiB) แล้วคืน `truncated: true` + `dropped` + `note`; `bytes` คือขนาดจริงของ payload ที่ส่งเข้า model

## secret ไม่เคยอยู่ใน process นี้

1. spawn `bwsr -- '<command>'` (ไม่ผ่าน shell; `spawn` + argv array, `detached` เพื่อให้ kill ได้ทั้ง process group)
2. `bwsr` ฉีด `MONGO_URI_STAGING` / `MONGO_URI_UAT` / `MONGO_URI_PROD` เป็น env ของ child (allowlist ตายตัว)
3. child คือ `mongosh --nodb --quiet --norc --file '<runner.js>'` — runner อ่าน URI จาก `process.env[job.uriEnv]` เอง

command line จึงมีแค่ path ของ runner ไม่มี URI ไม่มี query และ `childEnv()` กรอง `MONGO_URI_*` / `BWS_*` ที่ค้างใน env ของ DSH ออกก่อน spawn ด้วย

query (filter/pipeline/projection/sort) เขียนเป็น `job.json` ใน temp dir (`mkdtemp`, ไฟล์ 0600) แล้ว runner อ่านด้วย `EJSON.parse` — ค่า query ไม่เคยอยู่บน command line. temp dir ถูกลบใน `finally` ทุกกรณี

ข้อความ error จาก child ถูก scrub สองชั้น: runner แทนค่า URI จริงด้วย `[redacted]` ก่อนพิมพ์ และฝั่ง plugin แทน `mongodb(+srv)://...`, userinfo, `MONGO_URI_*=` ด้วย `[redacted]` อีกชั้น

## timeout / cancel

`bwsr` → `bws` → `mongosh` เป็นสามชั้น process: plugin จึง spawn แบบ `detached` แล้ว kill ทั้ง process group (`process.kill(-pid, 'SIGKILL')`) เมื่อ timeout, AbortSignal, หรือ output เกิน `maxBuffer` — ถ้า kill แค่ child ตรง ๆ หลานจะถือ pipe ไว้และ call จะค้างจนหลานจบเอง. `connect()` ของ mongosh ไม่รับ options จึงเติม `serverSelectionTimeoutMS` (default 8000) ต่อท้าย URI เพื่อให้ host ที่ต่อไม่ได้ fail เร็ว

## prod gate

`env: 'prod'` เรียก `ctx.approval.request()` (service `@deepseek-ai/dsh-user-approval`) ทุกครั้ง การ์ดแสดง env, db, collection, op, limit และ filter/pipeline (+ projection/sort ถ้ามี) และต้องได้ผล `allowed-once` เท่านั้นจึงจะรัน — `rejected` / `cancelled` / `unavailable` หรือไม่มี approval service = ไม่รัน (fail closed) ไม่มีวิธีพิมพ์ "PROD ok" ในแชท เพราะ plugin อ่านแชทไม่ได้ `staging` และ `uat` ไม่ถาม

filter/pipeline/projection/sort ที่ JSON ยาวเกิน 600 ตัวอักษรจะถูก **refuse** (ให้ย่อ query) ไม่ใช่ตัดให้สั้นลง — เพราะการ์ดที่ถูกตัดจะซ่อนส่วนที่ prod กำลังจะรันจริง

## config

```yaml
- insert:
    - id: mongo-read
      name: '@local/dsh-mongo-read'
      config: { bwsrPath: bwsr, timeoutMs: 30000 }
```

`enabled: false` ปิดทั้ง plugin, `mongoshPath` เปลี่ยน path ของ mongosh, `limit`/`maxLimit` (default 20/200), `maxTimeMS`/`maxMaxTimeMS` (5000/15000), `connectTimeoutMS` (8000), `timeoutMs` (30000), `maxBuffer` (8 MiB), `maxOutputBytes` (24576) ปรับ cap

## ข้อจำกัดที่รู้อยู่

- `bwsr` และ `mongosh` ต้องอยู่ใน PATH ของ child — PATH ที่สืบทอดมาอยู่หน้าสุด แล้วต่อท้ายด้วย `~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`, `/bin`
- `countDocuments` ไม่มี limit (ใส่ `maxTimeMS` อย่างเดียว) — filter ที่กว้างมากจึงช้าได้
- session policy `never` ทำให้ approval service คืน `rejected` ก่อนถึง answerer → prod call ถูกบล็อก (ไม่มี bypass) ข้อความคือ `rejected (by user or session policy)`
- runner ยิง connection ทุกครั้งที่เรียก ไม่มี connection pooling ข้าม call

ทดสอบ: `node test.mjs` (ไม่ต้องมี DB, ไม่ต้องมี secret — ใช้ fake `bwsr`, รัน `RUNNER_SOURCE` จริงใน `node:vm` เพื่อเช็ค argument ของ `find`/`countDocuments`/`aggregate`, และยิง runner จริงเข้า `127.0.0.1:1` เพื่อเช็ค error path)
