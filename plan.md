# Plan: ai-main → ศูนย์กลาง instruction / repo knowledge / memory / log ข้ามทุก AI tool

> **สถานะ: เสร็จครบทุก phase (2026-07-04)** + เพิ่ม self-learning (`skills/self-learning` + `memory/lessons/LESSONS.md` compile เข้า entry ทุก tool) ตามที่สั่งเพิ่ม `./scripts/verify.sh` ผ่านทุกข้อ

เป้าหมาย: ทุก AI (Claude Code, Codex, Cursor, Gemini, Claude Desktop) ใช้กฏ, style, skill, ข้อมูล repo และความจำชุดเดียวกันจาก repo นี้ สลับเครื่อง/สลับ account แล้ว `git clone` + `./install.sh` กลับมาทำงานเหมือนเดิมทันที พร้อมลด context ที่โหลดซ้ำและมี work log กลาง

สิ่งที่มีอยู่แล้ว (ไม่ต้องทำใหม่): shared style/workflow/profile, skills sync 4 tools, slash commands, template ต่อ tool, install.sh idempotent + backup + verify

---

## Phase 1 — Per-repo knowledge base (`knowledge/`)

ปัญหา: ข้อมูลเฉพาะ repo (JERA domain, `contact_links`, sender IDs, Nuxt migration rules) กระจายอยู่ใน profile.md ก้อนเดียว ทุก repo โหลดหมดแม้ไม่เกี่ยว

1. สร้าง `knowledge/<repo>.md` หนึ่งไฟล์ต่อ workspace:
   - `knowledge/oho-web-app.md` (Nuxt 2→3 rules, Smartchat, JERA UI)
   - `knowledge/oho-api.md`, `oho-developer-api.md`, `oho-backoffice.md`, `oho-webhook.md`, `oho-flutter-mobile.md`
   - `knowledge/migrant-labor-crm.md`, `vetrisync-cms.md`, `jeraspec-api.md`
   - `knowledge/_ohochat-shared.md` — domain vocab ข้าม repo (JERA, partner-connection, sender IDs, MongoDB Atlas caveat) ให้ไฟล์ repo อ้างถึง
2. ย้ายเนื้อหา repo-specific ออกจาก `config/profile.md` ไปไฟล์พวกนี้ — profile เหลือแค่ตัวตน + tech stack ภาพรวม
3. installer deploy เข้า workspace: symlink `knowledge/<repo>.md` → `<workspace>/AGENTS.md` แล้ว symlink `CLAUDE.md`, `GEMINI.md` ชี้ไฟล์เดียวกัน (1 canonical, 3 ชื่อ, ทุก tool อ่านที่ root repo ตัวเอง)
4. กัน commit หลุดเข้า work repo: เพิ่ม `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `CLAUDE.local.md` ลง global gitignore (`~/.config/git/ignore`) — installer จัดการให้

## Phase 2 — แก้ context โหลดซ้ำ (แทน diff เดิมที่ค้างอยู่)

diff ที่ค้างใน install.sh ตอนนี้ symlink workspace `CLAUDE.md` → `~/.claude/CLAUDE.md` ทั้งก้อน ผลคือ Claude Code โหลด global CLAUDE.md จาก `~/.claude` อยู่แล้วและโหลดซ้ำอีกรอบจาก repo root — จ่าย token สองเท่าทุก session ทุก repo

1. เปลี่ยน section 10b ให้ workspace file เป็น knowledge เฉพาะ repo (จาก Phase 1) แทน global ทั้งก้อน
2. Claude Desktop Local Agent Mode ที่ไม่โหลด `~/.claude/CLAUDE.md` เอง: ให้ workspace file ขึ้นต้นด้วย `@~/.claude/CLAUDE.md` import (Claude โหลด import ซ้ำได้แต่ dedupe เอง) หรือยอมรับว่า Desktop ได้เฉพาะ repo knowledge — ตัดสินใจตอน implement โดยเทสจริง
3. เนื้อหายาวๆ ย้ายเข้า skill (โหลดเฉพาะตอน trigger) แทนการอัดใน entry file

## Phase 3 — Memory กลางใน git (`memory/`)

ปัญหา: ความจำอยู่นอก repo (`~/.claude/projects/*/memory`, `~/.codex/memories`) เปลี่ยนเครื่อง/account แล้วหาย

1. สร้าง `memory/` ใน ai-main:
   - `memory/claude/` — ย้ายของจริงจาก `~/.claude/projects/-Users-tualek-ai-main/memory/` (และ project อื่นที่มี memory) มาไว้ แล้ว symlink กลับที่เดิม
   - `memory/codex/` — ย้าย `~/.codex/memories/` มา symlink กลับ
   - `memory/SHARED.md` — facts ข้าม tool ที่กลั่นแล้ว (ทุก tool อ่านผ่าน entry file import)
2. ผลคือ memory ถูก version ใน git = cache ความจำข้ามเครื่อง/account ตัวจริง เครื่องใหม่ clone มาก็จำได้เท่าเดิม
3. ⚠️ repo ต้องเป็น private เท่านั้น — memory มีข้อมูลส่วนตัว (การเงิน ฯลฯ) จะเช็ค remote ก่อนย้าย

## Phase 4 — Sync automation (`scripts/sync.sh`)

1. `scripts/sync.sh`: `git pull --rebase` → ถ้า `memory/` หรือ `logs/` เปลี่ยน auto-commit เป็น `chore(memory): sync <date>` → push
2. Auto-commit จำกัดแค่ path `memory/` + `logs/` เท่านั้น — config/skills ยังต้องสั่ง commit เองตามกฏเดิม (ต้องยืนยันว่าโอเคกับข้อยกเว้นนี้)
3. ผูกอัตโนมัติ: Claude Code `SessionStart` hook รัน pull เงียบๆ (มี lock + timeout กันช้า) และ launchd ทุก 6 ชม. รัน sync เต็ม / หรือเลือกแบบ manual ผ่าน `/sync` command อย่างเดียว

## Phase 5 — Work log (`logs/` + `/worklog`)

1. `logs/YYYY-MM.md` — บรรทัดละงาน: วันที่, repo, สิ่งที่ทำ, MR link
2. `commands/worklog.md` + skill `worklog` (sync ทุก tool อยู่แล้วผ่านกลไกเดิม): สั่ง `/worklog` ท้าย session ให้ AI สรุปงานที่ทำ append ลง log — ใช้ได้ทั้ง Claude/Codex/Cursor/Gemini เพราะเป็น skill กลาง
3. log อยู่ใน git → ตาม Phase 4 sync ข้ามเครื่องอัตโนมัติ

## Phase 6 — Verify + docs

1. อัพเดท `scripts/verify.sh`: เช็ค knowledge symlinks ทุก workspace, memory symlinks, global gitignore entries, sync.sh รันได้
2. อัพเดท README: โครงสร้างใหม่, ขั้นตอน new device (clone → install.sh → ได้ทั้ง config+memory+log), ข้อจำกัด (claude.ai/mobile อ่านไฟล์ local ไม่ได้ — memory ใน git คือชั้น portable ที่สุดที่ทำได้)

---

## ลำดับทำ + จุดที่ต้องยืนยัน

ลำดับ: 1 → 2 → 3 → 4 → 5 → 6 (Phase 1-2 ผูกกัน, 3-4 ผูกกัน, 5 อิสระ)

ต้องยืนยันก่อนเริ่ม:
1. diff เก่าที่ค้าง (install.sh 10b/10c, verify.sh, git-commit-helper) — จะแก้ทับ section 10b ตาม Phase 2 ส่วนที่เหลือคงไว้ โอเคไหม
2. ai-main remote เป็น private repo แล้วใช่ไหม (จำเป็นก่อนย้าย memory เข้า git)
3. ยอมรับข้อยกเว้น auto-commit เฉพาะ `memory/` + `logs/` ไหม และเลือก sync แบบ hook+launchd อัตโนมัติ หรือ manual `/sync` อย่างเดียว
