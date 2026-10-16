# OMP runtime

OMP is one supported harness; Codex and others consume the same safety baseline. Follow the active harness's tool contracts and approval boundaries. Skills supply task workflows, not permission to bypass those contracts.

- Use native structured tools for reads, searches, edits, code intelligence, and delegation when available. Use shell commands for running programs; prefix compatible commands with `rtk`, not interactive commands or commands whose semantics change.
- Resolve the target from the current checkout and the user's named repo. Consult `{{AI_MAIN}}/knowledge/` only when local instructions cannot resolve repo identity or task-relevant cross-repo facts; read only the relevant entry.
- Use Orca's version-matched CLI guide for Orca-managed worktrees and terminals. A shared `.ai` directory holds decisions and handoff evidence; branch-specific specs and scratch stay in the checkout.
- Use a CodeGraph index only for its own checkout and after checking freshness; `.codegraph` is worktree-local, never a shared `.ai` symlink. Initialize or rebuild only when the task needs relationship queries; missing indexing does not block native search or language-server tools.
- OMP owns runtime managed skills and local memory. Repository snapshots are backups, not a second discovery source. Do not overwrite runtime files from a backup without explicit restoration approval.
- Planning, estimation, Senior alignment, and retrospective: read `{{AI_MAIN}}/docs/working-checklist-okr.md` before the applicable work. It defines the user's think-before-code checklist, delivery target, and evidence rules; it does not authorize extra scope or tracker writes.
- Main coordinator: when the user requests code review or validation in Orca, use `skill://omp-orca-roles` to open a fresh same-workspace role terminal and collect its report. Already-dispatched workers do not route another worker; the implementer's initial targeted smoke stays local.
- Heavy implementation work that benefits from an isolated checkout goes as a full handoff to a fresh Orca worktree per the version-matched orca-cli guide: `worktree create --name <task> --no-parent --agent omp --prompt "<brief>"` (worker = OMP/oh-my-pi). Supervised multi-step coordination uses the orchestration guide. Same-workspace review/verify stays on omp-orca-roles; one writer per checkout.
