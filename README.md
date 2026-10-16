# ai-main

A harness-neutral source of truth for shared AI policy, skills, per-repo knowledge and memory. Each tool (OMP, Codex, Claude, Gemini, Cursor, and JSON-described extras) is an **adapter** that turns this core into its own entry files, skill catalog and launchers. No harness is the default: you opt in per machine.

## What lives here

| Path | What it holds |
| --- | --- |
| `config/` | Shared rules (`profile.md`, `style.md`, `workflow.md`), workspace registry, harness selection example |
| `knowledge/` | Per-repo facts, deployed to each registered workspace root |
| `skills/` + `external/` | Owned skills and pinned third-party packs |
| `memory/`, `logs/` | Promoted rules, tool histories and the central worklog |
| `core/` | Git hooks, PATH shims and guards that replaced prompt rules |
| `adapters/` | Everything harness-specific: `omp/`, `codex/`, `claude/`, `gemini/`, JSON extras, shared `lib/` |
| `eval/`, `scripts/` | Regression suite, sync/verify scripts, canary prompts |
| `build/` | **Generated** profiles and skill farm (gitignored, never edit) |

## Quick start

```bash
git clone --recurse-submodules <your-fork-of-ai-main> ~/ai-main
cd ~/ai-main
./install.sh                          # builds local outputs only; writes nothing outside the repo
./install.sh --harness omp,codex      # deploy the harnesses you actually use
cp config/harnesses.local.example config/harnesses.local   # remember the choice for sync/verify
```

Harness ids: `omp`, `codex`, `extra` (opencode/qwen/zcode), `legacy` (Claude/Gemini/Cursor all-harness installer). See [docs/deploy.md](docs/deploy.md).

## Daily commands

```bash
./bin/aimain build                    # compile build/full and the skill farm; deploys nothing
./bin/aimain link <path>              # attach a folder to its knowledge file (also: deploy, doctor, list)
./scripts/sync.sh                     # clean-tree pull, rebuild, redeploy config/harnesses.local; no commit/push
./scripts/verify.sh                   # audit installed files for the selected harnesses
bash eval/run.sh                      # local regression suite; no model calls
```

## Ground rules

- Edit shared policy in `config/`, repo facts in `knowledge/`, task workflows in `skills/`, harness specifics in `adapters/<id>/`; never edit `build/` or `external/` directly. `AGENTS.md` has the full ownership and validation rules.
- Deploy scripts write outside this repo and need an explicit scope; commits and pushes need explicit authorization.
- `memory/` contains personal data, so keep this repo **private**.

## Documentation

| Doc | Topic |
| --- | --- |
| [docs/architecture.md](docs/architecture.md) | Principles and repository structure |
| [docs/deploy.md](docs/deploy.md) | Harness selection, what each deploy writes, rollback |
| [docs/profiles.md](docs/profiles.md) | The shared prompt profile and its token ceiling |
| [docs/workspaces.md](docs/workspaces.md) | Multi-repo shared brain, `.ai` context, CodeGraph |
| [docs/skills.md](docs/skills.md) | Owned and external skill catalog |
| [docs/memory.md](docs/memory.md) | Memory, self-learning, local sync |
| [docs/checks.md](docs/checks.md) | Checks that replaced prompt rules |
| [docs/validation.md](docs/validation.md) | Regression suite, verification layers, canaries |
| [docs/adding.md](docs/adding.md) | Adding skills, rules, commands, packs |
| [docs/faq.md](docs/faq.md) | FAQ |
| [adapters/README.md](adapters/README.md) | Adapter contract, scoped loading, workspace ownership |
| [adapters/omp/README.md](adapters/omp/README.md) | OMP adapter, review/verify terminals, skill backups |
| [docs/working-checklist-okr.md](docs/working-checklist-okr.md) | Working checklist and OKRs |
