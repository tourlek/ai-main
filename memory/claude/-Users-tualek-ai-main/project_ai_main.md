---
name: ai-main-architecture
description: The ai-main repo is the single source of truth for Claude/Codex/Cursor/Gemini shared configs and skills
metadata: 
  node_type: memory
  type: project
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

`~/ai-main/` is the centralized config + skill repo. Every AI tool (Claude Code, Codex, Cursor, Gemini, Antigravity/agy) is set up via `install.sh` to read its configs from here. Edit one file in `ai-main/`; all tools see the change. Antigravity (agy, successor to Gemini CLI since 2026-06) reads global `~/.gemini/GEMINI.md` + workspace `AGENTS.md` + global skills `~/.agents/skills/` — all three ai-main-managed. CodeGraph is indexed in all 10 primary repos (2026-07-04).

**Why:** User wanted to stop maintaining the same style/workflow rules in multiple places (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`) and have new AI tools like opencode pick up the same rules automatically.

**How to apply:** When the user asks to add a new style rule, workflow rule, or skill that should apply to all AI tools — put it in `ai-main/` and run `./install.sh`, not in any tool-specific directory. Layout:

- `config/style.md` / `workflow.md` / `profile.md` — symlinked into each tool's `~/.<tool>/shared/`; entry files are COMPILED (imports inlined) so Codex/Cursor/Claude Desktop get full content
- `config/CLAUDE.md.template` / `GEMINI.md.template` / `AGENTS.md.template` — entry files, support `{{HOME}}` and `{{AI_MAIN}}` placeholders
- `knowledge/<repo>.md` — per-repo knowledge, deployed as `<workspace>/AGENTS.md` + `CLAUDE.md`/`GEMINI.md` symlinks; filename = workspace dir basename; never overwrites files the workspace's git tracks; deployed names are globally gitignored
- `memory/` — canonical cross-machine memory (as of 2026-07-04): `memory/claude/<slug>/` ⇄ `~/.claude/projects/<slug>/memory`, `memory/codex/` ⇄ `~/.codex/memories`, `memory/SHARED.md` (cross-tool facts), `memory/lessons/LESSONS.md` (self-learning rules, compiled into every entry file). `~/.ai-memory` → `memory/`
- `logs/YYYY-MM.md` — central worklog via `worklog` skill / `/worklog`
- `scripts/sync.sh` — pull + redeploy (`install.sh --sync`) + auto-commit/push `memory/` + `logs/` ONLY (user authorized this exception to the no-auto-commit rule, 2026-07-03); wired to Claude Code SessionStart hook (pull-only) and launchd `com.tualek.ai-main-sync` every 6h
- `skills/` — owned skills incl. `self-learning` + `worklog`, auto-symlinked to all 4 tools
- `external/9arm-skills/`, `external/agent-skills/` — git submodules of curated packs
- `install.sh` — full setup; `--sync` flag = fast redeploy path used by sync.sh

Don't reach into `~/.claude/`, `~/.codex/`, etc. directly to change global rules — they're regenerated from `ai-main/` on every install/sync. Repo is private and must stay private (memory holds personal data).
