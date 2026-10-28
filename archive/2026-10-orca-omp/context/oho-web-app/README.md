# oho-web-app shared context

Repo code and docs are canonical. Store durable cross-worktree decisions in `decisions/` and per-change QA notes in `handoffs/`, linked to the source rather than copying specs.
Before handing any change to QA, follow [QA.md](QA.md) and record the actual smoke evidence in its handoff. A link existing here does not mean the change is ready.

## Start or resume a task

Identify the issue, candidate repo/worktree, current branch and HEAD, approved scope, expected behavior, and acceptance checks. Recheck them when changing task or resuming work. Read the candidate's `CONTEXT.md`, the matching `docs/index.md` entry, and its `.scratch/<work-item>/` spec; use historical reports only for the recorded revision. Primary-workspace cross-repo references are indexed in `ohochat/CONTEXT-MAP.md`.

ClickUp/Orca own task status. This shared directory is not a task queue; worktree-local plans and artifacts remain with their owning repo. A handoff links to their actual location and records the candidate revision, tested role/environment, observed checks, blockers, and next action. Retain revision-specific evidence when updating a task handoff; changed HEAD requires revalidation under [QA.md](QA.md).

## Handoff index

These links locate evidence, not current readiness. Compare each recorded candidate HEAD with the current worktree before relying on its verdict.

| Work item | Handoff |
| --- | --- |
| Contact profile icons / sales owner | [Evidence and remaining acceptance](handoffs/contact-profile-icons-sales-owner.md) |
| OHO-1165 Multi-tannat | [Candidate handoff](handoffs/oho-1165-multi-tannat.md) |
| Channel V2 release/1.119.0 | [Revision-specific pre-QA evidence](handoffs/channel-v2-preqa-release-1.119.0.md) |
| Refactor QA runner | [Tooling handoff](handoffs/qa-refactor-runner.md); run captures against the feature candidate, not the tooling worktree |
