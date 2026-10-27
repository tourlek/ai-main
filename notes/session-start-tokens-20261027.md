# Session-start context: Claude Code vs pi (2026-10-27, Asia/Bangkok)

Read-only investigation. No config was changed. Helper scripts only: `~/agent-tools/{sess_an,shape_an,full_an}.py`.
Unit: CONTEXT-window occupancy at the first model call, as `/context` would count it. Not billed tokens.

## TL;DR
- The "99k" is real content, not the autocompact buffer. Real first-turn input = 97,650 tokens (Claude Desktop session `a2c117b6`, ohochat, 16:11). `/context` shows the buffer as its own row and leaves it out of "Tokens used" (logged `/context` from 2026-10-18 confirms: 44.4k used, 33k buffer on a separate row).
- It is a **Claude Desktop (`entrypoint: claude-desktop`)** session. Same machine, same CLAUDE.md: `sdk-cli` (Orca) sessions start at 46-50k, an older `cli` session was ~66k. About half of the 99k is Desktop-injected tool schemas and Anthropic built-in tools, not ai-main.
- Today's CLAUDE.md @import change added only about +4k chars (about +1.0-1.5k tokens). Not the cause.
- pi starts at about 60k when launched inside T3 Code (83 t3-code MCP tools are loaded in full) and about 27k in a plain pi session (`/tmp`).

## Method / calibration
- Claude: session JSONL `api-request-shape` (system blocks, tools array), `api-request-blob` (messages), `attachment` records (instructions, skill_listing, deferred_tools_delta, mcp_instructions_delta, hook_success). Total chars about 264k vs 97,650 real tokens, so about 0.367 tok/char (about 2.7 chars/token). Scaled estimates, +/-10%.
- pi: the first `system` message records `sections` and `toolsAdded`. Sections 104.8k chars + tools 126.5k chars = 231k chars vs 60.3k real first-turn input (input+cacheRead). About 3.85 chars/token. The plain `/tmp` session fits the same ratio (3.94), so tools are counted in full.
- Real first-turn usage: Claude = input + cache_creation + cache_read. pi = input + cacheRead + cacheWrite (deepseek-flash).

## Side-by-side (first turn, estimated tokens)
Claude column = Desktop session `a2c117b6` (97.6k real). pi column = newest pi session `01a17c2d` in ohochat via T3 Code (60.3k real). Last column = plain pi in `/tmp` (27.3k real).

| /context category | Claude Desktop (tok) | chars | pi in T3 Code (tok) | chars | pi plain (tok) |
|---|---|---|---|---|---|
| System prompt (base) | 12.6k | 34.2k | 0.75k (preamble/tools/rules/docs/cwd) + 2.8k addendum | 2.9k + 10.8k | about 3.6k |
| System tools (built-in) | 29.6k (20 tools; `Artifact` alone 13.4k) | 80.7k | 1.4k (8 tools) | 5.5k | about 4.5k |
| MCP tools (schemas loaded) | 17.5k (32 tools: Claude_Browser 8.2k, ccd_turn 2.9k, iOS-sim 2.4k, visualize 1.5k, ccd_session 1.4k, other 1.1k) | 47.7k | 30.9k (t3-code 83 tools 28.3k, graphify 10 tools 1.7k, context7 2 tools 1.3k) | 120.8k | 0 |
| MCP server instructions | 5.4k (codegraph 1.5k, open-design 1.5k, others 2.4k) | 14.6k | 0.1k (2 tool_search servers: clickup, open_design) | 0.4k | about 0 |
| Deferred tool NAMES (schemas not loaded) | 5.9k (326 names) | 16.2k | n/a (tool_search, 2 servers) | - | - |
| Custom agents | 1.2k (8 types) | 3.4k | 0 | 0 | 0 |
| Memory files | 11.2k (10 files) | 30.5k | 7.1k: ai_main_system 4.6k + oracle 1.0k + note 0.2k + project_context 1.3k | 27.1k | about 5.8k |
| Skills listing | 10.1k (80 skills) | 27.6k | 14.4k (skills section) | 55.6k | about 14.4k |
| Hook output (SessionStart) | 1.1k (ponytail, 2.9k chars; UserPromptSubmit codegraph hook adds about 0.4k per prompt) | 2.9k | 0 | 0 | 0 |
| Env / MCP notices / advisor / attribution / T3 orchestration | 2.1k | 5.7k | 2.1k (t3_code_orchestration 8.1k chars) | 8.1k | 0 |
| Messages (user prompt) | about 0 | - | about 0.1k | - | - |
| **Sum (estimated)** | **about 96.7k** | | **about 60k** | | **about 27k** |
| Real first-turn | **97,650** | | **60,296** | | **27,307** |
| Autocompact buffer (reserved, NOT in the sum) | see below | | pi has no reserve row | | |

Memory-file chars on Claude (10 files, 30.5k): ORACLE 3.9k, RTK 1.0k, profile 3.0k, style 1.8k, workflow 8.0k, SHARED 0.6k, RULES 4.1k, CLAUDE.md 0.3k, ohochat/CLAUDE.md 4.7k, project MEMORY.md 3.2k. The pi `ai_main_system` section (17.6k chars) is the same content as the five shared files; the pi `ai_main_oracle` section matches the ORACLE block. ai-main content costs about 6k tokens in pi and about 7-8k in Claude (plus project files).

Other Claude entrypoints (real first-turn):
| Session | Entrypoint | First turn |
|---|---|---|
| ohochat `a2c117b6` (16:11) | claude-desktop | 97,650 |
| cs-agent-kit `e563bf81` | claude-desktop | 90,605 |
| Orca p0 sessions | sdk-cli | 46.3k-49.7k |
| ohochat (Oct 14-15) | cli | about 66k |
| ohochat `46e58185` (Oct 16) | claude-desktop | 95,218 |

## Top contributors to Claude's 97.6k (estimated)
1. Built-in/system tool schemas 29.6k: `Artifact` 13.4k (36k chars), Workflow 2.0k, Agent 1.8k, ScheduleWakeup 1.8k, AskUserQuestion 1.6k, SendUserFile 1.2k, Bash 1.2k. Desktop adds these; Orca/sdk-cli has about 32k chars of built-ins instead of 80k.
2. MCP tool schemas 17.5k, all Desktop-injected (Claude_Browser 19 tools, ccd_turn, iOS simulator, visualize, ccd_session, terminal). Not from `~/.claude.json`.
3. System prompt 12.6k (fixed, Anthropic).
4. Memory files 11.2k (ai-main shared files + ORACLE + project files).
5. Skills listing 10.1k (80 skills: anthropic-skills 13 = 2.6k, mattpocock 11 = 0.9k, ponytail 6 = 0.6k, rest user/plugin).
6. Deferred names 5.9k + MCP instructions 5.4k = 11.3k. Names come from claude.ai connectors synced into Desktop: ClickUp 65, Figma 43, Gmail 30, Slack 27, Google Calendar 9, Claude Docs 5; plus claude-in-chrome 22, open-design 22, ccd_* about 60, scheduled-tasks 6. Instructions: codegraph 4.1k chars, open-design 4.1k, three connectors 5.3k, claude-in-chrome 1.0k.
7. Hook + agents + env + advisor about 4.4k.

## Does `/context` count the autocompact buffer in the 99k?
- No. The 97,650 is API-reported input (cannot contain a reservation). In `/context` the buffer is a separate row, and "Tokens" and "Free space" exclude deferred tools. Real sample from `~/.claude/projects/-Users-tualek/e1c927f0-...jsonl` (2026-10-18, 200k window): Tokens 44.4k (22%), Autocompact buffer 33k (16.5%), Free 122.6k.
- Before the 500k change, 99k was 49% of a 200k window (plus 33k buffer = 66%), which is why it looked huge. On a 500k window it is about 20%.
- With `autoCompactWindow: 500000` and `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=85`, the known formula (issue #27189, v2.1.49) is trigger = min(floor(effWindow x 85%), effWindow - 13k), where effWindow = window - reserved output. That gives about 408-425k, so compaction starts earlier than "500k", and the buffer would be about 75-92k if `/context` honors the override. The same issue says `/context` ignored the override and still showed the default 33k. Not verified for 2.1.311 (a live check is blocked until the session limit resets 18:00 Asia/Bangkok). If you want compaction near 500k, raise or unset the PCT (not changed here).
- pi has no reserve row; its first-turn figure is the whole prompt.

## Did today's CLAUDE.md import change add context?
- Old compiled CLAUDE.md (backup `~/.claude/backup-20261027-context/CLAUDE.md`, 14,770 chars) + ORACLE 3,943 = 18,713 chars. New: CLAUDE.md 257 + ORACLE 3,943 + RTK 957 + five shared files 17,531 = 22,688 chars. Delta about +3,975 chars, about +1.0-1.5k tokens (about 1.5% of the 99k).
- Causes: RULES.md grew to 4.1k chars (about 13 new rules), RTK.md is now a separate file, and the compiled copy was no longer deduplicated. SYSTEM.md is not imported by Claude, so nothing is duplicated.
- The remaining gap between cs-agent-kit (90.6k) and ohochat (97.6k) is project content: ohochat CLAUDE.md 4.7k + MEMORY.md 3.2k, more deferred names and MCP instructions.

## Reduction options, ranked by savings (nothing applied)
Always back up the target file first (`cp -p file file.bak-YYYYMMDD`). Revert = copy the backup back.

| # | Option | Est. saving | File / where | Revert |
|---|---|---|---|---|
| 1 | Start work in `claude` CLI / Orca (sdk-cli) instead of Desktop: no Artifact, no Desktop MCP servers, about 47-50k at start vs 98k | about 45-50k | No file. Choose the entrypoint. | Use Desktop again |
| 2 | Deny the `Artifact` tool (if it is not used): `permissions.deny` in `~/.claude/settings.json`. Needs a test that deny removes the schema from context | about 13k | `~/.claude/settings.json` | Restore `.bak` |
| 3 | Disable unused Desktop MCP servers/extensions (Claude_Browser, iOS simulator, visualize, ccd_*): Desktop Settings. Outside the allowed paths, so proposal only | up to 17k | Claude Desktop settings UI | Re-enable the toggle |
| 4 | Disconnect the claude.ai connectors you do not need in Claude sessions (Figma 43 names, Slack 27, Gmail 30, ClickUp 65, Calendar 9, Claude Docs): claude.ai Settings > Connectors. pi and Cursor have their own MCP copies | about 6-9k (names + instructions) | claude.ai account setting (not in `~/`) | Reconnect (OAuth) |
| 5 | Trim skills: set unused plugins to `false` in `enabledPlugins` (mattpocock-skills 0.9k, ponytail 0.6k, session-report); move rarely used entries out of `~/.claude/skills` (38 entries) to a backup folder | 1.5-4k | `~/.claude/settings.json`, `~/.claude/skills/` | Restore `.bak` / move back |
| 6 | Remove `open-design` (instructions 4.1k chars + 22 deferred names, about 2k) and `codegraph` (4.1k chars, about 1.6k) from top-level `mcpServers` if not used every session. Keep codegraph if the hooks rely on it | about 2-3.6k | `~/.claude.json` (`mcpServers`) | Restore `.bak` |
| 7 | Slim memory: `shared/workflow.md` 8.0k chars (about 3k tokens) and ORACLE 3.9k duplicate RULES/profile material. Edit the sources in `~/ai-main` (not the symlinks), rebuild | 2-4k (also helps pi) | `~/ai-main/shared/*` sources, `~/.hermes/state/ORACLE.md` | `git checkout`/`.bak`, rebuild |
| 8 | Silence SessionStart ponytail hook text (2.9k chars) and the per-prompt codegraph prompt-hook (1.1k chars x prompts, accumulates) | 1.1k + 0.4k per prompt | `~/.claude/settings.json` hooks, plugin hooks | Restore `.bak` |
| 9 | Project files: ohochat CLAUDE.md 4.7k chars and MEMORY.md 3.2k chars | about 1-2k | `~/ohochat/CLAUDE.md`, `~/.claude/projects/-Users-tualek-ohochat/memory/MEMORY.md` | `.bak` |

pi side (not requested, for reference): in T3 Code, the 83 t3-code tool schemas are 28k of the 60k. Skills section 14.4k (55.6k chars) is larger than Claude's skills listing. Options: load the t3-code MCP through `tool_search` mode like clickup/open_design (about 25k saved), and trim the pi skills manifest. Files: `~/.pi/agent` MCP config / T3 settings. Not examined further.

## Caveats
- Claude per-category tokens are scaled from chars (about +/-10%), not from the tokenizer. The real `/context` run was not possible: the session limit is hit until 18:00 Asia/Bangkok. Re-run `/context` once and compare to this table.
- UUID server names were mapped to products by their tool names (ClickUp, Figma, Gmail, Slack, Google Calendar, Claude Docs).
- Saving figures overlap (1 includes 2 and 3).
