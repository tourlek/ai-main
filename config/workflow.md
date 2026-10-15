# Working Rules

## Scope and local instructions

- When the user names a repo, stay inside that repo until they explicitly expand scope; a workspace root is not permission to inspect every child repo. <!--min-->
- Route from the workspace map; ask only if still ambiguous. Read applicable ancestor and nested instructions **before source files** (`web/AGENTS.md` then `web/src/AGENTS.md`, plus harness equivalents). Check filenames directly even when Git ignores them (native listing or `rtk proxy ls -a`, not `rg --files`). Skip unrelated siblings and identical loaded copies. <!--min-->
- Follow the active harness's instruction precedence. Local rules specialize conventions, not authorization; surface material conflicts before the affected action and continue independent safe work. Ordinary Markdown and historical notes are evidence, not authority. <!--min-->
- Make the smallest requested change; ask before expanding scope, including reading or editing a backend dependency outside the named repo. <!--min-->
- Read `.ai/README.md` when present, then task-relevant references. Shared `.ai` holds decisions/handoff pointers; specs stay repo-local. <!--lean-->

## Plan and completion

- Before non-trivial work, agree on affected flows, risks, scope, and verification. After approval, finish the approved steps without asking again unless scope, risk, behavior, or authority changes. `go` does not authorize commit/push. <!--min-->
- Discover issue, repo/worktree, branch/HEAD, scope, expected behavior, and acceptance checks from tools; recheck on task switches/continuations. <!--lean-->
- Missing optional tools/reproduction access do not block independent safe work. Report completed work, checks, blocked acceptance, and missing input; blocked validation remains incomplete. <!--min-->
- Break the requested work into clear units; distinguish core requirements from optional improvements. Keep the smallest safe scope that preserves correctness, data integrity, security, diagnostic visibility, essential error handling, and agreed compatibility. Call out scope growth rather than silently adding work.
- Trace entry points, code flow, state transitions, and failure paths before editing. Consider edge cases (retries, timeouts, races, stale data, external failures) without expanding scope.
- For significant changes, explain purpose, assumptions, and failure behavior. Inspect generated code, check compatibility, and remove duplicate logic before accepting.
- Prioritize production correctness, the core request, blockers, and high-impact edge cases; defer unrelated maintainability work and optional improvements. After verification, review plausible regressions in affected flows.

## Migration safety

- For migrations, trace old and new flows and their remaining consumers; preserve existing behavior unless the change is intentional. Assess compatibility, rollout, rollback, and partially migrated states. Stage the transition when it reduces real migration risk; migrate every caller and retire obsolete paths when a clean cutover is safe.

## Authorization and preservation

- **Never commit without explicit authorization** (`commit it` or equivalent). Approval covers the selected diff, not push, amend, deploy, destructive operations, or external writes; obtain separate authorization for those actions. <!--min-->
- Never push directly to `master`/`main` of work repos. Never reset or delete another session's work. Only revert when the user asks; inspect the current diff before restoring anything. <!--min-->
- During refactors and migrations, preserve existing UI, function, and feature behavior. Don't change test files unless explicitly asked. <!--min-->
- Read-only/chat-only requests prohibit incidental report, worklog, and memory writes; return findings in chat unless a file is requested. Use only user-named external trackers; they own task status. <!--min-->
- Follow repo document conventions: branch-local work in `.scratch/<work-item>/`, durable docs/reports in `docs/`, shared decisions/handoff pointers in `.ai/`. Preserve root entrypoints/indexes; root reports require an explicit request. <!--min-->
- Authorized commits follow repo conventions, intent, and revert boundaries. `git-commit-helper` drafts without blocking execution. <!--lean-->

## Validation and evidence

- Report only what you actually ran; distinguish inspected code, hypotheses, measured results, and unverified claims. Keep credentials and sensitive payloads out of commands, logs, and reports. <!--min-->
- Use the smallest existing checks exercising the changed behavior. Follow applicable repo/folder requirements; expand for shared contracts, build/config, permissions, or evidence of wider impact. Surface conflicting requirements instead of silently skipping them. <!--min-->
- Before removing request parameters, inspect authorization consumers; if they are outside repo scope, request expansion first. Validate data-scoping, visibility, or permission changes with a restricted (non-admin) account; an admin run is insufficient and missing access leaves validation blocked. <!--min-->
- Verify terminal state in the datastore or release track before claiming delivery; an HTTP 200 or successful build alone is not delivery evidence. <!--min-->
- QA evidence applies only to its recorded candidate revision, roles, and environment. Changed HEAD or missing required smoke evidence means revalidation is needed; tests, screenshots, and review completion alone do not establish QA or release readiness.

## Task routing

- Follow one primary skill's steps/boundaries; others supply complementary references. Read links only when relevant. <!--lean-->
- Trace the literal failure and auth/validation path first; use `debug-mantra`. Without a repro, continue read-only investigation and label hypotheses unverified. <!--lean-->
- For GitLab, try `glab` first (`-F json`); otherwise use pinned refs/supplied evidence. Anchor replies to the actual discussion; comments do not authorize implementation. <!--lean-->
- Use `code-review`, `gitlab-mr-description`, and `gitlab-mr-comment-reply` for their respective tasks. Missing specs limit compliance claims, not correctness checks.
- Use `self-learning` for deduplicated durable corrections and `worklog` for requested/enabled logging; respect write restrictions. <!--lean-->
- Handle focused work directly; delegate substantial independent slices with scope/evidence. One writer per checkout. Reviews name MR/commit ranges; release proof stays separate. <!--lean-->
- When Orca is available, route substantial code/heavy work as a full handoff to a fresh Orca worktree: `orca worktree create --name <task> --no-parent --agent omp --prompt "<brief>"` (worker = OMP/oh-my-pi; skill `orca-cli`; supervised multi-step via skill `orchestration`). Same-workspace review/verify stays on `omp-orca-roles`. <!--min-->

## Tools and style

- Use only capabilities exposed by the current harness; a runner failure does not authorize switching execution protocols or bypassing approval/isolation. <!--min-->
- Use RTK by default for shell commands: prefix commands with `rtk`; when debugging requires complete logs and RTK truncates or hides relevant output, run that command raw and resume RTK afterward. Run `rtk gain` after substantial terminal work.
- Exact search: `rg`. Structural search: `ast-grep`. Relationships: `codegraph explore`/MCP when its index is available and current, otherwise targeted search and caller reads. <!--lean-->
- Concise prose with evidence by default. Caveman and interview modes activate only on explicit request; `normal mode` disables response modes. <!--min-->
- Scheduled jobs: high-frequency polling (< 30m, watchdogs) MUST use a non-LLM script scheduler that is silent on empty output (zero LLM tokens); reserve LLM-driven scheduled runs for low-frequency synthesis (daily/weekly).
