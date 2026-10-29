# Retrospective รายละเอียดทุก AI Session ประจำวันที่ 2026-10-27 (Asia/Bangkok UTC+7)

- **ผู้จัดทำ:** Gemini (`antigravity` / `gemini-4-argon-high`, T3 thread `[Retro AI sessions 2026-10-27 (Gemini argon)](t3-thread://v1/mcp:117092e3-8f22-4ff7-a689-01ec99b7de26)`)
- **เวลาที่เก็บข้อมูล:** 2026-10-27 23:31–23:41 (+07) แบบ **READ-ONLY 100%**
- **แหล่งข้อมูลที่ตรวจสอบครบถ้วน:**
  1. `~/.t3/userdata/statev2.sqlite` (`orchestration_v2_projection_threads`, `orchestration_v2_projection_runs`, `orchestration_v2_projection_subagents`, `projection_projects`) และ `t3 thread list` / `t3 thread show` / `t3_thread_read`
  2. `~/.claude/projects/**/*.jsonl` (Claude Personal Pro) และ `~/.claude-team/projects/**/*.jsonl` (Claude Team) ที่ `mtime >= 2026-10-27 00:00:00 +07`
  3. `~/.pi/agent/sessions/**/*.jsonl` (Pi 1.4.0 sessions ที่ modified วันนี้)
  4. `~/.cursor/chats/**/store.db`, `~/.cursor/ai-tracking/ai-code-tracking.db`, `~/.cursor/cli-config.json`, และ `ps aux` (Cursor CLI / IDE agents)
  5. โน้ตวันนี้ใน `/Users/tualek/ai-main/notes/*20261027*.md` (รวมถึง `retro-20261027.md` และ `t3-nested-subagent-test-20261027.md`)
  6. `/Users/tualek/ai-main/skills/clickup-card/{SKILL.md,templates.md,compact-hook.sh}`, `/Users/tualek/ai-main/core/hooks/guard.sh`, `/Users/tualek/ai-main/config/{workflow.md,review.md}`, `/Users/tualek/ai-main/memory/lessons/RULES.md`, และ `/Users/tualek/orca/workspaces/oho-web-app-react/react-p0/.scratch/p0/{p0-chain-v2.sh,chain.log,status.md,batches.tsv}`

> [!IMPORTANT]
> **ข้อค้นพบสำคัญจากการตรวจสอบเชิงลึก (Data Forensics vs `retro-20261027.md` เดิม):**
> 1. **Session เก่าของ Claude Personal ถูกนับผิดว่าเป็นของวันนี้ใน `retro-20261027.md`:** ไฟล์ `~/.claude/projects/-Users-tualek-ohochat/46e58185-1b26-4082-b35a-20816e38e388.jsonl` (219 user msgs, 733 tool calls, 1.36M output tokens, 147.2M cache-read, `$53.81`) แท้จริงแล้วรันเมื่อ **2026-10-16 09:52 ถึง 2026-10-22 14:33 (+07)** (0 API call ในวันนี้) แต่ `mtime` เปลี่ยนเป็น `13:31:16` วันนี้เพราะ Claude Desktop เขียนบรรทัด `cost-state` ปิดท้ายตอน sync เช่นเดียวกับ `90e9d816-cb93-495f-9b00-6e47eeb10359.jsonl` (+ 6 Opus subagents, `$8.36`) ที่รันเมื่อ **2026-10-14 16:43–18:47 (+07)** และ `19e9e15c-267e-432e-bdf8-c3f4097de366.jsonl` (`$0.77`) ที่รันเมื่อ **2026-10-15 11:03–13:01 (+07)** (วันนี้มีแค่ event `pr-link !898` ตอน `13:51:12` ไม่มี LLM call)
> 2. **Pi `cacheRead` 65.7M ใน `retro-20261027.md` เป็นตัวเลขที่ถูกนับซ้ำจาก Fork + รวมยอดวันที่ 26 ต.ค.:** ไฟล์ `2026-10-27T10-34-26-902Z_01a17cec-f6d6-7596-9fbb-f022cdb914a0.jsonl` (thread `39952c4f-0128-4d4e-98ad-08ddf8c7a7c6`) เป็น fork ของ `2026-10-26T05-59-13-642Z_01a176ca-a1e9-70df-8c45-015db618b246.jsonl` (thread `f8f9a4c1-b7fb-43e6-b5d9-bfea4415a14e`) โดยคัดลอก entry เดิมมา 383 บรรทัด (`28.72M` cacheRead) และรันเพิ่มวันนี้เพียง 3 turns (`485.5k` cacheRead) ยอดใช้งาน Pi สุทธิเฉพาะวันที่ 2026-10-27 จริง ๆ คือ **`22.58M` cacheRead tokens (`$0.5812`)** ไม่ใช่ `65.7M`
> 3. **`OHO-8915 r3` ไม่ได้รันช้า 3 ชม. 25 นาทีเพราะ DeepSeek:** จาก transcript `01a17d40` และ `ce5ec979` ตัว executor (`deepseek-flash`) รันงานและ Docker build/test เสร็จใน **26 นาที** (`19:05:43 -> 19:31:40`) แต่เกิด `Connection error` 4 ครั้งติดกันตอน `19:31:44–19:32:07` พร้อมกับที่ฝั่ง `claude-team` (`ce5ec979`) เกิด `api_error` ตอน `19:32:13–20:51:06` และ `21:06:53` (เครื่องหลับ/เน็ตหลุด) พอกลับมาสั่ง `ทำต่อได้ไหม` ตอน `22:29:26` ใช้เวลาอีกเพียง **39 วินาที** (`22:29:26 -> 22:30:05`) ก็เขียน `done.md` จบ
> 4. **เหตุการณ์หลัง `22:51` (หลัง `retro-20261027.md` เขียนเสร็จ):**
>    - ตอน `22:37:30` งาน `OHO-8915` ถูก commit ลง branch `feature/oho-8915-node-24-alpine` แล้ว 2 commits (`f75ccdf53`, `73a43902e`) แต่ตอน `22:56` directory `/Users/tualek/.t3/worktrees/oho-web-app/feature-oho-8915-node-24-alpine` ถูกลบอีกรอบเพราะผูกอยู่กับ thread `mcp:ca8e1613` ที่ถูกลบไปแล้ว (`deleted_at: 18:32:17`)
>    - หลัง `23:00` (โควตา Claude Personal Pro reset) เกิด **Dual-Driver Collision** ตอน `23:06:50`: `p0-chain-v2.sh` (PID 17082) ตื่นมาสั่ง headless Claude (`b7f367c9`) ทำ `P02d` ชนกับ T3 thread `mcp:b1edee08-5636-4518-908c-86f65e470a54` (`23fb8e83`) ที่เริ่มรันตอน `23:06:59` ก่อนที่ผู้ใช้จะสั่งหยุด chain แล้วให้ T3 thread ทำ `P02d` จนเสร็จสมบูรณ์ตอน `23:34:16` (และกำลังรันรอบ 5 ตอน `23:38:08` เพื่อปรับ float contact tab ตามภาพแคป)

---

## A. สรุปภาพรวมวัน (จำนวน Session แยกตาม Provider / Model)

นับเฉพาะไฟล์และ thread ที่มีการสร้างหรือแก้ไขในวันที่ **2026-10-27 (00:00–23:41 UTC+7)**:

| แหล่งข้อมูล / Provider | Model | จำนวน Session / Thread ทั้งหมด (ไฟล์ที่แตะวันนี้) | จำนวนที่ Active จริงวันนี้ (มี LLM Turn วันนี้) | หมายเหตุสำคัญ |
|---|---|---:|---:|---|
| **T3 Code Threads** (`statev2.sqlite`) | ทุก provider รวมกัน | **17 threads** | **17 threads** | เป็น Top-level 10 threads (ลบแล้ว 4, อยู่ 6) + Nested Subagent 7 threads (`claude-team` 5, `pi` 2) |
| └─ T3: `pi` | `deepseek/deepseek-flash` | 8 threads | 8 threads | Top-level 5 (fork 1, ลบแล้ว 3) + `delegate_task` child 2 (`OHO-8915 r2`, `r3`) + 1 web brief |
| └─ T3: `claude-team` | `claude-sonnet-5-5` | 2 threads | 2 threads | `1f6be3d6` (`OHO-8883`), `ba9f806a` (`Monitor unread-unresponded`) |
| └─ T3: `claude-team` (subagents) | `claude-opus-5-5` (4), `claude-haiku-5-5` (1) | 5 threads | 5 threads | Native Claude `Agent` 4 threads + MCP `delegate_task` 1 thread (`design sub-agent`) |
| └─ T3: `claude-personal` | `claude-sonnet-5-5` | 1 thread | 1 thread | `mcp:b1edee08-5636-4518-908c-86f65e470a54` (`React P0 UX — handoff`, กำลังรัน `P02d`) |
| └─ T3: `antigravity` | `gemini-4-argon-high` | 1 thread | 1 thread | `mcp:117092e3-8f22-4ff7-a689-01ec99b7de26` (session ปัจจุบันที่ทำ retro นี้) |
| **Claude Code: Personal Pro** (`~/.claude/projects`) | `claude-sonnet-5-5`, `claude-opus-5-5`, `<synthetic>` | **98 ไฟล์ `.jsonl`** | **21 sessions** (+ **69 limit stubs**) | 98 ไฟล์ = `react-p0` 86 ไฟล์ (งานจริง 18 + limit stub 68) + นอก `react-p0` 12 ไฟล์ (งานจริงวันนี้ 2 + limit stub 1 + **ไฟล์เก่าจาก 14–22 ต.ค. ที่แค่อัปเดต `cost-state`/`pr-link` 9 ไฟล์**) |
| └─ Personal Real: `claude-sonnet-5-5` | `claude-sonnet-5-5` | 13 sessions (วันนี้) | 13 sessions | `react-p0` implement/fix 11 sessions (รวม T3 handoff `23fb8e83` และ `b7f367c9`) + probe 2 sessions (`e563bf81`, `a2c117b6`) |
| └─ Personal Real: `claude-opus-5-5` | `claude-opus-5-5` | 7 sessions (วันนี้) | 7 sessions | Reviewer ของ `react-p0` (`P02b` r2–r3, `P04` r1–r3, `P02c` r1–r2) |
| └─ Personal Limit Stubs | `<synthetic>` (0 tokens) | 69 sessions | 0 LLM turns | `react-p0` 68 ไฟล์ (`weekly limit resets 1pm` 46, `session limit resets 6pm` 18, `resets 11pm` 4) + `/tmp` probe `a3003b63` 1 ไฟล์ |
| └─ Personal Historical (mtime วันนี้) | `sonnet-5-5` (3), `opus-5-5` (6) | 9 ไฟล์เก่า | 0 LLM turns วันนี้ | `46e58185` (16–22 ต.ค.), `19e9e15c` (15 ต.ค.), `90e9d816` + 6 subagents (14 ต.ค.) |
| **Claude Code: Team** (`~/.claude-team/projects`) | `sonnet-5-5` (2), `opus-5-5` (4), `haiku-5-5` (1) | **7 ไฟล์ `.jsonl`** | **7 sessions** | ตรงกับ T3 `claude-team` ทั้ง 7 threads แบบ 1:1 (ไม่มี limit stub) |
| **Pi Agent Sessions** (`~/.pi/agent/sessions`) | `deepseek/deepseek-flash` | **8 ไฟล์ `.jsonl`** | **8 sessions** | 7 ไฟล์ผูกกับ T3 threads + 1 ไฟล์ headless smoke test (`01a17ce9` ใน `/private/tmp/t3vis-test`) |
| **Cursor CLI / IDE** (`~/.cursor`) | `cursor-agent` | **0 session ใหม่วันนี้** | **0 session วันนี้** | `store.db` ล่าสุดใน `~/.cursor/chats` คือ `2026-10-25 23:49` แต่มี **zombie `cursor-agent` processes ค้างในเครื่อง 2 ตัวตั้งแต่ 16 ต.ค.** (`PID 74570`, `PID 35947`) |

---

## B. รายละเอียดต่อ Session: Timeline, Goal, Outcome

### B.1 T3 Code Threads ทั้ง 17 Threads (เรียงตามเวลาเริ่ม UTC+7)

| # | เวลา (+07) | Thread Link / ID | Provider / Model (Parent) | Goal | Outcome & หลักฐาน |
|---|---|---|---|---|---|
| 1 | 26 ต.ค. 12:59 → 27 ต.ค. 13:54 (ลบ 17:30) | `[Replica Lag From Metrics Deletes](t3-thread://v1/f8f9a4c1-b7fb-43e6-b5d9-bfea4415a14e)` | `pi` / `deepseek-flash` (root, `ohochat`) | ติดตามปัญหา MongoDB replica lag จากการลบ metrics ต่อจาก `.scratch/OHO-5627/` และรัน live monitor | **สำเร็จ** (16 runs, 32 msgs; เฉพาะวันนี้ 51 turns) ก่อนถูก fork ไปปิด monitor แล้วลบ thread ตอน `17:30:00` (Pi file: `01a176ca`) |
| 2 | 14:05:11 → 17:18:59 (อัปเดต 17:30) | [Pipe-Separated Business ID Groups](t3-thread://v1/a3185c42-3984-445a-a019-9e54412370a7) | `pi` / `deepseek-flash` (root, `ohochat`) | แบ่งกลุ่ม Mongo ObjectId (business IDs 18 รายการ) ออกเป็นกลุ่มละ 9 คั่นด้วย `\|` และตรวจสอบความถูกต้อง | **สำเร็จ** (4 runs, 8 msgs, 1 tool call `diff` ยืนยันครบ 18 IDs ไม่ซ้ำ; Pi file: `01a17c2d`) |
| 3 | 17:29:47 → 17:34:44 (อัปเดต 17:49) | [Stop Replica Lag Monitor](t3-thread://v1/39952c4f-0128-4d4e-98ad-08ddf8c7a7c6) | `pi` / `deepseek-flash` (`fork` ของ `f8f9a4c1`) | หยุด `live_server.py`, `monitor.sh`, `monitor2.sh`, ปิดพอร์ต `8791` และปิดแท็บ preview | **สำเร็จ**ภายใน 18 วินาที (1 run, 3 turns ใหม่ใน Pi file `01a17cec`) |
| 4 | 17:34:51 → 17:34:56 (ลบ 17:38) | `[TEST clickup-card T3 visibility (safe to delete)](t3-thread://v1/mcp:94d197d3-d66f-47ab-abf7-fc7547614e29)` | `pi` / `deepseek-flash` (root, `ai-main`) | ทดสอบว่า `t3 thread start --provider pi` แสดงใน T3 UI และ `t3 thread list` หรือไม่ (`ok-t3`) | **สำเร็จ** (1 run, ตอบ `ok-t3`, ลบตอน `17:38:21`; Pi file: `01a17ced`) |
| 5 | 17:39:36 → 22:37:42 (อัปเดต 23:07) | [OHO-8883 Brief Securities แก้ช่องโหว่ของ Nodejs](t3-thread://v1/1f6be3d6-e113-43cc-ae78-2dba5db381a3) | `claude-team` / `claude-sonnet-5-5` (root, `ohochat`) | Orchestrator หลักของ parent card `OHO-8883` และ subcard `OHO-8915` (`oho-web-app` Node 24 alpine + ถอด legacy PM2) | **สำเร็จ (Committed 2 commits แต่ Worktree หายหลังจบ):** ทำ breakdown `OHO-8883`, คุม `OHO-8915` r2/r3/review, แก้ `README.md` และ commit `f75ccdf53` + `73a43902e` ลง branch `feature/oho-8915-node-24-alpine` (32 runs; Claude file: `ce5ec979`) |
| 6 | 17:39:53 → 17:40:37 | [Find Node version pins](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A1f6be3d6-e113-43cc-ae78-2dba5db381a3%253Aordinal%253A1%3Aab88b81ad700cb126) | `claude-team` / `claude-haiku-5-5` (native `subagent` ของ `1f6be3d6`) | Scout หาตำแหน่ง pin เวอร์ชัน Node.js ใน `oho-web-app`, `oho-backoffice`, `oho-media-api` | **สำเร็จ**ใน 44 วินาที (28 tool calls, คืนรายการ `file:line`; file: `agent-ab88b81ad700cb126.jsonl`) |
| 7 | 17:41:03 → 17:45:11 | [Draft OHO-8883 breakdown.md](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A1f6be3d6-e113-43cc-ae78-2dba5db381a3%253Aordinal%253A1%3Aafb3c081c6652ed44) | `claude-team` / `claude-opus-5-5` (native `subagent` ของ `1f6be3d6`) | ร่างไฟล์ `/Users/tualek/ohochat/.scratch/OHO-8883/breakdown.md` | **สำเร็จ**ใน 4 นาที 8 วินาที (12 tool calls; file: `agent-afb3c081c6652ed44.jsonl`) |
| 8 | 17:49:03 → 18:18:02 (อัปเดต 18:48) | [Monitor unread-unresponded feature](t3-thread://v1/ba9f806a-b8ee-4340-b17c-8a5718a33ce1) | `claude-team` / `claude-sonnet-5-5` (root, `ohochat`) | ตรวจสอบการทำงานของฟีเจอร์ unread/unresponded ตาม condition ใน Firebase ทั้ง client และ server (`oho-app-prod` `chat-room`) | **สำเร็จ** (7 runs, 35 tool calls; สรุปว่า business ที่เปิด ON ทำงานปกติ ส่วน OFF หยุดเขียนแล้ว; file: `2c41bfd8`) |
| 9 | 18:18:09 → 18:23:06 (ลบ 18:32) | `[OHO-8915 [Brief] node 24 alpine](t3-thread://v1/558bb262-5a9f-434d-a1a5-5d824c2b9b13)` | `pi` / `deepseek-flash` (root, `oho-web-app`) | เริ่ม `$clickup-card OHO-8915` บน Pi thread สร้าง worktree `feature-oho-8915-node-24-alpine`, เรียก Opus ร่าง `brief.md` และเปิด thread `r1` | **สำเร็จแต่ซ้ำซ้อน** (1 run, 44 tool calls; ถูกลบตอน `18:32:14` เพื่อย้ายไปรวมที่ thread `1f6be3d6`; Pi file: `01a17d14`) |
| 10 | 18:21:22 → 18:22:09 (อัปเดต 18:52) | [Act as the design sub-agent for this task. Draft ONE file: /Users/tu...](t3-thread://v1/thread:delegated-task:command%3Amcp%3Ad39144a5-b0ba-45ed-b273-dc7abe90aaa5%3Adelegate-task%3A8f01b184-c8fd-4dca-8f62-61472d22bdb2) | `claude-team` / `claude-opus-5-5` (`delegate_task` `subagent` ของ `558bb262`) | ร่าง `.scratch/OHO-8915/brief.md` ให้ Pi parent thread | **สำเร็จ**ใน 47 วินาที (2 tool calls; พิสูจน์ว่า `pi -> claude-team` ผ่าน `delegate_task` ทำงานได้; file: `302e3565`) |
| 11 | 18:22:21 → 18:28:35 (ลบ 18:32) | `[OHO-8915 r1 plan node24](t3-thread://v1/mcp:ca8e1613-d46d-4879-9093-e5486016c665)` | `pi` / `deepseek-flash` (root, ผูก worktree `feature-oho-8915-node-24-alpine`) | รัน Round 1 (plan-only + เก็บ test baseline Node 22 vs 24) เขียน `done.md` (`STATUS: plan-ready`) | **สำเร็จแต่ถูกลบพร้อม worktree:** ลบ thread ตอน `18:32:17` ทำให้ T3 ลบ worktree และไฟล์ baseline logs หาย (เหลือเฉพาะ `done.plan-r1.md`; Pi file: `01a17d18`) |
| 12 | 18:38:05 → 18:39:19 | [Review OHO-8915 plan](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A1f6be3d6-e113-43cc-ae78-2dba5db381a3%253Aordinal%253A1%3Aaeb901efea015f985) | `claude-team` / `claude-opus-5-5` (native `subagent` ของ `1f6be3d6`) | Review แผน Round 1 (`brief.md` + `done.md`) ของ `OHO-8915` แบบ read-only | **สำเร็จ**ใน 1 นาที 14 วินาที (ชี้จุดสำคัญ 4 ข้อ: worktree ถูกลบ, baseline หาย, `tee` กลืน exit code, `curl` ไม่มี `--retry`; file: `agent-aeb901efea015f985.jsonl`) |
| 13 | 18:47:01 → 18:54:09 (อัปเดต 19:31) | [OHO-8915 r2 implement node24](t3-thread://v1/thread:delegated-task:command%3Amcp%3Aae82891a-86b8-4e87-b4dc-9b0fefdf21f0%3Adelegate-task%3Aoho-8915-r2-implement) | `pi` / `deepseek-flash` (`delegate_task` `subagent` ของ `1f6be3d6`) | Implement `OHO-8915` Round 2 (อัปเกรด `Dockerfile` และ `engines` เป็น Node 24, รัน Jest baseline/build/docker probe) | **ติด Blocker จริง (`STATUS: blocked` ที่ข้อ g):** a–f ผ่านหมด แต่ `docker build --platform linux/amd64` พังที่ `deasync@0.1.30` ไม่มี prebuild สำหรับ Node 24 บน linux-x64 (Pi file: `01a17d2f`) |
| 14 | 19:05:43 → 19:32:07 (run 1) และ 22:29:23 → 22:30:05 (run 2) | [OHO-8915 r3 deasync + remove legacy pm2](t3-thread://v1/thread:delegated-task:command%3Amcp%3Aae82891a-86b8-4e87-b4dc-9b0fefdf21f0%3Adelegate-task%3Aoho-8915-r3-implement) | `pi` / `deepseek-flash` (`delegate_task` `subagent` ของ `1f6be3d6`) | Implement `OHO-8915` Round 3: อัปเดต `deasync` เป็น `0.1.32` (มี `linux-x64-node-24`) + ลบ legacy PM2 deployment + สร้าง `commit1.patch` และ `full.patch` | **สำเร็จใน Run 2 (`STATUS: complete`):** Run 1 ทำงานเสร็จแล้วแต่เจอ `Connection error` ตอน `19:32:07` ก่อนเขียน `done.md`; Run 2 (`22:29:23`) ใช้เวลา 42 วินาทีเขียน `done.md` จบ (Pi file: `01a17d40`) |
| 15 | 22:30:39 → 22:32:41 | [Review OHO-8915 r3 diff](t3-thread://v1/thread:provider:claudeAgent:native-thread:provider-thread%3Aprovider%3AclaudeAgent%3Anative-thread%3Apending%253Arun%253Athread%253A1f6be3d6-e113-43cc-ae78-2dba5db381a3%253Aordinal%253A1%3Aae1546d822116f156) | `claude-team` / `claude-opus-5-5` (native `subagent` ของ `1f6be3d6`) | Review diff และ patch ของ `OHO-8915` Round 3 | **สำเร็จ**ใน 2 นาที 2 วินาที: `Verdict: not ready` สำหรับ commit 2 เพราะลบเนื้อหาใน `README.md:22` ที่ไม่ใช่ PM2 (`OHO_API_URL` path prefix และ `NODE_ENV` vs `APP_ENV`) ไปด้วย (file: `agent-ae1546d822116f156.jsonl`) |
| 16 | 22:48:04 → 23:40+ (กำลังรัน) | [React P0 UX — handoff (oho-web-app-react, react-p0)](t3-thread://v1/mcp:b1edee08-5636-4518-908c-86f65e470a54) | `claude-personal` / `claude-sonnet-5-5` (root, `react-p0`) | ย้ายงาน `oho-web-app-react` (`feat/react-p0-ux`) จาก `p0-chain-v2.sh` เข้ามาทำใน T3 โดยเริ่มทำ batch `P02d` | **กำลังรัน (Run 1 ล้มเพราะ limit, Run 2–4 ทำ `P02d` เสร็จและส่งรูปแคป, Run 5 กำลังปรับ UI เพิ่ม):** 163 tool calls, แก้ 11 ไฟล์ + เพิ่ม 6 ไฟล์, `SHOTS_OK` / `VISUAL_OK`, ยังไม่ commit (file: `23fb8e83`) |
| 17 | 23:30:55 → ปัจจุบัน | [Retro AI sessions 2026-10-27 (Gemini argon)](t3-thread://v1/mcp:117092e3-8f22-4ff7-a689-01ec99b7de26) | `antigravity` / `gemini-4-argon-high` (root, `ai-main`) | ทำ Retrospective แบบละเอียดของทุก AI session วันนี้แบบ read-only และเขียนรายงานลง `retro-20261027-gemini.md` | **สำเร็จ** (session ปัจจุบัน) |

---

### B.2 Claude Code Sessions นอก T3 (`~/.claude/projects`)

#### (ก) งาน React P0 UX Chain (`p0-chain-v2.sh` ใน `~/orca/workspaces/oho-web-app-react/react-p0`)
วันนี้มีไฟล์ `.jsonl` ที่ถูกสร้าง/แก้ไขในโปรเจกต์ `react-p0` ทั้งหมด **86 ไฟล์** แบ่งเป็น:
- **68 Limit Stubs (`<synthetic>`, 0 tool calls):**
  - `00:03:57 – 12:45:11` (**46 sessions**): ติด `You've hit your weekly limit · resets 1pm (Asia/Bangkok)` ขณะรอทำ `P02b-review2`
  - `13:52:20 – 17:52:34` (**18 sessions**): ติด `You've hit your session limit · resets 6pm (Asia/Bangkok)` ขณะรอทำ `P05-impl` แล้วถูกแก้ `batches.tsv` สลับมาทำ `P02c-impl` ตอน `15:42`
  - `19:16:07 – 22:50:19` (**4 sessions**): ติด `You've hit your session limit · resets 11pm (Asia/Bangkok)` ขณะรอทำ `P05-impl` / `P02d-impl`
- **18 Real Sessions (17 headless จาก `p0-chain-v2.sh` + 1 T3 thread `23fb8e83`):**

| เวลา (+07) | ไฟล์ Session (`.jsonl`) | ขั้นตอนใน Chain | Model | Tools | Output Tokens | Cache Read | Cost (จริงจาก JSONL) | Outcome |
|---|---|---|---|---:|---:|---:|---:|---|
| 13:00:12 → 13:04:31 | `d5bdf3e5` | `P02b-review2` | `claude-opus-5-5` | 67 | 44,353 | 10.28M | `$2.8811` | สำเร็จ (ชี้จุดแก้รอบ 2) |
| 13:04:32 → 13:06:37 | `67e6186f` | `P02b-fixr2` | `claude-sonnet-5-5` | 40 | 31,227 | 3.27M | `$0.5241` | สำเร็จ (414 tests ผ่าน) |
| 13:07:30 → 13:08:45 | `c24ebb4f` | `P02b-review3` | `claude-opus-5-5` | 30 | 23,994 | 3.21M | `$1.0354` | **สำเร็จ (`P02b` DONE, commit `fac95a8`)** |
| 13:08:47 → 13:27:00 | `7bd94bbf` | `P04-impl` | `claude-sonnet-5-5` | 239 | 270,010 | 34.06M | `$4.5067` | สำเร็จ (แต่ `verify=0` ต้องเข้า `fixpre1`) |
| 13:27:41 → 13:29:57 | `d98399f9` | `P04-fixpre1` | `claude-sonnet-5-5` | 35 | 43,771 | 3.22M | `$0.5041` | สำเร็จ (`verify=1 shots=1 visual=1`, 434 tests) |
| 13:30:38 → 13:33:00 | `fe9cb34f` | `P04-review1` | `claude-opus-5-5` | 50 | 41,102 | 6.52M | `$1.7636` | สำเร็จ (พบ Important ส่งแก้รอบ 1) |
| 13:33:01 → 13:37:19 | `fb44b1da` | `P04-fixr1` | `claude-sonnet-5-5` | 76 | 63,304 | 9.14M | `$0.9733` | สำเร็จ (436 tests ผ่าน) |
| 13:38:02 → 13:39:43 | `50ba9e54` | `P04-review2` | `claude-opus-5-5` | 36 | 27,739 | 4.31M | `$1.3579` | สำเร็จ (ส่งแก้รอบ 2) |
| 13:39:45 → 13:43:30 | `33639251` | `P04-fixr2` | `claude-sonnet-5-5` | 46 | 27,157 | 4.82M | `$0.6747` | สำเร็จ (436 tests ผ่าน) |
| 13:44:12 → 13:45:55 | `a6ac70f0` | `P04-review3` | `claude-opus-5-5` | 37 | 26,847 | 4.10M | `$1.2443` | **สำเร็จ (`P04` DONE, commit `19a412e`)** |
| 13:45:58 → 13:52:19 | `a752b57d` | `P05-impl` (ครั้งที่ 1) | `claude-sonnet-5-5` | 81 | 74,822 | 12.25M | `$2.4979` | **ล้มเหลวกลางคัน:** ชน `session limit · resets 6pm` หลังทำไป 81 tools (งานสูญเปล่าเมื่อสลับไปทำ `P02c`) |
| 18:07:34 → 18:31:12 | `dd3ebe30` | `P02c-impl` | `claude-sonnet-5-5` | 251 | 406,122 | 80.37M | `$7.5595` | สำเร็จ (`verify=1 shots=1 visual=1`, 448 tests) |
| 18:32:14 → 18:34:39 | `14673e7b` | `P02c-review1` | `claude-opus-5-5` | 34 | 34,500 | 4.48M | `$1.6281` | สำเร็จ (พบ Important ส่งแก้รอบ 1) |
| 18:34:40 → 18:37:19 | `3be30327` | `P02c-fixr1` | `claude-sonnet-5-5` | 37 | 23,116 | 3.42M | `$0.5183` | สำเร็จ (448 tests ผ่าน) |
| 18:38:16 → 18:39:37 | `eb0fb5b7` | `P02c-review2` | `claude-opus-5-5` | 26 | 23,062 | 2.90M | `$1.1155` | **สำเร็จ (`P02c` DONE, commit `fbcbbff`, Important=0 หยุดที่รอบ 2 ตาม policy ใหม่)** |
| 18:39:40 → 19:01:07 | `ef07ee21` | `P05-impl` (ครั้งที่ 2) | `claude-sonnet-5-5` | 230 | 380,926 | 82.33M | `$6.0500` | **ล้มเหลวกลางคัน:** ชน `session limit · resets 11pm` ขณะกำลังเขียน `send-eligibility.ts` (ใช้ไป `$6.05` แต่ยังไม่จบ ต้องเก็บเข้า stash/patch เพื่อเปิดทางให้ `P02d`) |
| 23:06:50 → 23:07:53 | `b7f367c9` | `P02d-impl` (จาก chain PID 17082) | `claude-sonnet-5-5` | 26 | 13,223 | 2.67M | `$0.4702` | **ล้มเหลว/ซ้ำซ้อน (Killed):** `p0-chain-v2.sh` ที่ไม่ถูก kill ตื่นมารัน `P02d` ชนกับ T3 thread `mcp:b1edee08` นาน 1 นาที |
| 22:48:05 → 23:40+ | `23fb8e83` | T3 thread `mcp:b1edee08` (`P02d`) | `claude-sonnet-5-5` | 163 | 208,746 | 62.26M | ~$3.95 (ประเมิน) | **สำเร็จ `P02d` รอบแรก / กำลังรันปรับ UI เพิ่ม** (ดูตาราง T3 #16) |

#### (ข) งาน Probe / ไฟล์เก่าใน `~/.claude/projects` นอก `react-p0`
- **Active วันนี้ (3 sessions สั้น):**
  1. `15:20:41 → 15:20:48` (`-Users-tualek-cs-agent-kit/e563bf81-b3a4-49b2-9d45-5da9e0f07f7f.jsonl`): ถาม `"นายคือใคร"` (Claude Desktop, `claude-sonnet-5-5`, 0 tools, `in=2`, `out=311`, `cr=45,352`, `cw=45,251`, `$0.1887`) -> **สำเร็จ**
  2. `16:02:29 → 16:02:32` (`-private-tmp/a3003b63-1a86-4f30-a4db-b9b4329bf0f3.jsonl`): ทดสอบ `"reply ok"` ตอนตั้งค่า context 500k (`<synthetic>`, 0 tokens, `$0`) -> **ล้มเหลว (ติด session limit resets 6pm)**
  3. `16:11:48 → 16:12:00` (`-Users-tualek-ohochat/a2c117b6-5d93-45b8-b1c9-c9be392202c5.jsonl`): ถาม `"clickup slack ใช้งานได้แล้วใช่ไหม"` (`claude-sonnet-5-5`, 2 tools, `in=8`, `out=566`, `cr=307,128`, `cw=86,918`, `$0.2072`) -> **สำเร็จ**
- **ไฟล์เก่าที่ไม่มี LLM turn วันนี้ แต่ `mtime` เปลี่ยนวันนี้ (9 ไฟล์):**
  - `-Users-tualek-ohochat/46e58185-1b26-4082-b35a-20816e38e388.jsonl` (รันจริง 16–22 ต.ค., `mtime` 13:31:16 จาก `cost-state`)
  - `-Users-tualek-ohochat/19e9e15c-267e-432e-bdf8-c3f4097de366.jsonl` (รันจริง 15 ต.ค., `mtime` 17:32:42 จาก `pr-link` + `cost-state`)
  - `-Users-tualek-ohochat/90e9d816-cb93-495f-9b00-6e47eeb10359.jsonl` + 6 subagents ใน `90e9d816/subagents/` (รันจริง 14 ต.ค., `mtime` 13:30:57 จาก `cost-state`)

---

### B.3 Pi Sessions (`~/.pi/agent/sessions`) — 8 ไฟล์ที่แก้ไขวันนี้
- 7 ไฟล์ผูกกับ T3 threads (#1, #2, #3, #4, #9, #11, #13, #14 ในตาราง B.1)
- อีก 1 ไฟล์คือ Headless smoke test นอก T3:
  - `17:30:44 → 17:30:49`: `~/.pi/agent/sessions/--private-tmp-t3vis-test--/2026-10-27T10-30-44-499Z_01a17ce9-9213-75cb-9e0e-8cff827ce612.jsonl` (`deepseek/deepseek-flash`, prompt: `"Reply with exactly: ok-headless"`, 0 tools, `in=23,656`, `out=4`, `$0.0071`) -> **สำเร็จ** (พิสูจน์ว่า headless `pi -p` ไม่ถูก import เข้า T3 UI)

---

## C. เวลาและ Token ที่เสียเปล่า พร้อมสาเหตุและหลักฐาน

| อันดับ | ความสูญเสีย (เวลา / Token / Cost) | สาเหตุ (Root Cause) | หลักฐานอ้างอิง |
|---|---|---|---|
| **1** | **เสีย `$8.55` (`$2.50` + `$6.05`), 311 tool calls, 94.58M cache-read tokens, 455.7k output tokens และเวลา ~28 นาที** โดยไม่ได้ commit | **`P05-impl` ชน Session Limit กลางคัน 2 รอบซ้อน:** รอบแรก (`a752b57d`, `13:45–13:52`) รันไป 81 tools แล้วชน limit 18:00 พอแก้ `batches.tsv` แทรก `P02c` งานของ `P05` รอบแรกจึงถูกทิ้ง; รอบสอง (`ef07ee21`, `18:39–19:01`) รันไป 230 tools จนเกือบเสร็จ (`Writing send-eligibility.ts now`) แล้วชน limit 23:00 ต้องถูก stash/patch เก็บไว้เพื่อแทรก `P02d` | `a752b57d.jsonl`, `ef07ee21.jsonl`, `chain.log` บรรทัด `13:52:20` และ `19:01:07` |
| **2** | **68 Headless Limit Stubs ใน `p0-chain-v2.sh` + Restart ซ้ำ 5 รอบ** (`PID 44178`, `46598`, `88316`, `89327`, `17082`) เสียเวลารอรวม **> 11 ชั่วโมง** | **`p0-chain-v2.sh` ไม่มี Reset-Time Parser และไม่เช็กโควตาก่อนเริ่ม batch ใหม่:** ฟังก์ชัน `cc()` ใน `p0-chain-v2.sh:50-54` ใช้ `sleep 900` (15 นาที) ตายตัวแม้ข้อความจะระบุชัดว่า `resets 1pm` / `resets 6pm` / `resets 11pm` และไม่มีการหยุด process เก่าก่อนแก้สคริปต์/รันใหม่ | `p0-chain-v2.sh:50-54`, `chain.log` (68 บรรทัด `session limit hit`), ไฟล์ `.jsonl` ขนาด ~340KB จำนวน 68 ไฟล์ใน `react-p0` |
| **3** | **Dual-Driver Collision หลัง 23:00 (`b7f367c9` เสีย `$0.47`, 26 tools, 2.67M cache-read)** | **ไม่ kill `p0-chain-v2.sh` หลังย้ายงานเข้า T3:** ใน `retro-20261027.md` ย้ายงาน React เข้า T3 thread `mcp:b1edee08` ตอน `22:48` แต่ปล่อย `p0-chain-v2.sh` ค้างไว้ พอถึง `23:06:50` chain จึงตื่นมารัน `b7f367c9` แก้ worktree เดียวกันชนกับ `mcp:b1edee08` (`23fb8e83`) | `chain.log` บรรทัด `23:06:50 === p0-chain-v2 start (pid 17082)`, `b7f367c9.jsonl`, `23fb8e83.jsonl` (`23:07:17`) |
| **4** | **เสียเวลา Wall-Clock ~2 ชม. 57 นาที (`19:32 → 22:29`) ใน `OHO-8915 r3`** | **Network Drop / เครื่องหลับ + `delegate_task` (`mode:"async"`) ไม่ Auto-Resume เมื่อ Child ล้มจาก Network Error:** `01a17d40` เจอ `Connection error` ตอน `19:31:44–19:32:07` และ `ce5ec979` เจอ `api_error` ตอน `19:32:13–20:51:06` และ `21:06:53` ทำให้ parent ค้างจนถึง `21:07:20` กว่าจะส่งข้อความ resume child ตอน `22:29:23` | `01a17d40.jsonl` (บรรทัด 129–138), `ce5ec979.jsonl` (บรรทัด 1066–1136) |
| **5** | **Worktree `~/.t3/worktrees/oho-web-app/feature-oho-8915-node-24-alpine` ถูกลบ 2 รอบในวันเดียว** (เสียเวลา recreate + install + baseline รอบละ ~10–15 นาที) | **การลบ T3 Thread ที่ผูกกับ Worktree ทำให้ T3 ลบโฟลเดอร์ Worktree ทิ้ง:** รอบแรกตอน `18:32:17` เมื่อลบ thread `mcp:ca8e1613` (`r1 plan`) ทำให้ baseline logs (`fail-22.txt`, `fail-24.txt`) หายหมด; รอบสองตอน `22:56` หลัง commit เสร็จ เพราะ worktree ที่สร้างใหม่ด้วยมือตอน `18:46` ใช้ path เดิมของ `mcp:ca8e1613` ที่สถานะเป็น `deleted_at` โดยไม่มี active top-level thread ผูกไว้ | `statev2.sqlite` (`mcp:ca8e1613` `deleted_at=11:32:17Z`), `~/.t3/worktrees/oho-web-app` (`mtime 22:56`), `agent-aeb901efea015f985.jsonl` |
| **6** | **Permission Denials ใน Headless Chain (23 ครั้งใน `react-p0` วันนี้)** | **กฎ `COMMON_DENY` และ `REVIEW_ALLOW` ใน `p0-chain-v2.sh` ขัดกับพฤติกรรมของ Agent และ RTK:** `p0-chain-v2.sh` บล็อก `Bash(cat:*)` แต่ไม่อนุญาต `Bash(git rev-parse:*)` หรือ `Bash(rtk read:*)` ใน `REVIEW_ALLOW` ทำให้ Opus reviewer แทบทุกตัวโดน deny ใน tool call แรก (`git rev-parse --short HEAD && rtk git status ... && cat ...`) และต้องเสีย 1–2 turns เปลี่ยนไปใช้ `Read` tool แทน | `p0-chain-v2.sh:29-36`, tool_result errors ใน `14673e7b`, `50ba9e54`, `a6ac70f0`, `d5bdf3e5`, `eb0fb5b7`, `fe9cb34f`, `7bd94bbf`, `b7f367c9` |
| **7** | **สมมติฐานผิดและข้อผิดพลาดของ Agent ใน `OHO-8915` และ `retro-20261027.md`** | (1) `OHO-8915` brief รอบแรกไม่เช็ก native addon (`deasync@0.1.30`) ว่ามี prebuild สำหรับ Node 24 บน Alpine `linux-x64` หรือไม่; (2) Orchestrator `1f6be3d6` อ่าน `done.md` ของ r2 ผิดแล้วอ้างว่ารัน Cloud Build ทั้งที่แค่ grep ไฟล์ `cloudbuild.yaml`; (3) Executor r3 ลบ `## Staging` ใน `README.md` ทั้งก้อนจนเนื้อหา `OHO_API_URL` / `NODE_ENV` หาย; (4) `retro-20261027.md` นับไฟล์เก่าวันที่ 14–22 ต.ค. เป็นของวันนี้ | `t3-nested-subagent-test-20261027.md`, `OHO-8915/review.md`, `46e58185.jsonl` |
| **8** | **Session Start Context Overhead บน Claude Desktop (~97.6k tokens/turn แรก)** | Claude Desktop แนบ `Artifact` schema (13.4k), Desktop MCP tools (17.5k), claude.ai connectors (11.3k), และ skills 80 ตัว (10.1k) ทำให้แค่ถาม 1 บรรทัด (`a2c117b6`, `e563bf81`) ก็เสียค่า cache write + cache read ~90k–98k tokens (`~$0.20` ต่อคำถามสั้น ๆ) | `session-start-tokens-20261027.md`, `e563bf81.jsonl` (`$0.1887`), `a2c117b6.jsonl` (`$0.2072`) |

---

## D. สิ่งที่ Work ดี (What Worked Well)

1. **Cross-Provider `delegate_task` ใน T3 Code ทำงานได้ทั้งสองทิศทางและประหยัดมาก:**
   - พิสูจน์แล้วทั้ง `pi -> claude-team` (thread `558bb262` เรียก Opus subagent `302e3565` ร่าง `brief.md` ใน 47 วินาที ค่าใช้จ่าย `$0.50`) และ `claude-team -> pi` (thread `1f6be3d6` เรียก `deepseek/deepseek-flash` ทำ `OHO-8915 r2` และ `r3` ด้วยค่าใช้จ่ายเพียง **`$0.0522`** และ **`$0.0928`** ต่อรอบ!)
2. **Claude Opus 5.5 (`effort: medium`) ในบทบาท Read-Only Reviewer แม่นยำและคุ้มค่า:**
   - ใช้เวลาเพียง 1–4 นาทีต่อรอบ (ค่าใช้จ่าย `$0.50–$2.88` ต่อรอบ) แต่จับบั๊กสำคัญได้จริงทุกครั้ง เช่น จับได้ว่า `OHO-8915 r1` ลืมขั้นตอนสร้าง worktree ใหม่และ `tee` กลืน exit code, จับได้ว่า `OHO-8915 r3` ลบย่อหน้า `OHO_API_URL` และ `NODE_ENV` ใน `README.md` ที่ไม่เกี่ยวกับ PM2, และตรวจผ่านงาน React `P02b`, `P04`, `P02c` จน commit ได้ครบ
3. **การแยกบัญชี Dual Account (`claude-personal` vs `claude-team`) สำเร็จและไม่ชนกัน:**
   - แยก Keychain item ด้วย `CLAUDE_CONFIG_DIR=~/.claude-team` พร้อม symlink `settings.json`, `skills`, `hooks`, `agents` ทำให้เมื่อ `claude-personal` ติด session/weekly limit งานการ์ด `OHO-8883` / `OHO-8915` และการตรวจ `Monitor unread-unresponded` บน `claude-team` ยังเดินหน้าต่อได้โดยไม่สะดุดโควตา
4. **การปรับปรุง Policy ใน `p0-chain-v2.sh` ให้หยุด Review ทันทีเมื่อ `Important == 0 AND VISUAL: OK AND SHOTS: OK`:**
   - ใน `P02b` และ `P04` ต้องรันครบ 3 review rounds เสมอ แต่หลังแก้ policy ใน `P02c` พอ `P02c-review2` ได้ `Important=0` ก็จบและ commit `fbcbbff` ทันที ช่วยประหยัด Opus review รอบที่ 3 ได้ ~`$1.20–$1.50` และเวลา ~5 นาทีต่อ batch
5. **การแก้ปัญหา Read Permissions (`~/.claude/settings.json` +322 allow rules + `~/ai-main/bin/mongo-ro`) และ Live `@import` ใน `~/.claude/CLAUDE.md`:**
   - ปลดล็อกคำสั่ง read-only (`gcloud`, `kubectl`, `glab`, `docker`, `git` ทั้งแบบตรงและผ่าน `rtk`/`gtimeout`) โดยผ่านชุดทดสอบ `test-guard.sh` 105/105 ข้อ และเปลี่ยน `~/.claude/CLAUDE.md` จาก compiled snapshot ที่ล้าสมัยให้เป็น live `@import` ที่เห็นกฎใหม่ (`gtimeout`, `--freshness`) ทันที

---

## E. การใช้ Provider / Model และ Cost / Quota ต่อ Session

> [!NOTE]
> **คำอธิบายที่มาของตัวเลข (จริง vs ประเมิน):**
> - **ตัวเลขจริง (Actual Recorded):**
>   - **Claude Code (`~/.claude` และ `~/.claude-team`):** จำนวน token (`input_tokens`, `output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`) มาจาก `message.usage` ของทุก assistant turn ใน `.jsonl` และค่าเงิน USD มาจากบรรทัด `{"type":"cost-state","totalCostUSD":...}` ที่ Claude Code คำนวณและบันทึกไว้ใน `.jsonl` โดยตรง (หมายเหตุ: หักยอดใช้จริงจากโควตา Subscription ของ Personal Pro และ Team ไม่ได้คิดแยกเป็นรายบิล ยกเว้นส่วนเกินโควตา)
>   - **Pi (`~/.pi/agent/sessions`):** จำนวน token และ `usage.cost.total` (USD) บันทึกจริงในทุก assistant message ของ `.jsonl` จาก DeepSeek API
> - **ตัวเลขประเมิน (Estimated):**
>   - เฉพาะ Claude sessions ที่ยังไม่มีบรรทัด `cost-state` ปิดท้าย (ได้แก่ T3 thread `23fb8e83` ที่กำลังรันอยู่ และ native subagents 4 ตัวภายใต้ `ce5ec979` ซึ่งแชร์ cost หรือไม่เขียน `cost-state` แยก) ประเมินจากเรตเดียวกับที่ `cost-state` ของ Claude Code ใช้ในไฟล์อื่นของวันนี้

### E.1 สรุปยอดรวมเฉพาะกิจกรรมที่เกิดขึ้นจริงในวันที่ 2026-10-27 (00:00–23:41 UTC+7)

| Provider / Account | Model | Active Sessions (วันนี้) | Tool Calls (วันนี้) | Input Tokens (Uncached) | Cache Write Tokens | Cache Read Tokens | Output Tokens | Cost จริงใน Log (USD) | Cost ประเมินส่วนที่ขาด (USD) | รวมมูลค่า API เทียบเท่า (USD) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **Claude Personal Pro** (Quota: ชน Weekly Limit `<13:00`, Session Limit `13:52–18:00` และ `19:01–23:00`) | `claude-sonnet-5-5` | 13 | 1,226 | 3,495 | 7,188,239 | 295,908,210 | 1,543,311 | `$24.1957` (12 ไฟล์) | `~$3.9500` (`23fb8e83`) | **`~$28.1457`** |
| **Claude Personal Pro** | `claude-opus-5-5` | 7 | 280 | 964 | 2,311,354 | 35,790,090 | 221,597 | `$11.0259` (7 ไฟล์) | `$0.0000` | **`$11.0259`** |
| **Claude Personal Pro** (Stubs) | `<synthetic>` | 69 stubs | 0 | 0 | 0 | 0 | 0 | `$0.0000` | `$0.0000` | **`$0.0000`** |
| **Claude Team** (Quota: ปกติ ไม่ชน Limit) | `claude-sonnet-5-5` | 2 (`ce5ec979`, `2c41bfd8`) | 155 | 714 | 1,688,500 | 40,188,217 | 269,667 | `$8.8714` (รวม subagents ใน `ce5ec979`) | `$0.0000` | **`$8.8714`** |
| **Claude Team** (Subagents) | `claude-opus-5-5` (4), `haiku-5-5` (1) | 5 | 64 | 258 | 847,715 | 4,532,571 | 105,753 | `$0.4987` (`302e3565`) | (อีก 4 ตัวรวมใน `$7.9392` ของ `ce5ec979` แล้ว / แยกเฉพาะตัว `~$2.15`) | **`$0.4987`** (+รวมใน parent) |
| **Pi Agent** (DeepSeek API) | `deepseek/deepseek-flash` | 8 (หักส่วน Oct 26 และหัก fork ซ้ำแล้ว) | 212 (วันนี้) | 787,310 | 0 | 22,584,128 | 108,456 | **`$0.5812`** (จริง 100%) | `$0.0000` | **`$0.5812`** |
| **Antigravity (T3)** | `gemini-4-argon-high` | 1 (`mcp:117092e3`, session นี้) | ~38 | N/A (ACP DB) | N/A | N/A | N/A | N/A | `~$0.3500` (ประเมิน) | **`~$0.3500`** |
| **รวมสุทธิวันที่ 2026-10-27** | **ทุกโมเดล** | **36 active** (+69 stubs) | **~1,975** | **792,741** | **12,035,808** | **399,003,216** | **2,248,784** | **`$45.1729` (จริง)** | **`~$4.3000` (ประเมิน)** | **`~$49.4729`** |

*(เปรียบเทียบ: यदिนับรวมไฟล์เก่าวันที่ 14–22 ต.ค. ที่แค่ถูกแตะ `mtime` วันนี้ตามที่ `retro-20261027.md` นับผิด จะมียอดลวงเพิ่มอีก `169.2M` cache-read tokens และ `$62.94` จาก `46e58185`, `90e9d816`, `19e9e15c` ซึ่งไม่ได้เกิดขึ้นในวันนี้)*

### E.2 ตาราง Cost / Token ราย Session สำหรับ Pi (แยกตัวเลขจริงสุทธิของวันที่ 27 ต.ค.)
| ไฟล์ Pi Session (`.jsonl`) | งาน / Thread | Turns (27 ต.ค.) | Tools (27 ต.ค.) | Input (27 ต.ค.) | Output (27 ต.ค.) | Cache Read (27 ต.ค.) | Cost จริง 27 ต.ค. (USD) |
|---|---|---:|---:|---:|---:|---:|---:|
| `01a176ca` (`ohochat`) | `Replica Lag` (`f8f9a4c1`, เฉพาะส่วนวันที่ 27 ต.ค.; ส่วน 26 ต.ค. คือ `$0.2177`) | 51 | ~45 | 250,000 (สุทธิวันนี้) | 43,083 | 11,202,560 | **`$0.2382`** |
| `01a17c2d` (`ohochat`) | `Pipe-Separated Business ID Groups` (`a3185c42`) | 5 | 1 | 32,018 | 4,109 | 241,920 | **`$0.0160`** |
| `01a17ce9` (`t3vis-test`) | Headless smoke test (`ok-headless`) | 1 | 0 | 23,656 | 4 | 0 | **`$0.0071`** |
| `01a17cec` (`ohochat`) | `Stop Replica Lag Monitor` (`39952c4f`, เฉพาะ 3 turns ใหม่หลัง fork) | 3 | 3 | 236,593 | 566 | 485,504 | **`$0.0746`** |
| `01a17ced` (`ai-main`) | T3 visibility test (`mcp:94d197d3`, `ok-t3`) | 1 | 0 | 44,277 | 4 | 2,816 | **`$0.0133`** |
| `01a17d14` (`oho-web-app`) | `OHO-8915 [Brief]` (`558bb262`) | 30 | 44 | 103,435 | 13,200 | 2,412,800 | **`$0.0613`** |
| `01a17d18` (`worktree 8915`) | `OHO-8915 r1 plan node24` (`mcp:ca8e1613`) | 14 | 15 | 48,497 | 5,847 | 682,368 | **`$0.0257`** |
| `01a17d2f` (`ohochat`) | `OHO-8915 r2 implement` (`delegate_task` child) | 34 | 45 | 62,985 | 17,225 | 2,111,104 | **`$0.0522`** |
| `01a17d40` (`ohochat`) | `OHO-8915 r3 deasync + pm2` (`delegate_task` child) | 69 | 64 | 102,440 | 24,458 | 5,447,552 | **`$0.0928`** |
| **รวม Pi สุทธิ (27 ต.ค.)** | **9 ไฟล์ (8 sessions ไม่ซ้ำ)** | **208** | **~217** | **903,901** | **108,496** | **22,586,624** | **`$0.5812`** |

---

## F. ความผิดพลาดที่เกิดซ้ำ (Recurring Mistakes)

1. **การลบหรือปล่อยให้ Worktree ภายใต้ `~/.t3/worktrees/` ขาด Active Thread ผูกไว้ จนโฟลเดอร์ Worktree ถูกลบทิ้งซ้ำ 2 รอบในวันเดียว (`OHO-8915`):**
   - เกิดตอน `18:32:17` (เมื่อลบ `mcp:ca8e1613`) และเกิดซ้ำตอน `22:56` (หลังสร้าง worktree ชื่อเดิมกลับมาแต่ไม่ได้ผูกกับ active top-level thread ใน T3)
2. **การรัน Chain / Background Loop โดยไม่มี Quota Reset Parser และไม่ Kill Process เดิมก่อนเปลี่ยนวิธีทำงาน (`p0-chain-v2.sh`):**
   - ยิงซ้ำทุก 15 นาทีชน limit ถึง **68 ครั้ง** ในวันเดียว เสียงาน `P05-impl` ไป 2 รอบ (`$8.55`), และเมื่อย้ายงานเข้า T3 (`mcp:b1edee08`) ก็ลืม kill `p0-chain-v2.sh` ทำให้เกิด **Dual-Driver Collision** ตอน `23:06:50` (`b7f367c9` ชนกับ `23fb8e83`)
3. **การฝ่าฝืนกฎของ `clickup-card` เองระหว่างทำงานจริง (`OHO-8915` บน thread `1f6be3d6`):**
   - **ผิดซ้ำข้อที่ 1 (Orchestrator แก้โค้ดเอง):** ตอน `22:34:54` orchestrator (`1f6be3d6`) ใช้ `Edit` tool แก้ `/Users/tualek/.t3/worktrees/oho-web-app/feature-oho-8915-node-24-alpine/README.md` และสร้าง `full.patch` เอง ทั้งที่ Hard rule ระบุว่า `"The orchestrator never edits code. If asked to edit code here, dispatch instead."`
   - **ผิดซ้ำข้อที่ 2 (Commit โดยไม่มี `Verdict: ready` ที่ HEAD ล่าสุด):** ตอน `22:37:30` orchestrator commit ทั้ง 2 commits (`f75ccdf53`, `73a43902e`) ทั้งที่ `review.md` บันทึกไว้ชัดเจนว่า `"This edit was NOT re-reviewed by the reviewer agent"` และ `Verdict: not ready (commit 1 is ready on its own)`
   - **ผิดซ้ำข้อที่ 3 (ไม่สร้าง `rounds.md`):** ตลอดการทำงานของ `OHO-8915` ไม่มีไฟล์ `.scratch/OHO-8915/rounds.md` เลย ทำให้ต้องไล่ค้นหา thread IDs จาก SQLite
4. **การสรุปผลจาก `done.md` หรือ `mtime` ของไฟล์โดยไม่ Verify หลักฐานชั้นต้น (Unverified Claims):**
   - Orchestrator `1f6be3d6` อ้างว่า `r2` รัน Cloud Build ทั้งที่ไม่ได้รันจริง
   - Executor `r3` อ้างใน `done.md:35` ว่าเนื้อหาใน `README.md` ที่ลบไปมีอยู่ใน `docs/cicd.md` และ `.env.example` แล้ว ทั้งที่ `OHO_API_URL` path prefix และ `NODE_ENV` vs `APP_ENV` ไม่มีในไฟล์อื่นเลย
   - ผู้เขียน `retro-20261027.md` ดูแค่ `mtime` และ `HH:MM` ของ `.jsonl`/Pi sessions โดยไม่เช็กวันที่ (`YYYY-MM-DD`) และไม่เช็ก entry IDs ที่ซ้ำจากการ fork ทำให้รายงานตัวเลข token ผิดไปหลายเท่าตัว
5. **การทิ้ง Zombie Processes ค้างข้ามสัปดาห์:**
   - พบ `cursor-agent` ค้างตั้งแต่ **16 ต.ค.** 2 ตัว (`PID 74570` และ `PID 35947` ของการ์ด `OHO-7084`) บวก `codegraph` watchdogs และ `claude rc` (`PID 27132` ตั้งแต่ **15 ต.ค.** ใช้เวลา CPU ไป 40+ นาที) รวมถึง `p0-chain-v2.sh` ที่เพิ่งชนกับ T3 ตอน `23:06`

---

## G. ข้อเสนอปรับปรุงที่เป็นรูปธรรมสำหรับ `clickup-card` Skill และ Rules ใน `~/ai-main` (Diff-Style เท่านั้น)

### G.1 `/Users/tualek/ai-main/skills/clickup-card/SKILL.md`
**ปัญหาที่พบจากงานจริงวันนี้:**
1. **Untested & Flawed Assumption ใน Step 3e (v4):** ใน `SKILL.md` ปัจจุบัน (ที่เพิ่งแก้ตอน `22:49`) สั่งให้ Plan thread (`claude-team`) ส่งข้อความบอก Implement thread (`pi`) ให้เป็นคนเรียก `delegate_task` ไปหา `claude-team` (`opus`) เพื่อทำ review วิธีนี้มีข้อเสีย 3 ข้อ:
   - เสีย 1 LLM turn บน Pi (`deepseek-flash`) ที่มี context สะสมใหญ่ขึ้นเรื่อย ๆ เพียงเพื่อเป็นตัวกลางส่งต่อคำสั่ง `delegate_task`
   - เสี่ยงที่ Executor (`pi`) จะเผลอแก้โค้ดเองหรือแก้ `review.md` หลัง reviewer จบ
   - ทั้งที่ Plan thread (`claude-team`) สามารถเรียก **native Claude `Agent(subagent_type="reviewer", model="opus", effort="medium")`** ได้โดยตรง ซึ่งเร็วกว่า (ใช้เวลาแค่ 1–2 นาทีในวันนี้), T3 พับเก็บเป็น nested `subagent` ภายใต้ Plan thread ให้โดยอัตโนมัติ (พิสูจน์แล้วจาก `aeb901efea015f985` และ `ae1546d822116f156`), และแยกสิทธิ์จาก Executor 100%!
2. **ช่องโหว่เรื่อง T3 ลบ Worktree (`~/.t3/worktrees/<repo>/<slug>`):** ยังไม่มีกฎห้ามลบ `impl_thread` ใน T3 ก่อนที่การ์ดจะ merge/จบ และยังไม่มีคำสั่งให้สำรอง `.scratch/<CARD>/` ออกมาที่ `/Users/tualek/ohochat/.scratch/<CARD>/` ก่อนเริ่มและหลังจบทุก round (วันนี้รอดมาได้เพราะสำรองไว้ที่ `~/ohochat/.scratch/OHO-8915/`)
3. **การตรวจสอบ Native Addons ตอนอัปเกรด Node / Base Image และการกู้คืนเมื่อ `delegate_task` / `t3_thread_wait` ล้มด้วย `Connection error`:** ยังไม่ได้ระบุไว้ใน `SKILL.md`

```diff
--- a/skills/clickup-card/SKILL.md
+++ b/skills/clickup-card/SKILL.md
@@ -28,7 +28,7 @@
 - Implementation goes to the card's single implement thread (step 3): pi + DeepSeek, top-level, bound to the card worktree; later rounds are `t3_thread_send` to the same thread. Fallbacks are listed in step 3. If asked to edit code here, dispatch instead. Never Codex: the user has no Codex subscription.
 - Review budget: one pass plus re-checks on the new diff only, max 3 rounds per MR, then `Step back:` to the user. One reviewer per round; do not stack reviewers.
-- Reviewer is always Claude Opus (never Gemini). Default: the implement thread calls `delegate_task` to `claude-team` (opus, effort medium, role review, edits only `review.md`), nested under it, fresh context each round; fallback only if Claude quota is out or the delegate errors: agy with `claude-opus-5-5-medium`. Judge against REVIEW.md + brief acceptance, not the plan's reasoning. No automatic extra high pass; run opus high only when the user asks.
+- Reviewer is always Claude Opus (never Gemini). Default: the plan thread calls its native `Agent(subagent_type="reviewer", model="opus", effort="medium")` (T3 automatically nests native Claude subagents under the plan thread) OR calls `delegate_task` to `claude-team` (`claude-opus-5-5`, effort medium, role review) directly from the plan thread — never ask the pi implement thread to spawn its own reviewer. Fallback only if Claude quota is out: `agy` with `claude-opus-5-5-medium`. Judge against REVIEW.md + brief acceptance, not the plan's reasoning.
 - Do not add Claude/AI footers to MR text.
 - Write findings to `breakdown.md` (Investigation) as soon as they are found; chat is lost on compaction.
@@ -36,4 +36,5 @@
 - Code search goes through `Agent(subagent_type="scout")`. Do not run more than 2 rg/grep or 3 Read/cat/sed calls yourself in a row; delegate and keep only its file:line list.
 - Never write `Verdict: ready`, never say an MR is ready ("พร้อม MR"), never draft the Slack review request without a `reviewer` result at the current head SHA recorded in `.scratch/<CARD>/review.md`.
+- If the user approves a small post-review fix, either dispatch it to `impl_thread` and run a delta re-review on `<prev>..<head>`, or record `Verdict: ready-with-unreviewed-user-fix` and ask the user explicitly before committing. The orchestrator NEVER calls `Edit`/`Write` on repo source/docs files directly.
 
 ## 1. Breakdown (read-only until confirm)
@@ -57,6 +58,8 @@
 - Worktree path follows T3's own layout: `~/.t3/worktrees/<repo>/<branch with "/" replaced by "-">`, e.g. `~/.t3/worktrees/oho-api/feature-oho-8671-index-art-model`. Create it from `origin/master`, after a fetch:
   `cd <repo root> && git fetch origin master && git worktree add --no-track -b <branch> ~/.t3/worktrees/<repo>/<branch-slug> origin/master`
+  **CRITICAL T3 worktree GC warning:** T3 Code deletes `~/.t3/worktrees/<repo>/<slug>` from disk when a T3 thread bound to that `worktreePath` is deleted in the UI or GC'd! Never delete `impl_thread` while the worktree is still needed, never reuse a `worktreePath` of a deleted T3 thread without binding a live thread to it, and ALWAYS mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/` after every round.
   Any other base needs `allow-worktree`; if the card worktree sits on another branch, write that in `review.md`. The branch must track its own remote branch only after the first push: `git push -u origin <own-branch>` (never track `origin/master`). MR target is `develop`; check with `git ls-remote --exit-code --heads origin develop` (no pipe to `head`; exit 2 = missing) and tell the user if missing.
 - If the feature branch conflicts with `develop`, ask: merge into it, or a separate resolve branch. A master-based branch is also promoted to staging/master.
 - `brief.md` (one per repo) is drafted by an Agent call with `model: opus`, `effort: medium`; you check it against the breakdown before showing the user. It holds: repo, files allowed, out of scope, acceptance, a test command that has been run once (full node/jest paths, Node 20, install state), lint command, the repo's `## Rules earned` lines that apply, "do not proceed past the plan without approval". Show brief.md to the user and wait for approval. First round is plan-only (executor writes the plan into `done.md` with `STATUS: plan-ready`); the implementation round is a new run after the user approves the plan.
+  For Node.js / Dockerfile / base-image upgrades: `scout` MUST check `package-lock.json` for native addons (`binding.gyp`, `node-gyp`, `prebuild-install`, `deasync`, `sharp`, `canvas`, `bcrypt`) and verify prebuild availability for target OS/arch (`linux/amd64` on Alpine musl vs glibc) in `brief.md` before Round 1.
 
 ## 3. Implement and review: one implement thread per card (v4, 2026-10-27)
@@ -84,9 +87,10 @@
 **3d. Wait.** Wait for `done.md`, not for the thread going idle. `t3_thread_wait` on the implement thread (bounded timeout, repeat), or the watcher: Bash `run_in_background: true` with `D=<worktree>/.scratch/<CARD>/done.md; end=$(( $(date +%s) + 2400 )); while [ $(date +%s) -lt $end ]; do grep -q '^STATUS: ' "$D" 2>/dev/null && { echo DONE; tail -1 "$D"; exit 0; }; sleep 30; done; echo TIMEOUT; exit 3` and foreground waits of at most 570 s. TIMEOUT: `t3_thread_read` on the implement thread, report the last output and what is missing, stop; do not interrupt it without the user. `STATUS: blocked` = report the reason, no review.
+If the implement thread stops with a transient `Connection error` after completing the work edits/checks in the worktree (verify via `t3_thread_read` and `git status`), send a 1-line `t3_thread_send` (`"Continue from current worktree state and write .scratch/<CARD>/done.md"`) instead of re-running the entire round from scratch.
 
-**3e. Check, then review (nested under the implement thread).** On `STATUS: complete` the plan thread does the checks itself: `scout` maps every file:line in `done.md`, re-run each grep in `Grep proof`, the test and lint commands, `git log --oneline origin/master..HEAD` shows no executor commit, `git status --porcelain` and `git diff --stat` against Allowed files. Then it sends the implement thread one message: `Round <N> review: call delegate_task to claude-team (model claude-opus-5-5, effort medium, role "review", isolation "shared", mode "async", title "<CARD> r<N> review"). ...`
+**3e. Check, then review (nested under the plan thread).** On `STATUS: complete`, first sync `<worktree>/.scratch/<CARD>/*` to `/Users/tualek/ohochat/.scratch/<CARD>/`. Then the plan thread does the checks itself: `scout` maps every file:line in `done.md`, re-run each grep in `Grep proof`, the test and lint commands, `git log --oneline origin/master..HEAD` shows no executor commit, `git status --porcelain` and `git diff --stat` against Allowed files. Next, the **plan thread** spawns the reviewer directly via its native `Agent(subagent_type="reviewer", model="opus", effort="medium", description="<CARD> r<N> review")` (which T3 nests under the plan thread; no extra pi turn needed). The reviewer reads `<worktree>` and `.scratch/<CARD>/{brief,done}.md`, checks Ponytail & `REVIEW.md`, and returns the review to the plan thread, which writes `.scratch/<CARD>/review.md` and verifies `Head:` against `git rev-parse HEAD`.
```

---

### G.2 `/Users/tualek/ai-main/config/workflow.md`
**ปัญหาที่พบ:** บรรทัดที่ 55 ของ `config/workflow.md` ยังสั่งให้ route งานหนักไปยัง Orca worktree (`orca-cli`) ทั้งที่ `clickup-card` ประกาศเลิกใช้ Orca (`Orca retired 2026-10-27`) และย้ายมาใช้ T3 worktree (`~/.t3/worktrees/<repo>/<slug>`) แล้ว ทำให้เกิดความขัดแย้งระหว่างกฎกลางกับ skill นอกจากนี้ยังควรเพิ่มกฎห้ามรัน background bash loop ที่ยิง `claude -p` ซ้ำเมื่อติด quota limit

```diff
--- a/config/workflow.md
+++ b/config/workflow.md
@@ -55,3 +55,4 @@
 - Handle focused work directly; delegate substantial independent slices with scope/evidence. One writer per checkout. Reviews name MR/commit ranges; release proof stays separate.
-- When Orca is available, route substantial code/heavy work as a full handoff to a fresh Orca worktree via the version-matched `orca-cli` guide; the active harness names the worker agent and the same-workspace review/verify mechanism (supervised multi-step via skill `orchestration`).
+- Route substantial card/code work in T3 Code using a dedicated worktree under `~/.t3/worktrees/<repo>/<branch-slug>` bound to a single implement thread (`workspaceStrategy: {type: "existing_worktree"}`), with one writer per checkout (Orca retired 2026-10-27). Before starting interactive work in a worktree, verify with `ps aux` that no background chain/script is running against that checkout.
@@ -64,2 +65,3 @@
 - Ponytail plugin stays at `full` everywhere; never send `stop ponytail`, and `normal mode` does not turn it off. It never overrides house rules, validation, error handling, security, or accessibility.
 - Scheduled jobs: high-frequency polling (< 30m, watchdogs) MUST use a non-LLM script scheduler that is silent on empty output (zero LLM tokens); reserve LLM-driven scheduled runs for low-frequency synthesis (daily/weekly).
+- Headless/chain scripts calling `claude -p`: NEVER loop with a fixed short sleep (e.g. `sleep 900`) when output matches `hit your (session|weekly) limit · resets <time>`. Parse the reset timestamp and sleep until reset + 2 min (or exit immediately if interactive T3 handoff is active).
```

---

### G.3 `/Users/tualek/ai-main/memory/lessons/RULES.md`
**ปัญหาที่พบ:** บทเรียนที่เกิดขึ้นซ้ำหรือสร้างความเสียหายหนักในวันนี้ (การลบ section ใน doc ทั้งก้อนโดยไม่ตรวจรายย่อหน้า, การนับสถิติจาก `.jsonl` โดยดูแค่ `mtime` ไม่กรอง `timestamp` ราย event และ entry ซ้ำจากการ fork, และการปล่อย background chain ชนกับ T3 thread) ควรบันทึกเข้า `RULES.md`

```diff
--- a/memory/lessons/RULES.md
+++ b/memory/lessons/RULES.md
@@ -22,3 +22,6 @@
 - [*] When work needs many tool calls, don't use `gemini-3.8-flash` — it stalls in tool loops (src: pi retro 2026-10-26 01a1766e, 01a17678; hits:2)
 - [*] When waiting for CI, don't block the chat with `sleep` loops; run the wait in the background and check back (src: pi retro 2026-10-26, ~30 min blocked; hits:4)
+- [*] When a brief allows deleting a documentation section "if all about X", inspect every paragraph first and preserve non-X operational notes (e.g. `OHO_API_URL` path prefixes, `NODE_ENV` vs `APP_ENV`) — deleting a heading whole drops unrelated runbook knowledge (src: OHO-8915 r3 review 2026-10-27; hits:1)
+- [*] When computing session token/cost/hours from `.jsonl` transcripts (`~/.claude/projects`, `~/.pi/agent/sessions`), filter every message by its own ISO `timestamp` within the target date (never by file `mtime`, which updates on `cost-state`/`pr-link` syncs) and deduplicate entry `id`s across forked Pi sessions (src: retro 2026-10-27; hits:1)
+- [*] When handing off a worktree from a background script (`p0-chain-v2.sh`) to an interactive T3 thread, kill the background script PID first and verify with `ps aux` — leaving both alive causes dual-driver git collisions as soon as quota resets (src: react-p0 P02d 2026-10-27 23:06; hits:1)
```

---

### G.4 `/Users/tualek/orca/workspaces/oho-web-app-react/react-p0/.scratch/p0/p0-chain-v2.sh`
**ปัญหาที่พบ:** (1) `sleep 900` ตายตัวเมื่อชน limit ทำให้สร้างไฟล์ stub 68 ไฟล์; (2) `REVIEW_ALLOW` ขาด `Bash(git rev-parse:*)`, `Bash(rtk read:*)`, `Bash(rtk ls:*)` ทำให้ reviewer โดน deny ใน turn แรกทุกครั้ง; (3) ไม่มี pidfile lock ป้องกันการรันซ้ำหลาย instance ชนกัน

```diff
--- a/.scratch/p0/p0-chain-v2.sh
+++ b/.scratch/p0/p0-chain-v2.sh
@@ -11,4 +11,7 @@
 LIMIT_RE='(hit your|session|usage|weekly) limit|limit reached|resets [0-9]|resets at'
 TRANSIENT_RE='overloaded|API Error: 5[0-9][0-9]|ECONNRESET|socket hang up|Request timed out'
 cd $P || exit 9
+LOCKFILE=$S/chain.pid
+if [[ -f $LOCKFILE ]] && kill -0 $(cat $LOCKFILE) 2>/dev/null; then
+  print -u2 "ERROR: p0-chain-v2 already running (pid $(cat $LOCKFILE)). Kill it first."; exit 1
+fi
+print $$ > $LOCKFILE; trap "rm -f $LOCKFILE" EXIT INT TERM
 
@@ -32,4 +35,5 @@
 REVIEW_ALLOW=(Read Glob Grep 'Read(//Users/tualek/ohochat/oho-web-app/**)' 'Grep(//Users/tualek/ohochat/oho-web-app/**)'
   'Glob(//Users/tualek/ohochat/oho-web-app/**)' 'Bash(git diff:*)' 'Bash(git status:*)' 'Bash(git log:*)' 'Bash(git show:*)'
-  'Bash(rtk git diff:*)' 'Bash(rtk git status:*)' 'Bash(rtk git log:*)' 'Bash(rtk git show:*)')
+  'Bash(git rev-parse:*)' 'Bash(rtk git diff:*)' 'Bash(rtk git status:*)' 'Bash(rtk git log:*)' 'Bash(rtk git show:*)'
+  'Bash(rtk git rev-parse:*)' 'Bash(rtk read:*)' 'Bash(rtk ls:*)')
 REVIEW_DENY=(Edit Write NotebookEdit $COMMON_DENY)
@@ -49,6 +53,15 @@
     if tail -c 2000 $out | grep -qiE "$LIMIT_RE"; then
-      clog "session limit hit ($label): $(tail -c 300 $out | tr '\n' ' ') -> sleep 15m"
-      (( try > 80 )) && { clog "giving up on $label after $try limit waits"; return 3; }
-      sleep 900; continue
+      local wait_s=$(python3 -c '
+import re, sys, datetime
+txt = open(sys.argv[1], errors="ignore").read()[-2000:]
+m = re.search(r"resets\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)", txt, re.I)
+if not m: print(900); sys.exit(0)
+h, mn, ap = int(m.group(1)), int(m.group(2) or 0), m.group(3).lower()
+if ap == "pm" and h != 12: h += 12
+if ap == "am" and h == 12: h = 0
+now = datetime.datetime.now()
+target = now.replace(hour=h, minute=mn, second=0, microsecond=0)
+if target <= now: target += datetime.timedelta(days=1)
+print(max(120, int((target - now).total_seconds()) + 120))
+' "$out" 2>/dev/null || echo 900)
+      clog "session limit hit ($label): sleeping ${wait_s}s until reset"
+      sleep $wait_s; continue
     fi
```

---

## H. Top 5 Actions ที่ควรทำก่อน (เรียงตาม Impact สูงสุด → ทำได้ทันที)

1. **[ทำทันที] เคลียร์ Zombie Processes และตรวจไม่ให้ `p0-chain-v2.sh` รันซ้อนกับ T3 Thread `mcp:b1edee08`:**
   - รัน `kill 74570 35947 27132` เพื่อปิด `cursor-agent` 2 ตัวที่ค้างตั้งแต่ 16 ต.ค. (`OHO-7084`) และ `claude rc` ที่ค้างตั้งแต่ 15 ต.ค. พร้อมตรวจด้วย `ps aux | grep p0-chain` ให้มั่นใจว่าไม่มี `p0-chain-v2.sh` ค้างแย่งแก้ worktree `react-p0` แข่งกับ T3 thread [React P0 UX — handoff (oho-web-app-react, react-p0)](t3-thread://v1/mcp:b1edee08-5636-4518-908c-86f65e470a54)
2. **[ทำทันทีสำหรับการ์ด `OHO-8915`] สร้าง Worktree ของ `feature/oho-8915-node-24-alpine` กลับมาเมื่อจะ Push / เปิด MR (ห้าม Reset Branch):**
   - โฟลเดอร์ `/Users/tualek/.t3/worktrees/oho-web-app/feature-oho-8915-node-24-alpine` ถูกลบไปตอน `22:56` (เพราะเคยผูกกับ thread `mcp:ca8e1613` ที่ถูกลบไปแล้ว) แต่ **2 commits (`f75ccdf53` และ `73a43902e`) ยังอยู่ครบและปลอดภัยบน local branch `feature/oho-8915-node-24-alpine`** ใน `/Users/tualek/ohochat/oho-web-app` และไฟล์ `.scratch/OHO-8915/` ทั้งหมดยังอยู่ครบที่ `/Users/tualek/ohochat/.scratch/OHO-8915/` เมื่อจะเปิด MR สามารถ push จาก `/Users/tualek/ohochat/oho-web-app` (`git push -u origin feature/oho-8915-node-24-alpine`) ได้ทันทีโดยไม่ต้องรันงานใหม่
3. **[แก้ `skills/clickup-card/SKILL.md` ตามข้อ G.1] ให้ Plan Thread (`claude-team`) เรียก Opus Reviewer Subagent เองโดยตรง + ห้ามลบ `impl_thread` ก่อนจบการ์ด:**
   - เปลี่ยน Step 3e จากการสั่งผ่าน Pi `impl_thread` ให้ Plan thread เรียก native `Agent(subagent_type="reviewer", model="opus", effort="medium")` เองโดยตรง (เร็วกว่า ไม่เปลือง Pi context และปลอดภัยกว่า) และเพิ่มกฎห้ามลบ `impl_thread` ใน T3 UI ระหว่างทำงานเพื่อป้องกัน T3 ลบ worktree ทิ้ง
4. **[อัปเดต `config/workflow.md` และ `memory/lessons/RULES.md` ตามข้อ G.2–G.3 แล้วรัน `scripts/sync.sh`]:**
   - เอาคำสั่ง route งานไป `orca-cli` ออกจาก `config/workflow.md` ให้ตรงกับที่เลิกใช้ Orca แล้ว และเพิ่มกฎ 3 ข้อจากวันนี้เข้า `RULES.md` (ตรวจรายย่อหน้าก่อนลบ doc section, กรอง `.jsonl` ตาม event timestamp + deduplicate fork IDs, และ kill chain script ก่อน handoff เข้า T3)
5. **[ลด Context ตอนเริ่ม Session บน Claude Desktop (~45k–50k tokens/session)]:**
   - ปิด Desktop MCP extensions ที่ไม่ได้ใช้ (`Claude_Browser`, `iOS simulator`) หรือเริ่มงานผ่าน T3 Code (`claude-team` / `claude-personal` ซึ่งใช้ `sdk-cli` entrypoint ที่เริ่มด้วย ~47k–50k tokens แทนที่จะเป็น ~97.6k tokens บน Claude Desktop) เพื่อยืดอายุโควตา 5-hour session limit และ weekly limit ของบัญชี Personal Pro
