# Pi context optimization plan

## Goal

Make Pi the primary daily agent with a lean, predictable global context while preserving every long-tail skill through native `/skill:name` commands.

## Decisions

- Scope this pilot to Pi.
- `pi` uses lean context, a curated hybrid skill catalog, and safe startup sync.
- `pi-raw` bypasses startup sync and uses Pi's normal full skill discovery.
- Keep model-visible global context plus skill metadata at or below 4,000 estimated tokens.
- Keep concise prose as the default response mode; Caveman is manual.
- Keep small repo knowledge as hot context; keep Obsidian as cold cross-repo knowledge; repository docs remain canonical.
- Manage the shared MCP base from `ai-main`; reserve Pi's own MCP file for overrides.
- Keep CodeGraph and Obsidian global; defer Chrome DevTools and new workflow skills.
- Obsidian read/search is automatic; create/edit/tags require an explicit writing request; move/delete requires MCP approval.

## Implementation

### 1. Pi-specific prompt tier

- Link Pi shared prompt sources to `build/lean`; leave other tools on `build/full`.
- Remove OHO-specific facts from the lean profile without changing the full profile.
- Remove redundant self-learning, worklog, and MR skill trigger prose from `PI.md.template`.
- Change the shared Caveman default wording to concise prose plus explicit Caveman activation.

### 2. Hybrid Pi skill catalog

- Add `config/pi-skills.json` with the model-invoked allowlist and 4,000-token budget.
- Build `build/pi-skills/` from owned and external skills.
- Symlink auto-invoked skills to their canonical directories.
- Generate manual pointer skills with `disable-model-invocation: true` for the long tail so `/skill:name` remains native.
- Stop duplicating ai-main skills into both `~/.pi/agent/skills` and `~/.agents/skills`.
- Remove only Pi skill symlinks that resolve into `ai-main`; preserve unmanaged entries.

### 3. Direct launchers

- Install an ai-main-managed `pi` launcher in `~/.pi/agent/bin`, which is first on PATH.
- Run safe `sync.sh --pull-only --quiet`, ensure the curated farm exists, then execute real Pi with `--no-skills --skill build/pi-skills`.
- Install `pi-raw` as the escape hatch for normal Pi discovery and no startup sync.
- Avoid recursion by resolving the real Pi from PATH with the launcher directory removed.

### 4. Safe startup sync

- Remove `git pull --autostash` from `scripts/sync.sh`.
- Pull only when `ai-main` is clean; skip with a warning when dirty.
- Continue with local config when offline.
- Never rebase or stash around unrelated dirty work during retry.

### 5. Central MCP base

- Add `config/mcp.json.template` and deploy it to `~/.config/mcp/mcp.json`.
- Use `codegraph` from PATH rather than a versioned NVM path.
- Pin `obsidian-mcp` to `2.0.1`.
- Require approval for Obsidian move/delete tools.
- Back up the current Pi-local MCP file and leave `~/.pi/agent/mcp.json` available only for future overrides.

### 6. Obsidian and benchmark skill corrections

- Rewrite `obsidian-vault` around MCP bounded search/read, OHO hierarchy, etags, and source authority.
- Replace `branch-perf-compare` stash/checkout behavior with disposable worktrees.

### 7. Verification

- Add a Pi context budget script that measures the generated append context and model-visible catalog metadata.
- Verify Pi uses `build/lean`, the curated farm has unique names, required auto skills exist, MCP config is valid, destructive approvals are present, and launchers resolve.
- Run build, prompt regression suite, installer sync, deep verification, shell syntax checks, launcher smoke checks, MCP status, and a real read-only Obsidian note call.

## Deferred phase 2

- `gcp-log-investigator` skill + CLI.
- `gitlab-mr-review` skill.
- `nuxt2-nuxt3-parity-review` skill.
- Project-local Chrome DevTools MCP.
- `oho-websocket` workspace knowledge and generalized cross-repo impact review.

## Acceptance

- Typing `pi` launches the curated profile directly.
- Typing `pi-raw` launches ordinary Pi discovery.
- Long-tail skills remain available through `/skill:name`.
- Pi-owned global prompt plus visible skill catalog is at most 4,000 estimated tokens.
- Pi discovers no duplicate ai-main skill names through its curated launcher.
- Startup sync never stashes or rebases a dirty ai-main worktree.
- CodeGraph and Obsidian MCP remain usable.
- Existing Claude, Codex, Gemini, Cursor, and Antigravity prompt tiers and skill deployment remain unchanged except for the clarified Caveman default wording.
