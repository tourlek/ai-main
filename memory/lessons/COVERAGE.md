# Lesson coverage

Where each lesson in `LESSONS.md` ended up. Not loaded into any prompt — this file exists so
the shrink stays auditable: every lesson is either a rule in `RULES.md`, a deterministic check,
repo knowledge, or explicitly archived.

`LESSONS.md` itself stays in git as the full incident journal and is still what the
`self-learning` skill appends to. It is no longer compiled into any tool's entry file
(it was ~13.4 KB — roughly 3,350 tokens on every session of every tool).

## Enforced by a check instead of a prompt line

| Lesson | Check |
| --- | --- |
| No `Co-Authored-By` / AI attribution in commit messages | `core/checks/commit-msg-lint.sh` |
| `glab` uses `-F json`, never `--json` | `core/checks/shims/glab` |
| Never push to `master`/`main` of a work repo | `core/checks/pre-push-guard.sh` |
| Never amend/rebase a commit other branches already contain | `core/checks/git-guard.sh` |
| Git commands that default to "current branch" need an explicit branch argument | `core/checks/git-guard.sh` |
| Never commit without authorization | `core/checks/git-guard.sh` (Claude PreToolUse) + a `min` rule for tools with no hook |
| Renaming a field that gates user-visible state needs a backfill | `core/checks/pre-commit-guard.sh` |

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

The scanned-PDF duplicate-audit lesson is a one-off with no recurring surface; it stays in
`LESSONS.md` only.
