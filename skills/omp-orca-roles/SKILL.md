---
name: omp-orca-roles
description: Use for requested code review or validation in dedicated fresh OMP terminals inside the current Orca workspace.
---

# Dedicated OMP role sessions

For the main OMP coordinator only. A worker already running as Review/Verify follows its assigned role and live dispatch preamble; it does not open another worker.

Read `../../docs/omp-orca-roles.md` for the installed controller's start/wait/status/release interface. Resolve that reference against this canonical skill directory. Load Orca's version-matched `orca-cli` and `orchestration` guides before controlling terminals or dispatch lifecycle; use the same selected executable throughout.

## Route the request

- A request to review code/diff in Orca opens `omp-review`; a request to validate/run checks opens `omp-verify`. Explaining roles, discussing an architecture proposal, or performing the implementer's initial targeted smoke does not automatically open workers.
- Keep the main OMP session as source owner. Use the exact current workspace, not a new worktree. Do not switch branches or run setup hooks.
- If not in an Orca-managed workspace, state that fact. Do not register another repo or silently substitute an in-process subagent for the requested visible terminal.

## Prepare the handoff

- Name explicit target paths, requirements/acceptance, base revision when relevant, existing checks and test environment, and do-not-touch constraints. Include relevant staged, unstaged and untracked changes; do not send the entire parent conversation or credentials.
- Save the bounded task and snapshot in checkout-local `.scratch/omp-orca-roles/`, not shared `.ai`. The controller records source/HEAD fingerprints.
- Pause source edits until the worker settles. Only one role check at a time in a shared workspace unless genuine independence and artifact/environment isolation have been established.

## Consume results

- Use `omp-orca-role` to open the fresh preset, prove readiness and assign an authoritative Orca Dispatch. Track the returned job/Task/Dispatch IDs; terminal title, idle state and input acceptance do not prove completion.
- Wait through Orca's event-driven inbox. Handle questions/escalations explicitly; do not acknowledge unread deliveries, guess answers, blindly retry, or kill an unknown/live worker.
- Accept only the current Dispatch's completion. Compare the source snapshot: changed source makes the result stale, even if commands passed.
- Review completion is not code approval. Preserve severity, file/line, trigger/impact and reviewed scope; a completed review can contain blockers.
- Verify completion must retain exact commands, exits, relevant runtime smoke and missing prerequisites. No required test/role/environment evidence means blocked, not passed. Tests/builds alone do not establish feature delivery.
- Workers do not fix source or tests, install dependencies, update snapshots, commit, push or deploy. Findings/failures return to the main implementer; fix only within the user's approved scope, then re-review/re-verify affected changes.
- Retain settled role terminals for the user's inspection. Release only through the controller's native Orca lifecycle action after authoritative settlement or an explicit cleanup request; never use broad terminal close or workspace deletion as recovery.

## Permission boundary

Presets restrict tools and instructions; Bash is not an OS read-only sandbox. Inspect check scripts for mutation and remote/data side effects before execution. Use isolated test targets and restricted accounts for permission checks, and obtain explicit approval for unsafe/external writes. Snapshot guards detect changes; they do not prevent another process from editing the checkout.
