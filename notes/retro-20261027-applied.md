# Retro 2026-10-27 (Gemini argon) — applied 2026-10-28 (UTC+7)

Source: `notes/retro-20261027-gemini.md` (sections G, H, F). Edits made by a headless pi (DeepSeek) run from a fixed brief, then checked by hand: `git diff`, `bin/aimain build` OK, key-pattern grep on added lines clean (gitleaks not installed). Not committed; the sync job will commit.
Backups: `.scratch/backup-20261028-retro/` (git-ignored).

| # | Item | Status | Evidence / path |
|---|---|---|---|
| 1 | G.1 Reviewer spawned by the plan thread (native `Agent` reviewer) instead of a pi `delegate_task` | needs-decision | Reverses the v4 design from 2026-10-27 22:49 (review nested under impl thread). `SKILL.md` Hard rules + 3e left unchanged |
| 2 | G.1 Post-review user fix: dispatch + delta re-review, or `ready-with-unreviewed-user-fix`; orchestrator never Edit/Write | done-now | `skills/clickup-card/SKILL.md` Hard rules |
| 3 | G.1 T3 worktree GC warning, never delete `impl_thread`, mirror `.scratch/<CARD>/` every round | done-now | `SKILL.md` §2 (after `git worktree add`) |
| 4 | G.1 Native-addon prebuild check for Node/base-image upgrades | done-now | `SKILL.md` §2 brief bullet |
| 5 | G.1 Resume after `Connection error` with one `t3_thread_send` | done-now | `SKILL.md` 3d |
| 6 | G.1 3e: mirror scratch before checks | done-now | `SKILL.md` 3e first clause |
| 7 | F.3.3 `rounds.md` required | done-before | `SKILL.md` 3b/3c already require `rounds.md` (impl_thread, rN lines) |
| 8 | Lessons OHO-8915 (pipefail, baseline, curl retry, Cloud Build misclaim) | done-before | `SKILL.md` "Lessons from OHO-8915 r2/r3" |
| 9 | G.2 Replace Orca routing line with T3 worktree routing + ps check | done-now | `config/workflow.md:51` |
| 10 | G.2 Chain scripts: parse quota reset time, pidfile lock | done-now | `config/workflow.md:61` |
| 11 | G.3 Three lessons (doc section delete, jsonl timestamp/fork dedupe, kill chain before handoff) | done-now | `memory/lessons/RULES.md:22-24` |
| 12 | G.4 Patch `p0-chain-v2.sh` (lock, REVIEW_ALLOW, reset parser) | skipped | Lives in the React work worktree; the chain is retired (React runs in T3 thread b1edee08). Rule captured in workflow.md instead |
| 13 | H.1 Kill zombie `cursor-agent` 74570/35947, `claude rc` 27132; no `p0-chain` | done-before | `ps` 2026-10-28 01:3x: those PIDs gone, no `p0-chain` process |
| 14 | H.2 Push OHO-8915 branch / open MR | skipped | Work repo; user action |
| 15 | H.3 = items 1-6 | see above | |
| 16 | H.4 Run `scripts/sync.sh` after edits | done-before (scheduled) | launchd `com.tualek.ai-main-sync` every 6 h; `bin/aimain build` run now = OK |
| 17 | H.5 Turn off unused Claude Desktop MCP extensions / prefer T3 for short questions | needs-decision | App settings on the user's account |
| 18 | E/C stats corrections (old sessions miscounted in `retro-20261027.md`) | skipped | Report only; lesson captured in item 11 |
| 19 | Old Orca mentions in `docs/workspaces.md`, `docs/architecture.md`, `context/*`, `adapters/omp` | needs-decision | Historical docs/adapters; rewrite or archive is a separate cleanup |
| 20 | `RULES.md` over its ~2 KB cap (now ~4.9 KB) | needs-decision | Compact or move hits≥3 rules into `core/checks/` |

## Decisions applied 2026-10-28 (retro2, via cursor-agent; verified)
- (1) Reviewer spawn reversed: plan thread (claude-team) spawns its own Opus reviewer (effort medium max), independent of implementer. Files: skills/clickup-card/SKILL.md, config/workflow.md.
- (3) Orca/OMP archived to archive/2026-10-orca-omp/ (adapters/omp/ 17 files, state/omp-managed-skills/ 6 files; sections from ~25 docs/context/skills files with pointer lines). Code refs removed from bin/aimain, install.sh, scripts/verify.sh, core/hooks/guard.sh, eval. Remaining: memory/claude/.../feedback_worktree_base_master.md:11 (left as-is).
- (4) RULES.md lossless: 4937 -> 2045 bytes, 18 -> 18 rules (+C0 pointer). Full: archive/rules/RULES-full-20261028.md; mapping .scratch/rules-mapping.md.
- Checks: bin/aimain build exit 0 (warn: full profile ~4136 tok > 4000), test-guard 103/103, verify.sh/eval exit 0.
- (2) Claude Code (T3) MCP/plugins, read-only, usage = tool calls in last 14d transcripts: plugins in both ~/.claude and ~/.claude-team: caveman, cloudflare, codex, context7, frontend-design, hyperframes, playwright (6 calls), session-report, ponytail, mattpocock-skills; ~/.claude.json mcpServers: codegraph, open-design. Used: ClickUp connector, playwright, dsh. No calls seen: cloudflare, codex, context7, hyperframes, session-report, codegraph, open-design -> candidates to disable. Nothing changed.
- Backup: .scratch/backup-20261028-retro2/. Not committed.
