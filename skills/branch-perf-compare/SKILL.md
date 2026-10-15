---
name: branch-perf-compare
description: Use to measure the same workload across named Git refs.
---

# Branch Performance Comparison

Standardizes the workflow of running the same app on multiple branches, capturing comparable measurements, and writing a report. Designed for the recurring `uat` vs `nuxt3` vs `perf/*` comparison pattern.

## Workflow

1. Identify the branches and what to measure.
   - List of branches must be explicit. Common shape: `origin/uat`, `origin/nuxt3`, `perf/nuxt3-ram-reductions`, `feature/tk-XXXX-*`.
   - Measure the requested metric first; add supporting metrics only when needed to interpret it. Build, Lighthouse, and web-vitals are not automatic additions to a RAM comparison.
   - Use the specified workload; for an explicitly idle comparison, state the idle `/` assumption. Ask when page/flow choice materially changes the comparison.

2. Pre-flight check.
   - Resolve and record exact commit IDs; fetch only the relevant remote when fresh refs are required.
   - A dirty caller worktree does not block benchmarking committed refs in isolation. Never stash, reset, clean, or checkout over user/other-agent work; ask if uncommitted changes are part of the requested comparison.
   - Create one disposable detached worktree per branch with `git worktree add --detach <temp-dir> <branch>`.
   - Confirm Node version and package-manager (npm/yarn/pnpm) is the same across worktrees; if not, flag in the report.
   - If branches use different lockfiles, do a clean dependency install inside each disposable worktree and record install time too.

3. Run each branch.
   - Run from its disposable worktree; never switch the caller's branch.
   - Boot the dev server (or production build, if that's what was asked).
   - Wait until the server logs "ready" / equivalent stable signal, then start the measurement window.
   - Sample RSS at fixed intervals (e.g. every 2s for 60s) via `ps -o rss= -p <pid>` or `/usr/bin/time -l` for build commands. Average and peak both matter.
   - Open the agreed page once, wait for idle, sample again.
   - Capture command output and timings. Stop the server cleanly between branches.
   - Remove only worktrees created by this run with `git worktree remove`; leave failed worktrees in place and report their paths when cleanup is unsafe.

4. Compute deltas.
   - For each metric, compute absolute and percentage delta from the baseline branch (default: `origin/uat` or the branch the user names as baseline).
   - Highlight regressions ≥10% in the summary; flag improvements ≥10% too.
   - Cross-reference with `git log <baseline>..<branch> --oneline` to suggest likely contributors when a regression is large.

5. Write the report.
   - Save to `<perf-report>.md` at repo root unless the user requests chat-only/read-only output.
   - Use the template below. Keep numbers, drop adjectives.
   - If a measurement wasn't run (env couldn't boot, etc.), write `Not measured: <reason>` — never fabricate.

## Report Template

```markdown
# <Project> performance comparison — <date>

## Setup

- Branches compared: `<branch-a>`, `<branch-b>`, ...
- Workload: <page/flow>
- Node: <version> · PM: <npm|yarn|pnpm> · Machine: <local/CI>
- Notes: <lockfile differences, missing tools, etc.>

## Results

| Metric | `<baseline>` | `<branch-b>` | Δ | `<branch-c>` | Δ |
| --- | --- | --- | --- | --- | --- |
| Dev-server startup (s) | … | … | … | … | … |
| RSS at idle (MB) | … | … | … | … | … |
| RSS after open `/` (MB) | … | … | … | … | … |
| Bundle size (gzipped, kB) | … | … | … | … | … |

## Regressions ≥10%

- <branch>: <metric> +X% — likely contributors: <commits or files>

## Improvements ≥10%

- <branch>: <metric> -X% — likely contributors: <commits or files>

## Open questions

- <anything that couldn't be measured or needs the user's input>
```

## Rules

- Never present static analysis as measured performance. If measurement is blocked, report the exact blocker and reproducible benchmark plan; complete any independent requested analysis with its evidence limits stated.
- One branch per disposable worktree and process; never run two dev servers in parallel on the same port.
- Don't include performance theories the user didn't ask for. Stick to measured deltas and the smallest reasonable contributor list.
- If the user mentions a specific concern (`local uat ใช้ ram less then nuxt3`), order the metrics table so that concern is the first row.
