# pi resume vs RULES.md check — 2026-10-27 (ICT), read-only
Chain: memory/lessons/RULES.md --(aimain build, bin/aimain:286-292 PROFILE_SOURCES)--> build/full/SYSTEM.md (+build/full/RULES.md)
 --(extension adapters/pi/extensions/ai-main-brain.ts:20-45, before_agent_start, reads file fresh every run)--> system prompt section `ai_main_system`.
- ~/.pi/agent/extensions/ai-main-brain.ts is a symlink to the adapter file. It also injects ai_main_note (adapters/pi/agent/APPEND_SYSTEM.md) and ai_main_oracle (~/.hermes/state/ORACLE.md).
- RULES.md is NOT referenced directly in ~/.pi/agent (settings.json, APPEND_SYSTEM.md, extensions). ~/.pi/agent/shared/RULES.md -> build/lean/RULES.md is a stale 463-byte copy (Oct 18) with no new lessons; not injected by the brain ext.
- ~/.pi/agent/APPEND_SYSTEM.md (native pi addendum, Oct 1, 10.8 KB) has an old 3-rule "Rules earned" copy; 0 hits for gtimeout/freshness.
- build/full/SYSTEM.md rebuilt Oct 27 09:44 and contains gtimeout + --freshness (2 hits). build is also run by launchd com.tualek.ai-main-sync (comment in bin/aimain: every 6h). RULES.md itself mtime Oct 26 21:27 -> SYSTEM.md stale until a build ran.
- ORACLE.md (Oct 25 23:46) has no lesson text, only links.
## pi 1.4.0 session behavior
- Flags: --continue/-c, --resume/-r, --session <path|id>, --fork, --no-session. T3 pi provider driver=pi (~/.t3/userdata/settings.json); exact launch args not visible.
- Session jsonl stores system prompt as structured `message{role:system, sections{...}}` (first one: preamble, tools, rules, docs, addendum, project_context, skills, ai_main_note/oracle/system, ...), not a frozen string.
- dist/core/agent-session.js:1315-1328 `_preparePromptAndToolLoadout`: every run, diffSystemPromptSections(current system msg from transcript, buildSystemPromptSections(options after before_agent_start)) -> if changed, appends a new system message holding only changed sections. docs/session-format.md:125 compaction entries also checkpoint the system prompt.
- Empirical: session 2026-10-26T04-29-08 got a mid-session system patch at 04:54:51Z with sections {skills, ai_main_note, ai_main_oracle, ai_main_system, mcp_servers} (ai-main-brain appeared during the session) -> changed prompt sections propagate to an existing session on the next run. Across all sessions 4 such patch messages exist.
- No pi session file modified after RULES.md edit (21:27 Oct 26): newest session mtime 10-26 17:40 -> no resume has happened yet to test; no model call made.
- Not diffed on resume: project_context (AGENTS.md/CLAUDE.md context files) and addendum (~/.pi/agent/APPEND_SYSTEM.md) are discovered by pi at startup/reload (docs: `/reload`); not verified whether they are re-read per run.
## Caveat
Old history keeps yesterday's mistakes; after compaction the summary replaces them, and the system checkpoint is rebuilt/diffed again.
