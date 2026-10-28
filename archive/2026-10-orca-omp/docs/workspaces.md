# Shared brain in a multi-repo workspace

The shared core governs safety and approvals; workspace roots route to repos; repo and nested-folder instructions specialize their own paths. Starting at `ohochat` does not authorize scanning every child repo. Follow applicable ancestor/nested instructions without loading unrelated Markdown or recursively traversing references.

See [the adjustment summary](history/shared-brain-adjustment-summary.md) and [the adapter contract](../adapters/README.md). `AGENTS.md` documents ai-main's own source ownership and local validation. Installer/sync deployment is separate from editing these sources and needs an explicitly scoped rollout.

## Task sessions and document placement

Start or resume from the issue, repo/worktree, branch/HEAD, approved scope, expected behavior, and acceptance checks. The agent discovers available state; a task switch rechecks that anchor. Keep one writing owner per checkout, and distinguish implementation, review, QA, and release evidence.

`config/workflow.md` defines placement for requested files; read-only analysis stays in chat unless a report file is requested. Branch-local specs/plans and working artifacts follow the repo's `.scratch/<work-item>/` convention; durable system/code docs stay in `docs/`; historical reports use the indexed domain location, normally `docs/reports/<domain>/`. Shared `.ai` contains cross-worktree decisions and revision-specific handoff pointers. Root harness entrypoints and canonical indexes remain; root reports require an explicit request. Preserve active legacy plans until their owner confirms migration, and update references when moving historical snapshots.

Named ClickUp/Orca trackers own task status. A handoff records the candidate revision, role/environment, actual checks, artifact paths, blockers, and next action; it is not a second task queue. Evidence from an older HEAD does not establish readiness for the current candidate.

## Shared `.ai` context in Orca worktrees

`./bin/aimain context link <worktree>` links `<worktree>/.ai` to
`ai-main/context/<knowledge-name>/`. It uses the registered knowledge name,
then the git remote or repo name; use `--knowledge <name>` if detection is
ambiguous. The name must already exist under `knowledge/`. First use creates
`README.md`, `decisions/`, and `handoffs/` in that repo's central context.
Store only durable cross-worktree decisions and per-change QA handoffs there;
feature specs and current code behavior stay in the owning repo. Before QA,
run a task-specific smoke of the changed behavior in the candidate worktree,
then record the revision, environment, observed result, and safe artifact
location in `.ai/handoffs/<work-item>.md`. A command that merely starts, a
test-only pass, or a synthetic fixture does not establish release readiness.
All worktrees for the same repo see edits immediately, so keep branch-local
scratch and credentials out of `.ai`. `context/` is ordinary git content, unlike
the automatic `memory/`/`logs/` sync; publishing needs an authorized commit.

For each repo in Orca, set **Settings → Repository → Auto-run commands on
worktree create** to:

```sh
"$HOME/ai-main/bin/aimain" context link "$PWD"
```

Use the absolute `ai-main` path for the machine running Orca; `$PWD` must be
the newly created worktree root. Orca's `--setup skip` bypasses setup hooks.
Run the same command once in the primary checkout and in existing worktrees
that need the link. This command does not register worktrees, overwrite an
existing `.ai`, or replace repository-owned instruction files. Orca's
**Worktree Shared Paths** can APFS-clone rather than symlink on macOS; the
setup command is required when a symlink specifically is desired.

## CodeGraph in Orca worktrees

Share `.ai` for documents, but keep `.codegraph/` local to each checkout: different branches need different indexes. Use indexing for code-flow, callers, impact, or broad refactor work; skip it for small edits, docs, or short-lived worktrees. Do not add `.codegraph` to Orca shared/symlink paths.

```bash
codegraph init --yes /absolute/worktree    # first index; parses this checkout
codegraph status --json /absolute/worktree
codegraph sync /absolute/worktree          # pre-flight freshness for CLI-only use
```

The installed CodeGraph guide ties automatic watching to an active MCP session; `init` alone does not establish that OMP has a watcher. Keep native search/LSP available when no index exists. An isolated two-checkout smoke with shared `.ai` links returned only `alphaBranch` from the first index and only `betaBranch` from the second; no live Orca worktree was indexed or reconfigured.
