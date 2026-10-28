# Architecture

`ai-main` is a harness-neutral source of truth. The **core** (policy, skills, knowledge, memory, checks) knows nothing about any one tool; each **harness** (OMP, Codex, Claude, Gemini, Cursor, plus JSON-described tools) is an adapter that turns the core into that tool's native entry files, skill catalog and launchers. No harness is the default: a machine opts in with `install.sh --harness` or `config/harnesses.local` (see [deploy.md](deploy.md)).

## Principles

1. **Safety sources, one shared profile** — `config/style.md`, `config/workflow.md` and `config/profile.md` stay canonical; `aimain build` compiles them with `memory/` into `build/full/SYSTEM.md`. Adapters add overlays on top, never fork the rules ([profiles.md](profiles.md)).
2. **Per-repo knowledge, any folder** — `knowledge/<repo>.md` deploys to each registered workspace root as `AGENTS.md` (+ `CLAUDE.md`/`GEMINI.md` symlinks), so every tool loads repo-specific facts only inside that repo. Attach any folder with `./bin/aimain link <path>`. Knowledge is picked from `--knowledge`, else the git remote name (so a `.claude-worktrees/` worktree resolves to its real repo), else the folder name, else `knowledge/_generic.md`. Generated root files and Cursor's managed `.cursor/rules/ai-main-shared.mdc` are excluded in the target's `.git/info/exclude`. Deployment preserves tracked/handwritten files and foreign or dangling symlinks in both normal and sync mode; nested repo-owned instructions are untouched ([workspaces.md](workspaces.md)).
3. **Curated memory and self-learning** — Obsidian holds curated long-term memory; `memory/` holds promoted rules and tool histories ([memory.md](memory.md)).
4. **Skills** — owned skills in `skills/`, pinned third-party packs as submodules under `external/`, harness-specific skills under `adapters/<id>/skills/` ([skills.md](skills.md)).
5. **Checks instead of prompt rules** — rules a model can forget live in git hooks, PATH shims and guards ([checks.md](checks.md)).
6. **Git-portable** — templates use `{{HOME}}` and `{{AI_MAIN}}` placeholders that deployers rewrite; no hard-coded paths in version control.
7. **Ownership-safe updates** — deploys write only marker-managed files or exact-recognition migrations, preserve everything else and fail rather than overwrite.

## Repository structure

```
ai-main/
├── install.sh                 # harness dispatcher: --harness dsh|omp|codex|extra|legacy (no default);
│                              #   its legacy body is the Claude/Gemini/Cursor all-harness installer
├── bin/aimain                 # CLI: link/unlink/list/deploy/doctor/build/adapters/context
├── config/                    # neutral policy sources
│   ├── profile.md style.md workflow.md   # shared rules (compiled into build/full)
│   ├── workspaces.json                   # workspace registry ({{HOME}}-portable)
│   ├── harnesses.local.example           # per-machine harness selection (real file is gitignored)
│   ├── mcp.json.template RTK.manual.md caveman.json
│   ├── cursor-rules/ launchd/            # linked/installed by the legacy harness
├── adapters/                  # everything harness-specific (contract: adapters/README.md)
│   ├── lib/deploy-common.sh   # shared deploy helpers, ownership markers
│   ├── omp/                   # entry, runtime overlay, skill allowlist/builder, roles, launchers, deploy.sh
│   ├── codex/                 # AGENTS.md.template, deploy.sh
│   ├── claude/ gemini/        # entry templates, RTK/redirect skill templates
│   └── opencode.json qwen.json zcode.json   # JSON-described tools (aimain adapters deploy)
├── core/
│   ├── checks/                # git hooks + PATH shims that replaced prompt rules
│   └── hooks/                 # Claude Code hook wrappers (path referenced by live settings.json)
├── knowledge/                 # per-repo knowledge → deployed to each workspace root
├── context/                   # shared .ai context per repo (linked into Orca worktrees)
├── repo-agents/               # per-repo agent definitions
├── memory/                    # version-controlled context; commits remain explicit
│   ├── SHARED.md lessons/     # distilled cross-tool facts and rules
│   └── claude/ codex/         # native tool caches linked back by live installs
├── skills/                    # owned shared skills
├── external/                  # pinned upstream skill packs (git submodules)
├── commands/                  # slash commands (legacy Claude/Cursor deployment)
├── scripts/                   # sync.sh, verify.sh, link-worktree-agents.sh, canary-prompts.md
├── eval/                      # run.sh, shared-brain.py, harness-dispatch.py, models/
├── docs/                      # this documentation; history/ and plans/ keep older evidence
├── logs/ state/ archive/      # worklog, OMP skill snapshots, retired material
└── build/                     # GENERATED profiles and OMP skill farm — gitignored, never edit
```

Paths that live installs or tool settings reference by absolute path (`core/hooks/`, `config/cursor-rules/`, the `memory/` link targets) are deliberately stable.
