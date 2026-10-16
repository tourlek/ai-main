# Checks instead of prompt rules

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
