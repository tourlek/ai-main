---
name: git-commit-helper
description: Inspect local git changes and suggest commit names and which files to stage. Use when the user asks to name commits, review local changes before committing, decide whether changes should be split across multiple commits or combined, follow commit prefixes such as fix:, feat:, refactor:, core:, chore:, docs:, test:, style:, or add a commit body/description when the subject alone is insufficient.
---

# Git Commit Helper

## Overview

Inspect local changes and output a staging + commit plan. Do not run `git add`, `git commit`, or `git push` — only report what the user should do.

## Workflow

1. Inspect repo context:
   - Run `git status --short`.
   - Read relevant local instructions such as `AGENTS.md`, `CONTRIBUTING.md`, or package/repo docs when present.
   - Inspect unstaged and staged changes with `git diff`, `git diff --cached`, and targeted file diffs.
   - If the worktree is dirty from prior/user work, do not reset or revert it.

2. Classify local changes:
   - Identify functional behavior changes, UI/style-only changes, refactors, tests, docs, config/tooling, and generated artifacts.
   - Note risky or unrelated edits.

3. Decide commit grouping:
   - Split commits when changes have different intent, risk, rollback scope, or review ownership.
   - Split commits when a bug fix and a broad refactor are both present.
   - Split commits when frontend, backend, tests/docs, or generated artifacts are independently revertible.
   - Combine commits when changes are tightly coupled and one part is incomplete or misleading without the other.
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

## Output Format

Always output a plan in this shape — never run git commands that mutate state:

```
Commit 1:
  Stage: <file1>, <file2>
  Message: <prefix>: <subject>
  Body (if needed): ...

Commit 2 (if applicable):
  Stage: <file3>
  Message: <prefix>: <subject>
```

Do not run `git add`, `git commit`, `git push`, or any other mutating git command.
