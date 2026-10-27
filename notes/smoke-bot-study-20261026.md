# Hermes smoke-test bot study — 2026-10-26 (ICT)
Source: lekfedora ~/.hermes/profiles/smoke-test (read-only; state.db opened mode=ro). Nothing changed on lekfedora.

## 1. Jobs per session (ICT)
- 10-06→07 cli "Bot Chat": readiness pings, FB login help (passkey/notification 2FA failed → TOTP in vault).
- Main telegram session 20261007_183526_27aa372c, 10-07 18:35 → 10-22 18:34, 214 user msgs, 55 PASS reports:
  - 10-07 first smoke run, FB 2FA/identifier loop.
  - 10-08 Thai time, cases from QA-E2E, Chrome CDP 9222 + Playwright MCP, Capybara normal flow, chatbot settings page → script, fixed window; evening Meta-AI UI states run (A/B no answer), evidence; retest 22:18.
  - 10-09 realtime UI states, OHO-1802 retests per commit, QA-bot brief; "ผ่านแล้วหรอ merge ได้?"
  - 10-10 flakiness vs browser size, take/assign route retests, script v2, full test 65/76 → 68/76; no BS accept flow.
  - 10-12 moved rig to Linux, copied Chrome session, retest new core-api 74/76; UAT (Boonmions) handoff; standby/external-app debugging; user: "ทำไมนาย claim ว่า bug ละ".
  - 10-15 e2e on UAT — 3× exit 1.
  - 10-16 staging-test.md plan, ClickUp card errors.
  - 10-17/18 OHO-7707 ART deletion business A/B; biz create 500 → is_staging_1 RC; QA video clip with real UI/cursor side-by-side.
  - 10-19 Hermes update/gateway restart; "นาย run ที่ไหนเนี้ย".
  - 10-22 code not in git → moved QA-E2E to Mac worktree ~/ohochat/qa-e2e-master-wt branch qa/oho-7707-art-scoping (47 new files, not committed); export test data; setup via test/e2e-agent branch.
- 10-08 4 subagents studying chatbot code (oho-api, web-app, websocket, webhook); oneshots (LIVE Meta vs OHO accept, cron polling).
- Cron "Meta↔Oho staging smoke" 0 11 * * 1-5 — paused 10-06, never ran.
- 14 sessions total, ~US$4.55, 11.0M in / 4.2M out tokens.

## 2. Envs / flows
- staging-1: https://app.staging-1.devoho.com/business/636b2a54a80e169e7ff1646c/smartchat ; 2nd biz "Oho Chat STG B" (6ad37fbd…)
- UAT: app.uat.devoho.com biz Boonmions 615141d94f30710e534fe2ca room 6aa8bbee59eb7d3d717b8ad3 (sessions die fast); Sandbox-uat biz 68f2165c45f17997f4091c8e
- FB pages: ChicaChicken (Meta AI on; msgs arrive via standby) messenger t/61590623224049 ; Capybara thread 1093488400513934 (no Meta AI, normal flow N1/N1b)
- Matrix: PRE/CLEAN, F1, A/B handoff (AB), A3, C accept-chat bot-silent, D transfer, F2 Sandbox-uat, B1–B4, N1/N1b, FLAKE, E1LITE; OHO-7707 suite T1–T5, U1, X1/X2. Every case verified in UI + GCP log (core-api--staging-1, UTC, 1–2 min delay). Restore baseline after.

## 3. Tools
- Top tool calls (main session): terminal 1092, playwright browser_run_code_unsafe 423, browser_exec(headless) 348, execute_code 321, vision_analyze 127, computer_use 74 (cua, Mac only), browser_vault_fill 39, skill_manage 72.
- Mode: drove Chrome 9222 interactively via Playwright MCP (--cdp-endpoint localhost:9222), then own runner scripts/smoke-cdp.ts v2 (--case=ALL --repeat --routes) inside QA-E2E; later e2e/agent suite (branch test/e2e-agent). No smoke.sh exists. Skill smoke-matrix (~98KB). gcloud SA logging.read (project oho-platform).
- Suite on Linux: ~/orca/workspaces/oho-web-app/smoke-matrix-e2e/test/QA-E2E (no .git; ~30 tmp-*.mjs probes).

## 4. Chrome profiles (names only)
- lekfedora ~/.config/google-chrome: Default="สิทธิพร", Profile 2="Sittiphorn" (personal — not used by bot)
- lekfedora ~/.chrome-agent-profile: Default="Your Chrome" (the bot's only profile; holds Oho + FB Test sessions)
- Mac ~/Library/.../Chrome: Default="oho.chat", Profile 1="Sittiphorn", Profile 2="สิทธิพร", Profile 3="ReTourAPAC", Profile 5="Facebook ohochat"; Mac ~/.chrome-agent-profile Default="Your Chrome"
- Launch (Linux): /usr/sbin/google-chrome-stable --remote-debugging-port=9222 --user-data-dir=$HOME/.chrome-agent-profile --no-first-run --no-default-browser-check (no --profile-directory; launched from Hermes terminal background=true; no systemd unit). Mac: open -na "Google Chrome" --args same flags.
- Chrome 9222 NOT running now (26 Oct).
- Logins: Oho staging-1 + UAT (user's own stp.rodkeaw / vault items), Facebook test customer "Sitthiporn Rodkeaw" (TOTP 2FA + Messenger restore PIN), gcloud SA, GitLab gitlab.boonmeelab.com, ClickUp (oauth). Cookie pipe headless→smoke-cookies.json→9222 (user approved).

## 5. Pain points (counts = main-session messages mentioning)
- FB login/checkpoint 56, Messenger PIN dialog 42, Playwright timeouts 56, take_failed flake 48, cooldown 409 21, 9222 refused 12, Oho token_expired 8, Mac ssh timeout 16, context compaction 14; logs: 162×429, 432 timeout.
- Viewport drift (must force 1440×900), mouse.wheel hangs, focus stealing (no bringToFront), Linux background launch blocked, code not in git, UAT exit 1, bot over-claimed bugs (standby is expected), FB cookies expire as fast as Oho.

## 6. Report format liked
Thai + English tech terms, ICT time (น.), headline "Full test จบ — N/M PASS (time range · duration · flags)", ผ่านไฮไลต์ bullets, FAIL split into product layer (for dev) vs script layer (fixed), evidence paths (json/log/screenshots), room state after run, next step. ADHD style: action first, short. User wants: real-UI evidence/video "ต้องทำเหมือน user เล่น", honest no over-claiming, don't call it a bug without proof, merge-ready verdict, code in git.

## 7. curl https://app.staging-1.devoho.com/ (26 Oct)
- lekfedora: 302 (v4 302) ; Mac: 302 (v4 302) ; UAT both 302. Both egress same home ISP /48 (2405:9800:ba00:…). Grok Bot box timed out → likely IP allowlist / network; bot must run tests from user's network (lekfedora or Mac).
