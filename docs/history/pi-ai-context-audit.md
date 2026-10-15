# Pi AI context and capability audit — 2026-09-04

## Verdict

โครงสร้างหลักใช้งานได้ดีแล้ว: `ai-main` เป็น source of truth, per-repo knowledge ถูกแยกจาก global context, Pi โหลด `APPEND_SYSTEM.md`, skills, CodeGraph MCP และ Obsidian MCP ได้จริง.

จุดที่ควรแก้ก่อนเพิ่ม MCP ใหม่คือ skill catalog ใหญ่และซ้ำ, global context ปน OHO-specific facts, Obsidian skill ไม่ตรงกับ vault ปัจจุบัน, และ prompt regression suite กำลัง fail.

## Current state verified

- `./scripts/verify.sh`: ผ่านทุก wiring check.
- `./bin/aimain doctor`: workspace ทั้งหมดที่ลงทะเบียนอยู่สถานะ healthy.
- `./eval/run.sh`: ผ่าน 27 และ fail 3 เพราะ `<!--min-->` รั่วเข้า `build/full`, `build/lean`, และ `build/min`.
- Pi append context: `13,232` bytes หรือประมาณ `3,308` tokens ก่อน repo context, skill catalog และ tool schemas.
- Pi ค้นพบ skill definitions `147` ชุดจาก `~/.pi/agent/skills` และ `~/.agents/skills`, เหลือ `87` unique names หลัง deduplicate, โดยมีชื่อซ้ำ `60` รายการ.
- Unique skill descriptions ใช้ประมาณ `5,855` tokens ตาม rough character estimate.
- Baseline รวม append context กับ unique skill descriptions อยู่ราว `9,163` tokens ก่อน tool schemas และ project `AGENTS.md`.
- Obsidian MCP ต่อสำเร็จและอ่าน `OHO/Home.md` กับ `AI Work Patterns.md` ได้จริง.
- CodeGraph และ Obsidian เป็น MCP สองตัวที่ตั้งไว้ใน `/Users/tualek/.pi/agent/mcp.json`.
- Worktree มี changes เดิมจาก session อื่นอยู่แล้ว; audit นี้ไม่แก้หรือย้อน changes เหล่านั้น.

## P0 — Fix current correctness and safety issues

### 1. Fix tier marker compilation

`core/build.awk:40` ตรวจ heading แล้ว `next` ก่อน logic strip marker ที่ `core/build.awk:57`, ทำให้ heading แบบ `## Defaults <!--min-->` ไม่ถูก strip.

แก้ compiler ให้ parse/strip tier marker ก่อนแยก heading แล้วเพิ่ม case ของ tagged heading ใน regression test.

ให้ `scripts/verify.sh` เรียก prompt regression suite หรือมี check เดียวกันด้วย เพราะตอนนี้ verify ผ่านแต่ eval fail.

### 2. Remove the unsafe benchmark branch workflow

`skills/branch-perf-compare/SKILL.md:19-24` อนุญาต `git stash`, checkout branch ใน worktree เดิม และลบ `node_modules`, ซึ่งขัดกับ parallel-session guardrail.

เปลี่ยนเป็น disposable worktree ต่อ branch, refuse shared dirty worktree, และห้าม stash changes ที่ skill ไม่ได้สร้าง.

### 3. Resolve the default prose/Caveman conflict

`config/style.md:5` กำหนด Thai prose แต่ `config/workflow.md:56` เปิด Caveman เป็น default และ `skills/caveman/SKILL.md:22-34` บังคับ bullet fragments.

ให้ prose เป็น default และเปลี่ยน Caveman เป็น user-invoked ผ่าน `/caveman` เท่านั้น.

## P1 — Reduce context cost

### 1. Use a Pi-specific lean context

ตอนนี้ `install.sh:198-204` link ทุก tool รวม Pi ไปที่ `build/full`.

ประมาณการ final Pi entry จากไฟล์ปัจจุบัน:

| Tier | Estimated entry size |
| --- | ---: |
| full | ~3,299 tokens |
| lean | ~1,997 tokens |
| min | ~1,026 tokens |

ให้ Pi ใช้ `build/lean` เป็น default จะลดประมาณ `1,300` tokens ต่อ request โดยยังเก็บ commit authorization, scope, migration safety, evidence honesty, `glab`, RTK และ code-search ladder.

ย้าย Obsidian/OHO pointer ที่ Pi ยังต้องใช้ไปไว้ใน `knowledge/ohochat.md` ซึ่งมีอยู่แล้วที่ `knowledge/ohochat.md:22-36`.

### 2. Move OHO facts out of global profile

`config/profile.md:9-43` โหลด repo inventory, Nuxt migration, Mongo/Atlas, Cloud Run, GTM/Firebase, Obsidian และ CodeGraph ในทุก repo.

เก็บ global profile เฉพาะ role, language/style, multi-tool behavior และ stable machine capabilities.

ย้าย stack, deploy, migration และ domain facts ไป `knowledge/_ohochat-shared.md` กับแต่ละ `knowledge/<repo>.md`.

ลด semantic duplication ระหว่าง `config/workflow.md`, `memory/SHARED.md`, `memory/lessons/RULES.md`, และ repo knowledge โดยให้แต่ละ rule มี source of truth เดียว.

### 3. Curate Pi skills instead of exposing every pack

Pi auto-discoversทั้ง `~/.pi/agent/skills` และ `~/.agents/skills`; `install.sh:288` และ `install.sh:299-326` วาง skill ชุดเดียวกันในทั้งสองที่.

หยุด link ai-main skills ซ้ำเข้า `~/.pi/agent/skills` เพราะ Pi อ่าน `~/.agents/skills` อยู่แล้ว.

การเอา duplicate links ออกช่วยลด warning และ precedence ambiguity แต่ยังไม่ลด unique catalog; การลด token จริงต้อง curate skills ที่ model เห็น.

แนวทางที่ควรใช้กับ Pi คือ launcher ที่เรียก `pi --no-skills --skill <curated-pi-skill-farm>` เพราะ Pi ไม่มี global setting สำหรับปิด default skill directories ตาม docs ปัจจุบัน.

Global auto-invoked set ควรเหลือ workflow ที่ใช้บ่อย เช่น debugging, MR review, commit helper, self-learning, worklog, Obsidian, research, merge conflicts และ handoff.

เปลี่ยน explicit modes เช่น `caveman*`, `grill*`, `cavecrew`, และ one-off generators เป็น `disable-model-invocation: true` หรือไม่รวมใน curated farm.

ย้าย React/Vercel/Cloudflare/Sandbox skills ไปเป็น project or stack-specific catalogs.

### 4. Remove redundant hard-coded skill pointers

`config/PI.md.template:8-20` ย้ำ trigger ของ self-learning, worklog และ GitLab MR description ทั้งที่ skills มี model-facing descriptions อยู่แล้ว.

ปรับ skill descriptions ให้เป็น authoritative trigger แล้วตัด template tail นี้ออกเพื่อลด context และ maintenance duplication.

## P1 — Improve existing Obsidian integration

ไม่ต้องสร้าง Obsidian MCP ตัวใหม่; `obsidian-mcp@2` ที่มีอยู่ทำ real read/search ได้แล้วและรองรับ bounded reads, etag และ journaled destructive operations.

`skills/obsidian-vault/SKILL.md:12-24` ระบุว่า vault mostly flat, ห้ามใช้ folders และ index เป็นแค่ list แต่ vault จริงมี `OHO/Home.md`, `OHO/Source Docs`, `OHO/Indexes` และ source-authority rules.

ปรับ skill ให้:

1. ใช้ MCP `list_vaults` → `search_vault` → `read_note` เป็น primary flow.
2. เริ่ม OHO discovery ที่ `OHO/Home.md`.
3. ใช้ repo docs เป็น canonical สำหรับ code/API/setup/release ตาม `OHO/Home.md:9-39`.
4. ใช้ Obsidian สำหรับ cross-repo knowledge, incidents, runbooks และ durable summaries.
5. อ่าน etag ก่อน edit และใช้ shell search เป็น fallback เมื่อ MCP ใช้ไม่ได้.
6. Gate `delete_note` และ `move_note` ด้วย MCP `approveTools`.

ย้าย MCP config มาเป็น canonical template ใน `ai-main`, เช่น `config/mcp.json.template`, แล้ว deploy ไป standard global path `~/.config/mcp/mcp.json`.

เลิก hard-code `/Users/tualek/.nvm/versions/node/v24.14.0/bin/codegraph` ที่ `/Users/tualek/.pi/agent/mcp.json:4`; ใช้ stable PATH command/shim.

Pin Obsidian MCP เป็น exact version และเพิ่ม read-only smoke test ใน `scripts/verify.sh`.

## Highest-value new capabilities

### 1. Ship `gcp-log-investigator` skill + CLI

ทำตาม `plan-gcp-log-investigator.md` ที่มีอยู่แล้ว: bounded time range, compact NDJSON, redaction, trace correlation และ OHO presets.

ยังไม่ควรทำ GCP MCP เพราะ `gcloud` มี auth และ query capability อยู่แล้ว; CLI compactor ลด log payload ก่อนเข้า context ได้ตรงกว่า.

### 2. Add one `gitlab-mr-review` workflow skill

รวม flow ที่กระจายอยู่ระหว่าง generic code review, MR description, MR comment reply และ Caveman formatter.

Skill นี้ควร pin base/head SHA, อ่าน MR discussions/approvals/pipeline ผ่าน `glab`, เปิด linked spec, trace code path, แยก reviewer-requested scope ออกจาก new findings และส่ง merge verdict.

Reuse `gitlab-mr-description` กับ `gitlab-mr-comment-reply`; อย่าสร้าง GitLab MCP.

### 3. Add `nuxt2-nuxt3-parity-review`

ข้อมูลใช้งานจริงมี migration/refactor 192 sessions และ UI 92 sessions ใน `/Users/tualek/Tualek/AI Work Patterns.md:51-57`.

Skill ควรตรวจ route, auth, plugins, store, SSR/client boundaries, API payload, UI parity และ validation evidence โดยไม่แก้ tests อัตโนมัติ.

เพิ่ม Chrome DevTools MCP เฉพาะ `oho-web-app` เมื่อจะทำ browser/network/console/visual parity จริง; ไม่ต้องเปิด global ก่อนมี workflow นี้.

### 4. Add missing `oho-websocket` workspace knowledge

`/Users/tualek/ohochat/oho-websocket` เป็น Git repo จริงแต่ไม่มี entry ใน `config/workspaces.json` และ `knowledge/`.

เพิ่ม minimal repo knowledge ก่อนสร้าง generalized `oho-cross-repo-impact-review` สำหรับ trace contract → producer → persistence → queue/broadcast → consumer/UI → feature flag → rollout evidence.

### 5. Add a small cross-tool handoff contract

Extend generic handoff ด้วย `.scratch/<feature>/HANDOFF.md` ที่เก็บ repo/worktree/branch/SHA, dirty vs committed files, commands run, validation evidence, environment reached, unverified items และ next action.

เหมาะกับรูปแบบ multi-tool parallel ที่บันทึกไว้ใน `/Users/tualek/Tualek/AI Work Patterns.md:34,72`.

## Do not add now

- GitLab MCP: `glab` + local Git + existing skills ให้ข้อมูลครบกว่าและควบคุม auth ง่ายกว่า.
- Filesystem MCP: Pi มี `read`, `edit`, `write`, `grep`, `find`, `ls`, `bash` อยู่แล้ว.
- GCP Logging MCP: ทำ compact CLI contract ให้เสถียรก่อน.
- Obsidian RAG/vector store ตัวที่สอง: ใช้ linked-note retrieval และ source hierarchy ที่มีอยู่.
- Auto-write Obsidian/worklog/session memory ทุก session: จะเพิ่ม noise และ stale knowledge.
- Global hooks สำหรับ migration parity, tests หรือ handoff: งานเหล่านี้ต้องใช้ task context; hook เหมาะกับ deterministic safety checks เท่านั้น.

## Recommended execution order

1. แก้ tier compiler/eval failure และ benchmark safety.
2. ทำ Pi lean profile พร้อม final-entry budget check.
3. ตัด duplicate skill roots และสร้าง curated Pi skill farm.
4. ย้าย MCP config เข้า ai-main และ rewrite Obsidian skill.
5. Ship `gcp-log-investigator`.
6. ทำ `gitlab-mr-review` และ `nuxt2-nuxt3-parity-review`.
7. เพิ่ม `oho-websocket` knowledge และ cross-repo handoff/review flow.

## Validation performed

- Ran: `./scripts/verify.sh`.
- Ran: `./bin/aimain doctor`.
- Ran: `./eval/run.sh`.
- Ran: Pi MCP status/connect, Obsidian vault listing, `OHO/Home.md` read, `AI Work Patterns.md` read, and vault searches.
- Ran: filesystem/symlink inventory, skill discovery count, context byte estimate, semantic duplication searches, and `rtk gain`.
- Not run: behavioral canary prompts across Claude/Codex/Gemini/Cursor.
- Not run: live CodeGraph query from a primary indexed repo; current cwd `ai-main` has no `.codegraph` index.
- Not run: any write through Obsidian MCP.
