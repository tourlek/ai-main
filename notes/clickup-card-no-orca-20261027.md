# clickup-card: Orca removed, pi+DeepSeek executor in T3 (2026-10-27)

## Changed
- `skills/clickup-card/{SKILL.md,templates.md,compact-hook.sh}` rewritten (merge of the Orca-era deployed skill and the DSH-era ai-main source).
- `docs/skills.md` row 13 reworded.
- `~/.claude/skills/clickup-card` was a stale real dir; now a symlink to `~/ai-main/skills/clickup-card` (what install.sh adopt_link does). `~/.agents/skills` and `~/.hermes/skills-aimain` already pointed there, so they see the new version. `~/.claude-team/skills` -> `~/.claude/skills`, so Claude Team sees it too. settings.json hook path unchanged.

## Decisions implemented
- No Orca (one-line "retired" note only). Worktree = `git worktree add --no-track -b <branch> ~/.t3/worktrees/<repo>/<branch-slug> origin/master`.
- Orchestrator/planning/review = Claude Team, effort medium. Planning Agent and reviewer = opus medium. Reviewer = Claude `reviewer` agent; fallback agy `claude-opus-5-5-medium` only if Claude quota/error. Opus-high only on request.
- Executor = pi, provider deepseek, `deepseek-flash` default (`deepseek-v4-pro` for hard rounds), one fresh run per round, previous done.md moved to done-r<N-1>.md, round id in `.scratch/<CARD>/rounds.md`.
- DSH-only parts dropped (cc-review/cc-explore, DSH MCP mappings, "one DSH session per worktree"). Kept from DSH: lessons-proposed.md, session-hours.py in eod, anchored hook regex, review.md tags.

## T3 visibility (evidence)
- T3 `AgentSessionScanner` (`/tmp/t3asar-chk/apps/server/dist/binCli-tZsVKo_d.mjs`) imports only claudeAgent (`<homePath>/projects/*/*.jsonl`, per enabled instance incl. claude-team) and codex. pi is not scanned. A headless `pi -p` session (`~/.pi/agent/sessions/...`) never appears in T3.
- Tested: `t3 thread start ~/ai-main "..." --provider pi --model deepseek/deepseek-flash --wait --json` -> thread `mcp:94d197d3-d66f-47ab-abf7-fc7547614e29` completed, reply ok-t3; in `orchestration_v2_projection_threads` (provider_instance_id=pi, project ai-main) and in `t3 thread list`; pi session file `~/.pi/agent/sessions/--Users-tualek-ai-main--/2026-10-27T10-34-51-699Z_01a17ced-....jsonl`. Test thread title "TEST clickup-card T3 visibility (safe to delete)".
- Not tested: MCP `t3_thread_launch` with `existing_worktree` (needs a T3 orchestrator thread); documented from the tool schema.

## Backups / revert
- `~/.claude/backup-20261027-clickup-card/clickup-card/` (deployed Orca-era), `.../clickup-card-replaced-by-symlink/` (the moved original dir).
- `~/ai-main/.scratch/backup-20261027-clickup-card/clickup-card/` (DSH-era source) and `skills.md.orig`.
- Revert: `rm ~/.claude/skills/clickup-card && mv ~/.claude/backup-20261027-clickup-card/clickup-card-replaced-by-symlink ~/.claude/skills/clickup-card`; `cp -p ~/ai-main/.scratch/backup-20261027-clickup-card/clickup-card/* ~/ai-main/skills/clickup-card/`; `cp -p ~/ai-main/.scratch/backup-20261027-clickup-card/skills.md.orig ~/ai-main/docs/skills.md`. (To keep Orca-era in ~/.claude only, copy the first backup in place of the symlink instead.)
- Nothing committed.
