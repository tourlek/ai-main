---
name: ai-main-architecture
description: The ai-main repo is the single source of truth for Claude/Codex/Cursor/Gemini shared configs and skills
metadata: 
  node_type: memory
  type: project
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

`~/ai-main/` is the centralized config + skill repo. Every AI tool (Claude Code, Codex, Cursor, Gemini) is set up via `install.sh` to read its configs from here. Edit one file in `ai-main/`; all tools see the change.

**Why:** User wanted to stop maintaining the same style/workflow rules in multiple places (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`) and have new AI tools like opencode pick up the same rules automatically.

**How to apply:** When the user asks to add a new style rule, workflow rule, or skill that should apply to all AI tools — put it in `ai-main/` and run `./install.sh`, not in any tool-specific directory. Layout:

- `config/style.md` / `workflow.md` / `profile.md` — symlinked into each tool's `~/.<tool>/shared/` and `@`-imported by entry files
- `config/CLAUDE.md.template` / `GEMINI.md.template` / `AGENTS.md.template` — entry files generated per tool
- `config/RTK.md` (Claude, hook-aware) / `RTK.manual.md` (Codex, Gemini)
- `skills/` — owned skills, auto-symlinked to all 4 tools
- `external/9arm-skills/`, `external/agent-skills/` — git submodules of curated packs
- `commands/` — slash commands, symlinked to `~/.claude/commands/` and `~/.cursor/commands/`
- `install.sh` — bootstraps `rtk` + `glab` via brew, syncs everything, verifies symlinks

Don't reach into `~/.claude/`, `~/.codex/`, etc. directly to change global rules — they're regenerated from `ai-main/` on every install.
