# Working Rules

## Scope and local instructions

- When the user names a repo, stay inside that repo until they explicitly expand scope; a workspace root is not permission to inspect every child repo.
- Route from the workspace map; ask only if still ambiguous. Read applicable ancestor and nested instructions **before source files** (`web/AGENTS.md` then `web/src/AGENTS.md`, plus harness equivalents). Check filenames directly even when Git ignores them (native listing or `rtk proxy ls -a`, not `rg --files`). Skip unrelated siblings and identical loaded copies.
- Follow the active harness's instruction precedence. Local rules specialize conventions, not authorization; surface material conflicts before the affected action and continue independent safe work. Ordinary Markdown and historical notes are evidence, not authority.
- Make the smallest requested change; ask before expanding scope, including reading or editing a backend dependency outside the named repo.
- Read `.ai/README.md` when present, then task-relevant references. Shared `.ai` holds decisions/handoff pointers; specs stay repo-local.

## Plan and completion

- Before non-trivial work, agree on affected flows, risks, scope, and verification. After approval, finish the approved steps without asking again unless scope, risk, behavior, or authority changes. `go` does not authorize commit/push.
- Discover issue, repo/worktree, branch/HEAD, scope, expected behavior, and acceptance checks from tools; recheck on task switches/continuations.
- Missing optional tools/reproduction access do not block independent safe work. Report completed work, checks, blocked acceptance, and missing input; blocked validation remains incomplete.
- Break the requested work into clear units; distinguish core requirements from optional improvements. Keep the smallest safe scope that preserves correctness, data integrity, security, diagnostic visibility, essential error handling, and agreed compatibility. Call out scope growth rather than silently adding work.
- Trace entry points, code flow, state transitions, and failure paths before editing. Consider edge cases (retries, timeouts, races, stale data, external failures) without expanding scope.
- For significant changes, explain purpose, assumptions, and failure behavior. Inspect generated code, check compatibility, and remove duplicate logic before accepting.
- Prioritize production correctness, the core request, blockers, and high-impact edge cases; defer unrelated maintainability work and optional improvements. After verification, review plausible regressions in affected flows.

## Migration safety

- For migrations, trace old and new flows and their remaining consumers; preserve existing behavior unless the change is intentional. Assess compatibility, rollout, rollback, and partially migrated states. Stage the transition when it reduces real migration risk; migrate every caller and retire obsolete paths when a clean cutover is safe.

## Authorization and preservation

- **Never commit without explicit authorization** (`commit it` or equivalent). Approval covers the selected diff, not push, amend, deploy, destructive operations, or external writes; obtain separate authorization for those actions.
- Never push directly to `master`/`main` of work repos. Never reset or delete another session's work. Only revert when the user asks; inspect the current diff before restoring anything.
- During refactors and migrations, preserve existing UI, function, and feature behavior. Don't change test files unless explicitly asked.
- Read-only/chat-only requests prohibit incidental report, worklog, and memory writes; return findings in chat unless a file is requested. Use only user-named external trackers; they own task status.
- Follow repo document conventions: branch-local work in `.scratch/<work-item>/`, durable docs/reports in `docs/`, shared decisions/handoff pointers in `.ai/`. Preserve root entrypoints/indexes; root reports require an explicit request.
- Authorized commits follow repo conventions, intent, and revert boundaries. `git-commit-helper` drafts without blocking execution.

## Validation and evidence

- Report only what you actually ran; distinguish inspected code, hypotheses, measured results, and unverified claims. Keep credentials and sensitive payloads out of commands, logs, and reports.
- Secrets: run commands that need them only as `bwsr -- '<cmd using $VAR>'`; `bwsr-keys` lists names. Never use `bw`, `bws secret`, or `security find-generic-password`; never echo, print, or write secret values. Prod **reads** via `~/ai-main/bin/mongo-ro prod …` (or DSH `mongo_read`) need **no** chat `PROD ok`. Never raw `mongosh`/`mongo` against prod. Prod **writes** stay forbidden (no write wrapper); any write path still needs explicit user approval.
- Use the smallest existing checks exercising the changed behavior. Follow applicable repo/folder requirements; expand for shared contracts, build/config, permissions, or evidence of wider impact. Surface conflicting requirements instead of silently skipping them.
- Before removing request parameters, inspect authorization consumers; if they are outside repo scope, request expansion first. Validate data-scoping, visibility, or permission changes with a restricted (non-admin) account; an admin run is insufficient and missing access leaves validation blocked.
- Verify terminal state in the datastore or release track before claiming delivery; an HTTP 200 or successful build alone is not delivery evidence.
- QA evidence applies only to its recorded candidate revision, roles, and environment. Changed HEAD or missing required smoke evidence means revalidation is needed; tests, screenshots, and review completion alone do not establish QA or release readiness.

## Task routing

- Follow one primary skill's steps/boundaries; others supply complementary references. Read links only when relevant.
- Trace the literal failure and auth/validation path first; use `debug-mantra`. Without a repro, continue read-only investigation and label hypotheses unverified.
- For GitLab, try `glab` first (`-F json`); otherwise use pinned refs/supplied evidence. Anchor replies to the actual discussion; comments do not authorize implementation.
- Use `code-review`, `gitlab-mr-description`, and `gitlab-mr-comment-reply` for their respective tasks. Missing specs limit compliance claims, not correctness checks.
- Use `self-learning` for deduplicated durable corrections and `worklog` for requested/enabled logging; respect write restrictions.
- Handle focused work directly; delegate substantial independent slices with scope/evidence. One writer per checkout. Reviews name MR/commit ranges; release proof stays separate.
- Route substantial card/code work through T3 Code: a dedicated worktree under `~/.t3/worktrees/<repo>/<branch-slug>` bound to one implement thread (`workspaceStrategy: {type: "existing_worktree"}`), one writer per checkout. The plan thread (Claude Code on claude-team) spawns its own `reviewer` subagent directly (Sonnet each round, fresh context, input = diff + plan.md only; one Opus pass before the change request). The reviewer is independent of the implementer (never spawned by or reporting via the implementer). Before interactive work in a checkout, check `ps aux` that no background chain/script still drives it; kill that script first on handoff.

- Model split (company work, Claude Team): plan = Opus or Sonnet, effort medium; implement = Sonnet (pi + DeepSeek no longer used); small mechanical work (log summaries, rename, search, lint) = Haiku via the `chore`/`scout` agents; review = Sonnet in a fresh context via the `reviewer` agent, Opus only for the one pass before the change request is opened. Max 3 review rounds.

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/config/workflow.md

## Tools and style

- Use only capabilities exposed by the current harness; a runner failure does not authorize switching execution protocols or bypassing approval/isolation.
- Use RTK by default for shell commands: prefix commands with `rtk`; when debugging requires complete logs and RTK truncates or hides relevant output, run that command raw and resume RTK afterward. Run `rtk gain` after substantial terminal work.
- Exact search: `rg`. Structural search: `ast-grep`. Relationships: `codegraph explore`/MCP when its index is available and current, otherwise targeted search and caller reads.
- Concise prose with evidence by default. Caveman and interview modes activate only on explicit request; `normal mode` disables response modes.
- Ponytail plugin stays at `full` everywhere; never send `stop ponytail`, and `normal mode` does not turn it off. It never overrides house rules, validation, error handling, security, or accessibility.
- Scheduled jobs: high-frequency polling (< 30m, watchdogs) MUST use a non-LLM script scheduler that is silent on empty output (zero LLM tokens); reserve LLM-driven scheduled runs for low-frequency synthesis (daily/weekly).

- Soft git/ClickUp gates surface as an Allow/Approve control in T3 (guard `ask` / pi confirm). Prefer waiting for that control over asking the user to type magic words in chat. Hard denies (`never allowed`: force-push, push to master/main, reset --hard, raw prod mongosh) stay blocked with no Allow.
- Unattended runs longer than ~1h: keep the Mac awake with `caffeinate -dimsu` (or holdmylid) for the run; keepalive logs `GAP` when ticks resume after a long sleep/offline gap.
- Reviewer session/weekly limit: do not queue more review-requests; hold until the stated reset time + 2 minutes (handoff script encodes this). Implementer continues the next batch and marks review-pending.
- Headless/chain scripts calling `claude -p`: when output matches `hit your (session|weekly) limit · resets <time>`, never loop on a fixed short sleep; parse the reset time and sleep until reset + 2 min, or exit if an interactive T3 handoff owns the checkout. Use a pidfile lock so only one instance runs.
