# Installed skills

OMP loads `build/omp-skills/`: names in `adapters/omp/skills.json` expose descriptions for automatic invocation; the remaining discovered skills are manual pointers available through `/skill:name`. Native OMP managed skills remain runtime-owned and independently discovered. The cross-harness links described below belong to explicit legacy deployment.

## Owned (this repo, `skills/`)

| Skill | Purpose |
| --- | --- |
| `gitlab-mr-description` | Draft / improve / standardize GitLab MR descriptions from `glab` data. Triggered by a GitLab MR URL or an MR-description request. |
| `gitlab-mr-comment-reply` | Draft concise Thai/English replies to GitLab MR review comments, anchored to actual code, with reply category (accept / push-back / explain / defer). |
| `git-commit-helper` | Inspect local diff, decide commit grouping, pick conventional prefix, write subject + body. Ported from Codex. |
| `branch-perf-compare` | Standardize RAM/startup/bundle comparisons across git branches (e.g. `uat` vs `nuxt3` vs `perf/*`) and produce a paste-ready perf report. |
| `clickup-card` | Per-card workflow from a DSH coordinator: breakdown via `cc-review`, ClickUp writes with preview+confirm, one DSH session per worktree, review per `config/review.md`, MR/Slack drafts, eod. |
| `self-learning` | Route authorized correction captures through the Obsidian memory workflow; manage RULES.md / `## Rules earned` lines from approved `lessons-proposed.md`; propose unrequested writes in chat. |
| `worklog` | Append one-line work log entries to `logs/YYYY-MM.md`; read back when asked "what did I work on". |

## From [`thananon/9arm-skills`](https://github.com/thananon/9arm-skills) — `external/9arm-skills/`

| Skill | Purpose |
| --- | --- |
| `debug-mantra` | Four-step debugging discipline — reproduce, trace, falsify, cross-reference — recited verbatim at the start of any debug session. |
| `scrutinize` | Outsider-perspective end-to-end review of a plan, PR, or code change. Questions intent and traces the actual code path. |
| `post-mortem` | Canonical engineering write-up of a fixed bug: root cause, mechanism, fix, validation, slip-through analysis. |
| `management-talk` | Rewrites engineer-to-engineer content for leadership audiences across JIRA / Slack / email / standup channels. |

## From [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) — `external/agent-skills/` (Vercel's verified pack)

| Skill | Purpose |
| --- | --- |
| `deploy-to-vercel` | Deploy applications / preview deployments to Vercel from natural-language requests. |
| `vercel-cli-with-tokens` | Manage Vercel projects via CLI using access-token auth (non-interactive). |
| `vercel-optimize` | Audit Vercel-deployed projects for cost, performance, and Core Web Vitals; produces ranked recommendations. |
| `react-best-practices` | React / Next.js performance optimization guidelines (40+ rules) from Vercel Engineering. |
| `react-native-skills` | React Native + Expo best practices for performant mobile apps (16 rules). |
| `react-view-transitions` | Implement smooth animations with React's View Transition API. |
| `composition-patterns` | React composition patterns for scalable component architecture (compound components, render props, etc.). |
| `web-design-guidelines` | Audit UI code against the Web Interface Guidelines (100+ rules), incl. accessibility. |

## From [`mattpocock/skills`](https://github.com/mattpocock/skills) — `external/mattpocock-skills/` (Matt Pocock's skills)

| Skill | Purpose |
| --- | --- |
| `code-review` | Two-axis review of a diff against repo standards and original spec using parallel sub-agents. |
| `tdd` | Test-driven development discipline: Red-Green-Refactor loop with minimal viable tests. |
| `to-spec` | Grounding and generating technical specifications from requirements and codebase context. |
| `to-tickets` | Break down specs into small, vertical, tracer-bullet tickets. |
| `diagnosing-bugs` | Systematic bug diagnosis flow before jumping into fixes. |
| `improve-codebase-architecture` | Architecture refactoring guidelines and domain modeling workflows. |
| `implement` | Focused implementation workflows following specifications. |
| `prototype` | Rapid prototyping workflows with clear guardrails. |
| `resolving-merge-conflicts` | Guided resolution of git merge conflicts preserving intent. |
| `wayfinder` | Codebase navigation and discovery helper. |

> Skills under `deprecated/`, `in-progress/`, `personal/`, or `node_modules/` in any external pack are automatically excluded by the skill builders and the legacy installer.
