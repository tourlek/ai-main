# 🤖 AI-Main: Centralized AI Configurations & Shared Skills

A single source of truth for global AI configurations, per-repo knowledge, shared memory, lessons, work logs, skills, slash commands, and external skill packs — synced across **Claude Code**, **Gemini CLI**, **Cursor**, and **Codex**, and across machines/accounts via git.

---

## 🌟 Key Features

1. **Single source of truth for style, workflow, and profile** — `config/style.md`, `config/workflow.md`, `config/profile.md` are symlinked into every tool's `~/.<tool>/shared/` dir and compiled into each tool's entry file. Edit once, every AI agent sees the change on the next sync.
1b. **Per-repo knowledge, any folder** — `knowledge/<repo>.md` deploys to each registered workspace root as `AGENTS.md` (+ `CLAUDE.md`/`GEMINI.md` symlinks), so every tool loads repo-specific facts only inside that repo. Attach any folder with `./bin/aimain link <path>` — repo or not, in the registry or ad-hoc. Knowledge is picked from `--knowledge`, else the git remote name (so a `.claude-worktrees/` worktree resolves to its real repo), else the folder name, else `knowledge/_generic.md`. Deployed files are gitignored globally *and* root-anchored in the target's `.git/info/exclude`, and never overwrite a file the workspace's own git tracks.
1c. **Shared memory in git** — `memory/` holds Claude project memories, Codex memories, cross-tool facts (`memory/SHARED.md`), and lessons (`memory/lessons/LESSONS.md`); tool locations are symlinked into it. Clone on a new machine and every tool remembers everything.
1d. **Self-learning** — the `self-learning` skill appends mistakes/corrections to `LESSONS.md`, which is compiled into every tool's entry file: one tool's mistake becomes every tool's rule.
1e. **Auto-sync** — `scripts/sync.sh` pulls, redeploys, and auto-commits/pushes `memory/` + `logs/` (only those paths). Wired to a Claude Code SessionStart hook (pull-only) and a launchd job every 6 h.
1f. **Central worklog** — the `worklog` skill / `/worklog` command appends one-line entries to `logs/YYYY-MM.md`, synced across machines.
2. **Git-Portable Design** — Templates use `{{HOME}}` placeholders that the installer rewrites to the active user's `$HOME`. No hard-coded paths in version control.
3. **Centralized Skills** — One canonical copy in `skills/`. Modify it once; every assistant sees the change.
4. **External Skill Packs** — Curated/verified third-party skill repos are pulled in as git submodules under `external/`, version-pinned by commit (currently [thananon/9arm-skills](https://github.com/thananon/9arm-skills) and [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)).
5. **Slash Commands** — A shared `commands/` folder is symlinked into `~/.claude/commands/` and `~/.cursor/commands/`.
6. **Per-Tool Rule Files** — Each assistant gets the rule file it expects (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md` for Codex) generated from `config/*.template`, and that file `@`-imports the shared style/workflow/profile.
7. **RTK Auto-Bootstrap** — The installer checks for `rtk` and `glab` via Homebrew and installs them when missing.
8. **Automatic Backups** — Existing configs are moved to `~/.ai-backup-<timestamp>` before being overwritten.
9. **Verification Pass** — End-of-install check confirms all symlinks resolve.

---

## 🎚️ Prompt profiles (any model, not just the frontier ones)

The rule sources under `config/` and `memory/` carry tier markers. A line tagged `<!--min-->`
ships in every profile, `<!--lean-->` in lean and full, and an untagged line only in full.
`./bin/aimain build` compiles all three into `build/` (gitignored); tools read from there, so
markers never reach a model.

| Profile | Ceiling | For | Built from |
| --- | --- | --- | --- |
| `full` | 4,000 tok | Claude, Codex, Gemini Pro | everything — byte-identical to the pre-tiering files |
| `lean` | 1,600 tok | mid-tier and cheap hosted models (opencode) | hard rules + working method, no narrative or examples |
| `min` | 650 tok | 7B-class local models (qwen) | only the rules a small model can actually follow |

`aimain build` warns when a profile is over its ceiling but never fails — it runs from launchd
every 6 h and must not brick. `scripts/verify.sh` is where an overrun fails.

## 🔌 Adapters — adding a tool without editing shell

`adapters/*.json` describes any tool beyond the five original targets: where its entry file
lives, which profile it gets, and where to link skills. Adding a tool means adding one JSON
file. An entry file ai-main did not generate is backed up, never overwritten. See
`adapters/README.md`.

## 🧩 Hermes Agent bridge

Hermes can consume the same shared baseline without replacing its native memory or bundled
skills. On a machine where Hermes is installed, run:

```bash
./bin/aimain hermes sync
```

The bridge:

- generates Hermes `SOUL.md` from `config/hermes-soul.md` and the shared response style;
- builds a gitignored skill farm at `build/hermes-skills/` (owned skills + external packs,
  excluding `deprecated/`/`in-progress/`/`personal/`/`node_modules/`) and points Hermes
  `skills.external_dirs` at it, alongside native skills;
- redeploys registered workspace knowledge so Hermes can load `AGENTS.md` / `.hermes.md`;
- keeps Hermes native memory separate from Codex memory to avoid format and ownership conflicts.

On Linux the bridge prefers the service profile at `~/lekagents/hermes/profiles/personal`;
override it with `AI_MAIN_HERMES_HOME=/path/to/hermes-home ./bin/aimain hermes sync`. The
bridge does not commit or push changes. Pull the private repo first, then run the command
when shared rules or skills change. Restart Hermes or start a new session after syncing.

## 🛡️ Checks instead of prompt rules

Rules a model can forget were moved out of the prompt and into places a model cannot skip:

| Check | Where it runs | Replaces |
| --- | --- | --- |
| `core/checks/commit-msg-lint.sh` | git `commit-msg` | "no Co-Authored-By / AI attribution" |
| `core/checks/pre-push-guard.sh` | git `pre-push` | "never push to master/main" |
| `core/checks/pre-commit-guard.sh` | git `pre-commit` | "renaming a state-gating field needs a backfill" |
| `core/checks/shims/glab` | PATH shim | "`glab` uses `-F json`, not `--json`" |
| `core/checks/git-guard.sh` | CLI + Claude `PreToolUse` | amend-of-merged-commit, implicit branch targets, `reset --hard`, `clean -f`, force push, unauthorized commit |

Every check has an escape hatch (`AIMAIN_BYPASS=1`, `AIMAIN_ALLOW_COMMIT=1`,
`AIMAIN_ALLOW_DELETE_MIGRATION=1`). The Claude `PreToolUse` guard runs in **audit** mode by
default — it reports and gets out of the way; `export AIMAIN_ENFORCE=block` makes it blocking.

`memory/lessons/COVERAGE.md` maps every lesson to where it ended up, so the shrink stays
auditable. `LESSONS.md` remains the full journal — it is just no longer loaded every session.

## 🧪 Prompt regression suite

```bash
./eval/run.sh     # 30 assertions, no model calls, runs in a second
```

Asserts that each profile still carries the rules it is supposed to, that retired rules really
are enforced by a check, that `git-guard` classifies the commands behind past incidents, and
that no tier leaks its markers. Run it after touching `config/*.md`, `memory/lessons/*`, or
`core/checks/*`.

## 🛠️ Quick Installation (New Device)

```bash
git clone --recurse-submodules <your-fork-of-ai-main> ~/ai-main
cd ~/ai-main
./install.sh
```

If you forgot `--recurse-submodules`, the installer will run `git submodule update --init` for you.

---

## 📂 Repository Structure

```
ai-main/
├── install.sh                    # idempotent installer + verifier
├── bin/aimain                    # CLI: link/unlink/list/deploy/doctor/build/adapters/hooks/shims
├── adapters/                     # one JSON per extra tool (opencode, qwen, ...)
├── build/                        # GENERATED prompt profiles (full/lean/min) — gitignored
├── core/
│   ├── build.awk                 # tier compiler
│   ├── checks/                   # git hooks + PATH shims that replaced prompt rules
│   └── hooks/                    # Claude Code hook wrappers
├── eval/run.sh                   # prompt regression suite
├── config/
│   ├── workspaces.json           # workspace registry ({{HOME}}-portable)
│   ├── CLAUDE.md.template        # → ~/.claude/CLAUDE.md   (entry — @-imports shared/*)
│   ├── GEMINI.md.template        # → ~/.gemini/GEMINI.md   (entry — @-imports shared/*)
│   ├── AGENTS.md.template        # → ~/.codex/AGENTS.md    (entry — @-imports shared/*)
│   ├── RTK.md                    # → ~/.claude/RTK.md      (hook-aware variant)
│   ├── RTK.manual.md             # → ~/.codex/RTK.md, ~/.gemini/RTK.md (manual prefix)
│   ├── style.md                  # ⇄ symlinked into each tool's shared/  — response style
│   ├── workflow.md               # ⇄ symlinked into each tool's shared/  — working rules
│   └── profile.md                # ⇄ symlinked into each tool's shared/  — user profile + tech stack
├── knowledge/                    # per-repo knowledge → deployed to each workspace root
│   ├── _ohochat-shared.md        # OHO domain vocab, imported by every oho-* file
│   └── <repo>.md                 # one per primary workspace (filename = dir basename)
├── memory/                       # canonical cross-machine memory (auto-committed by sync.sh)
│   ├── SHARED.md                 # distilled cross-tool facts — compiled into every entry file
│   ├── lessons/LESSONS.md        # self-learning: mistakes → permanent rules, loaded everywhere
│   ├── claude/<project-slug>/    # ⇄ ~/.claude/projects/<slug>/memory
│   └── codex/                    # ⇄ ~/.codex/memories
├── logs/                         # central worklog, YYYY-MM.md (auto-committed by sync.sh)
├── scripts/
│   ├── sync.sh                   # pull + redeploy + auto-commit memory/ logs/ + push
│   └── verify.sh                 # deep verification
├── skills/
│   └── gitlab-mr-description/    # canonical shared skill (+ self-learning, worklog, ...)
├── commands/                     # slash commands → ~/.claude/commands, ~/.cursor/commands
├── redirects/                    # in-tree SKILL.md redirects for Claude & Gemini
│   ├── claude/
│   └── gemini/
└── external/
    ├── 9arm-skills/              # git submodule — synced to all four tools
    └── agent-skills/             # vercel-labs/agent-skills — Vercel's verified pack
```

---

## 🧠 Installed Skills

Every skill below is symlinked into `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`, and `~/.gemini/skills/` by `install.sh`.

### Owned (this repo, `skills/`)

| Skill | Purpose |
| --- | --- |
| `gitlab-mr-description` | Draft / improve / standardize GitLab MR descriptions from `glab` data. Triggered by a GitLab MR URL or an MR-description request. |
| `gitlab-mr-comment-reply` | Draft concise Thai/English replies to GitLab MR review comments, anchored to actual code, with reply category (accept / push-back / explain / defer). |
| `git-commit-helper` | Inspect local diff, decide commit grouping, pick conventional prefix, write subject + body. Ported from Codex. |
| `branch-perf-compare` | Standardize RAM/startup/bundle comparisons across git branches (e.g. `uat` vs `nuxt3` vs `perf/*`) and produce a paste-ready perf report. |
| `self-learning` | Capture mistakes and user corrections as permanent lessons in `memory/lessons/LESSONS.md`, loaded by every tool at session start. |
| `worklog` | Append one-line work log entries to `logs/YYYY-MM.md`; read back when asked "what did I work on". |

### From [`thananon/9arm-skills`](https://github.com/thananon/9arm-skills) — `external/9arm-skills/`

| Skill | Purpose |
| --- | --- |
| `debug-mantra` | Four-step debugging discipline — reproduce, trace, falsify, cross-reference — recited verbatim at the start of any debug session. |
| `scrutinize` | Outsider-perspective end-to-end review of a plan, PR, or code change. Questions intent and traces the actual code path. |
| `post-mortem` | Canonical engineering write-up of a fixed bug: root cause, mechanism, fix, validation, slip-through analysis. |
| `management-talk` | Rewrites engineer-to-engineer content for leadership audiences across JIRA / Slack / email / standup channels. |

### From [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) — `external/agent-skills/` (Vercel's verified pack)

| Skill | Purpose |
| --- | --- |
| `deploy-to-vercel` | Deploy applications / preview deployments to Vercel from natural-language requests. |
| `vercel-cli-with-tokens` | Manage Vercel projects via CLI using access-token auth (non-interactive). |
| `vercel-optimize` | Audit Vercel-deployed projects for cost, performance, and Core Web Vitals; produces ranked recommendations. |
| `react-best-practices` | React / Next.js performance optimization guidelines (40+ rules) from Vercel Engineering. |
| `react-native-skills` | React Native + Expo best practices for performant mobile apps (16 rules). |
| `react-view-transitions` | Implement smooth animations with React's View Transition API. |
| `composition-patterns` | React composition patterns for scalable component architecture (compound components, render props, etc.). |
| `web-design-guidelines` | Audit UI code against the Web Interface Guidelines (100+ rules), incl. accessibility. |

> Skills under `deprecated/`, `in-progress/`, `personal/`, or `node_modules/` in any external pack are automatically excluded by `install.sh`.

---

## 🔁 What `install.sh` Does

| Step | Action |
| --- | --- |
| 1 | Detect `$HOME` and resolve paths |
| 2 | Bootstrap `rtk` and `glab` via Homebrew if missing |
| 3 | `git submodule update --init --recursive --remote` |
| 4 | Back up existing configs to `~/.ai-backup-<ts>/` |
| 5 | Symlink `~/.ai-skills → skills/` |
| 6 | Generate `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` from templates |
| 7 | Copy RTK rules (`RTK.md` for Claude, `RTK.manual.md` for Codex & Gemini) |
| 7b | **Symlink `config/style.md`, `workflow.md`, `profile.md` into every tool's `shared/` dir** — single source of truth |
| 8 | Redirect-link `gitlab-mr-description` for Claude & Gemini |
| 9 | Direct-symlink `gitlab-mr-description` for Cursor & Codex |
| 9b | **Direct-symlink every other owned skill** in `ai-main/skills/*` into all four tools |
| 10 | Symlink **every shippable skill** in each `external/<pack>/skills/` into all four tools (excludes `deprecated/`, `in-progress/`, `personal/`, `node_modules/`) |
| 11 | Symlink files from `commands/` into `~/.claude/commands/` & `~/.cursor/commands/` |
| 12 | Link canonical memory: `~/.ai-memory → memory/`, `~/.codex/memories → memory/codex/`, Claude project memories ⇄ `memory/claude/<slug>/` (adopts any new local memory dirs into the repo) |
| 13 | Deploy per-repo knowledge: compile `knowledge/<repo>.md` → `<workspace>/AGENTS.md` + `CLAUDE.md`/`GEMINI.md` symlinks (skips anything the workspace's git tracks) |
| 14 | Add `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`/`CLAUDE.local.md` to the global gitignore |
| 15 | Wire Claude Code `SessionStart` hook (`sync.sh --pull-only --quiet`) and load the launchd job (`com.tualek.ai-main-sync`, every 6 h) |
| 16 | Verify every link resolves |

`./install.sh --sync` is the fast path used by `sync.sh`: it skips brew/submodules/backups/Claude-Desktop/hook/launchd and only redeploys configs, memory links, and knowledge.

---

## 🔄 Sync & New Device

```bash
# any machine, any account:
git clone --recurse-submodules git@github.com:tourlek/ai-main.git ~/ai-main
cd ~/ai-main && ./install.sh
```

That restores configs, skills, commands, per-repo knowledge, **and all memory/lessons/logs**.

Ongoing sync is automatic: Claude Code pulls at session start; launchd runs a full sync (pull → redeploy → auto-commit `memory/` + `logs/` → push) every 6 hours. Manual: `./scripts/sync.sh`. Auto-commit is scoped to `memory/` and `logs/` only — config/skill changes are always committed by hand.

⚠️ `memory/` contains personal data — this repo must stay **private**.

---

## ➕ Adding Your Own Items

### A new shared skill

```bash
mkdir -p skills/<my-skill>
$EDITOR skills/<my-skill>/SKILL.md        # YAML frontmatter: name, description
./install.sh
```

The installer's step 9b auto-discovers any new folder in `skills/` and direct-symlinks it to all four tools. Redirect templates under `redirects/` are only needed for the historical `gitlab-mr-description` skill.

### A new shared rule file

```bash
$EDITOR config/<my-rule>.md
```

Then add the filename to the `for shared_file in style.md workflow.md profile.md ...` loop in `install.sh` and append a corresponding `@{{HOME}}/.<tool>/shared/<my-rule>.md` line to the relevant entry templates (`config/CLAUDE.md.template`, `AGENTS.md.template`, `GEMINI.md.template`).

### A new slash command

```bash
$EDITOR commands/<my-command>.md
./install.sh
```

Format details are in `commands/README.md`.

### A new external skill pack

```bash
git submodule add <repo-url> external/<pack-name>
```

If the pack uses the same `skills/.../SKILL.md` layout as 9arm-skills, extend the `NINE_ARM_DIR` block in `install.sh` to iterate over it.

---

## ✅ Verifying the Setup

Two layers — run both whenever you suspect a tool isn't picking up the global config.

**Layer 1: File-level (automated)**

```bash
./scripts/verify.sh
```

Checks:
- Entry files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) exist and every `@`-import resolves
- `shared/style.md`, `workflow.md`, `profile.md` symlinks point back into `ai-main/config/`
- RTK files match the canonical copies (no drift)
- Each tool's `skills/` dir contains all 4 owned skills
- Reports the actual auto-loaded byte/token payload per tool

Exit code 0 = clean, non-zero = something broke. Re-run after `./install.sh` if you tweaked anything.

**Layer 2: Behavioral (manual canary prompts)**

```bash
cat scripts/canary-prompts.md
```

A set of paste-ready prompts that test whether each tool is actually *following* the rules (not just loading them). Covers Thai response style, commit authorization, scope discipline, tech-stack awareness, `glab` conventions, and skill discoverability.

Use Layer 1 to rule out wiring; if Layer 1 passes but a behavioral check fails, the issue is model-side (restart the tool, or check whether the tool actually expands `@`-imports).

---

## ❓ FAQ

**Do I have to run AI tools from `~/ai-main`?**
No. All four tools auto-load global config from `~/.claude/`, `~/.gemini/`, `~/.codex/`, `~/.cursor/` — which `install.sh` wires to point here. Run `claude`, `gemini`, `codex`, etc. from any project directory.

**How do I update external skill packs?**
```bash
cd ~/ai-main
git submodule update --remote --recursive        # updates 9arm-skills + agent-skills
./install.sh                                     # picks up any new skill folders
```

**Why not use `npx skills add ...` instead of submodules?**
`npx skills` (vercel-labs/skills) is a great installer but resolves at install time only — no version pinning, no offline reproducibility, and `npx skills init` only creates a `SKILL.md` template (it does not fetch skills). Submodules pin a specific commit so every machine ends up with the same set. If you prefer the CLI, you can still run `npx skills add vercel-labs/agent-skills -g --all` standalone — it won't conflict with this setup.

**How do I roll back?**
Each install creates `~/.ai-backup-<timestamp>/`. Move files back out of there manually.
