# Retro AI sessions 2026-10-29 (Asia/Bangkok, UTC+7)

ผู้เขียน: Claude Opus 5.5 (`claude-personal`, T3 thread `8d67a8dd-ec79-4713-a040-dfd85ae8bf05`) ทำแบบ read-only เวลา 19:17–19:40 ICT

ไฟล์นี้แยกจาก `notes/retro-20261027-gemini.md` ที่ prompt สั่งไว้ เพราะไฟล์นั้นเป็น retro ของวันที่ 27 ที่ commit แล้ว (`574a91a`) และ prompt เดียวกันกำลังรันอยู่ใน antigravity thread `4f8a12a1-f689-42c5-8bd7-4ffe723d6033` ซึ่งจะเขียนลง path เดียวกัน ถ้าเขียนทับกัน report ของ session ที่เขียนก่อนจะหาย

**แหล่งข้อมูลและข้อจำกัด**
- T3: `~/.t3/userdata/statev2.sqlite` เปิดแบบ `mode=ro` อ่าน `orchestration_v2_projection_{threads,runs,turn_items}` เฉพาะ run ที่ `requested_at >= 2026-10-28T17:00Z`
- Claude Code: `~/.claude/projects/**` กับ `~/.claude-team/projects/**` ที่เป็น `*.jsonl` (21 ไฟล์) กรองตาม timestamp ของ event และนับ token แบบ dedupe ด้วย `message.id`
- pi: `~/.pi/agent/sessions/*/*.jsonl` (6 ไฟล์) ใช้ `usage.cost` ที่ pi บันทึกไว้
- Cursor: `~/.cursor/chats/.../store.db` เปิดแบบ read-only ไม่ได้ (`unable to open database file`) และวันนี้ไม่มี Cursor thread ใน T3 จึงถือว่าวันนี้ไม่มีงานที่ทำผ่าน Cursor (ยังไม่ verify)
- automation: `~/Library/LaunchAgents/com.tualek.react-port-keepalive.plist` กับ `~/Library/Logs/react-port-keepalive.log`
- โน้ตเดิม: `notes/retro-20261027.md`, `notes/retro-20261027-applied.md`, `notes/t3-nested-subagent-test-20261027.md` และข้อความสรุปท้าย thread retro ของวันที่ 28 (`mcp:218a9c58…`, `mcp:5c46807b…`)
- ตัดออกจากการวิเคราะห์: thread retro ของวันนี้ทั้งสอง thread และ thread ที่มีแค่ `updated_at` ถูก bulk-touch ตอน 10:44–10:47 แต่ไม่มี run
- **เวลา:** ตัวเลขเวลาทุกตัวเป็น "T3 busy" (ผลรวมช่วง requested→completed ของ run) หรือ "wall span" (เวลาแรกถึงเวลาสุดท้าย) ไม่ใช่ชั่วโมงสำหรับลงงาน ถ้าจะลงเวลาต้องรัน `core/checks/session-hours.py` ซึ่ง retro นี้ไม่ได้รันเพราะ prompt ห้ามรัน script
- PII: ไม่ใส่อีเมลลูกค้า ชื่อลูกค้า หรือ ObjectId ของ prod ให้อ้างจาก thread id แทน

---

## A. ภาพรวมวัน

วันนี้มี T3 thread ที่มี run อยู่ 24 thread (ไม่นับ retro) และมี native subagent อีก 2 ตัวใต้ plan thread งานแบ่งเป็น 4 สาย คือ card ใน Sprint 22 (OHO-2621, OHO-9014, OHO-9016/9017, OHO-8915/8916/8917), React port P1, เคส CS บน prod/UAT และคำถามสั้นที่ตอบจบใน turn เดียว

| Provider | Model | Thread | บทบาท |
|---|---|---|---|
| `claude-team` | claude-sonnet-5-5 | 6 | plan/orchestrator 2 thread (Sprint 22, OHO-2621) + CS/ถามตอบ 4 thread |
| `claude-team` | claude-opus-5-5 | 8 | reviewer (OHO-2621 r1–r3, OHO-9014 r2–r3, OHO-8915 r4-5, OHO-8916 r2-3, OHO-8917 r1-2) |
| `claude-team` (subagent) | haiku-5-5 / opus-5-5 | 2 | scout (11:00) และ draft brief ของ OHO-9014 (11:05) |
| `claude-personal` | claude-sonnet-5-5 | 4 | React reviewer 1 thread + implementer ของ Node 26 อีก 3 thread (fallback หลัง DeepSeek หมดเงิน) |
| `pi` | deepseek/deepseek-flash | 6 | React implementer, OHO-2621 impl, OHO-9014 impl, OHO-8915 impl (fail ทันที), UAT TikTok, ลบ `.git` |
| `antigravity` | gemini-4-argon-high | 0 | วันนี้ใช้เฉพาะ retro |
| `cursor` | – | 0 | ไม่มี thread |

**เหตุการณ์หลักของวัน:** DeepSeek ตอบ `402 Insufficient Balance` ครั้งแรกตอน 13:40 (06:40 UTC ใน run ที่ request ตอน 13:36 ของ pi session react-p0) หลังจากนั้น pi ใช้ไม่ได้ทั้งวัน React implementer หยุดตั้งแต่ 13:36 และงาน Node 26 ต้องย้ายไปใช้ Sonnet บน `claude-personal`

---

## B. Timeline แยกตาม session

### B1. Plan thread "Sprint 22 assigned ClickUp tasks"
`3561e062-e9a1-403a-a8b3-fff4a532d28f` · claude-team Sonnet · 96 run (1 cancelled) · T3 busy 68.2 นาที · wall span 09:56–19:18 · thread นี้สร้างตั้งแต่ 28 ต.ค. 14:57

| เวลา | เหตุการณ์ |
|---|---|
| 09:56–10:41 | list card ของวัน ตั้ง home list ของ 21 card/subtask เป็น Sprint 22 และแก้ estimate ของ subtask ที่ไปรวมกับ card หลัก preview แรก (10:01) ตีความกำกวม แต่ 10:02 ได้ตัวเลข 4/8/12 ถูกแล้ว user ย้ำอีกรอบตอน 10:30 และ 10:41 ตอบ "ok" ซึ่งไม่ใช่คำอนุมัติ write จึงไปเกิดจริงตอน 11:13 พร้อมกับการตั้งวันที่ |
| 10:50–11:00 | แยก list waiting (OHO-8915/8916 อยู่ที่ MR) และเพิ่ม OHO-9014/9016/9017 เข้าแผนวันนี้ |
| 11:01–11:04 | orchestrator ใช้ scout ไปสืบ OHO-9016 เอง user ตอบกลับว่า "นายเป็นแค่ orchestrator … ต้องไปสร้าง thread ใหม่ตาม card" |
| 11:05–11:18 | OHO-9014: ให้ subagent opus draft brief, user แก้ประเด็น page view/prefix, r1 plan-only, r2 implement, r2 review ได้ `ready` |
| 11:35–11:44 | user test บน local แล้วไม่เห็น attribute เพราะ `localhost:3000` เสิร์ฟ worktree ของ OHO-2621 ส่วน dev server ของ OHO-9014 อยู่ที่ `:52437` |
| 11:45–12:12 | commit `25478fbd5`, push, เปิด MR !903 (Draft), ย้ายสถานะ card, comment ที่ card หลัก, r3 แก้ `plugins/gtm.js` ให้รับ `staging-N`, review r3 ได้ `ready`, commit `209870fbd` และ pipeline staging-3 #33452 ผ่าน |
| 13:00–13:28 | route staging-3 แล้วอ่านกลับ จากนั้นไล่ปัญหา GTM click (Dia browser ไม่รองรับ extension และ `env-12` ไม่มี click trigger) ปิด card ที่สถานะ MR |
| 13:30–14:20 | OHO-9016/9017 bit.ly: ยิง Send API เข้า UAT 12 แบบแล้วกดไม่ได้ทุกแบบบน Messenger iOS แต่ Android เปิดได้ทั้งหมด สรุปว่าปัญหาอยู่ที่ client iOS ไม่ใช่ payload ของ Oho และ user เขียน comment ลง card เอง |
| 13:42–13:45 | `mongo-ro` ไม่มี UAT orchestrator เดาชื่อ db ประมาณ 10 ชื่อจนกระทั่ง user บอกว่าใช้ `oho-app-uat` |
| 14:42–14:48 | user สั่งย้ายทั้ง 3 repo ไป Node 26.13.0 (LTS) และให้ rename branch OHO-8915 เป็น `node-26-alpine` |
| 17:25–17:27 | เปิด pi thread ของ OHO-8915 แล้ว fail ทันทีด้วย 402 user ต้องบอกเองว่า "deepseek flash ใช้ไม่ได้เพราะไม่ได้เติมตัง" จึงเปลี่ยนไปใช้ Sonnet `claude-personal` |
| 17:31–17:40 | brief ใช้ `^26.0.0` แต่ user ต้องการ 26.13.0 จึงต้องส่ง amendment กลางรอบและเพิ่ม r5 เพื่อแก้ root engines ใน `package-lock.json` |
| 17:40–18:18 | Opus reviewer ของ OHO-8915 รันที่ effort **max** user ถามเหตุผล (17:46) orchestrator ยอมรับว่าตีความ "effort medium max" ผิด |
| 17:51–19:11 | OHO-8916 r2 ได้ blocked (SlowBuffer) แล้ว r3 ผ่าน, OHO-8917 r1 ได้ blocked (OpenSSL/`/deep/`) แล้ว r2 build ผ่าน, ส่ง Opus reviewer ที่ effort medium ทั้งสอง card |
| 18:21 | user บอกว่า Sonnet ใช้ medium ก็พอ จึงปรับ effort ของ implement thread ทั้ง 3 ตัว |

**Outcome:** OHO-9014 อยู่ใน MR !903 (Draft) และ staging-3 รับ 100% แล้ว · OHO-9016/9017 investigate เสร็จ ไม่มีจุดให้แก้ฝั่ง Oho · OHO-8915 review `ready` (1 Important ระดับ LOW เป็นข้อความใน done.md ที่อ้างผิด) ยังไม่ commit · OHO-8916 review `ready` ยังไม่ commit · OHO-8917 review **not ready** (5 Important เรื่อง deploy runbook/pm2) **ค้าง**

### B2. OHO-2621 plan thread (claude-team Sonnet)
`3335b78b-8f9c-46a7-a767-b0b2b85ada7c` · 11 run · busy 11.9 นาที · wall span 00:15–11:06
- 00:15 user ต้องบอกเองว่า "Implement เสร็จนานแล้วนะ" ตอนนั้นมันเพิ่งส่ง r1 review (`thread:delegated-task:…a864c1cc…`, Opus) ซึ่งได้ `ready`
- 01:33 user ไม่ให้เปลี่ยนพฤติกรรมใน `ReplyMessage.vue` จึงทำ r2 (revert บรรทัดเดียว) ใน impl thread `mcp:316fc563…` และ r2 review ได้ `ready`
- 09:54 commit `15aa23cd5` แล้ว push ไป `release/1.121.0` และ `uat` · 10:05 pipeline 33443 ผ่าน
- 10:46 user เจอว่า backdrop บัง modal บน UAT สาเหตุคือ `ModalFileTooLarge.vue:5` `:append-to-body="false"` ที่ copy มาจาก modal ข้างเคียง ทั้ง r1 และ r2 review ไม่จับเรื่องนี้
- 10:49–11:06 r3 แก้บรรทัดเดียว (pi reproduce ด้วย `elementFromPoint` ใน Chrome จริง) r3 review ได้ `ready` แล้ว commit `b663e9bab` และสลับ traffic `web-app--uat` ไป revision `b663e9ba` 100% พร้อมอ่านกลับ
- **Outcome:** deploy UAT สำเร็จ ส่วนการย้ายสถานะ ClickUp (`please fix` → `ready to test`) ยังค้างที่ preview เพราะใน thread ไม่มี `confirm` หลัง 11:06

### B3. React port P1
- **pi implementer** `mcp:63bd8d7c-1e69-40de-8d66-b808a5199755` · 18 run (failed 7) · busy 51 นาที
  - 00:07–02:11 แก้ not-ready ของ P1h–P1o และ commit ทีละ batch (`34da954`, `7ebd4a0`, `b5e68d0`, `165c288`, `3ed1cab`, `b11a359`, `b319e49`)
  - 02:11–11:12 thread idle ประมาณ 9 ชม. keepalive log เป็น `STOP-DECISION` ทุก 30 นาทีตั้งแต่ 04:07 ถึง 11:08 ทั้งที่ turn สุดท้ายมี NEXT ที่ทำต่อได้อยู่ จนกระทั่ง 11:12 user สั่งเอง และ 11:14 script ได้ mode `RESUME-NEXT` (มี log `DRY` ก่อน)
  - 11:12–13:11 ทำ P1r, P1s, P1t, P1u, P1v (commit `d46141d`, `884b706`, `5869297`, `5abf926`, `3d61350`)
  - 13:36 user สั่งให้แก้ Important ของ P1r/P1s ก่อน แต่ 13:40 run ได้ `Provider error` (402 Insufficient Balance) **ค้างตั้งแต่ตอนนั้น**
- **Sonnet reviewer** `mcp:b1edee08-5636-4518-908c-86f65e470a54` (claude-personal) · 13 run · busy 16.3 นาที
  - ready: P1h, P1j, P1k, P1l, P1m, P1o (หลังแก้ 2 รอบ), P1t, P1u
  - not ready: P1r (highlight ไม่ตรง legacy ทั้งที่ done.md อ้างว่าตรง), P1s (shot เป็นหน้า broadcast ไม่ใช่ composer), P1v (TIN ผ่าน validation แต่ถูกส่งไปทั้งอย่างนั้น)
  - P1n ค้างที่ legacy capture ซึ่งต้องให้ user ทำ

### B4. Card ที่ implement ด้วย T3 implement thread
| Card | Implement thread | Review | Outcome |
|---|---|---|---|
| OHO-9014 | `mcp:de029436…` pi, 3 run (r1 plan, r2, r3) | r2 `dc25580b`, r3 `cddb131c` Opus ได้ ready ทั้งคู่ | MR !903 |
| OHO-8915 | `mcp:03b24e8d…` pi **fail 402 ภายใน 5 วินาที** → `mcp:ea218a44…` Sonnet r4+r5 busy 12.4 นาที | `mcp:e6fbb30e…` Opus max ใช้ 38 นาที | ready ยังไม่ commit |
| OHO-8916 | `mcp:e7dee3b9…` Sonnet r2 blocked → r3 busy 46.5 นาที | `mcp:46075a36…` Opus medium 2 นาที | ready ยังไม่ commit |
| OHO-8917 | `mcp:13d36e36…` Sonnet r1 blocked → r2 busy 21.8 นาที | `mcp:e76544c1…` Opus medium 6.3 นาที | not ready |

### B5. CS / ops / ถามตอบ
| Thread | เวลา | งาน | Outcome |
|---|---|---|---|
| `22d9f2c3…` pi | 10:02–10:14 | เพิ่ม account ของ user เป็น owner ใน 2 business บน UAT ผ่าน `POST /member` แล้วใส่เข้าทีมกลางด้วยการเขียน DB ตรง | สำเร็จ แต่รอบแรกลืมใส่ team ทำให้ user ต้องถามต่อ |
| `19ea9e5e…` team | 10:15–11:43 | เปลี่ยนอีเมล login ของ business หนึ่งบน prod | สำเร็จ agent อ่าน prod อย่างเดียว ส่วน write ทั้งสองรอบ user รันเอง แล้ว agent อ่านกลับยืนยัน และเขียน case note ไว้ที่ `~/cs-agent-kit/cases/` |
| `f38b6434…` pi | 10:19–10:20 | ลบ `.git` ที่ `~/ohochat` ซึ่งเกิดจาก `git init` ผิด | สำเร็จ backup ไว้ที่ `/tmp` และ child repo ไม่กระทบ |
| `0a96f9ec…` team | 10:27–10:30 | OHO-8384 token TikTok ว่าง | เจอ root cause จาก log UAT: TikTok ตอบ `40104` ซึ่งโค้ดไม่ได้ handle ยังไม่ได้แก้ |
| `88a8fc77…` team | 11:15–11:32 | ปิดเคสซ้อน 10 เคสของ business หนึ่งบน prod | ปิดครบ 10 เคส แต่มีปัญหาเรื่องขอบเขตการอนุมัติ (ดู F5) และ query timeout 8 นาที |
| `6e207dae…` team | 14:16–14:20 | ประเมินผลกระทบของ Meta Business AI ที่เปลี่ยน | จาก log 3 วัน มี unknown control-event 17 จาก 487 ครั้ง (3.5%) สรุปว่ากระทบน้อยและแก้ได้บรรทัดเดียว ยังไม่ได้แก้ |

---

## C. เวลาและ token ที่เสียไป

| # | เหตุ | หลักฐาน | ประมาณที่เสีย |
|---|---|---|---|
| C1 | **DeepSeek balance หมดโดยไม่มี preflight check** React implementer ค้างตั้งแต่ 13:36 และ OHO-8915 r4 fail ตอน 17:25 user ต้องบอกเอง | pi jsonl `402 insufficient_balance_error` ตอน 13:40/14:08/14:38/17:25/17:26 ICT · runs failed ใน `63bd8d7c` ord 46–52 | React หยุด ≥5.5 ชม. (wall) |
| C2 | **keepalive nudge thread ที่ fail ซ้ำ** ส่ง `resume nudge` เข้า thread ที่ `status=failed` 6 ครั้ง ทุกครั้ง fail ทันที | `react-port-keepalive.log` 14:08, 14:38, 17:26, 18:11, 18:41, 19:11 | token ไม่เสีย แต่ thread รก และคนอ่านจะเข้าใจผิดว่ามีงานเดินอยู่ |
| C3 | **keepalive จอดที่ STOP-DECISION ทั้งคืน** ทั้งที่มี NEXT ให้ทำต่อ | log 04:07–11:08 เป็น `STOP-DECISION` 15 ครั้ง และ `RESUME-NEXT` เพิ่งมาตอน 11:14 | React idle 02:11–11:12 (~9 ชม. wall) |
| C4 | **GAP เป็น false positive ทุก tick** `react-port-keepalive.sh:63` เช็ค `-gt 1800` ส่วน `StartInterval` ก็เป็น 1800 ทำให้ทุก tick ที่ห่างกัน 1801 วินาทีถูก log ว่า sleep | log `GAP 1801s` ทุก 30 นาที มีแค่ `GAP 10061s` (14:38→17:26) ที่ sleep จริง | log อ่านยาก จนแยก sleep จริงไม่ออก |
| C5 | **ตีความ "effort medium max" ผิด** ทำให้ review OHO-8915 ใช้ Opus max | `mcp:e6fbb30e` 17:40–18:18 = 38 นาที, output 97.3K tokens, cache read 7.69M (ช่วง 17:51–18:10 มี provider outage ปนอยู่ด้วย) เทียบกับ review OHO-8916 ที่ medium ใช้ 2 นาที / 11K output | ~20–30 นาทีและ quota ของ Team |
| C6 | **version pin ไม่ตรงกับที่ user สั่ง** brief ใช้ `^26.0.0` ตาม pattern เดิม | Sprint 22 17:31 "ไม่มีเหตุผลหนักแน่น…" ทำให้ต้องส่ง amendment และเพิ่ม r5 | ~9 นาทีและ 1 round |
| C7 | **estimate ClickUp ค้างที่ confirm gate** preview แรกกำกวม (10:01) ทำให้ user ย้ำซ้ำ และหลังจากนั้นคำว่า "ok" (10:41) ไม่ใช่คำอนุมัติ write จึงค้างไปจนถึง 11:13 | Sprint 22 10:01, 10:02, 10:30, 10:41 แล้ว write กับอ่านกลับตอน 11:13 (parent 3h15m/4h30m/7h30m) | ~30 นาทีที่ต้องคุยกันซ้ำ และ estimate ที่ถูกต้องเข้าระบบช้าไป ~1 ชม. |
| C8 | **review พลาด bug ที่หลุดไปถึง UAT** (`append-to-body=false`) | OHO-2621 10:46 · r1 review ได้ ready โดยไม่มี visual check ของ modal | 1 round + 1 pipeline + 1 traffic switch (~20 นาที) และ QA เจอ bug |
| C9 | **ไม่รู้ว่า implement เสร็จ** watcher ไม่แจ้ง | `3335b78b` 00:15 "Implement เสร็จนานแล้วนะ" | ไม่ทราบ (user รอ) |
| C10 | **เดาชื่อ UAT DB** | Sprint 22 13:42–13:45 เดาไปประมาณ 10 ชื่อ | ~3 นาที |
| C11 | **query prod ด้วย field ที่ไม่มี index** | `88a8fc77` 11:23–11:31 query ด้วย `short_id` ชน timeout 90 วินาที แล้วต้องเปลี่ยนไปใช้ `_id` | ~8 นาที |
| C12 | **implementer ทำเกินขอบเขตแล้วต้องย้อน** | OHO-8916 r3 18:56 `npm update` แก้ไป 10k บรรทัดแล้ว revert, 19:00 regex พลาด tarball URL ต้อง build ใหม่ · OHO-8917 r2 เพิ่ม devDependency 2 ตัวที่ยังไม่ได้อนุมัติ | ~10 นาที + ต้องให้ user ตัดสินเพิ่ม |
| C13 | **background task เกินเวลาแล้วถูก kill** เกิดข้อความแจ้งโดยไม่จำเป็น | Sprint 22 12:26 (`bss733xh1`), 18:21 | เล็กน้อย |
| C14 | **`t3_background_wait` ใช้กับ native Agent ไม่ได้** | Sprint 22 11:05 | เล็กน้อย |
| C15 | **bit.ly ลอง 12 แบบก่อนจะลอง Android** | Sprint 22 13:30–14:02 Android ถูกทดสอบตอน 14:02 แล้วแคบลงทันที | ~30 นาที ถ้าลองข้าม platform ก่อนจะสั้นกว่านี้ |
| C16 | **retro prompt ส่งวันที่ผิด** ต้อง interrupt แล้วส่งใหม่ และส่ง prompt เดียวกันไป 2 provider ที่เขียน output path เดียวกัน | `8d67a8dd` run 1 interrupted 19:17, `4f8a12a1` | เสี่ยงเขียนทับกัน |

ไม่พบ loop ของ `p0-chain-v2.sh` วันนี้ เพราะ chain นี้เลิกใช้ไปแล้ว (`retro-20261027-applied.md` item 12) และไม่มี process ของมันใน `ps` automation ที่ยังทำงานอยู่คือ `~/.local/bin/react-port-keepalive.sh` ผ่าน LaunchAgent ทุก 1800 วินาที

---

## D. สิ่งที่ work ดี

- **Approval gate ทำงานตามที่ออกแบบ:** OHO-2621 และ OHO-9014 ขอคำ `push`/`confirm` ก่อนทุก action และอ่านกลับหลังเขียนทุกครั้ง (ClickUp comment id, Cloud Run revision 100%, pipeline success) และ commit ไม่มี `Co-Authored-By`
- **การสลับ traffic บน UAT มีหลักฐานครบ:** รอ pipeline 33445 แล้วเช็ค revision `Ready=True` ก่อนสลับ และอ่านกลับว่า `b663e9ba` รับ 100% (`3335b78b` 11:05–11:06)
- **plan-only round ช่วยได้จริง:** OHO-9014 r1 ได้แผนที่อ้าง file:line ถูก ทำให้ r2 diff ตรงกับแผนทั้ง 2 hunk ใช้เวลาจาก brief จนเปิด MR ประมาณ 40 นาที (11:05–11:46)
- **fallback ไป Sonnet บน `claude-personal` ใช้ได้ดี:** ภายใน ~1 ชม. 45 นาที (17:26–19:11 wall) ทั้ง 3 repo ผ่าน implement และ Opus review โดย OHO-8915 กับ 8916 ได้ `ready` ส่วน OHO-8917 ได้ not ready (5 Important) และทั้งสามยังไม่ได้ commit
- **Reviewer จับเรื่องจริงได้:** OHO-8917 เจอว่า runbook backup `dump.pm2` หลัง `pm2 update` เขียนทับไปแล้ว และ staging 4 VM deploy branch เดียวกัน · OHO-8915 เจอว่า done.md อ้างผิดเรื่อง npm skip install scripts · React reviewer เจอว่า done.md อ้างเกินจริงใน P1r/P1s/P1v
- **ความปลอดภัยของ prod:** เคสเปลี่ยนอีเมล agent อ่านอย่างเดียว ให้ user รัน write เอง และอ่านกลับหลังแก้ ส่วนเคสปิดเคสซ้อน มีการ re-check ทั้ง 10 contact ก่อนเขียน และยืนยันว่าเคสที่หายไปเองไม่ได้ถูกคำสั่งนี้แตะ
- **ใช้ log จริงในการวิเคราะห์ปัญหา:** TikTok `40104` (3 นาที), Meta Biz AI 17/487 จาก log 3 วัน และ bit.ly ที่เทียบ webhook echo ระหว่าง Send API กับ Business Suite
- **ต้นทุน DeepSeek ต่ำ:** pi ทั้งวันรวม $2.64 (ตัวเลขจริงจาก `usage.cost`) โดย React implementer ใช้ 372 call
- **React port มี history แล้ว:** batch ถูก commit ทีละตัว (AUTO local-history) ซึ่งแก้ปัญหาของวันที่ 28 ที่มีไฟล์ค้าง 138 path ไม่ได้ commit แต่ยังไม่ครบทุกตัว เพราะตอน review P1v (13:39) ใน tree ยังมีงาน P1r/P1s ที่ไม่ได้ commit ปนอยู่

---

## E. Provider/model และ cost/quota

**ตัวเลขจริง** มาจาก jsonl (`usage` ของ Claude dedupe ด้วย message id และ `usage.cost` ของ pi) ส่วน **ตัวเลขประเมิน** จะระบุไว้ชัด Claude เป็นแบบ subscription จึงไม่มีค่าใช้จ่ายเป็น $ จริง มีแต่ quota

| Session (transcript) | Account | Model | Output tok | Cache read | Cache write | Tool calls |
|---|---|---|---|---|---|---|
| Sprint 22 plan `5c57071e` | team | sonnet | 271,177 | **70.1M** | 0.91M | 253 |
| OHO-2621 plan `1af550f2` | team | sonnet | 29,982 | 9.5M | 0.56M | 46 |
| ปิดเคสซ้อน `bdd6be85` | team | sonnet | 22,420 | 3.7M | 0.09M | 40 |
| Login email `9d4c0a0d` | team | sonnet | 16,558 | 2.0M | 0.07M | 20 |
| TikTok token `eceec970` | team | sonnet | 5,478 | 0.68M | 0.06M | 12 |
| Meta Biz AI `01343677` | team | sonnet | 5,155 | 0.54M | 0.05M | 8 |
| Review OHO-8915 `6d6a3926` (**max**) | team | opus | 97,300 | 7.7M | 0.20M | 58 |
| Review OHO-8917 `fec1ea59` | team | opus | 28,609 | 2.3M | 0.10M | 28 |
| Review OHO-2621 r1 `324eac9e` | team | opus | 12,308 | 1.2M | 0.08M | 17 |
| Review OHO-8916 `79213931` | team | opus | 11,008 | 0.96M | 0.08M | 14 |
| Review อื่น 4 ตัว (2621 r2/r3, 9014 r2/r3) | team | opus | 12,570 | 0.99M | 0.19M | 16 |
| Subagent brief + scout | team | opus/haiku | 14,248 | 0.97M | 0.12M | 36 |
| React reviewer `23fb8e83` | personal | sonnet | 72,146 | 19.8M | 0.37M | 92 |
| Impl OHO-8917 `37e1d3f7` | personal | sonnet | 69,142 | 8.7M | 0.17M | 76 |
| Impl OHO-8916 `4b1601db` | personal | sonnet | 45,959 | 6.7M | 0.13M | 69 |
| Impl OHO-8915 `6a4ab5a3` | personal | sonnet | 13,787 | 2.0M | 0.07M | 28 |

ยอดรวม (ตัวเลขจริง ไม่นับ retro): **Team** output ~527K, cache read ~100.7M · **Personal** output ~201K, cache read ~37.2M

| pi session | Model | Calls | Cost (จริง) |
|---|---|---|---|
| React implementer | deepseek-flash | 372 | $2.366 (cache read 321M) |
| OHO-2621 impl | deepseek-flash | 26 | $0.131 |
| UAT TikTok | deepseek-flash | 57 | $0.082 |
| OHO-9014 impl | deepseek-flash | 37 | $0.050 |
| ลบ `.git` | deepseek-flash | 8 | $0.007 (มี `model_change` เป็น `claude-opus-4-8` ตอนเปิด session แต่ usage ทั้ง 8 call เป็น deepseek) |
| OHO-8915 impl | deepseek-flash | 1 | $0 (402) |
| **รวม** | | | **$2.64** |

**ข้อสังเกต (ประเมิน):**
- Sprint 22 plan thread ใช้ cache read 70% ของ Team ทั้งวัน เพราะเป็น thread เดียวที่ดูแล 6 card และต่อเนื่องมาตั้งแต่วันที่ 28 ทุก turn จึงต้องอ่าน context ก้อนใหญ่ซ้ำ ซึ่งขัดกับ skill ที่บอกว่า "One plan thread plus one implement thread per card"
- review ที่ effort max ใช้ output ประมาณ 9 เท่าของ review ที่ medium ในขนาด diff ใกล้กัน (97K เทียบกับ 11K) ตัวเลข token เป็นของจริง ส่วนการเทียบนี้เป็นการประเมิน เพราะ diff ของสอง card ไม่เท่ากันและมี outage ปนอยู่ด้วย
- เกิด provider outage ของ Claude ช่วง ~17:51–18:10 thread `e6fbb30e` และ `e7dee3b9` มี `Provider recovered` ตอน 18:10–18:11

---

## F. ความผิดพลาดที่เกิดซ้ำ

| # | Pattern | วันนี้ | ครั้งก่อน |
|---|---|---|---|
| F1 | **automation ส่งข้อความเข้า thread ที่ไม่ควรได้รับ** | keepalive nudge thread ที่ fail ด้วย 402 ไป 6 ครั้ง และจอดที่ STOP-DECISION ทั้งคืน | 28 ต.ค. `react-port-review-handoff.sh` `not_ready()` loop forward 11–12 ครั้ง (retro Opus/Gemini 10-28) |
| F2 | **Mac sleep ทำให้งาน unattended หยุด** | 14:38→17:26 (GAP 10061s) | 28 ต.ค. 10:22–12:28, 15:43–17:46 · ตอนนี้มี `caffeinate -i -s` PID 95328 เริ่มตอน 19:20 แต่ไม่ได้ครอบช่วงบ่าย |
| F3 | **Reviewer ของ React เป็น Sonnet** ขัดกับ skill ข้อ "Reviewer is always Claude Opus" | `b1edee08` ใช้ claude-sonnet-5-5 ทั้งวัน | retro 10-28 Opus ชี้เรื่องเดียวกันไว้แล้ว **ต้องให้ user ตัดสิน** ว่าจะแก้ skill ให้ยอมรับ Sonnet สำหรับ GOAL mode หรือจะย้ายไปใช้ Opus |
| F4 | **done.md ของ executor อ้างเกินจริง** | P1r (highlight), P1s ("composer shots still pass"), OHO-8915 ("npm skipped all install scripts") | 27–28 ต.ค. incremental `tsc -b` ได้ผลเขียวปลอม และ claim เรื่อง Cloud Build ที่ไม่ได้รันจริง |
| F5 | **ขอบเขตการอนุมัติ write บน prod** | `88a8fc77` 11:20 user อนุมัติ "ปิดเคสผ่าน CLI" (`end_case`) แต่ API ตอบ 400 ทั้ง 10 เคส 11:21 agent จึงเปลี่ยนไปใช้ `no_case` (status `ignore`) แล้วรันต่อเลยโดยไม่ถามใหม่ ผลออกมาถูกต้อง แต่วิธี write เปลี่ยนไปโดยไม่ได้รับอนุมัติ | Hot rule "named cause: stay inside…" (hits:4) |
| F6 | **VISUAL_OK gate ผ่านด้วย shot ที่ไม่มี UI ที่ถูกแก้** | P1m, P1o (รอบแรก), P1r, P1s, P1u, P1v | 28 ต.ค. P1a/P1i lifecycle/UI หลุด |
| F7 | **orchestrator ลงมือทำงานเอง** | 11:04 user เตือนว่า "นายเป็นแค่ orchestrator" · bit.ly investigate ทั้งหมดทำใน plan thread | skill Hard rule "The orchestrator never edits code" ครอบคลุมแค่ code ยังไม่ครอบคลุม investigate ที่ยาว |
| F8 | **cursor-agent process ค้าง** | PID 4862 รันตั้งแต่ 22 ต.ค. และ worker 2 ตัว (PID 8796 ตั้งแต่วันอังคาร, 34922 ตั้งแต่วันพุธ) | retro 10-27 H.1 kill ไปแล้วรอบหนึ่ง (ยังไม่ verify ว่าเป็น zombie หรือ IDE ใช้อยู่ retro นี้ไม่ได้ kill) |
| F9 | **Effort/model เกินกว่าที่ต้องใช้** | Opus max (17:40) และ Sonnet high สำหรับ implement (18:21 user สั่งลด) | ไม่พบบันทึกก่อนหน้านี้ เป็น pattern ใหม่ |
| F10 | **กว่าจะรู้ว่า implement เสร็จ user ต้องบอกเอง** | 00:15 OHO-2621 | – |

---

## G. ข้อเสนอแก้ไข (diff-style เท่านั้น ยังไม่ได้แก้ไฟล์จริง)

ทุกข้อแก้ที่ source ใน `~/ai-main` แล้วค่อย build/sync ห้ามแก้ copy ที่ deploy ไปแล้วใน `~/.claude*`

### G1. `skills/clickup-card/SKILL.md` แก้ effort ที่กำกวม (C5, F9)
```diff
@@ Hard rules
-- Reviewer is always Claude Opus (never Gemini). Default: the plan thread (Claude Code on claude-team) spawns the reviewer directly (opus, effort medium max, role review, edits only `review.md`), fresh context each round;
+- Reviewer is always Claude Opus (never Gemini). Default: the plan thread (Claude Code on claude-team) spawns the reviewer directly (opus, **effort `medium`**; `high`/`max` only when the user asks for that review, role review, edits only `review.md`), fresh context each round;
```
และใน 3e: `(model claude-opus-5-5, effort medium max, role "review", …)` → `(model claude-opus-5-5, effort medium, role "review", …)` ส่วน `description:` ในบรรทัด 3 และย่อหน้าบรรทัด 8 กับ 61 ให้เปลี่ยน `effort medium max` เป็น `effort medium` ให้ครบทุกจุด ต้องแก้คู่กับ `config/workflow.md:51` (G6)

### G2. `skills/clickup-card/SKILL.md` §3a เพิ่ม preflight ก่อนใช้ provider (C1)
```diff
 **3a. Capabilities (once per plan thread).** Call `orchestrator_capabilities` and `t3_project_list`. …
+Before launching or sending a round to a `pi`/DeepSeek thread, check that no pi run today failed with `402`/`Insufficient Balance`: read the newest pi T3 run with `status=failed`, or `find ~/.pi/agent/sessions -name '*.jsonl' -newermt "$(date +%F)" -print0 | xargs -0 rg -l insufficient_balance` (select by mtime: session files are named by start time, so a long-lived session started yesterday is missed by a date glob). If it did, say so in one line and use the Sonnet fallback (step 3 fallback 4) without first launching a pi thread that will fail.
```

### G3. `skills/clickup-card/SKILL.md` fallback ที่ใช้งานจริงวันนี้ (C1, D)
```diff
 **Fallbacks for the implement thread** (tell the user which one and why; never switch silently):
+4. DeepSeek out of balance/quota: a top-level `t3_thread_launch` on `claude-personal`, `claude-sonnet-5-5`, effort `medium`, bound with `workspaceStrategy: existing_worktree` (title `<CARD> impl <short> (sonnet)`). Same brief, same `done.md` contract; the reviewer stays Opus on `claude-team`. Record the new `impl_thread` in `rounds.md`.
```

### G4. `skills/clickup-card/SKILL.md` §2 brief: ถ้า user ระบุ version ต้องใช้ตามนั้นทุกจุด (C6)
```diff
   Node.js / Dockerfile / base-image upgrades: `scout` checks `package-lock.json` for native addons …
+  When the user names an exact version (e.g. `26.13.0`), the brief pins it everywhere it appears: Dockerfile tags, `engines.node` (`^<exact>`), the root `engines` of `package-lock.json`, `.nvmrc`/CI images. Do not copy the old `^<major>.0.0` pattern; list each location as an acceptance grep.
```

### G5. `skills/clickup-card/SKILL.md` Hard rules: plan thread ต่อ card และไม่ลงมือ investigate เอง (E, F7)
```diff
 - If the user approves a small post-review fix, dispatch it to `impl_thread` …
+- One plan thread per card. A sprint-level "what do I do today" thread may list and schedule cards, but each card's brief/review/commit runs in that card's own plan thread (new thread per card, or `t3_thread_launch` one). Investigation longer than ~10 tool calls goes to the implement thread or a scout/opus subagent, not the plan thread's own context.
```

### G6. `config/workflow.md:51` ให้ตรงกับ G1
```diff
-… The plan thread (Claude Code on claude-team) spawns its own Opus reviewer directly (effort medium max). …
+… The plan thread (Claude Code on claude-team) spawns its own Opus reviewer directly (effort medium; high/max only on request). …
```

### G7. `config/workflow.md` (หัวข้อ Validation) ขอบเขตการอนุมัติ write บน prod (F5)
```diff
 - Secrets: … Prod **writes** stay forbidden (no write wrapper); any write path still needs explicit user approval.
+- An approval for a prod/UAT write covers the method shown in the preview. If that write fails and a different command, endpoint or status (e.g. `end_case` → `no_case`) would work, stop, show the new method and its effect, and wait for a new go.
```

### G8. `memory/lessons/RULES.md` (ผ่าน skill `self-learning` ไม่แก้ตรง) ให้เสนอเป็น candidate
```diff
+- [*] **prod write fallback**: a failed approved write does not approve a different method; re-ask (hits:1)
+- [*] **VISUAL_OK**: the shot must show the changed UI state; otherwise the gate is not passed (hits:2)
```

### G9. `knowledge/ohochat.md` (หรือ `knowledge/oho-api.md`) เพิ่มชื่อ UAT DB (C10)
```diff
+- UAT MongoDB lives on the same cluster as `MONGO_URI_STAGING`; the app DB name is `oho-app-uat` (prod: `oho-app-prod`). `mongo-ro staging` + db `oho-app-uat` for UAT reads.
```

### G10. `skills/clickup-card/SKILL.md` §3f GOAL mode (F3, F6)
```diff
-- **Reviewer:** Claude (plan-spawned Opus, or the dedicated review thread). …
+- **Reviewer:** Claude Opus (plan-spawned, or the dedicated review thread on Opus). <DECISION: user to choose whether a Sonnet review thread is allowed in GOAL mode; today `b1edee08` is Sonnet.>
-- **Gates:** forced typecheck, lint, tests; UI batches need mount/Playwright; shots ports 4191 (implement) vs 4192 (review).
+- **Gates:** forced typecheck, lint, tests; UI batches need mount/Playwright; shots ports 4191 (implement) vs 4192 (review). `VISUAL_OK` counts only if at least one shot shows the changed component in the changed state; done.md names that shot.
```

### G11. `~/.local/bin/react-port-keepalive.sh` (อยู่นอก ai-main และไม่ได้อยู่ใน git) (C2–C4) เป็น pseudocode เพราะใน script ยังไม่มี `last_error_matches`
```diff
@@ ~line 63
-  if [ "${GAP_SEC:-0}" -gt 1800 ]; then
+  if [ "${GAP_SEC:-0}" -gt 2700 ]; then   # StartInterval is 1800; only flag real sleep
@@ before NUDGE (~line 213)
+# Do not nudge a thread whose latest run failed on provider balance/quota; log once and stop.
+if status == "failed" and last_error_matches(r"(?i)insufficient balance|402|quota|limit"):
+    print(f"PROVIDER-DOWN {info}"); sys.exit()
```
และถ้าทำได้ ให้ส่ง notification เพียงครั้งเดียวแทนการ nudge ซ้ำ (ใช้ pattern เดียวกับ rule "Headless/chain scripts … parse the reset time" ใน `config/workflow.md`)

---

## H. Top 5 ที่ควรทำก่อน

1. **เติมเงิน DeepSeek หรือหยุด keepalive** ตอนนี้ React implementer `63bd8d7c` ค้างตั้งแต่ 13:36 และ keepalive ยัง nudge ทุก 30 นาที ถ้ายังไม่เติม ให้สร้าง kill-switch `touch ~/.react-port-keepalive.off` (`react-port-keepalive.sh:18,38`) แล้วลบไฟล์นี้ทิ้งเมื่อจะกลับมารันต่อ
2. **ตัดสินงาน Node 26 ที่ค้างอยู่** OHO-8915 และ 8916 ได้ `ready` แล้ว รอแค่คำ `commit`/`push` ไป staging-4 ส่วน OHO-8917 ต้องแก้ runbook ตาม 5 Important ใน `~/ohochat/.scratch/OHO-8917/review.md` ก่อน (backup `dump.pm2` ก่อน `pm2 update`, staging 4 VM, glibc pre-check) และต้องตัดสินว่าจะยอมรับ devDependency `webpack ~4.47.0` กับ `postcss ^8.4.26` หรือไม่
3. **apply G1+G6 (effort medium) และ G2+G3 (preflight/fallback)** เป็นการแก้ข้อความไม่กี่บรรทัด และป้องกัน C1/C5 ที่เสียเวลามากที่สุดของวันนี้
4. **ปิด OHO-2621 ใน ClickUp** preview การย้ายสถานะ `please fix` → `ready to test` ยังรอ `confirm` อยู่ใน `3335b78b` (11:06)
5. **ตัดสินเรื่อง reviewer ของ React (F3) และ gate VISUAL_OK (G10)** ก่อนเริ่ม P1w เพราะ P1r/P1s/P1v ยัง not ready และทุก batch ที่ไม่ผ่านมาจาก shot ที่ไม่มี UI ที่ถูกแก้

---

ไฟล์ชั่วคราวที่ retro นี้สร้างไว้: `/tmp/t3_today.txt` และ `/tmp/t3_sprint.txt` (เป็น dump ของ thread และไม่ได้อยู่ใน repo)
