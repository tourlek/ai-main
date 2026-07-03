---
name: git-commit-workflow
description: Inspect local git changes, decide whether to split or combine commits, and write conventional-prefix commit messages with an optional body when the subject alone is not enough.
argument-hint: "[repo or commit task]"
disable-model-invocation: true
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# Git Commit Workflow

## When to Use

Use this when the user asks to:

- review local changes before committing
- decide whether changes should be one commit or several
- name a commit with prefixes like `fix:`, `feat:`, `chore:`, `refactor:`
- add a commit body/description when the subject is not enough

Do not use this for history rewriting, pushing, or release surgery. Pair it with repo-specific git workflow memory when the task is really about branches or releases rather than commit grouping.

## Inputs and Context to Gather

1. Confirm the real repo root before running git commands.
2. Check whether the user wants review-only, message help, commit prep, or an actual commit.
   - If they say something like `commit local changes`, treat that as an actual commit request once the diff boundary is clear.
   - If they invoke a helper name only, inspect/classify first and use the surrounding task wording to decide whether to stop at prep or carry the commit through.
3. Capture current worktree state:
   - `git status --short --branch`
   - `git diff --stat`
   - `git diff --cached --stat`
4. If grouping is unclear, inspect touched files and hunks:
   - `git diff --name-only`
   - `git diff --cached --name-only`
   - targeted `git diff -- <path>`
5. Note unrelated dirty files before proposing a commit boundary.
6. Check workspace instructions for command wrappers such as `RTK.md`; some repos expect `rtk`-prefixed shell commands.

## Procedure

1. Inspect the worktree first.
   - Use `git status --short --branch` to see staged, unstaged, and untracked files.
   - Use `git diff --stat` and `git diff --cached --stat` to estimate change clusters.
2. Classify the change by intent.
   - `fix:` for bug fixes
   - `feat:` for user-visible additions
   - `refactor:` for structural cleanup without behavior change
   - `chore:` for maintenance/setup
   - `docs:`, `test:`, `style:`, `core:` when those labels are the clearest fit
3. Decide split vs combine.
   - Split when changes have different rollback risk, different user intent, or clearly separate file clusters.
   - Combine when the files all support one behavior change and splitting would make the history harder to read.
4. Draft the subject line.
   - Keep it short and specific.
   - Prefer the user’s terminology, ticket wording, or exact feature area when available.
5. Add a commit body only when needed.
   - Use a short body if the subject alone misses an important why/scope note.
   - Skip the body for obvious one-file or one-fix commits.
6. Before an actual commit, re-check scope.
   - `git diff --cached --stat`
   - `git diff --cached --name-only`
7. If staging or commit fails on `.git/index.lock` / `Operation not permitted`, treat that as a repo-write permission boundary and switch to the environment's approved repo-write path before retrying.
8. After an actual commit, verify the remainder.
   - `git status --short`
   - `git status --short --branch`
   - `git log -1 --oneline`
   - mention any intentionally uncommitted files

## Efficiency Plan

- Start with `git status --short --branch` and the two diff stats before reading full hunks.
- Use file clusters to decide whether deeper diff reading is necessary.
- If the workspace uses a shell wrapper such as `rtk`, keep that prefix consistent across inspection, testing, and commit verification commands.
- Reuse the user’s wording for commit subjects when it is already specific.
- Stop once the rollback boundary and subject/body are clear; do not over-analyze cosmetic hunks.

## Pitfalls and Fixes

- Symptom: commit suggestion ignores unstaged or untracked files. Likely cause: only cached diff was inspected. Fix: always inspect staged, unstaged, and untracked state first.
- Symptom: one commit mixes unrelated cleanup with a bug fix. Likely cause: grouping was based on “changed together” rather than rollback boundary. Fix: split by intent/risk.
- Symptom: subject line is vague. Likely cause: it describes effort, not outcome. Fix: name the concrete bug, feature, or subsystem changed.
- Symptom: commit body repeats the subject. Likely cause: no real extra context was needed. Fix: drop the body unless it adds scope or rationale.
- Symptom: `git add` or `git commit` fails with `.git/index.lock` / `Operation not permitted`. Likely cause: repo-write permission boundary. Fix: retry through the environment's approved write path instead of re-debugging the diff.
- Symptom: commit command returns a terse token and it is unclear whether anything landed. Likely cause: wrapped-shell output compression. Fix: verify with `git status --short --branch` and `git log -1 --oneline`.

## Verification Checklist

- The repo root is explicit.
- Staged, unstaged, and untracked state were all inspected.
- The recommendation says whether to split or combine, and why.
- The proposed subject uses a conventional prefix.
- A body is included only when it adds real context.
- Workspace command-wrapper requirements were followed when present.
- If a commit was made, remaining uncommitted files are reported.
- If a commit was made, the last commit and branch/worktree state were verified explicitly.
