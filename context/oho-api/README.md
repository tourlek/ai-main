# oho-api shared context

Repo code and docs are canonical. Record durable cross-worktree decisions in `decisions/` and per-change QA handoffs in `handoffs/`; link to canonical sources rather than copying specs.
Before QA, smoke the changed behavior in the candidate worktree and record its revision, environment, actual result, and safe evidence location. Keep secrets and worktree-local scratch out of this shared directory.

## Start or resume a task

Identify the issue, candidate repo/worktree, branch and HEAD, approved scope, expected behavior, and acceptance checks. Recheck that anchor on a task switch or continuation. Use the candidate's `docs/index.md` and matching `.scratch/<work-item>/` spec when present; cross-repo references are indexed in the primary workspace's `CONTEXT-MAP.md`.

Named ClickUp trackers own task status. Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/context/oho-api/README.md Keep branch-local plans and artifacts in the owning repo; shared `handoffs/` stores pointers with candidate revision, tested roles/environment, observed checks, blockers, and next action. Retain revision-specific evidence when updating a handoff. Changed HEAD or missing required runtime proof means revalidation is needed, not readiness.
