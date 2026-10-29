# Retrospective รายละเอียดทุก AI Session ประจำวันที่ 2026-10-29 (Asia/Bangkok UTC+7)

- **ผู้จัดทำ:** Gemini (`antigravity` / `gemini-4-argon-high`, T3 thread `[ช่วยทำ retro แบบละเอียดของ "ทุก AI session ของวันน...](t3-thread://v1/4f8a12a1-f689-42c5-8bd7-4ffe723d6033)`)
- **เวลาที่เก็บข้อมูล:** 2026-10-29 19:17–19:31 (+07) แบบ **READ-ONLY 100%**
- **แหล่งข้อมูลที่ตรวจสอบครบถ้วน (เฉพาะ session ที่สร้างหรือแก้ไขวันนี้ 2026-10-29):**
  1. `~/.t3/userdata/statev2.sqlite` (`orchestration_v2_projection_threads`, `orchestration_v2_projection_runs`, `orchestration_v2_projection_subagents`, `projection_projects`, `orchestration_v2_projection_provider_session_bindings`) และ `t3 thread list --project /Users/tualek/ai-main --json`
  2. `~/.claude/projects/**/*.jsonl` (Claude Personal) และ `~/.claude-team/projects/**/*.jsonl` (Claude Team) ที่ modified วันนี้ (21 ไฟล์ `.jsonl`)
  3. `~/.pi/agent/sessions/**/*.jsonl` ที่ modified วันนี้ (6 ไฟล์ `.jsonl`)
  4. `~/.cursor/chats/**/store.db`, `~/.cursor/ai-tracking/ai-code-tracking.db`, และ `ps aux` (Cursor CLI / IDE)
  5. โน้ตเดิมใน [retro-20261027.md](file:///Users/tualek/ai-main/notes/retro-20261027.md), [t3-nested-subagent-test-20261027.md](file:///Users/tualek/ai-main/notes/t3-nested-subagent-test-20261027.md), และ [retro-20261027-applied.md](file:///Users/tualek/ai-main/notes/retro-20261027-applied.md)
  6. [skills/clickup-card/SKILL.md](file:///Users/tualek/ai-main/skills/clickup-card/SKILL.md), [skills/clickup-card/templates.md](file:///Users/tualek/ai-main/skills/clickup-card/templates.md), [config/workflow.md](file:///Users/tualek/ai-main/config/workflow.md), [config/review.md](file:///Users/tualek/ai-main/config/review.md), [memory/lessons/RULES.md](file:///Users/tualek/ai-main/memory/lessons/RULES.md), [core/hooks/guard.sh](file:///Users/tualek/ai-main/core/hooks/guard.sh), `/Users/tualek/.local/bin/react-port-keepalive.sh`, `/Users/tualek/.local/bin/react-port-review-handoff.sh`, และ `/Users/tualek/orca/workspaces/oho-web-app-react/react-p0/.scratch/p0/p0-chain-v2.sh`

> [!IMPORTANT]
> **สรุปเหตุการณ์สำคัญของวันนี้ (2026-10-29):**
> 1. **DeepSeek API Credit หมด (`402 Insufficient Balance`) ตอน `13:40:07` (+07):** ทำให้ `pi / deepseek-flash` หยุดทำงานกลางคันใน React port (`P1w`) และล้มเหลวทันทีตอนเปิด `OHO-8915 impl node 26.13.0` (`17:25:31`)
> 2. **`react-port-keepalive.sh` (LaunchAgent ทุก 30 นาที) ไม่มีวงจรหยุดเมื่อเจอ `status=failed` / `402 Insufficient Balance`:** ส่ง `NUDGE IDLE` ซ้ำเข้า thread `mcp:63bd8d7c` ถึง **6 รอบติดต่อกัน** (`14:08`, `14:38`, `17:26`, `18:11`, `18:41`, `19:11`) เพราะตัวแปร `lastNudgeItemCount` เก็บค่าก่อนส่งข้อความ แต่เมื่อส่งแล้ว `items` เพิ่มขึ้นทีละ 2 (user msg + failed assistant msg) ทำให้เช็ก `lastNudgeItemCount == items` ไม่เคยเป็นจริง!
> 3. **การปรับสถาปัตยกรรม `clickup-card` กลางวัน (Pivot จาก Pi สู่ Multi-Repo Parallel Sonnet + Opus):** หลัง DeepSeek เครดิตหมดตอน `17:26` Orchestrator (`3561e062`) สลับไปใช้ `claude-personal / claude-sonnet-5-5` เป็น Implementer และ `claude-team / claude-opus-5-5` เป็น Top-level Reviewer ผูก worktree เดียวกัน รันขนาน 3 repos (`OHO-8915` web-app, `OHO-8916` media-api, `OHO-8917` backoffice) อัปเกรดเป็น **Node 26.13.0 LTS** ได้ครบภายใน ~2 ชั่วโมง
> 4. **ตีความวลี `"effort medium max"` ใน `SKILL.md` ผิดเป็น `effort: max`:** ตอน `17:40:19` Orchestrator เปิด `OHO-8915 r4-5 review (opus)` ด้วย `effort: max` ทำให้ Opus คิดและรันคำสั่งตรวจลึกถึง 58 tool calls (97.3k output tokens, `$6.82`–`$7.54`, นาน 38 นาที) ก่อนที่ผู้ใช้จะทักตอน `17:46:41`

---

## A. สรุปภาพรวมวัน (จำนวน Session แยกตาม Provider / Model)

นับเฉพาะ session/thread ที่มีการสร้างหรือแก้ไขในวันที่ **2026-10-29 (00:00–19:30 UTC+7)**:

| แหล่งข้อมูล / Provider | Model | จำนวน Session / Thread ที่แตะวันนี้ | จำนวนที่ Active จริงวันนี้ (มี Run/Turn วันนี้) | รายละเอียดและการจับคู่ (Mapping) |
|---|---|---:|---:|---|
| **T3 Code Threads** (`statev2.sqlite`) | ทุก provider รวมกัน | **40 threads** | **26 threads** | อีก **14 threads** เป็นของวันที่ 27–28 ต.ค. ที่ไม่มี run วันนี้ แต่ `updated_at` ขยับตอน `10:44–10:49` (เช่น settle/archive/sync UI) |
| └─ T3: `claude-team` (Top-level) | `claude-sonnet-5-5` (6), `claude-opus-5-5` (3) | 12 threads | **9 threads** | Orchestrator/Card/Adhoc 6 threads (`3561e062`, `3335b78b`, `19ea9e5e`, `0a96f9ec`, `88a8fc77`, `6e207dae`) + Top-level Opus Reviewers 3 threads (`mcp:e6fbb30e`, `mcp:46075a36`, `mcp:e76544c1`) |
| └─ T3: `claude-team` (Subagents) | `claude-opus-5-5` (6), `claude-haiku-5-5` (1) | 10 threads | **7 threads** | `delegate_task` Opus reviewers 5 threads (`OHO-2621` r1–r3, `OHO-9014` r2–r3) + Native `Agent` 2 threads (`afbd45bd` Haiku scout, `a68334fa` Opus planner) |
| └─ T3: `claude-personal` | `claude-sonnet-5-5` (4), `claude-opus-5-5` (1) | 6 threads | **5 threads** | React reviewer `mcp:b1edee08`, Node 26 implementers 3 threads (`mcp:ea218a44`, `mcp:e7dee3b9`, `mcp:13d36e36`), และ Retro Opus `8d67a8dd` |
| └─ T3: `pi` | `deepseek/deepseek-flash` | 8 threads | **6 threads** | React implementer `mcp:63bd8d7c`, Card implementers 3 threads (`mcp:316fc563`, `mcp:de029436`, `mcp:03b24e8d`), Adhoc 2 threads (`22d9f2c3`, `f38b6434`) |
| └─ T3: `antigravity` | `gemini-4-argon-high` | 4 threads | **1 thread** | Thread ปัจจุบัน `4f8a12a1` (อีก 3 threads คือ retro/audit วันที่ 27–28 ต.ค. ที่ถูก settle วันนี้) |
| **Claude Code: Personal** (`~/.claude/projects`) | `claude-sonnet-5-5` (4), `claude-opus-5-5` (1) | **5 ไฟล์ `.jsonl`** | **5 sessions** | ตรงกับ 5 active threads ของ `claude-personal` ใน T3 แบบ 1:1 (`23fb8e83`, `6a4ab5a3`, `4b1601db`, `37e1d3f7`, `dcdf6f79`) |
| **Claude Code: Team** (`~/.claude-team/projects`) | `sonnet-5-5` (6), `opus-5-5` (9), `haiku-5-5` (1) | **16 ไฟล์ `.jsonl`** | **16 sessions** | ตรงกับ 16 active threads/subagents ของ `claude-team` ใน T3 แบบ 1:1 (14 ไฟล์หลัก + 2 ไฟล์ใน `5c57071e/subagents/`) |
| **Pi Agent Sessions** (`~/.pi/agent/sessions`) | `deepseek/deepseek-flash` | **6 ไฟล์ `.jsonl`** | **6 sessions** | ตรงกับ 6 active threads ของ `pi` ใน T3 แบบ 1:1 (`01a18071`, `01a182b2`, `01a18229`, `01a185ab`, `01a185dc`, `01a18731`) |
| **Cursor CLI / IDE** (`~/.cursor`) | `cursor-agent` | **0 session ใหม่** | **0 session วันนี้** | ไม่มีการสร้าง chat ใหม่วันนี้ แต่มี **zombie process `cursor-agent` (`PID 74570`)** ค้างตั้งแต่ 16 ต.ค. ที่เขียนไฟล์ `931661a1/store.db` (`mtime 19:21`) และ `ai-code-tracking.db` (`mtime 13:08`) |

---

## B. รายละเอียดต่อ Session: Timeline, Goal, Outcome

จัดกลุ่มตามสายงาน (Workstreams) เพื่อให้เห็นความเชื่อมโยงของ Parent / Implementer / Reviewer ชัดเจน (เวลาทั้งหมดเป็น Asia/Bangkok UTC+7):

### B.1 สายงานที่ 1: React Port Autonomous Loop (`oho-web-app-react / react-p0`)

| เวลา (+07) | T3 Thread Link / ID | Transcript File | Provider / Model | Runs / Turns วันนี้ | Goal & กิจกรรม | Outcome |
|---|---|---|---|---:|---|---|
| 00:00:03 → 19:11:38 | [React P0 UX — pi implement (react-p0)](t3-thread://v1/mcp:63bd8d7c-1e69-40de-8d66-b808a5199755) | `01a18071-03fd-767a-a651-84b87c184c93.jsonl` | `pi` / `deepseek-flash` | 19 runs (12 completed, **7 failed**) / 372 turns (356 tools) | Implement & fix React port batches ต่อเนื่องจากเมื่อวาน ภายใต้ `react-port-keepalive.sh`: แก้ findings ของ `P1h, P1j, P1k, P1l, P1m, P1n, P1o` (ช่วง `00:00–02:15`), และเมื่อ keepalive อัปเดตฟีเจอร์ `RESUME-NEXT` ตอน `11:14` ก็รัน `P1r, P1s, P1t, P1u, P1v` จนเสร็จ (`819 tests`) | **สำเร็จ 11 batches (commits `4fe37d2`..`3d61350`) แต่ค้างที่ `P1w` ตอน `13:40:07`:** ชน `402 Insufficient Balance` ระหว่างรัน `P1r/P1s` fix + `P1w` และถูก keepalive ยิงซ้ำอีก 6 รอบ (`ordinal 47..52` ล้มเหลวทั้งหมด) |
| 00:07:43 → 13:39:32 | [React P0 UX — handoff (oho-web-app-react, react-p0)](t3-thread://v1/mcp:b1edee08-5636-4518-908c-86f65e470a54) | `23fb8e83-1bf6-4471-9e26-4a80070277f1.jsonl` | `claude-personal` / `claude-sonnet-5-5` | 13 runs (13 completed) / 98 API calls (92 tools) | ทำหน้าที่ **Reviewer-only** รับข้อความ `[review-handoff]` จาก `react-port-review-handoff.sh`: รีวิว `P1m`, `P1n`, re-check `P1h/j/k/l`, re-check `P1m/n`, รีวิว `P1o` (3 รอบจน `ready`), และช่วงบ่ายรีวิว `P1r` (`not ready`), `P1s` (`not ready`), `P1t` (`ready`), `P1u` (`ready`), `P1v` (`not ready`) | **สำเร็จครบทุกคำขอรีวิว (13/13 runs):** แยกแยะ `ready` vs `not ready` แม่นยำ และหยุดทำงานหลัง `13:39:32` เพราะฝั่ง `pi` ไม่มี `done.md` ใหม่ส่งมาอีก |

---

### B.2 สายงานที่ 2: การ์ด `OHO-2621` — พัฒนาการแสดงผลเมื่อไฟล์ใหญ่เกินไป (`oho-web-app`)

| เวลา (+07) | T3 Thread Link / ID | Transcript File | Provider / Model | Runs / Turns วันนี้ | Goal & กิจกรรม | Outcome |
|---|---|---|---|---:|---|---|
| 00:15:52 → 11:06:35 | [OHO-2621 [Review r3] พัฒนาการแสดงผลเมื่อไฟล์ใหญ่เกินไป (backdrop fix)](t3-thread://v1/3335b78b-8f9c-46a7-a767-b0b2b85ada7c) | `1af550f2-17d3-4d79-84cf-05f931e29f82.jsonl` | `claude-team` / `claude-sonnet-5-5` (fork จาก `54608d44`) | 11 runs / 49 API calls (46 tools) | Plan/Orchestrator ของ `OHO-2621`: ตรวจผล r1, สั่งแก้ r2 (คืน `@onExpandMediaFile` ใน `ReplyMessage.vue`), commit `15aa23cd5` & push ขึ้น `uat`, พอพบว่า backdrop ทับ modal บน UAT จึงสั่งแก้ r3 (`:append-to-body="true"` ใน `ModalFileTooLarge.vue:5`), commit `b663e9bab`, push และสลับ Cloud Run traffic `web-app--uat` 100% | **สำเร็จสมบูรณ์ (Deployed & Traffic Switched on UAT):** ปรับสถานะการ์ดเป็น `ready to test` |
| 00:16:34 → 00:18:58 | [OHO-2621 r1 review](t3-thread://v1/thread:delegated-task:command%3Amcp%3A9f027854-5250-4e98-a6a3-35738fc3912a%3Adelegate-task%3Aa864c1cc-ff2b-44af-8fc0-6622edc78edd) | `324eac9e-65d5-4a75-a4ed-ab68f05c2138.jsonl` | `claude-team` / `claude-opus-5-5` (`delegate_task` ของ `3335b78b`) | 1 run / 16 API calls (17 tools) | รีวิว diff รอบ 1 ของ `OHO-2621` บน worktree `fix-oho-2621-too-large-file-dialog` | **สำเร็จ:** `Verdict: ready` (0 Important, 2 Nit) ที่ head `0dd6d5082` |
| 09:49:37 → 10:50:46 | [OHO-2621 impl too-large file dialog](t3-thread://v1/mcp:316fc563-4878-4b37-b946-b990fbf185b0) | `01a182b2-f143-7392-8b66-165ca67f60ad.jsonl` | `pi` / `deepseek-flash` (ผูก worktree `fix-oho-2621`) | 2 runs วันนี้ (`ordinal 2, 3`) / 26 turns (26 tools) | รัน Round 2 (`09:49–09:50`: คืนค่า `ReplyMessage.vue` 1 บรรทัด) และ Round 3 (`10:49–10:50`: แก้ `:append-to-body="true"` ใน `ModalFileTooLarge.vue:5` + จับภาพ Playwright preview) | **สำเร็จอย่างรวดเร็ว:** รอบละ ~1 นาที เขียน `done.md` ครบตามรูปแบบ |
| 09:50:30 → 09:51:03 | [OHO-2621 r2 review (delta)](t3-thread://v1/thread:delegated-task:command%3Amcp%3A870387ea-83de-4983-b617-95e1df8f2e25%3Adelegate-task%3A01eb3114-36d5-410f-8037-76c27269d2ec) | `d6c85edf-f749-4637-8d49-62eb55d014f0.jsonl` | `claude-team` / `claude-opus-5-5` (`delegate_task` ของ `3335b78b`) | 1 run / 4 API calls (3 tools) | Delta re-review รอบ 2 ของ `OHO-2621` | **สำเร็จใน 33 วินาที:** `Verdict: ready` (0 Important) |
| 10:50:58 → 10:51:35 | [OHO-2621 r3 review (delta)](t3-thread://v1/thread:delegated-task:command%3Amcp%3Adf114c77-e917-411e-85d9-8d4af67d9f7c%3Adelegate-task%3A5df277ec-07c0-4405-a240-f17f52de33b5) | `b72991ad-0ff9-48eb-91a3-f33e0595a881.jsonl` | `claude-team` / `claude-opus-5-5` (`delegate_task` ของ `3335b78b`) | 1 run / 5 API calls (4 tools) | Delta re-review รอบ 3 (backdrop fix) ของ `OHO-2621` | **สำเร็จใน 37 วินาที:** `Verdict: ready` (0 Important) |

---

### B.3 สายงานที่ 3: Adhoc Tasks & Customer Support Cases (ช่วงเช้า–บ่าย)

| เวลา (+07) | T3 Thread Link / ID | Transcript File | Provider / Model | Runs / Turns วันนี้ | Goal & กิจกรรม | Outcome |
|---|---|---|---|---:|---|---|
| 10:02:44 → 10:14:04 | [ตรวจธุรกิจเชื่อม TikTok ใน UAT](t3-thread://v1/22d9f2c3-a6f0-4ef5-945f-4e1cddfd85f0) | `01a18229-8a0c-7734-8e79-f1d5ec715bd2.jsonl` | `pi` / `deepseek-flash` | 4 runs / 57 turns (61 tools) | เพิ่ม account ของผู้ใช้ (`tualek`) เข้าไปในธุรกิจที่เชื่อม TikTok บน UAT และเพิ่มเข้าทีมกลาง (`central team`) ใน MongoDB UAT | **สำเร็จ:** อัปเดตข้อมูลใน UAT DB ให้ผู้ใช้เข้าทดสอบ TikTok ได้ |
| 10:15:17 → 11:43:51 | [Change business login email](t3-thread://v1/19ea9e5e-3565-46fb-ac5c-795d31883c67) | `9d4c0a0d-3a60-469b-97b5-baf5d301521a.jsonl` | `claude-team` / `claude-sonnet-5-5` | 14 runs / 32 API calls (20 tools) | ตรวจสอบและเตรียมคำสั่งเปลี่ยนอีเมลล็อกอินและอีเมลโปรไฟล์ธุรกิจ (`users.email` และ `businesses.email`) บน PROD (อ่านผ่าน `mongo-ro prod` ปฏิเสธการรัน write เองตามกฎ แล้วให้ผู้ใช้รันคำสั่งแก้เอง จากนั้นอ่านยืนยันและบันทึกเคสลง `/Users/tualek/cs-agent-kit/cases/login-email-change-vr-treasure-2026-10-29.md`) | **สำเร็จและปลอดภัยตาม Guardrail 100%** |
| 10:19:35 → 10:20:08 | [Remove accidental git repo in workspace](t3-thread://v1/f38b6434-f18c-4159-8c96-a31afb480fb2) | `01a185ab-8f16-7422-ac43-f11c8bb8dd09.jsonl` | `pi` / `deepseek-flash` | 1 run / 8 turns (9 tools) | ลบ `.git` ที่เผลอกด `git init` ใน `/Users/tualek/ohochat` (workspace root ที่ไม่ใช่ git repo) | **สำเร็จใน 33 วินาที:** เช็กว่าไม่มี commit/remote แล้วลบ `/Users/tualek/ohochat/.git` |
| 10:27:13 → 10:30:32 | [Fix access token refresh on UAT](t3-thread://v1/0a96f9ec-1c7d-4e6a-8a44-37e146f5d734) | `eceec970-c91c-4582-b102-3e15856747fd.jsonl` | `claude-team` / `claude-sonnet-5-5` | 2 runs / 11 API calls (12 tools) | ตรวจสาเหตุที่การทดสอบ `OHO-8384` บน UAT เมื่อแก้ `access_token`/`refresh_token` เป็นค่าว่างแล้วไม่เกิด auto-refresh | **สำเร็จใน 3 นาที:** ชี้ชัดจาก UAT log ว่า TikTok ตอบ code `40104` ("The access_token is empty.") ไม่ใช่ `40105` ที่โค้ดดักไว้ |
| 11:15:10 → 11:32:02 | [Clear duplicate cases for Robinhood](t3-thread://v1/88a8fc77-e92b-4740-91d7-4ebfdd558693) | `bdd6be85-8e0b-40d8-bd7a-f4a5a11b4817.jsonl` | `claude-team` / `claude-sonnet-5-5` | 5 runs / 44 API calls (40 tools) | ตรวจสอบปัญหาเคสซ้อน (`inprogress` ค้างคู่กับเคสที่ปิดแล้ว) บน PROD จำนวน 10 เคส เสนอแผนใช้ `oho fix close_chat end_case` แทนการลบ doc ตรง ๆ รอผู้ใช้อนุมัติ แล้วรันปิดเคสซ้อนทั้ง 10 เคสพร้อม verify ด้วย `_id` | **สำเร็จ:** ปิดเคสซ้อนครบ 10 เคสโดยไม่กระทบเคสปัจจุบัน |
| 14:16:57 → 14:20:55 | [meta biz ai มีเปลี่ยน กระทบเราเยอะไหม](t3-thread://v1/6e207dae-7934-40e5-9d75-bfb62d384d9d) | `01343677-9387-4c20-bea9-f2f79321d408.jsonl` | `claude-team` / `claude-sonnet-5-5` | 2 runs / 10 API calls (8 tools) | วิเคราะห์ผลกระทบจากประกาศ Meta Business AI ต่อระบบ handoff detection ใน `oho-webhook` พร้อมเช็ก production log ย้อนหลัง 3 วัน | **สำเร็จใน 4 นาที:** สรุปว่ากระทบน้อยและชี้จุดแก้ regex บรรทัดเดียว |

---

### B.4 สายงานที่ 4: Sprint 22 Hub Orchestrator + `OHO-9014` + `OHO-9016/9017` + ชุดอัปเกรด Node 26.13.0 (`OHO-8915`, `OHO-8916`, `OHO-8917`)

> [!WARNING]
> **ข้อสังเกตเชิงโครงสร้าง:** แทนที่จะแยก 1 Plan Thread ต่อ 1 Card ตามที่ `skills/clickup-card/SKILL.md` กำหนด วันนี้ใช้ Thread [Sprint 22 assigned ClickUp tasks](t3-thread://v1/3561e062-e9a1-403a-a8b3-fff4a532d28f) (`5c57071e.jsonl`) เป็น **Mega-Orchestrator** คุมงานถึง **5 การ์ดรวด** (`OHO-9014`, `OHO-9016/9017`, `OHO-8915`, `OHO-8916`, `OHO-8917`) รวม **98 runs วันนี้ (299 API calls, 259 tool calls, 73.4M cache-read tokens)** จนเกิด context compaction ตอน `13:29:36`

| เวลา (+07) | T3 Thread Link / ID | Transcript File | Provider / Model | Runs / Turns วันนี้ | Goal & กิจกรรม | Outcome |
|---|---|---|---|---:|---|---|
| 09:56:02 → 19:27:50 | [Sprint 22 assigned ClickUp tasks](t3-thread://v1/3561e062-e9a1-403a-a8b3-fff4a532d28f) | `5c57071e-092c-40bd-a000-831d619935b2.jsonl` | `claude-team` / `claude-sonnet-5-5` | 98 runs (97 completed, 1 cancelled) / 299 API calls (259 tools) | **Mega-Orchestrator:**<br>1. `09:56–11:00`: จัดระเบียบ ClickUp Sprint 22, ปรับ estimate subtasks<br>2. `11:00–13:29`: คุมการ์ด `OHO-9014` (GTM tracking + staging-3 deploy + เปิด MR `!901`)<br>3. `13:30–14:30`: สืบสวน `OHO-9016/9017` (Bitly link กดไม่ได้บน Messenger iOS — ยิงทดสอบทุกท่าทั้ง attachment/tag จนพิสูจน์ว่าเป็นข้อจำกัดฝั่ง Meta iOS in-app browser กับ `bit.ly` แล้วร่างสรุปคอมเมนต์)<br>4. `14:42–19:28`: คุมการอัปเกรด **Node 26.13.0 LTS** พร้อมกัน 3 repos (`OHO-8915`, `OHO-8916`, `OHO-8917`) | **สำเร็จ:**<br>- `OHO-9014`: เปิด MR `!901` + deploy `staging-3` สำเร็จ<br>- `OHO-9016/9017`: สรุป root cause จบ<br>- `OHO-8915`: รีวิว `ready`<br>- `OHO-8916`: รีวิว `ready`<br>- `OHO-8917`: โค้ด + runbook รอบ 3 เสร็จ รอ commit/deploy |
| 11:00:00 → 11:00:40 | [Scout chat message model for payload](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A3561e062-e9a1-403a-a8b3-fff4a532d28f%253Aordinal%253A1%3Aafbd45bdefc10b197) | `agent-afbd45bdefc10b197.jsonl` | `claude-team` / `claude-haiku-5-5` (native `subagent` ของ `3561e062`) | 9 API calls (22 tools) | Scout หาตำแหน่ง chat message schema และ GTM tracking ใน `oho-api` / `oho-web-app` | **สำเร็จใน 40 วินาที** |
| 11:05:03 → 11:06:18 | [Draft OHO-9014 breakdown and brief](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A3561e062-e9a1-403a-a8b3-fff4a532d28f%253Aordinal%253A1%3Aa68334fa71bc05688) | `agent-a68334fa71bc05688.jsonl` | `claude-team` / `claude-opus-5-5` (native `subagent` ของ `3561e062`) | 14 API calls (14 tools) | ร่าง `breakdown.md` และ `brief.md` ของ `OHO-9014` | **สำเร็จใน 1 นาที 15 วินาที** |
| 11:12:50 → 11:57:35 | [OHO-9014 impl start-oho tracking](t3-thread://v1/mcp:de029436-3a96-4fa5-b486-7f1709bdd92a) | `01a185dc-5011-7731-91a5-ca87af06a6ad.jsonl` | `pi` / `deepseek-flash` (ผูก worktree `feature-oho-9014`) | 3 runs / 37 turns (40 tools) | Implement `OHO-9014` ทั้ง 3 รอบ: r1 (`plan-only`), r2 (ติด `data-tracking` ในหน้า `start-oho`), r3 (แก้ `plugins/gtm.js` ให้รองรับ `staging-N`) | **สำเร็จครบทั้ง 3 รอบ** (ค่าใช้จ่ายรวมเพียง `$0.0498`) |
| 11:17:44 → 11:18:33 | [OHO-9014 r2 review](t3-thread://v1/thread:delegated-task:command%3Amcp%3Af7490371-e12e-46a1-b7ca-d0b630ace902%3Adelegate-task%3A9dfd661d-24ec-4ff6-8f7e-3a9c32d20120) | `dc25580b-afa1-4dd2-9f99-653b482f5c92.jsonl` | `claude-team` / `claude-opus-5-5` (`delegate_task` ของ `3561e062`) | 1 run / 5 API calls (4 tools) | รีวิว diff รอบ 2 ของ `OHO-9014` | **สำเร็จใน 49 วินาที:** `Verdict: ready` (0 Important, 1 Nit) |
| 11:58:29 → 11:59:19 | [OHO-9014 r3 review](t3-thread://v1/thread:delegated-task:command%3Amcp%3Af7490371-e12e-46a1-b7ca-d0b630ace902%3Adelegate-task%3A17913654-4982-4324-9084-d1c9d5e43779) | `cddb131c-8a0a-45f5-9698-1f8153309627.jsonl` | `claude-team` / `claude-opus-5-5` (`delegate_task` ของ `3561e062`) | 1 run / 6 API calls (5 tools) | Delta review รอบ 3 (`plugins/gtm.js`) ของ `OHO-9014` | **สำเร็จใน 50 วินาที:** `Verdict: ready` (0 Important) |
| 17:25:25 → 17:25:31 | [OHO-8915 impl node 26.13.0](t3-thread://v1/mcp:03b24e8d-cdb2-46bd-a822-991ce45961b8) | `01a18731-6c89-71e0-b27a-22babad86257.jsonl` | `pi` / `deepseek-flash` (ผูก worktree `feature-oho-8915-node-26-alpine`) | 1 run (**failed**) / 1 turn (0 tools) | พยายามรัน Round 4 ของ `OHO-8915` (อัปเกรด `oho-web-app` จาก Node 24 เป็น 26.13.0) บน Pi | **ล้มเหลวใน 6 วินาที:** ชน `402 Insufficient Balance` |
| 17:26:56 → 17:39:58 | [OHO-8915 impl node 26.13.0 (sonnet)](t3-thread://v1/mcp:ea218a44-f4ce-4821-ae93-e4b20884aaff) | `6a4ab5a3-b845-4a1b-89f7-bba0d2d4321c.jsonl` | `claude-personal` / `claude-sonnet-5-5` (ผูก worktree `feature-oho-8915-node-26-alpine`) | 2 runs / 29 API calls (28 tools) | รับช่วงต่อจาก Pi: รัน Round 4 (อัปเกรด `Dockerfile` + `package.json` เป็น `26.13.0`, รัน Jest & Docker build) และ Round 5 (แก้ `package-lock.json` root engines 1 บรรทัด) | **สำเร็จใน 13 นาที (`STATUS: complete`)** |
| 17:40:19 → 18:18:16 | [OHO-8915 r4-5 review (opus)](t3-thread://v1/mcp:e6fbb30e-8d5a-431e-829c-48518c1f332f) | `6d6a3926-9a02-4857-8160-6addee602a68.jsonl` | `claude-team` / `claude-opus-5-5` (`effort: max`, ผูก worktree `feature-oho-8915-node-26-alpine`) | 1 run / 56 API calls (58 tools) | รีวิว Round 4–5 ของ `OHO-8915` (ถูกตั้ง `effort: max` โดยความเข้าใจผิดของ Orchestrator + เจอเครื่องหลับตอน `18:10:39–18:11:28`) | **สำเร็จ (`Verdict: ready`) แต่ใช้ทรัพยากรสูงเกินจำเป็น** (97.3k output tokens, `$6.82`–`$7.54`, นาน 38 นาที) |
| 17:51:47 → 19:03:47 | [OHO-8916 impl node 26.13.0 (sonnet)](t3-thread://v1/mcp:e7dee3b9-7543-4479-95fe-5702b7c0c88c) | `4b1601db-3fc3-45d0-af62-90a0aa1235aa.jsonl` | `claude-personal` / `claude-sonnet-5-5` (ผูก worktree `feature-oho-8916-node-26-alpine`) | 2 runs / 70 API calls (69 tools) | อัปเกรด `oho-media-api` เป็น Node 26.13.0:<br>- Round 2 (`17:51–18:30`): พบ blocker ว่าแอปบูตไม่ขึ้นเพราะ `buffer-equal-constant-time` เรียก `buffer.SlowBuffer` ที่ถูกถอดใน Node 26 (`STATUS: blocked`)<br>- Round 3 (`18:56–19:03`): อัปเดต `jws`/`jwa` ใน lockfile จนแอปบูตผ่านและทดสอบ JWT ครบ (`STATUS: complete`) | **สำเร็จครบสมบูรณ์ (`STATUS: complete`)** |
| 19:04:37 → 19:06:37 | [OHO-8916 r2-3 review (opus)](t3-thread://v1/mcp:46075a36-1b93-461c-9a78-e35780e8e87f) | `79213931-99ee-4f36-b504-6ad58fbc82a2.jsonl` | `claude-team` / `claude-opus-5-5` (`effort: medium`, ผูก worktree `feature-oho-8916-node-26-alpine`) | 1 run / 14 API calls (14 tools) | รีวิว Round 2–3 ของ `OHO-8916` ด้วย `effort: medium` | **สำเร็จใน 2 นาที (`Verdict: ready`, 0 Important, 2 Nit)** — เร็วกว่าตอนใช้ `effort: max` ถึง 19 เท่า! |
| 18:19:34 → 19:27:09 | [OHO-8917 impl node 26.13.0 (sonnet)](t3-thread://v1/mcp:13d36e36-be30-4637-8f77-49c0bc160366) | `37e1d3f7-fe5e-4759-a7ed-de7159ceaf81.jsonl` | `claude-personal` / `claude-sonnet-5-5` (ผูก worktree `feature-oho-8917-node-26`) | 3 runs / 86 API calls (85 tools) | อัปเกรด `oho-backoffice` (จาก Node 14!) เป็น Node 26.13.0:<br>- Round 1 (`18:19–18:25`): `STATUS: blocked` (ติด OpenSSL 3 md4 บน webpack 4 และ Dart Sass ปฏิเสธ `/deep/` 24 ไฟล์)<br>- Round 2 (`18:54–19:10`): อัปเกรด `nuxt ^2.18.1` + แปลง `/deep/` → `::v-deep` 68 จุด + pin `webpack ~4.47.0` & `postcss ^8.4.26` จน build & smoke ผ่าน (`STATUS: complete`)<br>- Round 3 (`19:25–19:27`): เพิ่ม `source /root/.nvm/nvm.sh;` ใน `ecosystem.config.yml` และเขียน `runbook.md` แก้ข้อบล็อกของ reviewer | **สำเร็จ (`STATUS: complete` ทั้งโค้ดและ `runbook.md`)** |
| 19:11:13 → 19:17:32 | [OHO-8917 r1-2 review (opus)](t3-thread://v1/mcp:e76544c1-3e8b-48f4-8d21-44d2c04ec213) | `fec1ea59-ed77-4159-8c11-7ba6c4362034.jsonl` | `claude-team` / `claude-opus-5-5` (`effort: medium`, ผูก worktree `feature-oho-8917-node-26`) | 1 run / 28 API calls (28 tools) | รีวิว Round 1–2 ของ `OHO-8917` (ตรวจ CSS selector equivalence, protected packages, และ PM2 deploy path) | **สำเร็จใน 6 นาที 19 วินาที:** ยืนยันว่าโค้ดและ CSS ผ่านทั้งหมด แต่ให้ `Verdict: not ready` (5 Important เรื่องขั้นตอน PM2 deploy runbook บน VM ที่รัน Node 14) ซึ่งถูกนำไปแก้ใน Round 3 ทันที |

---

### B.5 สายงานที่ 5: Retrospective Threads (รันขนาน 2 Providers ตอน 19:17)

| เวลา (+07) | T3 Thread Link / ID | Transcript File | Provider / Model | Runs / Turns วันนี้ | Goal & กิจกรรม | Outcome |
|---|---|---|---|---:|---|---|
| 19:17:09 → 19:30+ | [ช่วยทำ retro แบบละเอียดของ "ทุก AI session ของวันน...](t3-thread://v1/8d67a8dd-ec79-4713-a040-dfd85ae8bf05) | `dcdf6f79-9308-4b0f-b81e-79c028d77a21.jsonl` | `claude-personal` / `claude-opus-5-5` (`effort: high`) | 2 runs (run 1 interrupted ตอน `19:17:13`, run 2 running) / 41 API calls | ทำ Retrospective ของวันนี้ในฝั่ง Claude Opus (สังเกตเห็นว่า thread นี้กำลังทำงานอยู่จึงหลีกเลี่ยงการทับไฟล์เดียวกันและเขียนลง `notes/retro-20261029-claude.md`) | **สำเร็จ** |
| 19:17:43 → ปัจจุบัน | [ช่วยทำ retro แบบละเอียดของ "ทุก AI session ของวันน...](t3-thread://v1/4f8a12a1-f689-42c5-8bd7-4ffe723d6033) | `brain/f6889f11.../transcript.jsonl` | `antigravity` / `gemini-4-argon-high` | 1 run (running) | ทำ Retrospective แบบละเอียดของวันนี้ตามคำสั่งผู้ใช้และเขียนลง `/Users/tualek/ai-main/notes/retro-20261027-gemini.md` | **สำเร็จ (รายงานฉบับนี้)** |

---

## C. เวลา / Token ที่เสียเปล่า และสาเหตุเชิงลึก

1. **Keepalive ยิงซ้ำเข้า Thread ที่เครดิตหมด (`402 Insufficient Balance`) 6 รอบติดต่อกัน (เสียเวลาเปล่า 13:40–19:11):**
   - **หลักฐาน:** ใน `/Users/tualek/Library/Logs/react-port-keepalive.log` และ `statev2.sqlite` (`orchestration_v2_projection_runs` ของ thread `mcp:63bd8d7c` ordinal `46..52`)
   - **สาเหตุ (Bug ใน `/Users/tualek/.local/bin/react-port-keepalive.sh`):**
     - ตอน `13:40:07` `mcp:63bd8d7c` ล้มเหลวด้วย `status=failed` เพราะ DeepSeek ตอบ `402: {"message":"Insufficient Balance"}`
     - ใน `react-port-keepalive.sh` บรรทัด 158–160 มีการ์ดป้องกันการยิงซ้ำว่า:
       ```python
       if state.get("lastNudgeItemCount") is not None and state.get("lastNudgeItemCount") == items:
           print(f"NO-PROGRESS ...")
       ```
     - **ทำไมการ์ดนี้ไม่ทำงาน:** ตอนส่ง `t3 thread send` สำเร็จ บรรทัด 189 บันทึก `st["lastNudgeItemCount"] = t.get("itemCount")` จากไฟล์ `$TMP` ซึ่งดึงมาก่อนส่งข้อความ (`items = 1968`) แต่การส่งข้อความเข้า T3 แล้วได้ error กลับมาทำให้ `itemCount` ของ thread เพิ่มขึ้น **+2** ทุกครั้ง (`1968 -> 1970 -> 1973 -> 1977 -> 1979 -> 1981`) ดังนั้นใน tick ถัดไป `lastNudgeItemCount` จึงไม่เท่ากับ `items` เลยแม้แต่ครั้งเดียว!
     - นอกจากนี้ สคริปต์ไม่ได้ตรวจจับคำว่า `Insufficient Balance` / `402` / `quota` ในข้อความล่าสุดของ `pi` จึงยิงซ้ำทุก 30 นาทีต่อไปเรื่อย ๆ

2. **ตั้ง `effort: max` แทน `medium` บน Opus Reviewer ของ `OHO-8915` (เสียเวลา ~30 นาที และ ~`$6.00`):**
   - **หลักฐาน:** Thread `mcp:e6fbb30e-8d5a-431e-829c-48518c1f332f` (`6d6a3926.jsonl`, `17:40:19 -> 18:18:16`) ใช้ **56 API calls, 58 tool calls, 97,300 output tokens, 7.69M cache-read tokens (`$6.82` ใน `cost-state` / `$7.54` ตามเรต API)** เพื่อรีวิว diff ขนาดเพียง 3 ไฟล์ (`Dockerfile`, `package.json`, `package-lock.json`)
   - **เปรียบเทียบ:** เมื่อผู้ใช้ทักตอน `17:46:41` (`"ทำไมนายถึงเลือกใช้ opus max หรอฉันสงสัย"`) และสั่งให้ใช้ `medium` ในรอบถัดไป การรีวิว `OHO-8916` (`mcp:46075a36`, `79213931.jsonl`) ใช้เพียง **14 API calls, 11,008 output tokens (`~$1.24`) ในเวลา 2 นาที**
   - **สาเหตุ:** ใน `skills/clickup-card/SKILL.md` และ `config/workflow.md` เขียนว่า `"effort medium max"` (ตั้งใจหมายถึง "อย่างมากไม่เกิน medium") แต่ LLM ตีความคำว่า `max` ท้ายสุดเป็นระดับ `effort: "max"`

3. **ส่ง `OHO-8917` Round 2 ไปพยายามทำ Lockfile-Only 6 รอบก่อนยอมเพิ่ม `devDependencies` (เสียเวลา ~8 นาที, 18 tool calls):**
   - **หลักฐาน:** ใน `.scratch/OHO-8917/r2-lock-only*.log` (6 ไฟล์: `18:56` ถึง `19:02`) และ `37e1d3f7.jsonl`
   - **สาเหตุ:** Brief รอบ 2 ของ `OHO-8917` ไม่อนุญาตให้เพิ่ม `webpack` และ `postcss` ใน `package.json` และสั่งให้ลองแก้ผ่าน `package-lock.json` อย่างเดียวก่อน ทั้งที่ npm 11 บังคับให้ `npm ci` ตรวจความตรงกันของ root dependencies กับ `package.json` เสมอ สุดท้าย Implementer ต้องเขียน `DEVIATION` ขอเพิ่ม 2 บรรทัดใน `package.json` ซึ่ง Reviewer ยืนยันว่าถูกต้องและจำเป็น

4. **เครื่อง Mac หลับ / เน็ตตัดช่วง `18:10:39 – 18:11:40` และ `19:18 – 19:21`:**
   - **หลักฐาน:**
     - `6d6a3926.jsonl`: `18:10:39 API_ERR: Connection lost while your computer was asleep` ตามด้วย `ENOTFOUND api.anthropic.com` 7 ครั้ง
     - `4b1601db.jsonl`: `18:11:11–18:11:30` `ENOTFOUND` 6 ครั้ง
     - `5c57071e.jsonl`: `18:11:23–18:11:40` `ENOTFOUND` 6 ครั้ง และตอน `19:18:27 -> 19:21:50` stream ขาดกลางคัน (`run ordinal 91 cancelled` / ต้องส่งข้อความ `"Your response above was cut off mid-stream"` เพื่อต่อ)
     - `/Users/tualek/Library/Logs/react-port-keepalive.log`: มีบันทึก `GAP` ตลอดวันเมื่อไม่มี `caffeinate` ครอบ

5. **ความสับสนของ `t3_thread_launch` vs `delegate_task` และการผูก Worktree:**
   - **หลักฐาน:**
     - ตอนเช้า (`OHO-2621` r1–r3 และ `OHO-9014` r2–r3) Plan threads (`3335b78b` ใน `oho-web-app` และ `3561e062` ใน `ohochat`) ใช้ `delegate_task` เรียก Opus Reviewer ข้ามเข้าไปตรวจ worktree ได้สำเร็จ (เพราะส่ง absolute path ใน prompt ให้ Reviewer `cd` เข้าไปเอง)
     - ตอนเย็น (`OHO-8915`, `OHO-8916`, `OHO-8917`) Plan thread (`3561e062`) เปลี่ยนมาใช้ `t3_thread_launch` เปิด Top-level Reviewer threads (`mcp:e6fbb30e`, `mcp:46075a36`, `mcp:e76544c1`) พร้อม `workspaceStrategy: {type: "existing_worktree"}` ผูกกับ worktree เดียวกับ Implementer
     - **ความเสี่ยงสำคัญ:** การใช้ `t3_thread_launch` ผูก `existing_worktree` ซ้ำกับ Implement thread ทำให้มี **2 Top-level threads ผูกกับ worktree เดียวกัน** (เช่น `mcp:ea218a44` และ `mcp:e6fbb30e` ต่างผูกกับ `/Users/tualek/.t3/worktrees/oho-web-app/feature-oho-8915-node-26-alpine`) หากผู้ใช้กดลบ Reviewer thread ใน T3 UI เพื่อจัดระเบียบ Sidebar **T3 Worktree GC อาจลบโฟลเดอร์ worktree ของ Implement thread ทิ้งไปด้วยทันที!** (เหมือนที่เคยเกิดใน `OHO-8915` เมื่อวันที่ 27 ต.ค.)

6. **Zombie Processes ที่ยังค้างในระบบ (`ps aux`):**
   - `PID 74570`: `/Users/tualek/.local/bin/cursor-agent ... --yolo --resume 63fda548-f5a9-4507-a049-ce9d1014bd3f` (รันค้างตั้งแต่ `16Oct26` กินเวลา CPU สะสม `9:46.13` และยังแตะไฟล์ `store.db` วันนี้ตอน `19:21`)
   - `PID 27132`: `claude rc` (รันค้างตั้งแต่ `15Oct26` กินเวลา CPU สะสม `46:11.87`)
   - *(หมายเหตุ: ใน `notes/retro-20261027-applied.md` รายงานว่า PID เหล่านี้หายไปแล้ว แต่จากการตรวจ `ps aux` วันนี้ตอน `19:24` พบว่าทั้ง `PID 74570` และ `PID 27132` **ยังมีชีวิตอยู่จริง** บน `ttys013` และ `ttys000`)*

---

## D. สิ่งที่ Work ดีมากในวันนี้

1. **Permission Prompts หายไปเกือบ 100% (ผลจากการเพิ่ม 322 allow rules + `mongo-ro` เมื่อวันที่ 27 ต.ค.):**
   - ตลอดทั้งวันนี้ (กว่า 600 tool calls ใน Claude Code ทั้ง Personal และ Team) **ไม่มีการติด permission prompt ของคำสั่งอ่าน (`git`, `glab`, `gcloud`, `docker`, `mongo-ro`) เลย**
   - มีเพียง 1 ครั้งใน `5c57071e.jsonl` (`14:50:20`) ที่ผู้ใช้กดปฏิเสธ action เอง และ 2 ครั้งที่ `Monitor` บล็อกการใช้ `sleep` ใน foreground ตามที่ออกแบบไว้

2. **`mongo-ro` Guardrail ทำงานปกป้อง PROD ได้สมบูรณ์แบบ:**
   - ใน thread [Change business login email](t3-thread://v1/19ea9e5e-3565-46fb-ac5c-795d31883c67) (`9d4c0a0d.jsonl`) แม้ผู้ใช้จะพิมพ์ว่า `"แก้ได้เลย"` ตอน `10:38:50` ตัว Agent ก็ปฏิเสธการรันคำสั่งเขียนลง PROD เองอย่างสุภาพ อธิบายข้อจำกัดของ `mongo-ro` ส่ง script ให้ผู้ใช้รันเอง แล้วค่อยอ่านกลับมา verify ให้

3. **ฟีเจอร์ `RESUME-NEXT` ใน `react-port-keepalive.sh` (เพิ่มตอน `11:14`) ช่วยปลดล็อกงานค้างได้อัตโนมัติ:**
   - ก่อน `11:14` เมื่อ `pi` จบงานด้วย `STOP: NEEDS-DECISION` (เพราะบางข้อรอผู้ใช้ตัดสินใจ) keepalive จะหยุดนิ่งทั้งหมด (`02:37–11:08`)
   - หลังเพิ่ม `parse_actionable_next()` ตอน `11:14` keepalive สามารถอ่านบรรทัด `NEXT: P1s` ที่ไม่ต้องรอการตัดสินใจ แล้วสั่งรัน `P1s -> P1t -> P1u -> P1v` ต่อเนื่องจนเสร็จอัตโนมัติ พร้อมส่งให้ `mcp:b1edee08` รีวิวทุก 30 นาทีผ่าน `react-port-review-handoff.sh`

4. **การสลับไปรัน Parallel Implementers (`claude-personal` Sonnet) + Independent Reviewers (`claude-team` Opus) สำหรับ Node 26.13.0:**
   - เมื่อ `pi` เครดิตหมด การแยกโควตาโดยใช้ `claude-personal` (Sonnet `medium`) รัน Implementer 3 worktrees ขนานกัน และใช้ `claude-team` (Opus `medium`) รีวิว ทำให้งานใหญ่อย่างการย้าย `oho-web-app`, `oho-media-api`, และ `oho-backoffice` (จาก Node 14!) ขึ้น Node 26.13.0 เสร็จภายในช่วงเย็นวันเดียว
   - ตัวอย่างคุณภาพของ Opus Reviewer (`medium`): ใน `OHO-8917` (`fec1ea59.jsonl`) Reviewer เปิดอ่านซอร์สโค้ดของ `pm2` (`lib/API.js`) พิสูจน์ว่า `pm2 update` จะเขียนทับ `dump.pm2` ก่อนฆ่า daemon ดังนั้นถ้าสำรองไฟล์หลัง `pm2 update` จะไม่ทัน และตรวจพบว่า `origin/staging` มีไฟล์ `.vue` ที่มี `/deep/` มากกว่าบน `master` อยู่ 1 ไฟล์ (`components/Dialog/SwitchCenterModal.vue`) ซึ่งป้องกันคลื่นตายบน staging ได้จริง!

5. **Delta Re-Review ของ `OHO-2621` และ `OHO-9014` รวดเร็วและประหยัดมาก:**
   - การรัน Opus `medium` เฉพาะ delta diff (`d6c85edf`, `b72991ad`, `dc25580b`, `cddb131c`) ใช้เวลาเพียง **33–50 วินาทีต่อรอบ** และใช้เงินเพียง **`~$0.47–$0.54` ต่อรอบ**

---

## E. การใช้ Provider / Model และ Cost / Quota ต่อ Session

> [!NOTE]
> **คำอธิบายวิธีคำนวณ (สำคัญมากเพื่อความแม่นยำ):**
> - ในไฟล์ `.jsonl` ของ Claude Code แต่ละ API call ที่สตรีมออกมามักถูกบันทึกแยกเป็นหลายบรรทัด `type:"assistant"` ที่มี `message.id` เดียวกัน การนำ `usage` ทุกบรรทัดมาบวกกันตรง ๆ จะทำให้ตัวเลขเฟ้อขึ้น ~1.8–2.2 เท่า ตารางด้านล่างนี้จึง **Deduplicate ตาม `message.id` เฉพาะที่มี `timestamp >= 2026-10-29 00:00:00 +07`** แล้วคำนวณเทียบทั้ง:
>   1. **ตัวเลขจริงจาก `cost-state` ใน `.jsonl`** (ถ้ามีบันทึกไว้ — หมายเหตุ: `cost-state` ในไฟล์ที่รันข้ามวันเป็นยอดสะสมตั้งแต่สร้างไฟล์ จึงต้องหักยอดวันก่อนออก)
>   2. **ตัวเลขประเมินตามเรต API มาตรฐานของ Anthropic** (Sonnet: `$3/$15/cw $3.75/cr $0.30` ต่อ 1M tokens; Opus: `$5/$25/cw $6.25/cr $0.50`; Haiku: `$1/$5/cw $1.25/cr $0.10`) — ทั้งนี้ทั้ง `claude-personal` และ `claude-team` ใช้งานผ่าน Subscription Quota จึงไม่ได้ถูกเรียกเก็บเป็นรายดolarโดยตรง ยกเว้น `pi` (DeepSeek API) ที่ตัดเครดิตจริง

### E.1 ตารางสรุป Token & Cost ราย Session (เฉพาะวันที่ 2026-10-29)

| Provider / Account | Thread ID / ชื่อ Session | Transcript File | Model | API Calls วันนี้ (Tools) | Input / Cache Write (วันนี้) | Cache Read (วันนี้) | Output Tokens (วันนี้) | Cost จริงใน JSONL (วันนี้) | Cost ประเมินตามเรต API (วันนี้) |
|---|---|---|---|---:|---:|---:|---:|---:|---:|
| **pi (DeepSeek)** | `mcp:63bd8d7c` (React P0 impl) | `01a18071.jsonl` | `deepseek-flash` | 372 (356) | 918,051 / 0 | 321,206,400 | 136,159 | **`$2.3660` (จริง)** | `$2.3660` |
| **pi (DeepSeek)** | `mcp:316fc563` (OHO-2621 impl r2-3) | `01a182b2.jsonl` | `deepseek-flash` | 26 (26) | 251,977 / 0 | 6,853,376 | 11,859 | **`$0.1309` (จริง)** | `$0.1309` |
| **pi (DeepSeek)** | `22d9f2c3` (TikTok UAT DB) | `01a18229.jsonl` | `deepseek-flash` | 57 (61) | 82,644 / 0 | 5,516,160 | 20,204 | **`$0.0821` (จริง)** | `$0.0821` |
| **pi (DeepSeek)** | `mcp:de029436` (OHO-9014 impl r1-3) | `01a185dc.jsonl` | `deepseek-flash` | 37 (40) | 43,538 / 0 | 2,278,016 | 19,206 | **`$0.0498` (จริง)** | `$0.0498` |
| **pi (DeepSeek)** | `f38b6434` (Remove .git) | `01a185ab.jsonl` | `deepseek-flash` | 8 (9) | 2,988 / 0 | 402,048 | 2,626 | **`$0.0065` (จริง)** | `$0.0065` |
| **pi (DeepSeek)** | `mcp:03b24e8d` (OHO-8915 r4 fail) | `01a18731.jsonl` | `deepseek-flash` | 1 (0) | 0 / 0 | 0 | 0 | **`$0.0000` (402)** | `$0.0000` |
| *รวม Pi (DeepSeek)* | *6 active sessions* | | | *501 (492)* | *1.30M / 0* | *336.26M* | *190,054* | ***`$2.6353` (จริง)*** | *`$2.6353`* |
| **claude-personal** | `mcp:b1edee08` (React Reviewer) | `23fb8e83.jsonl` | `claude-sonnet-5-5` | 98 (92) | 218 / 372,168 | 19,819,831 | 72,146 | **`$4.3205` (จริง)** *(60.87−56.55)* | `$8.4244` (ประเมิน) |
| **claude-personal** | `mcp:13d36e36` (OHO-8917 impl r1-3) | `37e1d3f7.jsonl` | `claude-sonnet-5-5` | 86 (85) | 178 / 193,686 | 10,292,779 | 77,968 | *(ไม่มี cost-state)* | `$4.9842` (ประเมิน) |
| **claude-personal** | `mcp:e7dee3b9` (OHO-8916 impl r2-3) | `4b1601db.jsonl` | `claude-sonnet-5-5` | 70 (69) | 144 / 133,953 | 6,721,097 | 45,959 | *(ไม่มี cost-state)* | `$3.2085` (ประเมิน) |
| **claude-personal** | `mcp:ea218a44` (OHO-8915 impl r4-5) | `6a4ab5a3.jsonl` | `claude-sonnet-5-5` | 29 (28) | 62 / 73,021 | 1,976,279 | 13,787 | **`$0.6279` (จริง)** *(เฉพาะ r4)* | `$1.0737` (ประเมิน r4+r5) |
| **claude-personal** | `8d67a8dd` (Retro Claude Opus) | `dcdf6f79.jsonl` | `claude-opus-5-5` | 41 (42) | 86 / 202,998 | 5,905,329 | 45,124 | *(ไม่มี cost-state)* | `$5.3499` (ประเมิน) |
| *รวม Claude Personal* | *5 active sessions* | | | *324 (316)* | *688 / 0.98M* | *44.72M* | *254,984* | *Subscription Quota* | *`~$23.04` (ประเมิน)* |
| **claude-team** | `3561e062` (Sprint 22 Orchestrator) | `5c57071e.jsonl` | `claude-sonnet-5-5` | 299 (259) | 724 / 931,110 | 73,417,405 | 283,331 | **`$9.7425` (จริงถึง 14:52)** *(11.50−1.76)* | `$29.7690` (ประเมินทั้งวัน) |
| **claude-team** | `mcp:e6fbb30e` (OHO-8915 review max) | `6d6a3926.jsonl` | `claude-opus-5-5` | 56 (58) | 116 / 201,628 | 7,688,132 | 97,300 | **`$6.8180` (จริง)** | `$7.5373` (ประเมิน) |
| **claude-team** | `3335b78b` (OHO-2621 Plan/UAT) | `1af550f2.jsonl` | `claude-sonnet-5-5` | 49 (46) | 104 / 558,876 | 9,515,409 | 29,982 | **`$3.4871` (จริงวันนี้)** *(5.64−2.15)* | `$5.4004` (ประเมิน) |
| **claude-team** | `mcp:e76544c1` (OHO-8917 review med) | `fec1ea59.jsonl` | `claude-opus-5-5` | 28 (28) | 58 / 99,033 | 2,341,815 | 28,609 | *(ไม่มี cost-state)* | `$2.5054` (ประเมิน) |
| **claude-team** | `88a8fc77` (Robinhood dup cases) | `bdd6be85.jsonl` | `claude-sonnet-5-5` | 44 (40) | 98 / 92,274 | 3,661,672 | 22,420 | **`$0.9600` (จริง)** | `$1.7811` (ประเมิน) |
| **claude-team** | `OHO-2621 r1 review` (delegate) | `324eac9e.jsonl` | `claude-opus-5-5` | 16 (17) | 32 / 78,770 | 1,180,483 | 12,308 | **`$1.1128` (จริง)** | `$1.3904` (ประเมิน) |
| **claude-team** | `mcp:46075a36` (OHO-8916 review med) | `79213931.jsonl` | `claude-opus-5-5` | 14 (14) | 28 / 78,268 | 960,587 | 11,008 | *(ไม่มี cost-state)* | `$1.2448` (ประเมิน) |
| **claude-team** | `19ea9e5e` (Change login email) | `9d4c0a0d.jsonl` | `claude-sonnet-5-5` | 32 (20) | 84 / 67,290 | 2,036,508 | 16,558 | **`$0.6388` (จริง)** | `$1.1119` (ประเมิน) |
| **claude-team** | `Draft OHO-9014` (native subagent) | `agent-a68334fa.jsonl` | `claude-opus-5-5` | 14 (14) | 28 / 60,908 | 692,689 | 7,403 | *(ไม่มี cost-state)* | `$0.9122` (ประเมิน) |
| **claude-team** | `OHO-9014 r3 review` (delegate) | `cddb131c.jsonl` | `claude-opus-5-5` | 6 (5) | 12 / 47,204 | 308,458 | 3,635 | **`$0.5123` (จริง)** | `$0.5402` (ประเมิน) |
| **claude-team** | `OHO-9014 r2 review` (delegate) | `dc25580b.jsonl` | `claude-opus-5-5` | 5 (4) | 10 / 50,367 | 245,485 | 3,308 | **`$0.5185` (จริง)** | `$0.5203` (ประเมิน) |
| **claude-team** | `0a96f9ec` (TikTok 40104 UAT) | `eceec970.jsonl` | `claude-sonnet-5-5` | 11 (12) | 28 / 61,521 | 681,302 | 5,478 | **`$0.3694` (จริง)** | `$0.5173` (ประเมิน) |
| **claude-team** | `OHO-2621 r2 review` (delegate) | `d6c85edf.jsonl` | `claude-opus-5-5` | 4 (3) | 8 / 50,426 | 189,775 | 2,690 | **`$0.4955` (จริง)** | `$0.4773` (ประเมิน) |
| **claude-team** | `OHO-2621 r3 review` (delegate) | `b72991ad.jsonl` | `claude-opus-5-5` | 5 (4) | 10 / 45,489 | 248,351 | 2,937 | **`$0.4727` (จริง)** | `$0.4820` (ประเมิน) |
| **claude-team** | `6e207dae` (Meta Biz AI impact) | `01343677.jsonl` | `claude-sonnet-5-5` | 10 (8) | 22 / 50,069 | 540,333 | 5,155 | **`$0.3062` (จริง)** | `$0.4272` (ประเมิน) |
| **claude-team** | `Scout payload` (native subagent) | `agent-afbd45bd.jsonl` | `claude-haiku-5-5` | 9 (22) | 20 / 58,376 | 281,045 | 6,845 | *(ไม่มี cost-state)* | `$0.1353` (ประเมิน) |
| *รวม Claude Team* | *16 active sessions* | | | *602 (554)* | *1,382 / 2.53M* | *103.99M* | *538,967* | *Subscription Quota* | *`~$54.75` (ประเมิน)* |
| **antigravity** | `4f8a12a1` (Retro Gemini ฉบับนี้) | `f6889f11.../transcript.jsonl` | `gemini-4-argon-high` | ~12 (~32) | ~180k (ประเมิน) | — | ~12k (ประเมิน) | N/A | `~$0.50` (ประเมิน) |

---

## F. ความผิดพลาดที่เกิดซ้ำ (Recurring Mistakes)

1. **[เกิดซ้ำจาก 27 ต.ค. — รูปแบบใหม่] Background Automation Script ยิงซ้ำเมื่อชน Billing / Quota Error:**
   - เมื่อวันที่ 27 ต.ค. `p0-chain-v2.sh` ยิงซ้ำ 69 รอบตอนชน Claude Pro limit
   - วันนี้ (`2026-10-29`) `react-port-keepalive.sh` ยิงซ้ำ 6 รอบ (`14:08–19:11`) ตอนชน DeepSeek `402 Insufficient Balance` เพราะ:
     1. ไม่ได้ตรวจข้อความ error ประเภท billing/balance (`Insufficient Balance` / `402` / `quota`) ใน assistant turn ล่าสุด
     2. การเช็ก `lastNudgeItemCount == items` พังเสมอเมื่อ `t3 thread send` สร้าง user item + failed assistant item เพิ่มขึ้นรอบละ 2 items

2. **[เกิดซ้ำ] ใช้ Thread เดียว (`3561e062`) เป็น Mega-Orchestrator คุมหลายการ์ดจน Context บวม (73.4M cache-read tokens) และถูก Compaction:**
   - แม้ `skills/clickup-card/SKILL.md` จะระบุว่า *"One plan thread plus one implement thread per card"* แต่เมื่อผู้ใช้เริ่มถามจาก `"วันนี้ต้องทำ card อะไรบ้าง"` ใน thread `3561e062` ตัว Agent ก็รันงานของทั้ง `OHO-9014`, `OHO-9016/9017`, `OHO-8915`, `OHO-8916`, และ `OHO-8917` ใน thread เดียวกันถึง 98 runs (แม้ผู้ใช้จะเตือนตอน `11:04:09` ว่า `"นายเป็น แค่ orcreast งานใน sprint ต้องไปสร้าง สร้าง thread ใหม่ตาม card สิ"` ตัว Agent ก็ไปเปิดเฉพาะ Implement/Review threads แยก แต่ยังใช้ `3561e062` เป็น Plan thread รวมของทุกการ์ดอยู่ดี)

3. **[เกิดซ้ำ] ตั้งระดับ `effort` สูงเกินจำเป็น (`high` / `max`) โดยผู้ใชไม่ได้ขอ:**
   - เกิดขึ้น 2 ครั้งในเย็นวันนี้:
     - `17:26:56`: เปิด `OHO-8915 impl (sonnet)` ด้วย `effort: high` (จนผู้ใช้ทักตอน `18:21:12` ว่า `"sonnet จริงๆก็ใช้แค่ medium พอนะ"`)
     - `17:40:19`: เปิด `OHO-8915 r4-5 review (opus)` ด้วย `effort: max` เพราะอ่าน `"effort medium max"` ใน `SKILL.md` ผิด (จนผู้ใช้ทักตอน `17:46:41`)

4. **[เกิดซ้ำ] ผูกหลาย Top-level T3 Threads เข้ากับ Worktree เดียวกัน (`existing_worktree`):**
   - ทั้ง `OHO-8915`, `OHO-8916`, และ `OHO-8917` มีการเปิด Top-level Opus Reviewer thread ด้วย `t3_thread_launch` + `workspaceStrategy: {type: "existing_worktree"}` ชี้ไปที่ worktree เดียวกับ Implement thread ซึ่งเสี่ยงต่อการถูก T3 Worktree GC ลบโฟลเดอร์ทิ้งหากลบ Reviewer thread

5. **[เกิดซ้ำ] พยายามรัน `sleep` ใน Foreground Bash เพื่อรอ Background Docker Build:**
   - เกิดขึ้นใน `6a4ab5a3.jsonl` (`17:35:49`: `Blocked: sleep 60 followed by: tail -c 400 .scratch/OHO-8915/docker-build-26.log`) และ `4b1601db.jsonl` (`18:12:06`: `Blocked: sleep 150 followed by...`) ก่อนที่ Hook ของ Claude Code จะบล็อกและบังคับให้ใช้ `Monitor`

6. **[เกิดซ้ำ] Zombie Processes (`cursor-agent` PID 74570 และ `claude rc` PID 27132) ยังไม่ถูกฆ่าจริง:**
   - แม้จะมีกฎใน `RULES.md` และบันทึกใน `retro-20261027-applied.md` แต่โปรเซสทั้งสองตัวที่รันค้างมาตั้งแต่วันที่ 15–16 ต.ค. ยังคงทำงานอยู่ในเครื่องจนถึงตอนนี้

---

## G. ข้อเสนอปรับปรุงที่เป็นรูปธรรมสำหรับ `clickup-card` Skill, Rules และ Scripts (Diff-Style เท่านั้น)

> [!NOTE]
> ข้อเสนอทั้งหมดด้านล่างนี้อยู่ในรูปแบบ **diff-style ในรายงานเท่านั้น** (ไม่ได้แก้ไขไฟล์จริงตามข้อห้ามเด็ดขาด)

### G.1 แก้ไข [skills/clickup-card/SKILL.md](file:///Users/tualek/ai-main/skills/clickup-card/SKILL.md)
**ประเด็นที่แก้:**
1. เปลี่ยนคำว่า `"effort medium max"` ที่กำกวมจนทำให้ LLM ตั้ง `effort: "max"` เป็น `"effort: medium (never high or max unless the user explicitly asks)"`
2. กำหนด fallback ลำดับแรกเมื่อ `pi` (`deepseek-flash`) เครดิตหมด (`402 Insufficient Balance`) ให้สลับไปใช้ `claude-personal` / `claude-sonnet-5-5` (`effort: medium`) อย่างเป็นทางการ
3. ห้ามผูก Reviewer thread ด้วย `workspaceStrategy: {type: "existing_worktree"}` ซ้ำกับ `impl_thread` (เพราะถ้าลบ Reviewer thread แล้ว T3 GC จะลบ worktree ของ `impl_thread` ทิ้ง!) ให้เปิด Reviewer thread ที่ repo root (`workspaceStrategy` เว้นว่าง) แล้วสั่งให้ `cd <worktree>` ในบรรทัดแรกของ prompt แทน
4. เพิ่มกฎแยก Plan thread ต่อการ์ดเมื่อเริ่มจาก Sprint Hub thread

```diff
--- a/skills/clickup-card/SKILL.md
+++ b/skills/clickup-card/SKILL.md
@@ -1,10 +1,10 @@
 ---
 name: clickup-card
-description: Use when starting a ClickUp card (breakdown, estimate, dates, sprint), running its implementation as ONE pi + DeepSeek implement thread per card in T3 (bound to the card worktree) with the plan thread spawning its own Opus reviewer directly (effort medium max, independent of the implementer), or drafting the end-of-day progress and time log.
+description: Use when starting a ClickUp card (breakdown, estimate, dates, sprint), running its implementation as ONE implement thread per card in T3 (bound to the card worktree) with the plan thread spawning its own Opus reviewer directly (effort: medium — never high or max unless asked; independent of the implementer), or drafting the end-of-day progress and time log.
 ---
 
 # clickup-card
 
-Per-card workflow for Tualek. Two main T3 threads per card: the **plan thread** (this orchestrator: Claude Code on the Team account, T3 instance `Claude Team`, terminal alias `claude-team`, `CLAUDE_CONFIG_DIR=~/.claude-team`, effort medium: breakdown, brief, checks, ClickUp, mr.md) and ONE **implement thread** (pi + DeepSeek, top-level, bound to the card worktree so the user can use T3's git and MR UI). The plan thread (Claude Code on claude-team) spawns its own Opus reviewer directly (effort medium max). The reviewer is independent of the implementer (never spawned by or reporting via the implementer). Review is not a third top-level thread. The orchestrator never edits code.
+Per-card workflow for Tualek. Two main T3 threads per card: the **plan thread** (this orchestrator: Claude Code on the Team account, T3 instance `Claude Team`, terminal alias `claude-team`, `CLAUDE_CONFIG_DIR=~/.claude-team`, effort `medium`: breakdown, brief, checks, ClickUp, mr.md) and ONE **implement thread** (default: `pi` + `deepseek/deepseek-flash`; fallback when pi returns `402 Insufficient Balance`: `claude-personal` + `claude-sonnet-5-5` with `effort: medium`; top-level, bound to the card worktree so the user can use T3's git and MR UI). The plan thread spawns its own Opus reviewer directly with `effort: medium` (never `high` or `max` unless the user explicitly asks). The reviewer is independent of the implementer. The orchestrator never edits code.
+If the current thread is a general sprint/triage hub covering multiple cards, do NOT run 3+ cards inside the hub thread (causes >70M cache-read bloat and compaction); either launch one plan thread per card or keep the hub strictly to dispatching briefs/reviews.
 
@@ -26,7 +26,7 @@
 - Implementation goes to the card's single implement thread (step 3): pi + DeepSeek, top-level, bound to the card worktree; later rounds are `t3_thread_send` to the same thread. Fallbacks are listed in step 3. If asked to edit code here, dispatch instead. Never Codex: the user has no Codex subscription.
 - Review budget: one pass plus re-checks on the new diff only, max 3 rounds per MR, then `Step back:` to the user. One reviewer per round; do not stack reviewers.
-- Reviewer is always Claude Opus (never Gemini). Default: the plan thread (Claude Code on claude-team) spawns the reviewer directly (opus, effort medium max, role review, edits only `review.md`), fresh context each round; the reviewer is independent of the implementer (never spawned by or reporting via the implementer); fallback only if Claude quota is out or the plan thread's reviewer spawn errors: agy with `claude-opus-5-5-medium`. Judge against REVIEW.md + brief acceptance, not the plan's reasoning. No automatic extra high pass; run opus high only when the user asks.
+- Reviewer is always Claude Opus (never Gemini). Default: the plan thread (`claude-team`) spawns the reviewer directly (`claude-opus-5-5`, `effort: "medium"` — NEVER `"high"` or `"max"` unless the user explicitly asks; role review, edits only `review.md`), fresh context each round; the reviewer is independent of the implementer. Judge against REVIEW.md + brief acceptance, not the plan's reasoning.
 
@@ -47,7 +47,7 @@
   `cd <repo root> && git fetch origin master && git worktree add --no-track -b <branch> ~/.t3/worktrees/<repo>/<branch-slug> origin/master`
-  **T3 worktree GC:** deleting (or GC of) a T3 thread bound to a `worktreePath` deletes that folder from disk. Never delete `impl_thread` before the card is merged or closed, never reuse the `worktreePath` of a deleted thread without binding a live thread to it, and mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/` after every round.
+  **T3 worktree GC:** deleting (or GC of) ANY T3 thread bound to a `worktreePath` deletes that folder from disk. Bind ONLY `impl_thread` to `worktreePath` (`workspaceStrategy: {type: "existing_worktree"}`). NEVER bind a temporary reviewer thread to the same `worktreePath` (if the user deletes the reviewer thread later, T3 will delete the active worktree!). Reviewer threads launched via `t3_thread_launch` must omit `workspaceStrategy` (run at repo root) and `cd <worktree>` in their first Bash command. Mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/` after every round.
 
@@ -78,7 +78,7 @@
-**3e. Check, then review (plan thread spawns the reviewer).** On `STATUS: complete`, first mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/`; then the plan thread does the checks itself: `scout` maps every file:line in `done.md`, re-run each grep in `Grep proof`, the test and lint commands, `git log --oneline origin/master..HEAD` shows no executor commit, `git status --porcelain` and `git diff --stat` against Allowed files. Then the plan thread (Claude Code on claude-team) spawns its own Opus reviewer directly with `delegate_task` to `claude-team` **only when the reviewer stays in the same cwd/repo as the plan thread** (model claude-opus-5-5, effort medium max, role \"review\", isolation \"shared\", mode \"async\", title \"<CARD> r<N> review\"). **Hard rule: never `delegate_task` across repo or worktree** — it cannot change cwd (#17415). For a different checkout use `t3_thread_launch` + `workspaceStrategy: existing_worktree` or `t3 thread start <path> --worktree` and wait.
+**3e. Check, then review (plan thread spawns the reviewer).** On `STATUS: complete`, first mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/`; then the plan thread does the checks itself: `scout` maps every file:line in `done.md`, re-run each grep in `Grep proof`, the test and lint commands, `git log --oneline origin/master..HEAD` shows no executor commit, `git status --porcelain` and `git diff --stat` against Allowed files. Then the plan thread (`claude-team`) spawns its own Opus reviewer (`model: "claude-opus-5-5"`, `options: [{id: "effort", value: "medium"}]` — NEVER `"max"` or `"high"` unless asked). If using `t3_thread_launch` for a different repo/worktree, do NOT pass `workspaceStrategy: existing_worktree` (so only `impl_thread` owns the worktree binding); pass the worktree path in the prompt (`First: cd <worktree> && pwd && git rev-parse HEAD`).
 
@@ -87,6 +87,7 @@
 **Fallbacks for the implement thread** (tell the user which one and why; never switch silently):
+0. `pi` fails with `402 Insufficient Balance` / credit exhausted: launch ONE top-level `claude-personal` thread (`model: "claude-sonnet-5-5"`, `options: [{id: "effort", value: "medium"}]` — never `high` unless asked) bound to the card worktree via `workspaceStrategy: {type: "existing_worktree"}`, and record the new `impl_thread` in `rounds.md`.
 1. Plan thread has no `t3-code` MCP (plain terminal): `t3 thread start <repo root> "<prompt>" --provider pi --model deepseek/deepseek-flash --title "<CARD> impl" --wait --json`...
```

---

### G.2 แก้ไข [config/workflow.md](file:///Users/tualek/ai-main/config/workflow.md) และ [memory/lessons/RULES.md](file:///Users/tualek/ai-main/memory/lessons/RULES.md)

```diff
--- a/config/workflow.md
+++ b/config/workflow.md
@@ -51,7 +51,7 @@
-- Route substantial card/code work through T3 Code: a dedicated worktree under `~/.t3/worktrees/<repo>/<branch-slug>` bound to one implement thread (`workspaceStrategy: {type: "existing_worktree"}`), one writer per checkout. The plan thread (Claude Code on claude-team) spawns its own Opus reviewer directly (effort medium max). The reviewer is independent of the implementer (never spawned by or reporting via the implementer). Before interactive work in a checkout, check `ps aux` that no background chain/script still drives it; kill that script first on handoff.
+- Route substantial card/code work through T3 Code: a dedicated worktree under `~/.t3/worktrees/<repo>/<branch-slug>` bound to ONE implement thread (`workspaceStrategy: {type: "existing_worktree"}`), one writer per checkout. Never bind a second thread (such as a reviewer thread) to the same `worktreePath`, because deleting either thread triggers T3 worktree GC. The plan thread (`claude-team`) spawns its own Opus reviewer directly with `effort: medium` (never `high` or `max` unless asked). Before interactive work in a checkout, check `ps aux` that no background chain/script still drives it; kill that script first on handoff.
@@ -63,4 +63,4 @@
-- Headless/chain scripts calling `claude -p`: when output matches `hit your (session|weekly) limit · resets <time>`, never loop on a fixed short sleep; parse the reset time and sleep until reset + 2 min, or exit if an interactive T3 handoff owns the checkout. Use a pidfile lock so only one instance runs.
+- Headless/chain/keepalive scripts (`claude -p`, `t3 thread send`): when a thread or command fails with billing/quota errors (`402`, `Insufficient Balance`, `hit your (session|weekly) limit`), immediately hold or exit instead of nudging on every cron tick. Never compare pre-send `itemCount` to post-send `itemCount` for stall detection, because a failed send+response increments `itemCount` by 2 on every retry.
```

```diff
--- a/memory/lessons/RULES.md
+++ b/memory/lessons/RULES.md
@@ -22,3 +22,5 @@
 - [*] **doc section delete**: if told to delete a section only when all about X, keep non-X paragraphs (hits:1)
 - [*] **jsonl timestamp**: filter events by timestamp, not file mtime; dedupe forked session ids (hits:1)
 - [*] **background script handoff**: kill the script PID and check ps aux before interactive T3 use (hits:1)
+- [*] **default effort is medium**: use `effort: medium` for Sonnet implementers and Opus reviewers unless the user explicitly asks for `high`/`max` (hits:2)
+- [*] **keepalive billing/failed guard**: stop nudging a T3 thread when its latest run is `failed` with `402 Insufficient Balance` or when `itemCount <= lastNudgeItemCount + 2` with no new tool/file progress (hits:2)
```

---

### G.3 แก้ไข `/Users/tualek/.local/bin/react-port-keepalive.sh`
**ประเด็นที่แก้:**
1. ดักจับ `Insufficient Balance` / `402` / `quota` หรือกรณีที่ `status == "failed"` ติดต่อกัน เพื่อหยุดส่ง `NUDGE IDLE` ทันที (ป้องกันการยิงซ้ำทุก 30 นาทีเหมือนที่เกิดตอน `14:08–19:11`)
2. แก้การเทียบ `lastNudgeItemCount`: เมื่อส่งข้อความ nudge แล้วล้มเหลวทันที `itemCount` จะเพิ่มขึ้น `+2` (user message + failed assistant message) โดยที่ `scratch_fp` (ไฟล์งานจริงใน `.scratch/p0`) ไม่ขยับเลย จึงต้องเช็ก `lastNudgeScratchFp == scratch_fp` ร่วมด้วย

```diff
--- a/Users/tualek/.local/bin/react-port-keepalive.sh
+++ b/Users/tualek/.local/bin/react-port-keepalive.sh
@@ -142,6 +142,14 @@
 text = (last_assistant() or {}).get("text") or ""
 asst = last_assistant() or {}
+asst_err = str(asst.get("errorMessage") or asst.get("error") or "") + "\n" + json.dumps(d)
+
+if re.search(r"Insufficient Balance|insufficient_balance_error|\"402\"|402:|hit your (session|weekly) limit", text + "\n" + asst_err, re.I):
+    print(f"HOLD-BILLING-OR-LIMIT {info} (provider returned balance/quota error; stop nudging)")
+    sys.exit()
+
 asst_id = asst.get("id") or asst.get("messageId") or ""
 asst_ts = asst.get("createdAt") or asst.get("timestamp") or asst.get("updatedAt") or updated or ""
 
@@ -168,7 +176,9 @@
 kind = "STALLED" if busy_like else "IDLE"
-if state.get("lastNudgeItemCount") is not None and state.get("lastNudgeItemCount") == items:
+if (state.get("lastNudgeItemCount") is not None and items <= state.get("lastNudgeItemCount") + 2) or (
+    state.get("lastNudgeScratchFp") is not None and state.get("lastNudgeScratchFp") == scratch_fp
+):
     print(f"NO-PROGRESS {kind} {info} age={int(age)}s (last nudge produced nothing)"); sys.exit()
-print(f"NUDGE {kind} {info} age={int(age)}s")
+print(f"NUDGE {kind} scfp={scratch_fp} {info} age={int(age)}s")
 PY
 )
 ACTION=${DECISION%% *}
```

---

## H. Top 5 Actions ที่ควรทำก่อน

1. **หยุด `react-port-keepalive.sh` ชั่วคราว หรือเติมเครดิต DeepSeek พร้อมแก้บั๊ก `NO-PROGRESS` ใน `/Users/tualek/.local/bin/react-port-keepalive.sh`:**
   - ขณะนี้ LaunchAgent `com.tualek.react-port-keepalive` ยังคงรันทุก 30 นาทีและยิง `NUDGE IDLE` เข้า thread `mcp:63bd8d7c` ที่ติด `402 Insufficient Balance` ไปแล้ว 6 รอบ (`ordinal 47..52`)
   - **คำสั่งหยุดทันที:** `touch ~/.react-port-keepalive.off` (หรือเติมเครดิต DeepSeek แล้วแก้สคริปต์ตามข้อ G.3)

2. **ฆ่า Zombie Processes ที่ค้างมาตั้งแต่ 15–16 ต.ค. (`PID 74570` และ `PID 27132`):**
   - จาก `ps aux` วันนี้ โปรเซส `cursor-agent` (`PID 74570`, กิน CPU 9m46s และยังเขียน `store.db` ตอน `19:21`) และ `claude rc` (`PID 27132`, กิน CPU 46m11s) ยังไม่ตายจริง
   - **คำสั่ง:** `kill -15 74570 27132`

3. **แก้ไขวลี `"effort medium max"` และกฎการผูก `existing_worktree` ใน [skills/clickup-card/SKILL.md](file:///Users/tualek/ai-main/skills/clickup-card/SKILL.md) และ [config/workflow.md](file:///Users/tualek/ai-main/config/workflow.md) (ตามข้อ G.1–G.2):**
   - เปลี่ยนเป็น `effort: medium (never high or max unless asked)` เพื่อไม่ให้เสียโควตา Opus `max` รอบละ `$7.50` / 38 นาทีเหมือนใน `OHO-8915`
   - ห้ามผูก Reviewer thread (`mcp:e6fbb30e`, `mcp:46075a36`, `mcp:e76544c1`) เข้ากับ `existing_worktree` ซ้ำกับ Implement thread และ **ห้ามกดลบ Reviewer threads ทั้ง 3 ตัวนี้ใน T3 UI จนกว่าจะ commit/push งานเสร็จ** เพราะ T3 Worktree GC จะลบโฟลเดอร์ worktree ทิ้ง!

4. **ปิดงานชุดอัปเกรด Node 26.13.0 (`OHO-8915`, `OHO-8916`, `OHO-8917`) ที่ทำเสร็จรออยู่ใน Worktrees:**
   - `OHO-8915` (`oho-web-app`, worktree `feature-oho-8915-node-26-alpine`): รีวิว `ready` แล้ว รอเพียงอนุมัติ `commit` และ `push` ขึ้น `staging-4` / อัปเดต MR `!900`
   - `OHO-8916` (`oho-media-api`, worktree `feature-oho-8916-node-26-alpine`): รีวิว `ready` แล้ว รอเพียงอนุมัติ `commit` และ `push` ขึ้น `staging-4` / อัปเดต MR `!21`
   - `OHO-8917` (`oho-backoffice`, worktree `feature-oho-8917-node-26`): Round 3 แก้ `ecosystem.config.yml` + เขียน `runbook.md` เสร็จแล้ว (`19:27:09`) พร้อมให้ตัดสินใจเรื่อง 2 devDependencies (`webpack`, `postcss`) และสั่ง delta re-review / deploy `staging-4`

5. **ปลดบล็อก `P1n` ของ React Port (`oho-web-app-react`) เมื่อพร้อมรันต่อ:**
   - ปัจจุบัน React port เสร็จถึง `P1v` (`819 tests` ผ่าน) เหลือข้อบล็อกจากผู้ใช้เพียงข้อเดียวใน `P1n` คือการแคปภาพหน้าจอ `smartchat-room-label-1280.png` และ `smartchat-room-label-request-1280.png` จาก legacy `oho-web-app` (`:3000`) ที่มีห้องแชทเปิดอยู่ แล้ววางลงใน `.scratch/p0/visual/legacy/`
