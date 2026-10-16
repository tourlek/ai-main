# Memory, self-learning and sync

- **Curated memory in Obsidian** — `~/Tualek/AI Memory/Home.md` is the shared entry point for long-term preferences, corrections, and cross-project decisions. Repo docs retain code contracts; `memory/` retains promoted rules and tool-specific histories, not a second curated journal.
- **Self-learning** — authorized captures go to the vault's `AI Inbox`, then through evidence review and curation. Executable shared rules stay in `RULES.md` and `config/workflow.md`; a memory note does not automatically become policy.
  Memory recall is triggered by prior-work questions, remembered preferences/decisions, or task continuation: read the vault index first, then only relevant notes. Users do not need to name the memory system; unrelated new tasks do not require loading the whole vault. Recall does not authorize memory writes.
- **Central worklog** — the `worklog` skill / `/worklog` command appends one-line entries to `logs/YYYY-MM.md`, synced across machines.

## Local sync without Git writes

`scripts/sync.sh` pulls only from a clean tree, never autostashes, rebuilds local outputs and then redeploys the harnesses listed in `config/harnesses.local` (see `config/harnesses.local.example`). With no selection it only rebuilds. It never commits or pushes; a dirty `ai-main` worktree skips the pull and continues from local state. Existing startup/scheduled hooks call `scripts/sync.sh`; default installation does not create or restart hooks.

`memory/` contains personal data, so this repo must stay **private**. Native tool caches under `memory/claude/` and `memory/codex/` are owned and rewritten by those tools through live links; do not rename or prune them by hand.
