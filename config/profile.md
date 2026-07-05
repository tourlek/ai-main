# User Profile & Environment

## Role

Software engineer working across web frontend, backend APIs, and mobile. Heavy GitLab-driven code review workflow with senior reviewers. Multi-tool AI user (Claude Code, Codex, Cursor, sometimes Gemini) running in parallel against the same repos.

## Primary workspaces

- `/Users/tualek/ohochat/` — multi-repo monorepo-style root
  - `oho-web-app` — Vue 2 / Nuxt 2, mid-migration to Nuxt 3. The most active repo.
  - `oho-api` — backend service
  - `oho-developer-api` — public/developer-facing API
  - `oho-backoffice` — internal admin UI
  - `oho-webhook` — webhook ingestion
  - `oho-flutter-mobile` — mobile app
  - `script-oho` — helper scripts
- `/Users/tualek/Documents/migrant-labor-crm/` — greenfield monorepo CRM (formerly `New project 2`)
- `/Users/tualek/thaivagroups/vetrisync-cms/` — Strapi-based CMS
- `/Users/tualek/ohochat/jeraspec-api/` — Gemini-backed work

## Tech stack

- **Web frontend**: Vue 2, Nuxt 2 → Nuxt 3 (in progress), Vuex
- **Backend**: Node.js services under `oho-*`
- **Mobile**: Flutter (`oho-flutter-mobile`)
- **Database**: MongoDB, with Atlas Data Lake (Federated) accessed via Compass — write endpoints require the real cluster, not the Data Lake
- **Deploy**: Cloud Run
- **VCS host**: GitLab self-hosted at `gitlab.boonmeelab.com`
- **Tracking**: GTM, Firebase Remote Config for feature flags (e.g. `rt_jera_feature_enabled`)
- **Docs**: Notion, with CSV imports

## Domain vocabulary

Per-repo and OHO domain knowledge lives in each workspace's root `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` (deployed from `ai-main/knowledge/`). Read it there — it is not duplicated here.

## Tool environment

- macOS, zsh, Homebrew available at `/opt/homebrew/`.
- `rtk` (Rust Token Killer) installed via brew — shell commands get auto-rewritten via Claude Code hook; manual `rtk <cmd>` prefix for Codex / Gemini.
- `glab` CLI for GitLab; the working JSON flag is `-F json`.
- AI configs centralized in `~/ai-main/`, synced into `~/.claude/`, `~/.codex/`, `~/.gemini/`, `~/.cursor/`, `~/.agents/` (Antigravity/agy) by `install.sh`. Antigravity reads global rules from `~/.gemini/GEMINI.md` and workspace `AGENTS.md` — both ai-main-managed.
- CodeGraph indexed in every primary repo (`.codegraph/`) — use `codegraph explore` / MCP for "who calls this" questions before grep.
- `~/.claude/projects/`, `~/.codex/sessions/` carry past transcripts for analysis when relevant.

## Cross-cutting facts

- Sessions are daily-driver (~5–10 Codex sessions/day, sustained). Active iteration, not occasional use.
- Worktree workflow: `.claude-worktrees/` exists in `oho-api` and `migrant-labor-crm` to run parallel sessions.
- The user often consults Codex and Claude side-by-side and pastes one tool's output to the other for a second opinion (`จาก codex แนะนำมา นายมีความเห็นว่าไง`).
