---
name: branch-perf-compare
description: Compare runtime performance (RAM, CPU, startup time, bundle size) of the same app across two or more git branches and produce a paste-ready Markdown report. Use when the user asks to "compare performance between branches", "benchmark uat vs nuxt3", "why does X branch use more RAM than Y", or wants a written perf summary saved to a .md file at repo root.
---

# Branch Performance Comparison

Standardizes the workflow of running the same app on multiple branches, capturing comparable measurements, and writing a report. Designed for the recurring `uat` vs `nuxt3` vs `perf/*` comparison pattern.

## Workflow

1. Identify the branches and what to measure.
   - List of branches must be explicit. Common shape: `origin/uat`, `origin/nuxt3`, `perf/nuxt3-ram-reductions`, `feature/tk-XXXX-*`.
   - Default metrics: dev-server RAM (RSS), dev-server startup time, first-page TTFB, bundle size if a build step exists. Add Lighthouse / web-vitals only if the user asks.
   - Ask the user which page(s) or flow(s) define "the same workload" before measuring. Default to opening the app idle on `/` if not specified.

2. Pre-flight check.
   - `git fetch --all --prune` to refresh remotes.
   - `git stash` or refuse to proceed if the working tree is dirty — never measure on dirty trees.
   - Confirm Node version and package-manager (npm/yarn/pnpm) is the same across branches; if not, flag in the report.
   - If branches use different lockfiles, do a clean `node_modules` install per branch (`rm -rf node_modules && <pm> install --frozen-lockfile`) and record install time too.

3. Run each branch.
   - `git checkout <branch>`.
   - Boot the dev server (or production build, if that's what was asked).
   - Wait until the server logs "ready" / equivalent stable signal, then start the measurement window.
   - Sample RSS at fixed intervals (e.g. every 2s for 60s) via `ps -o rss= -p <pid>` or `/usr/bin/time -l` for build commands. Average and peak both matter.
   - Open the agreed page once, wait for idle, sample again.
   - Capture command output and timings. Stop the server cleanly between branches.

4. Compute deltas.
   - For each metric, compute absolute and percentage delta from the baseline branch (default: `origin/uat` or the branch the user names as baseline).
   - Highlight regressions ≥10% in the summary; flag improvements ≥10% too.
   - Cross-reference with `git log <baseline>..<branch> --oneline` to suggest likely contributors when a regression is large.

5. Write the report.
   - Save to `<perf-report>.md` at repo root (e.g. `nuxt3-perf-review.md`, `jera-performance-review.md`).
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

- Never compare branches by reading code alone. The report is empty without numbers — if measurement isn't possible, say so and stop.
- One branch per process; never run two dev servers in parallel on the same port.
- Don't include performance theories the user didn't ask for. Stick to measured deltas and the smallest reasonable contributor list.
- If the user mentions a specific concern (`local uat ใช้ ram less then nuxt3`), order the metrics table so that concern is the first row.
