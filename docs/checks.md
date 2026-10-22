# Checks instead of prompt rules

Rules a model can forget were moved out of the prompt and into places a model cannot skip:

| Check | Where it runs | Replaces |
| --- | --- | --- |
| `core/checks/commit-msg-lint.sh` | git `commit-msg` | "no Co-Authored-By / AI attribution" |
| `core/checks/pre-push-guard.sh` | git `pre-push` | "never push to master/main" |
| `core/checks/pre-commit-guard.sh` | git `pre-commit` | "renaming a state-gating field needs a backfill" |
| `core/checks/shims/glab` | PATH shim | "`glab` uses `-F json`, not `--json`" |
| `core/hooks/guard.sh` | Claude `PreToolUse` (`~/.claude/hooks/guard.sh`), DSH guard bridge | push to master/main or `--all`/`--mirror`, force push, worktree not based on `origin/master`, commit/push/`glab mr` without the user's word in the last 30 min, ClickUp writes without preview + confirm, amend-of-merged-commit, implicit branch targets, `reset --hard`, `clean -f`; react-parity run exception flag |
| `core/checks/git-guard.sh` | CLI | thin wrapper over `core/hooks/guard.sh` (no transcript, so commit/push always deny) |

The git hooks and the CLI wrapper have escape hatches (`AIMAIN_BYPASS=1`, `AIMAIN_ALLOW_COMMIT=1`,
`AIMAIN_ALLOW_DELETE_MIGRATION=1`). `core/hooks/guard.sh` itself has none and always blocks;
`bash core/hooks/test-guard.sh` covers every rule offline. The former audit-mode wrapper is in
`archive/claude-pre-tool-use.sh`.

`memory/lessons/COVERAGE.md` preserves the earlier promotion map. The six legacy journal
entries now live in Obsidian's `AI Memory/Lessons.md`; `memory/lessons/LESSONS.md` points there.
