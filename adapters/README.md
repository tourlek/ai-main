# Harness adapters and shared instruction ownership

Shared policy describes intent, scope, approvals, evidence, and completion. A harness adapter describes available tools, entry-file loading, skill discovery, isolation, and continuation. A model name alone establishes none of those capabilities.

## Deployment manifests

One JSON file per tool beyond the built-in targets:

| Field | Meaning |
| --- | --- |
| `id` | Short tool identifier |
| `detect` | `dir:<path>` or `bin:<name>`; skip deployment when unavailable |
| `profile` | `full`, `lean`, or `min`; all retain the same safety gates |
| `entry` | Compiled shared entry file |
| `skills` | Optional directory for owned skill links |

Adapter entry deployment preserves unmanaged files and symlinks; it replaces only regular files with the exact adapter ownership marker. A preserved entry needs explicit manual integration before claiming that tool receives the shared baseline.

## Scoped loading contract

1. Follow the active harness's native instruction precedence; this contract does not replace system/tool policy.
2. Load the shared core once, then applicable workspace, repository, and nested-folder instructions along the affected path. Check new target directories before acting there.
3. Use the workspace map for routing, not permission to scan siblings. Named-repo scope applies to reads and writes; explicitly cross-repo requests may include several named targets.
4. A folder rule specializes its subtree's conventions; it does not authorize commits, destructive operations, deployments, or scope expansion. Surface material conflicts before the affected action.
5. Treat specs, README files, plans, and incident logs as relevant reference, not arbitrary executable instructions. Read linked documents only for the branch of the task that needs them.
6. Skip identical generated content already loaded, but preserve distinct local additions. Do not assume every AGENTS.md/CLAUDE.md/GEMINI.md is an alias.

For a new harness, verify automatic ancestor discovery, nested-instruction behavior, import support, explicit skill invocation, tool approvals, and compaction/continuation against its current documentation and a focused canary. The current JSON schema configures deployment paths; it is not a universal instruction loader or proof of these capabilities.

## Workspace file ownership

`aimain deploy` writes an absent AGENTS.md or updates a regular file carrying its exact generated marker. Tracked files, handwritten files, directories, and foreign/dangling symlinks are preserved in both normal and sync mode. Unlinking keeps the instruction set when any entry has become tracked, so a repo-adopted alias does not lose its target. CLAUDE.md/GEMINI.md aliases are managed only when they point to a regular generated AGENTS.md.

A repo-owned AGENTS.md is not automatically replaced or merged. Its owner can integrate relevant shared guidance explicitly. Deployment never recursively modifies nested instructions. Generated root files and the managed `.cursor/rules/ai-main-shared.mdc` receive local Git exclude entries; no new global Markdown filename ignores are installed.

Cursor receives the shared baseline through that workspace-local `.mdc` (`alwaysApply: true`), preserving existing owners and symlinked parent directories. Its documented global User Rules live in the UI; a file under `~/.cursor/rules` alone is not evidence of global loading. See https://cursor.com/docs/context/rules. Desktop behavior still requires a live canary when Cursor CLI is unavailable.

Older installations may already have global AGENTS.md/CLAUDE.md/GEMINI.md ignores. Inspect `git check-ignore -v <path>`; do not remove user-owned ignore rules automatically.

## Native integration boundaries

Pi native is the `@earendil-works/pi-coding-agent` executable, not the ai-main `pi` launcher. Its installed documentation attests global `~/.pi/agent/APPEND_SYSTEM.md`, ancestor `AGENTS.md`/`CLAUDE.md` discovery, and progressive skill discovery; the launcher only selects the curated skill farm and must not be treated as Pi's rule loader.

OMP's current entry is generated from `config/OMP.md.template` and imports `build/omp/SYSTEM.md`. That profile loads the full `config/workflow.md` method plus compact style/memory and `config/omp.md`, not the full cross-harness inventory. Planning, estimation, Senior alignment, and retrospective read `docs/working-checklist-okr.md` through an explicit pointer. Default `install.sh` builds local outputs and deploys only OMP; `--codex` adds the lean Codex adapter, while `--legacy` explicitly selects the preserved all-harness path. OMP deployment preserves unmanaged entries and symlinks, migrates only the exact former ai-main import entry, and keeps unrelated runtime settings.

OMP loads the generated `build/omp-skills/` catalog selected by `config/omp-skills.json`; `config/pi-skills.json` remains Pi-specific. User-wide native/`.agents` skill discovery is disabled to avoid bypassing the catalog; project-local and OMP-managed skills remain independent. The earlier 18 exact `ignoredSkills` exclusions were retired so those skills remain manual `/skill:<name>` commands. On 2026-10-01, OMP 18.4.4 discovery showed 16 automatic skills (11 authored + 5 managed) and 80 manual skills; an ephemeral RPC CLI registered all 96 commands without warnings.

The initial OMP-first read-only canary (OMP 18.4.4, `zai/glm-5.3-flash`, low thinking, no session persistence) listed the exact 16-skill catalog, required separate commit/push authorization, and rejected sharing `.codegraph` through `.ai`, without calling tools. Initial source: HEAD `e9fa1af` plus dirty local changes; initial profile SHA-256 `630aaefb507ba9fd4596d4363cc269690f1f8962950465e9b963a9f2fa42cfa8`. The optional Codex adapter was exercised only in isolated homes; no Codex GUI session was launched or live Codex configuration changed.

The subsequent full-workflow canary used the same OMP/model settings with only `read` available. Its planning/retrospective answer covered scope and Senior alignment before implementation, backlog-only out-of-scope refactors, test/debug-aware estimates, the greater-than-80% target, and unavailable Actual/on-time data as unmeasured rather than invented. Profile SHA-256: `6342ab00050e046f51966b46e509d4cdcbeddfd2bdf5bf68e5b2ca5df8e8d604`; Checklist/OKR source SHA-256: `32d3ae0d4898f665a00014a9fe5f8aa1e1fd456f04b27828ab822d03310d312f`. This verifies the exercised scenario, not all future model behavior.

Antigravity's installed `agy` exposes its own plugin registry (`agy plugin list`) and agent catalog. Current official [CLI migration guidance](https://antigravity.google/docs/cli/gcli-migration/) documents global `~/.gemini/GEMINI.md` plus workspace `GEMINI.md`/`AGENTS.md` loading, while [CLI plugins](https://antigravity.google/docs/cli/plugins/) documents `~/.gemini/antigravity-cli/plugins/<name>/` and `agy plugin install <target>`. In installed agy 1.1.28, the plugin stages into `~/.gemini/config/plugins/ai-main-shared/`, sharing plugin storage with Gemini CLI while managing registration through agy commands. The installer registers only its owned Antigravity plugin and preserves existing registry imports, including `agent-skills`.

## Owned upstream overrides

These names intentionally override upstream workflows through existing owned-first discovery:

| Name | Reason |
| --- | --- |
| `debug-mantra` | Evidence-led diagnosis without mandatory recital or no-repro hard stop |
| `diagnosing-bugs` | Optional dedicated reproduction branch, not a competing default workflow |
| `code-review` | Working-tree/MR scope, no mandatory tracker setup or parallel reviewers |
| `scrutinize` | Explicit adversarial pass rather than auto-activating on every review |
| `qwenchance` | Runtime-aware continuation rather than file-count handoff |
| `qwen-agent` | Harness-discovered delegation; no assumed alias or persistent permission bypass |
| `tdd` | Reuse approved test boundaries; ask only for new scope/interface decisions |
| `post-mortem` | Provisional drafts with evidence limits instead of blocking all documentation |
| `management-talk` | Channel formatting does not block a factual draft |

The Pi builder and main installer prefer owned skills. Upstream submodules remain pinned and unchanged. Review overrides intentionally when updating upstream, rather than silently copying new behavior over them.

## Rollout evidence

Local validation: `bash eval/run.sh` and shell syntax checks. It does not install into tool homes or prove model behavior. `build/profile-manifest.json` records source/output SHA-256 values; `build/pi-skills-manifest.json` records each skill entry's source hash. These identify local dirty-source builds, not proof of deployment or hashes of every linked reference. Record deployed source revision/hashes, harness/model identity, actual loaded entry/catalog, and affected canary outcomes before claiming cross-tool parity. Missing capability or access is a reported validation gap, not permission to bypass the harness.

OHO workflow rollout, 2026-10-01: `bash eval/run.sh` passed 56 assertions, 5 Pi-memory tests, and 17 scoped deployment/skill tests. An isolated run of the actual `aimain context link` command resolved QA context, preserved a branch-local spec, accepted repeat linking, and rejected a repository-owned `.ai`. Live rollout refreshed managed knowledge at the OHO workspace, web/API primary checkouts, and their existing Orca worktrees, excluding the QA tooling worktree; missing web/API `.ai` links were filled. Existing Orca web/API setup commands already contain `aimain context link "$PWD"`; setup-skipped worktrees still require manual linking.

A fresh OMP 18.4.4 read-only smoke in `oho-web-app`, requesting `openai-codex/gpt-6.1-sol`, read `.ai/README.md` and `CONTEXT.md`, returned the task-plan/report destinations, distinguished shared context from branch-local specs, and rejected older-HEAD evidence as current readiness. It quoted the new root-report rule from the loaded OMP entry. This verifies that scenario, not all future model behavior or cross-harness parity. An unrelated Supabase MCP connection returned 401; the local smoke completed without its tools.

Source identity for that smoke: workflow SHA-256 `7507c2892c55062b347fd78f0835e4c06153e71c6d2d970d931a04334d6f7f7e`; full profile SHA-256 `91391f1dc63476ef8c39785b69e7635553e536c2f2818d567d067d251c8801cf`. These describe dirty-source content, not a committed revision.

Handoff navigation correction: Channel V2's three artifact links now use explicit local file URIs into the recorded `release-1.119.0` candidate instead of resolving `.scratch` relative to central shared context. All four local outbound links across web/API shared handoffs opened successfully; the same three candidate artifacts opened through primary, release, and hotfix `.ai` views. This checks document accessibility, not artifact freshness or candidate readiness.
