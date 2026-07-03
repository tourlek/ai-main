---
name: oho-web-app-git-branch-workflow
description: Analyze oho-web-app branch differences, squash feasibility, develop sync order, cherry-pick equivalence, and narrow release reverts without over-editing.
argument-hint: "[branch or release task]"
disable-model-invocation: true
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO Web App Git Branch Workflow

## When to Use

Use this for `/Users/tualek/ohochat/oho-web-app` branch/MR work, especially:

- squash feasibility or MR readability questions
- MR review base selection for feature branches targeting `develop`
- whether to bring `origin/develop` into a feature branch before squash
- revert-the-latest-commit-then-merge-`develop` cleanup on the current branch
- comparing `develop`, `release/*`, `staging-*`, and feature branches
- checking whether cherry-picked commits are patch-equivalent
- reviewing uncommitted changes or confirming a clean worktree has no patch
- narrow revert requests such as removing one feature from release while preserving unrelated fixes

Do not use this for general code debugging. If the user says not to fetch or not to change anything yet, keep the run read-only.

## Inputs and Context to Gather

1. Confirm the repo root is `/Users/tualek/ohochat/oho-web-app`; `/Users/tualek/ohochat` is a multi-repo workspace, not the git root.
2. Capture the exact branch names and whether the user permits fetch.
3. Check dirty worktree before acting: `git status --short --branch`.
4. For MR review, inspect refs before choosing the comparison base; this checkout previously had local `origin/develop` pointing at the feature head while `develop` was the actual base.
5. If remote truth matters and the user permits it, refresh refs; if fetch is blocked or refused, label all conclusions as local-ref-only.
6. If the user asks only "ทำได้ไหม" or "จะเป็นยังไง", answer feasibility/impact without changing history.

## Procedure

1. Start in the repo:
   - `git -C /Users/tualek/ohochat/oho-web-app status --short --branch`
   - `git -C /Users/tualek/ohochat/oho-web-app branch --all --list '*<name>*'`
2. For branch difference:
   - `git rev-list --left-right --count --cherry-pick <base>...<topic>`
   - `git log --oneline --decorate --no-merges <base>..<topic>`
   - `git log --left-right --cherry-pick --no-merges <base>...<topic>`
3. For MR review base selection:
   - run `git branch -vv` and use explicit refs such as `develop...feature/tk-4255-jera-cloud/develop` when remote-tracking refs are misleading
   - if `coderabbit` is requested but missing on PATH, report the missing binary and do a manual review if useful; do not claim plugin output
4. For squash feasibility:
   - confirm whether the topic range is a linear stack or includes merges
   - report ahead/behind counts and whether the branch is behind target branch
   - mention untracked or dirty files that would not be included unless staged
5. For update-before-squash advice:
   - if the topic branch is behind `origin/develop`, recommend syncing with develop before final squash
   - if shared branch risk exists, present merge as lower-risk than force-push squash/rebase
6. For reviewable branch rewrite:
   - create a backup ref before rewriting, e.g. `backup/<branch>-before-squash-YYYYMMDD`
   - preserve original commit order when later commits depend on earlier file additions; out-of-order cherry-picks previously conflicted in `components/MaxPanel.vue` and `components/MaxPanelJeraProfilePanel.vue`
   - run `npm run build` after the rewrite when feasible
7. For patch equivalence:
   - use `git rev-list --cherry-pick` first
   - if `git patch-id --no-stat` is unsupported, compare touched-file diffs and patch-equivalent output instead
8. For uncommitted-change reviews:
   - inspect staged, unstaged, and untracked state with `git status --short --branch`, `git diff --stat`, `git diff --name-only`, and `git diff --cached --stat`
   - if there is no patch content, say there are no findings / patch is correct rather than inventing issues
9. For narrow release revert:
   - identify the exact commit(s) to remove
   - avoid unrelated dirty files
   - preserve unrelated release fixes unless the user explicitly asks for a broader branch sync
10. For “revert latest commit first, then pull/merge develop into this branch”:
   - confirm the current branch and inspect `git status --short --branch`
   - run `git revert --no-edit HEAD`
   - fetch `develop`, then if `git pull origin develop` stops on divergent-branch policy, merge the fetched ref with `git merge --no-edit FETCH_HEAD`
   - verify with `git status --short --branch`, `git log --oneline --decorate --max-count=6 --graph`, and `git diff --check`

## Efficiency Plan

- Use local refs only when the user says not to fetch; do not retry network just to satisfy curiosity.
- Keep branch reports short: current branch, ahead/behind, unique commits, practical recommendation, and caveats.
- Prefer exact command outputs like `11 12`, commit SHAs, and touched files over long prose.
- Stop before rewriting history unless the user explicitly authorizes the operation.

## Pitfalls and Fixes

- Symptom: `fatal: not a git repository` from `/Users/tualek/ohochat`. Likely cause: top-level workspace is multi-repo. Fix: run commands in `/Users/tualek/ohochat/oho-web-app`.
- Symptom: `Could not resolve host: gitlab.boonmeelab.com`. Likely cause: network/DNS unavailable. Fix: do local-only analysis and say refs may be stale unless user permits/retries fetch.
- Symptom: user says `ไม่ต้อง fertch` or `ยังไม่ต้อง`. Likely cause: they want read-only analysis. Fix: stop fetching or changing branch state.
- Symptom: patch-id command fails on `--no-stat`. Likely cause: local git variant. Fix: verify equivalence with `git rev-list --cherry-pick`, touched files, and diffs.
- Symptom: MR diff is unexpectedly empty. Likely cause: wrong base/ref, such as `origin/develop` already pointing at the feature head. Fix: inspect `git branch -vv` and compare explicit local refs.
- Symptom: CodeRabbit requested but `coderabbit` is `command not found`. Likely cause: CLI not installed. Fix: report that and switch to manual review if the user still needs findings.
- Symptom: cherry-pick/squash rewrite conflicts in JERA panel files. Likely cause: commits applied out of dependency order. Fix: abort and reapply in original stack order.
- Symptom: `git pull origin develop` stops with `Need to specify how to reconcile divergent branches`. Likely cause: Git requires an explicit policy for divergent histories. Fix: use the fetched `FETCH_HEAD` and run `git merge --no-edit FETCH_HEAD` when the user wants `develop` merged into the current branch.
- Symptom: git operations fail on `.git/index.lock` or `.git/FETCH_HEAD` with `Operation not permitted`. Likely cause: repo-write permission boundary. Fix: treat it as a write-path problem before changing the branch plan.

## Verification Checklist

- The answer states whether refs were refreshed or local-only.
- The real repo root and current branch are named.
- Ahead/behind counts and relevant SHAs are included when branch comparison is the task.
- Dirty/untracked worktree state is noted before any proposed rewrite/revert.
- For MR review, the comparison base is explicit and checked against local refs.
- For uncommitted-change review, staged, unstaged, and untracked state were all inspected.
- For revert-then-merge cleanup, the final branch history and `git diff --check` were inspected after the merge.
- No squash, rebase, force-push, or revert is performed unless explicitly requested.
