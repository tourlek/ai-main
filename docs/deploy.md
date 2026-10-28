# Deploying harnesses

`ai-main` has **no default harness**. `./install.sh` with no arguments only builds local outputs under `build/` and lists the choices; nothing is written outside the repo.

```bash
git clone --recurse-submodules <your-fork-of-ai-main> ~/ai-main
cd ~/ai-main
./install.sh --harness dsh,codex          # choose explicitly
```

Initialize missing pinned packs with `git submodule update --init --recursive`; deployment never fetches or updates them.

| Harness id | Script | Writes |
| --- | --- | --- |
| `dsh` | `adapters/dsh/deploy.sh` | `~/.dsh/AGENTS.md`, `~/.agents/AGENTS.md`, and the two `@local` plugin links plus bundle entries in `~/.dsh/profiles/desktop/package.json`, then `pnpm install`; backups go to `~/.dsh/backup-<ts>/`, and it refuses while DSH is running |
| `codex` | `adapters/codex/deploy.sh` | `~/.codex/AGENTS.md` (managed entry) and owned-skill links in `~/.codex/skills` |
| `extra` | `aimain adapters deploy` | Entries for JSON-described tools (`adapters/*.json`: opencode, qwen, zcode) |
| `legacy` | the all-harness body of `install.sh` | Claude, Gemini and Cursor entries, skills, hooks, MCP base, memory links, launchd (one-time setup) |

Aliases kept for older callers: `--codex` = `--harness codex`, `--legacy` = `--harness legacy`. `--sync` selects the fast redeploy mode used by `scripts/sync.sh`.

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/docs/deploy.md

Shared helpers and the ownership model (managed markers, exact-recognition migration, preserve anything else) live in `adapters/lib/deploy-common.sh`. Deployment preserves unmanaged entries and unrelated runtime settings, and fails instead of overwriting anything it does not recognize.

## DSH (main harness)

`aimain build` writes `build/dsh/AGENTS.md` (from `adapters/dsh/AGENTS.md`) and `build/dsh/agents-AGENTS.md` (RTK manual plus `build/full/SYSTEM.md`). `adapters/dsh/propose.sh` renders the files DSH would get into `~/.dsh/backup-20261021-consolidate/*.proposed` and changes nothing live: `package.json` (both `@local` plugin links to ai-main), `cordis.patch.yml` (live plus any missing row from `adapters/dsh/cordis.patch.yml`: `cc-review`, `cc-review-high`, `cc-explore`, `guard-bridge`), `AGENTS.md`, `agents-AGENTS.md`. `adapters/dsh/APPLY.md` has the manual apply, check and rollback steps. DSH is normally open, so leave `dsh` out of `config/harnesses.local` until you mean to quit DSH for a sync.

## Choosing harnesses per machine

Copy `config/harnesses.local.example` to `config/harnesses.local` (gitignored). `scripts/sync.sh` and `scripts/verify.sh` read it; without it `sync.sh` only rebuilds and `verify.sh` only runs repo-level checks.

```bash
cp config/harnesses.local.example config/harnesses.local   # e.g. "codex"
./scripts/sync.sh
./scripts/verify.sh
```

## What the `legacy` harness does

| Step | Action |
| --- | --- |
| 1 | Detect `$HOME` and resolve paths |
| 2 | Bootstrap `rtk` and `glab` via Homebrew if missing |
| 3 | `git submodule update --init --recursive --remote` |
| 4 | Back up existing configs to `~/.ai-backup-<ts>/` |
| 5 | Symlink `~/.ai-skills → skills/` |
| 6 | Generate Claude, Gemini, and Codex entry files from templates |
| 7 | Copy RTK rules (`RTK.md` for Claude, `RTK.manual.md` for Codex and Gemini) |
| 7b | Link the shared profile to Claude/Codex/Gemini |
| 8 | Redirect-link `gitlab-mr-description` for Gemini; back up then symlink Claude assets owned by ai-main (`core/hooks/guard.sh`, `adapters/claude/hooks/*`, `adapters/claude/agents/*`, `clickup-card`, `gitlab-mr-description` into `~/.claude` and `~/.agents/skills`) |
| 9 | Direct-symlink `gitlab-mr-description` for Cursor & Codex |
| 9b | **Direct-symlink every other owned skill** in `ai-main/skills/*` into all four tools |
| 10 | Symlink owned skills |
| 10b | Deploy `config/mcp.json.template` to the shared MCP base at `~/.config/mcp/mcp.json` |
| 11 | Symlink files from `commands/` into `~/.claude/commands/` & `~/.cursor/commands/` |
| 12 | Link canonical memory (`~/.ai-memory → memory/`, `~/.codex/memories → memory/codex/` and Claude project memories) |
| 13 | Deploy per-repo knowledge: compile `knowledge/<repo>.md` → `<workspace>/AGENTS.md` + `CLAUDE.md`/`GEMINI.md` symlinks (preserves tracked and unmanaged files, including foreign/dangling symlinks) |
| 14 | Preserve user/global ignores; generated workspace files use local Git excludes |
| 15 | Wire historical startup/scheduled hooks; `scripts/sync.sh` redeploys harnesses listed in `config/harnesses.local` without committing or pushing |
| 16 | Verify every link resolves |

`./install.sh --sync` rebuilds and redeploys the selected harnesses. `./install.sh --legacy --sync` explicitly uses the historical fast redeploy path without one-time setup steps.

`./install.sh --legacy --sync` is the historical fast redeploy path without the one-time setup steps.

## Rolling back

Legacy installation keeps `~/.ai-backup-<timestamp>/` backups. Other adapters preserve unmanaged files; restore only the entry or config changes you own, then start a fresh session. Restoring managed-skill snapshots is a separate explicit action, never an automatic sync.
