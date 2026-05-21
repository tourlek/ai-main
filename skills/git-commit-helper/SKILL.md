---
name: git-commit-helper
description: Inspect local git changes and create clean commits. Use when the user asks Codex to commit changes, name commits, review local changes before committing, decide whether changes should be split across multiple commits or combined, follow commit prefixes such as fix:, feat:, refactor:, core:, chore:, docs:, test:, style:, or add a commit body/description when the subject alone is insufficient.
---

# Git Commit Helper

## Overview

Use this skill to turn local changes into reviewable commits with clear boundaries and messages. Prefer the repository's local instructions first, then apply the defaults below.

## Workflow

1. Inspect repo context before staging:
   - Run `git status --short`.
   - Read relevant local instructions such as `AGENTS.md`, `CONTRIBUTING.md`, or package/repo docs when present.
   - Inspect unstaged and staged changes with `git diff`, `git diff --cached`, and targeted file diffs.
   - If the worktree is dirty from prior/user work, do not reset or revert it. Decide what belongs to the current commit from the diff.

2. Classify local changes:
   - Identify functional behavior changes, UI/style-only changes, refactors, tests, docs, config/tooling, and generated artifacts.
   - Note risky or unrelated edits. If unrelated changes are mixed in the same files and cannot be safely separated with normal staging, ask before committing.
   - Prefer staging explicit paths. Use patch staging only when one file contains separate logical changes.

3. Decide commit grouping:
   - Split commits when changes have different intent, risk, rollback scope, or review ownership.
   - Split commits when a bug fix and a broad refactor are both present.
   - Split commits when frontend, backend, tests/docs, or generated artifacts are independently revertible.
   - Combine commits when changes are tightly coupled and one part is incomplete or misleading without the other.
   - Combine small style tweaks when they support the same UI surface and have the same rollback scope.
   - If uncertain, choose the grouping that makes `git revert <commit>` least surprising.

4. Choose the prefix:
   - `fix:` for bug fixes or corrections to behavior.
   - `feat:` for new user-visible or API-visible capability.
   - `refactor:` for internal restructuring without intended behavior change.
   - `core:` when the repo convention uses it for broad shared/internal infrastructure.
   - `chore:` for maintenance, tooling, dependencies, generated updates, or non-user-facing cleanup.
   - `docs:` for documentation-only changes when accepted by the repo convention.
   - `test:` for test-only changes when accepted by the repo convention.
   - `style:` for formatting/CSS-only changes when accepted by the repo convention; otherwise use `fix:` or `chore:` based on local convention.

5. Write the commit message:
   - Use lowercase prefix, colon, then a concise imperative or noun-phrase summary.
   - Keep the subject specific to the observable change, not the implementation mechanics.
   - Prefer examples like `fix: update jera appointment quick action url` or `refactor: extract contact sync state helpers`.
   - Avoid vague summaries like `fix: update code`, `chore: changes`, or `feat: improvements`.

6. Add a body only when the subject is not enough:
   - Add a body for multi-file or multi-reason commits where reviewers need context.
   - Add a body for migrations, compatibility tradeoffs, behavior caveats, or why changes were split/combined.
   - Use short bullet lines or 1-2 concise paragraphs.
   - Do not add a body for trivial single-purpose commits.

7. Verify before and after commit:
   - Before committing, review `git diff --cached --stat` and `git diff --cached`.
   - Run targeted tests or lint when risk justifies it and the repo has an obvious command.
   - Commit only staged files that match the chosen boundary.
   - After committing, run `git status --short` and report the commit hash/message plus any remaining uncommitted files.

## Commit Body Template

Use this shape when a body is useful:

```text
<prefix>: <subject>

- <why this change exists>
- <notable behavior or rollback boundary>
- <tests or verification, if useful>
```

## User Consent

If the user only asks for a commit-name suggestion or review, do not create a commit. If the user explicitly says to commit, proceed after inspecting and grouping the local changes.
