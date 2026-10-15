# AI-Main: OMP-first configuration

OMP is the primary harness, with an optional Codex adapter and Orca integration workflows. This repository owns concise instructions, a curated startup skill catalog, repo knowledge, and explicit backups; legacy harness integrations remain available only through opt-in deployment.

---

## 🌟 Key Features

1. **Safety sources, harness-specific loading** — `config/style.md` and `config/workflow.md` remain canonical. OMP loads the full workflow with compact style/memory and `config/omp.md`; optional Codex receives the lean shared baseline.
1b. **Per-repo knowledge, any folder** — `knowledge/<repo>.md` deploys to each registered workspace root as `AGENTS.md` (+ `CLAUDE.md`/`GEMINI.md` symlinks), so every tool loads repo-specific facts only inside that repo. Attach any folder with `./bin/aimain link <path>` — repo or not, in the registry or ad-hoc. Knowledge is picked from `--knowledge`, else the git remote name (so a `.claude-worktrees/` worktree resolves to its real repo), else the folder name, else `knowledge/_generic.md`. Generated root files and Cursor's managed `.cursor/rules/ai-main-shared.mdc` are excluded in the target's `.git/info/exclude`. Deployment preserves tracked/handwritten files and foreign or dangling symlinks in both normal and sync mode; nested repo-owned instructions are untouched.
1c. **Curated memory in Obsidian** — `~/Tualek/AI Memory/Home.md` is the shared entry point for long-term preferences, corrections, and cross-project decisions. Repo docs retain code contracts; `memory/` retains promoted rules and tool-specific histories, not a second curated journal.
1d. **Self-learning** — authorized captures go to the vault's `AI Inbox`, then through evidence review and curation. Executable shared rules stay in `RULES.md` and `config/workflow.md`; a memory note does not automatically become policy.
Memory recall is triggered by prior-work questions, remembered preferences/decisions, or task continuation: read the vault index first, then only relevant notes. Users do not need to name the memory system; unrelated new tasks do not require loading the whole vault. Recall does not authorize memory writes.
1e. **Local sync without Git writes** — `scripts/sync.sh` pulls only from a clean tree, never autostashes, and redeploys OMP. It never commits or pushes; existing startup/scheduled hooks therefore cannot redeploy legacy harnesses through the default path.
1f. **Central worklog** — the `worklog` skill / `/worklog` command appends one-line entries to `logs/YYYY-MM.md`, synced across machines.
2. **Git-Portable Design** — Templates use `{{HOME}}` placeholders that the installer rewrites to the active user's `$HOME`. No hard-coded paths in version control.
3. **Curated OMP skills** — `config/omp-skills.json` selects automatic skills. Other discovered skills remain manual `/skill:name` commands through generated pointers; canonical files are not changed.
4. **External Skill Packs** — Curated/verified third-party skill repos are pulled in as git submodules under `external/`, version-pinned by commit (currently [thananon/9arm-skills](https://github.com/thananon/9arm-skills) and [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)).
5. **OMP-first deployment** — `./install.sh` deploys only OMP; `--codex` adds Codex. Default deployment does not install dependencies, update submodules, mutate work repos, or reconfigure legacy harnesses.
6. **Legacy integrations preserved** — `./install.sh --legacy` explicitly selects the previous all-harness path; existing tool homes and historical data are not deleted by OMP deployment.
7. **Ownership-safe updates** — Deployment preserves unmanaged entries and unrelated runtime settings.

## Dedicated review and verification terminals

Requested code review/validation in Orca uses fresh role terminals in the current workspace: `omp-review` (Sol high) and `omp-verify` (GLM high), with the main OMP session remaining source owner. `omp-orca-role` supplies bounded handoff, source snapshots, authoritative completion, report collection, retention and native release receipts. Normal installation adds owned launcher links to `~/.local/bin`; it does not change the main OMP's model or approval settings.

Role work already authorized by the user runs without local approval popups. Approved read/Git/Orca operations and exact verifier `--check` commands are allowed; other Bash is denied, and explicit user denies remain in force. These are role/tool policies, not an OS sandbox. See [role usage and observed smoke evidence](docs/omp-orca-roles.md).

---

## 🎚️ Prompt profiles (any model, not just the frontier ones)

The rule sources under `config/` and `memory/` carry tier markers. A line tagged `<!--min-->`
ships in every profile, `<!--lean-->` in lean and full, and an untagged line only in full.
`./bin/aimain build` compiles the shared tiers and the OMP profile into `build/` (gitignored), and builds the OMP skill farm. `aimain build --legacy` selects the Pi skill farm instead; neither command deploys to tool homes.

| Profile | Ceiling | For | Built from |
| --- | --- | --- | --- |
| `full` | 4,000 tok | Full-context harness profile | shared safety + methods + optional background |
| `lean` | 1,800 tok | Optional Codex and compact legacy profiles | same safety + concise working methods |
| `min` | 1,200 tok | Minimal-context profiles | same safety, scope, approval, and completion gates |
| `omp` | 3,000 tok | Primary OMP runtime | full workflow + compact style/memory + `config/omp.md`, without the global workspace inventory |

Ceilings are estimates, not targets or model capability claims. The min/lean ceilings retain the added folder-scope and permission gates rather than dropping safety for a smaller model.

OMP profile overruns fail the build before deployment. The legacy shared-tier compiler still warns on overruns; `scripts/verify.sh` enforces their ceilings. Static checks do not prove live model compliance.

On the checked machine, `omp toks` measured the former full shared profile at 2,781 `o200k_base` tokens. The initial lean OMP profile was 1,614; full workflow plus Checklist/OKR pointer was 2,074, and dedicated-role routing brings the current body to 2,133 (648 fewer than the former full profile, about 23%). These are shared instruction bodies only, not OMP's entire prompt or billed usage after caching. The catalog now has 17 automatic skills and 80 manual skills; start a new main OMP session after deployment.

The user's [Working Checklist and OKRs](docs/working-checklist-okr.md) preserves task breakdown/Senior alignment, data flow/edge cases, test/debug-aware estimation, intentional AI coding, scope control, Skill Matrix feedback, and Estimate vs Actual. `config/omp.md` routes planning, estimation, alignment, and retrospective to this document. The on-time delivery target is greater than 80%; no baseline or measured achievement is claimed.

### OMP managed-skill backups

```bash
python3 scripts/backup-omp-managed-skills.py --note "before a skill change"
python3 scripts/backup-omp-managed-skills.py --verify
python3 scripts/backup-omp-managed-skills.py --list
```

Snapshots live under `state/omp-managed-skills/<content-digest>/`, with original file paths under `files/` and an integrity manifest. They are immutable and deduplicated; changed runtime content creates another snapshot, never overwrites an old one. The script never writes runtime files, invokes Git, or adds backups to skill discovery. Commit snapshots only with explicit authorization; restoration is a separate manual, explicitly approved action. The initial cutover snapshot contains all five current managed skills.

## 🔌 Adapters — adding a tool without editing shell

`adapters/*.json` describe preserved legacy targets. They are not invoked by normal OMP-first deployment; explicit legacy commands retain their ownership checks.
See `adapters/README.md` for ownership, scoped loading, and owned upstream overrides.

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

`memory/lessons/COVERAGE.md` preserves the earlier promotion map. The six legacy journal
entries now live in Obsidian's `AI Memory/Lessons.md`; `memory/lessons/LESSONS.md` points there.

## 🧪 Prompt and memory regression suite

```bash
bash eval/run.sh  # profile/skill assertions, Pi memory behavior, isolated deployment fixtures; no model calls
```

Asserts profile safety rules, Pi memory bounds and mutation behavior, deployment protections, and git-guard coverage. Live harness/model compliance is a separate check using `scripts/canary-prompts.md`.

## 🧠 Shared brain in a multi-repo workspace

The shared core governs safety and approvals; workspace roots route to repos; repo and nested-folder instructions specialize their own paths. Starting at `ohochat` does not authorize scanning every child repo. Follow applicable ancestor/nested instructions without loading unrelated Markdown or recursively traversing references.

See [the adjustment summary](docs/history/shared-brain-adjustment-summary.md) and [the adapter contract](adapters/README.md). `AGENTS.md` documents ai-main's own source ownership and local validation. Installer/sync deployment is separate from editing these sources and needs an explicitly scoped rollout.

### Task sessions and document placement

Start or resume from the issue, repo/worktree, branch/HEAD, approved scope, expected behavior, and acceptance checks. The agent discovers available state; a task switch rechecks that anchor. Keep one writing owner per checkout, and distinguish implementation, review, QA, and release evidence.

`config/workflow.md` defines placement for requested files; read-only analysis stays in chat unless a report file is requested. Branch-local specs/plans and working artifacts follow the repo's `.scratch/<work-item>/` convention; durable system/code docs stay in `docs/`; historical reports use the indexed domain location, normally `docs/reports/<domain>/`. Shared `.ai` contains cross-worktree decisions and revision-specific handoff pointers. Root harness entrypoints and canonical indexes remain; root reports require an explicit request. Preserve active legacy plans until their owner confirms migration, and update references when moving historical snapshots.

Named ClickUp/Orca trackers own task status. A handoff records the candidate revision, role/environment, actual checks, artifact paths, blockers, and next action; it is not a second task queue. Evidence from an older HEAD does not establish readiness for the current candidate.

### Shared `.ai` context in Orca worktrees

`./bin/aimain context link <worktree>` links `<worktree>/.ai` to
`ai-main/context/<knowledge-name>/`. It uses the registered knowledge name,
then the git remote or repo name; use `--knowledge <name>` if detection is
ambiguous. The name must already exist under `knowledge/`. First use creates
`README.md`, `decisions/`, and `handoffs/` in that repo's central context.
Store only durable cross-worktree decisions and per-change QA handoffs there;
feature specs and current code behavior stay in the owning repo. Before QA,
run a task-specific smoke of the changed behavior in the candidate worktree,
then record the revision, environment, observed result, and safe artifact
location in `.ai/handoffs/<work-item>.md`. A command that merely starts, a
test-only pass, or a synthetic fixture does not establish release readiness.
All worktrees for the same repo see edits immediately, so keep branch-local
scratch and credentials out of `.ai`. `context/` is ordinary git content, unlike
the automatic `memory/`/`logs/` sync; publishing needs an authorized commit.

For each repo in Orca, set **Settings → Repository → Auto-run commands on
worktree create** to:

```sh
"$HOME/ai-main/bin/aimain" context link "$PWD"
```

Use the absolute `ai-main` path for the machine running Orca; `$PWD` must be
the newly created worktree root. Orca's `--setup skip` bypasses setup hooks.
Run the same command once in the primary checkout and in existing worktrees
that need the link. This command does not register worktrees, overwrite an
existing `.ai`, or replace repository-owned instruction files. Orca's
**Worktree Shared Paths** can APFS-clone rather than symlink on macOS; the
setup command is required when a symlink specifically is desired.

### CodeGraph in Orca worktrees

Share `.ai` for documents, but keep `.codegraph/` local to each checkout: different branches need different indexes. Use indexing for code-flow, callers, impact, or broad refactor work; skip it for small edits, docs, or short-lived worktrees. Do not add `.codegraph` to Orca shared/symlink paths.

```bash
codegraph init --yes /absolute/worktree    # first index; parses this checkout
codegraph status --json /absolute/worktree
codegraph sync /absolute/worktree          # pre-flight freshness for CLI-only use
```

The installed CodeGraph guide ties automatic watching to an active MCP session; `init` alone does not establish that OMP has a watcher. Keep native search/LSP available when no index exists. An isolated two-checkout smoke with shared `.ai` links returned only `alphaBranch` from the first index and only `betaBranch` from the second; no live Orca worktree was indexed or reconfigured.

## 🥧 Pi Persistent Memory

`memory/pi/MEMORY.md` stores up to 700 characters of durable Pi context. The
curated `pi` launcher's startup sync compiles it into
`~/.pi/agent/APPEND_SYSTEM.md`. Each successful CLI mutation atomically refreshes
only the marked memory block there. This is legacy Pi integration, separate from OMP's native memory and entry file.

Keep this separate from `config/profile.md`, shared rules, and
`knowledge/<repo>.md`. Delegated Pi agents read the same notes, but only the
parent session writes them. Sync never commits or pushes; keep credentials and sensitive personal data out of snapshots and keep ai-main private.

## 🛠️ Quick Installation (New Device)

```bash
git clone --recurse-submodules <your-fork-of-ai-main> ~/ai-main
cd ~/ai-main
./install.sh
```

Initialize missing pinned packs explicitly with `git submodule update --init --recursive`. Default OMP deployment does not fetch or update them.

---

## 📂 Repository Structure

```
ai-main/
├── install.sh                    # idempotent installer + verifier
├── bin/aimain                    # CLI: link/unlink/list/deploy/doctor/build/adapters/hooks/shims
├── bin/pi-memory                 # bounded Pi persistent-memory CLI
├── adapters/                     # one JSON per extra tool (opencode, qwen, ...)
├── build/                        # GENERATED prompt profiles and OMP/Pi skill farms — gitignored
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
│   ├── PI.md.template            # → ~/.pi/agent/APPEND_SYSTEM.md (lean entry)
│   ├── pi-skills.json            # Pi model-visible allowlist + total context budget
│   ├── mcp.json.template         # → ~/.config/mcp/mcp.json (shared MCP base)
│   ├── RTK.md                    # → ~/.claude/RTK.md      (hook-aware variant)
│   ├── RTK.manual.md             # → ~/.codex/RTK.md, ~/.gemini/RTK.md (manual prefix)
│   ├── style.md                  # ⇄ symlinked into each tool's shared/  — response style
│   ├── workflow.md               # ⇄ symlinked into each tool's shared/  — working rules
│   └── profile.md                # ⇄ symlinked into each tool's shared/  — user profile + tech stack
├── knowledge/                    # per-repo knowledge → deployed to each workspace root
│   ├── _ohochat-shared.md        # OHO domain vocab, imported by every oho-* file
│   └── <repo>.md                 # one per primary workspace (filename = dir basename)
├── memory/                       # version-controlled context; commits remain explicit
│   ├── SHARED.md                 # distilled cross-tool facts — compiled into every entry file
│   ├── lessons/LESSONS.md        # pointer to the canonical Obsidian correction journal
│   ├── claude/<project-slug>/    # ⇄ ~/.claude/projects/<slug>/memory
│   ├── codex/                    # ⇄ ~/.codex/memories
│   └── pi/MEMORY.md              # Pi-only durable context (loaded each session)
├── logs/                         # central worklog, YYYY-MM.md; commits remain explicit
├── bin/
│   └── pi-launcher               # `pi` curated launcher + `pi-raw` escape hatch
├── scripts/
│   ├── sync.sh                   # clean-tree pull + OMP redeploy; no commit/push
│   ├── build-pi-skills.py        # builds model-visible + manual Pi skill farm
│   ├── pi-context-budget.py      # enforces Pi's 4,000-token ai-main budget
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

OMP loads `build/omp-skills/`: names in `config/omp-skills.json` expose descriptions for automatic invocation; the remaining discovered skills are manual pointers available through `/skill:name`. Native OMP managed skills remain runtime-owned and independently discovered. The cross-harness links and Pi catalog described below belong to explicit legacy deployment.

### Owned (this repo, `skills/`)

| Skill | Purpose |
| --- | --- |
| `gitlab-mr-description` | Draft / improve / standardize GitLab MR descriptions from `glab` data. Triggered by a GitLab MR URL or an MR-description request. |
| `gitlab-mr-comment-reply` | Draft concise Thai/English replies to GitLab MR review comments, anchored to actual code, with reply category (accept / push-back / explain / defer). |
| `git-commit-helper` | Inspect local diff, decide commit grouping, pick conventional prefix, write subject + body. Ported from Codex. |
| `branch-perf-compare` | Standardize RAM/startup/bundle comparisons across git branches (e.g. `uat` vs `nuxt3` vs `perf/*`) and produce a paste-ready perf report. |
| `self-learning` | Route authorized correction captures through the Obsidian memory workflow; propose unrequested writes in chat. |
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

### From [`mattpocock/skills`](https://github.com/mattpocock/skills) — `external/mattpocock-skills/` (Matt Pocock's skills)

| Skill | Purpose |
| --- | --- |
| `code-review` | Two-axis review of a diff against repo standards and original spec using parallel sub-agents. |
| `tdd` | Test-driven development discipline: Red-Green-Refactor loop with minimal viable tests. |
| `to-spec` | Grounding and generating technical specifications from requirements and codebase context. |
| `to-tickets` | Break down specs into small, vertical, tracer-bullet tickets. |
| `diagnosing-bugs` | Systematic bug diagnosis flow before jumping into fixes. |
| `improve-codebase-architecture` | Architecture refactoring guidelines and domain modeling workflows. |
| `implement` | Focused implementation workflows following specifications. |
| `prototype` | Rapid prototyping workflows with clear guardrails. |
| `resolving-merge-conflicts` | Guided resolution of git merge conflicts preserving intent. |
| `wayfinder` | Codebase navigation and discovery helper. |

> Skills under `deprecated/`, `in-progress/`, `personal/`, or `node_modules/` in any external pack are automatically excluded by `install.sh`.

---

## What `install.sh --legacy` does

| Step | Action |
| --- | --- |
| 1 | Detect `$HOME` and resolve paths |
| 2 | Bootstrap `rtk` and `glab` via Homebrew if missing |
| 3 | `git submodule update --init --recursive --remote` |
| 4 | Back up existing configs to `~/.ai-backup-<ts>/` |
| 5 | Symlink `~/.ai-skills → skills/` |
| 6 | Generate Claude, Gemini, Codex, and Pi entry files from templates |
| 7 | Copy RTK rules (`RTK.md` for Claude, `RTK.manual.md` for Codex, Gemini, and Pi) |
| 7b | Link the full profile to Claude/Codex/Gemini and the lean profile to Pi |
| 8 | Redirect-link `gitlab-mr-description` for Claude & Gemini |
| 9 | Direct-symlink `gitlab-mr-description` for Cursor & Codex |
| 9b | **Direct-symlink every other owned skill** in `ai-main/skills/*` into all four tools |
| 10 | Symlink owned skills and Pi memory CLI; build Pi's curated/manual skill farm and direct launchers |
| 10b | Deploy `config/mcp.json.template` to the shared MCP base at `~/.config/mcp/mcp.json` |
| 11 | Symlink files from `commands/` into `~/.claude/commands/` & `~/.cursor/commands/` |
| 12 | Link canonical memory (`~/.ai-memory → memory/`, `~/.codex/memories → memory/codex/`, Claude project memories, and Pi's `memory/pi/MEMORY.md`) |
| 13 | Deploy per-repo knowledge: compile `knowledge/<repo>.md` → `<workspace>/AGENTS.md` + `CLAUDE.md`/`GEMINI.md` symlinks (preserves tracked and unmanaged files, including foreign/dangling symlinks) |
| 14 | Preserve user/global ignores; generated workspace files use local Git excludes |
| 15 | Wire historical startup/scheduled hooks; `scripts/sync.sh` now performs OMP-only local deployment without committing or pushing |
| 16 | Verify every link resolves |

`./install.sh --sync` uses the OMP-first path. `./install.sh --legacy --sync` explicitly uses the historical fast redeploy path without one-time setup steps.

---

## 🔄 Sync & New Device

```bash
# any machine, any account:
git clone --recurse-submodules git@github.com:tourlek/ai-main.git ~/ai-main
cd ~/ai-main && ./install.sh
```

That deploys OMP's entry, settings, and curated skill catalog. Add `--codex` for the optional Codex adapter; project instructions, historical memory formats, and legacy homes are not rewritten by the default installer.

Existing startup/scheduled hooks can still call `scripts/sync.sh`, but the script now redeploys only OMP and never commits or pushes. A dirty `ai-main` worktree skips pull without stashing and continues from local state. Default installation does not create or restart hooks; run `./scripts/sync.sh` manually when needed.

⚠️ `memory/` contains personal data — this repo must stay **private**.

---

## ➕ Adding Your Own Items

### A new shared skill

```bash
mkdir -p skills/<my-skill>
$EDITOR skills/<my-skill>/SKILL.md        # YAML frontmatter: name, description
./install.sh
```

New skills are manual-only by default. Add a name to `config/omp-skills.json` only when OMP should expose its description automatically, then rebuild/deploy. Use `/skill:<name>` for the remaining catalog.

### A new shared rule file

```bash
$EDITOR config/<my-rule>.md
```

Edit the existing canonical safety/style sources for shared rules or `config/omp.md` for OMP runtime details. Extend the profile compiler only when a separate source has a real loading boundary.

### A new slash command

```bash
$EDITOR commands/<my-command>.md
./install.sh --legacy
```

This is legacy Claude/Cursor command deployment. For OMP, use a skill's `/skill:<name>` entry; format details for the historical command files are in `commands/README.md`.

### A new external skill pack

```bash
git submodule add <repo-url> external/<pack-name>
```

Add its pinned source root to `scripts/build-omp-skills.py` discovery; keep new names manual until explicitly added to the startup allowlist.

---

## ✅ Verifying the Setup

Two layers — run both whenever you suspect a tool isn't picking up the global config.

**Layer 1: Local checks (no model calls)**

```bash
bash eval/run.sh
bash -n install.sh scripts/sync.sh bin/aimain
```

The isolated fixtures exercise ownership and deployment behavior; the profile build checks startup budgets. `scripts/verify.sh` remains the historical all-harness installation audit and is not proof that a new OMP-only machine needs every legacy home.

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
No. Start `omp` from the target checkout; optional Codex loads its own deployed entry. A fresh session is required after global prompt/catalog changes.

**How do I update external skill packs?**
```bash
cd ~/ai-main
git submodule update --remote --recursive        # updates 9arm-skills + agent-skills
./install.sh                                     # picks up any new skill folders
```

**Why not use `npx skills add ...` instead of submodules?**
`npx skills` (vercel-labs/skills) is a great installer but resolves at install time only — no version pinning, no offline reproducibility, and `npx skills init` only creates a `SKILL.md` template (it does not fetch skills). Submodules pin a specific commit so every machine ends up with the same set. If you prefer the CLI, you can still run `npx skills add vercel-labs/agent-skills -g --all` standalone — it won't conflict with this setup.

**How do I roll back?**
Legacy installation has historical `~/.ai-backup-<timestamp>/` backups. OMP-first deployment preserves unmanaged files; restore only the entry/config changes you own, then start a fresh session. Restoring managed-skill snapshots is a separate explicit action, never an automatic sync.
