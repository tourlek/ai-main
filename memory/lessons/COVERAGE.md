# Lesson coverage

Historical promotion map from the earlier ai-main lesson journal. Not loaded into prompts; the tables below record earlier destinations and are not a claim that every row was reverified during the Obsidian cutover.

The six journal entries present on 2026-10-06 were migrated to `~/Tualek/AI Memory/Lessons.md`. `LESSONS.md` is now a pointer; `self-learning` follows the vault workflow for new captures. Promoted rules and deterministic checks remain owned by ai-main. Earlier versions of this journal remain in Git history.

## Enforced by a check instead of a prompt line

| Lesson | Check |
| --- | --- |
| No `Co-Authored-By` / AI attribution in commit messages | `core/checks/commit-msg-lint.sh` |
| `glab` uses `-F json`, never `--json` | `core/checks/shims/glab` |
| Never push to `master`/`main` of a work repo | `core/hooks/guard.sh` (PreToolUse/DSH) + `core/checks/pre-push-guard.sh` (git hook) |
| Never amend/rebase a commit other branches already contain | `core/hooks/guard.sh` |
| Git commands that default to "current branch" need an explicit branch argument | `core/hooks/guard.sh` |
| Never commit without authorization | `core/hooks/guard.sh` (Claude PreToolUse, DSH bridge; CLI via `core/checks/git-guard.sh`) + the profile rule for tools with no hook |
| Worktrees branch from `origin/master` | `core/hooks/guard.sh` |
| ClickUp writes need preview + confirm | `core/hooks/guard.sh` |
| Renaming a field that gates user-visible state needs a backfill | `core/checks/pre-commit-guard.sh` |
| Session work time = wall-clock union of active intervals; ClickUp time entries must not overlap or be invented | `core/checks/session-hours.py` (run by `clickup-card` eod) |

## Moved into repo knowledge (loaded only inside that repo)

| Lesson | File |
| --- | --- |
| `$nin`/`$ne` on array fields; unbounded `countDocuments` on polled paths; per-tenant flag rollout; one flag per feature | `knowledge/_ohochat-shared.md` |
| OTA build succeeded ≠ delivered to customers | `knowledge/oho-flutter-mobile.md` |
| Replay acked 200 ≠ recovered | `knowledge/oho-webhook.md` |

## Kept as a prompt rule

Revert discipline, branch/worktree confirmation, evidence honesty, "จดเป็น task" scope,
migration behavior preservation, release-tag diffing, permission-scope params, restricted-account
verification, delivery evidence — all in `RULES.md`.

## Archived

The earlier scanned-PDF duplicate-audit lesson was classified as a one-off. It was not present among the six entries migrated on 2026-10-06; consult Git history for its original record.
