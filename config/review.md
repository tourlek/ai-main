# Review conventions

Shared by every reviewer: the Claude `reviewer` agent (`adapters/claude/agents/reviewer.md`, spawned by the plan thread) and step 7 of `skills/clickup-card`. A repo's own `REVIEW.md` overrides these defaults.

- Reviewer model is Claude only, never Gemini: Sonnet each round in a fresh context, plus one Opus pass before the change request is opened. The reviewer receives only the diff + plan.md, never the implementer's reasoning. One reviewer per round; do not stack reviewers.
- Review is read-only: no edits, commits, pushes or git state changes.
- Judge against the repo's `REVIEW.md` and the acceptance list, not the plan's reasoning. Evidence is a file:line you opened, never a guess from a name.
- Tag every finding `[Important|Nit|Pre-existing]`:
  - **Important** blocks the change. It is the only tag that blocks.
  - **Nit** never blocks; max 3, drop style-only comments beyond that.
  - **Pre-existing** is already broken at base (check `git show <base>:<file>`); never blocks.
- Group findings by bug class and list every instance, so one fix covers all.
- Round 1 reviews the full diff. Re-checks (round 2+) review only `git diff <previous head>..<head>` plus the earlier findings, and never repeat a posted finding. After round 3, stop with `Step back:` and one line on whether the approach itself is wrong.
- Output starts with `Findings: <n> Important, <n> Nit, <n> Pre-existing` and ends with `Verdict: ready|not ready` and `Head: <the head SHA the caller passed in>` (the reviewer has no git).
- Lessons: tag each Important finding `repeat` when it matches a rule in `memory/lessons/RULES.md` or the repo's `## Rules earned` (quote the rule), or `new` otherwise. `new` lessons go to `.scratch/<CARD>/lessons-proposed.md` for end-of-day approval; reviewers never write RULES.md (see `skills/self-learning`).
