# Lessons — mistakes every AI tool must not repeat

Loaded into every session of every tool. Append via the `self-learning` skill.
Format: one `##` entry per lesson — newest last. When this file exceeds ~50 lessons,
consolidate: merge duplicates, drop obsolete ones, keep the rule one line each.

## 2026-05 — Reverted user code to "clean up"
- **Mistake**: undid prior user work during a refactor; user: `Why you revert code ???`
- **Rule**: never revert or reset work you didn't create; only revert when asked.

## 2026-05 — Altered passing-QA behavior during Nuxt 3 migration
- **Mistake**: "improved" UI/logic while migrating; QA-passed behavior changed.
- **Rule**: migrations preserve behavior exactly; improvements need a separate ask.

## 2026-06 — Added Co-Authored-By to commits
- **Mistake**: appended AI attribution lines; user removed them repeatedly.
- **Rule**: no Co-Authored-By or AI-attribution lines in commit messages.

## 2026-06 — Used `--json` with glab
- **Mistake**: `glab ... --json` fails on this machine.
- **Rule**: use `glab ... -F json`.

## 2026-06 — Committed without being asked
- **Mistake**: auto-committed after finishing a change.
- **Rule**: commit only after explicit `commit it` / `create commit ให้เลย`. (Exception: `ai-main` auto-sync of `memory/` + `logs/` via sync.sh is authorized.)
