---
name: code-review
description: Use to review a specified MR, Git diff, or working-tree change.
---

# Code review

1. Confirm repo, branch/worktree, and review scope without switching branches. For an MR, try `glab` first and pin base/head metadata. For named refs, state whether comparison is merge-base or exact endpoints. For local work, inspect staged and unstaged diffs and relevant untracked files; `...HEAD` alone excludes them.
2. Read applicable repo/folder instructions and the requested spec or discussion. Ask only when the baseline is ambiguous; do not require tracker setup for a review.
3. Trace changed behavior and directly affected callers/contracts within scope. Review correctness, security, regressions, and compliance with applicable requirements; distinguish requirements from stylistic heuristics.
4. If required specs are inaccessible, request them and label compliance unknown. Continue independent correctness checks without inventing requirements.
5. Run focused checks when requested or needed for a material claim and permitted by scope. State what was inspected versus executed; a review request does not authorize fixing files.
6. Report actionable findings ordered by severity, with path/line, failing condition, consequence, and smallest suggested fix. If none, state coverage and remaining validation gaps.

Use one reviewer by default. Delegate only when independent scopes justify overhead and the harness supports the required protocol; never require two agents for a small diff. A governed runner failure is a blocker for that lane, not permission to change execution modes.

Use `scrutinize` only for an explicitly requested adversarial/alternative-design review. Formatting skills do not replace the review or silently cancel its checks.
