thread_id: 019fc64c-3291-73a0-9abc-8400c6838b3d
updated_at: 2026-08-03T06:38:46+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/03/rollout-2026-08-03T13-25-10-019fc64c-3291-73a0-9abc-8400c6838b3d.jsonl
cwd: /Users/tualek/Documents/Codex/2026-08-03/r

# Verified Cursor ai-main integration and removed a conflicting home-level rule

Rollout context: The user asked in Thai whether Cursor still used the rules and symlinks configured by ai-main, then asked to fix the conflicting rule source.

## Task 1: Audit Cursor rules and symlinks

Outcome: success

Key steps:
- Inspected `/Users/tualek/.cursor` and `/Users/tualek/ai-main/install.sh`.
- Verified 22 symlinks under `~/.cursor/skills/`, including `gitlab-mr-description`, `branch-perf-compare`, `debug-mantra`, and others; no broken links were found.
- Verified `~/.cursor/commands/worklog.md -> /Users/tualek/ai-main/commands/worklog.md`.
- Confirmed Cursor 3.14.7 runtime state included ai-main skills and workspace rules.
- Confirmed Cursor had no `~/.cursor/rules/` directory, but loaded workspace-level `AGENTS.md`/`CLAUDE.md` rules.
- `ai-main/bin/aimain list` reported all 11 registered workspaces as `ok`.

Reusable knowledge:
- ai-main deploys repo-specific compiled `AGENTS.md` files, with `CLAUDE.md` and `GEMINI.md` symlinking to them. Cursor loads these as `always_applied_workspace_rule` entries.
- ai-main’s installer links owned skills into `~/.cursor/skills/` and shared commands into `~/.cursor/commands/`.
- Cursor’s available runtime state provided stronger evidence of actual rule/skill loading than filesystem inspection alone.

Failures and how to do differently:
- `rtk find` does not support compound predicates/actions; use native `find` for symlink and file predicates.
- `cursor agent --help` could not run because `cursor-agent` was absent and installation failed due to unavailable network. Runtime state/log inspection was used instead.

## Task 2: Remove conflicting `/Users/tualek/AGENTS.md`

Outcome: success

Preference signals:
- The user said “จัดการให้หน่อย” after being told a stale home-level rule conflicted with ai-main -> future fixes should act on the conflicting artifact while preserving a recoverable backup and avoiding unrelated repo changes.

Key steps:
- Detected `/Users/tualek/AGENTS.md` as an old generic rule source containing potentially conflicting assumptions such as Vue 3, strict TypeScript, and npm usage.
- Preserved all unrelated dirty changes in `ai-main`; did not modify its installer or repository contents.
- Moved the stale file to `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`.
- Verified the original home-level file was absent, the backup existed, workspace `AGENTS.md`/`CLAUDE.md` remained intact, and all registered workspaces still reported `ok`.
- User was advised to open a new Cursor chat or reload the window because existing sessions may cache old rules.

References:
- `/Users/tualek/ai-main/install.sh`
- `/Users/tualek/ai-main/config/AGENTS.md.template`
- `/Users/tualek/ai-main/bin/aimain list`
- Backup: `/Users/tualek/Documents/Codex/2026-08-03/r/outputs/AGENTS.md.stale-home-backup-20260803`
