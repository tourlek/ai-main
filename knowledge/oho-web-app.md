# Repo: oho-web-app

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Vue 2 / Nuxt 2 with Vuex, mid-migration to Nuxt 3. The most active repo.

## Nuxt 2 → 3 migration context

The migration targets behavior parity, not a UI redesign; shared migration and test-edit approval rules apply. Use `branch-perf-compare` only for requested measurements across named refs.

## Task context

For app work, read `CONTEXT.md` and the relevant entry in `docs/index.md` when present. Specs and branch-local evidence stay in `.scratch/<work-item>/`; historical reports are indexed under `docs/reports/`. When `.ai/README.md` exists, use its task-specific handoff pointers; before proposing QA, follow `.ai/QA.md` and compare the recorded candidate HEAD with the current worktree.

## Known trouble spots

- Smartchat: unread detection and mark-read are separate mechanics; refetch-skip race conditions have bitten before (`filtered_list_refetch_fn`).
- UI bugs that survive a scoped-style fix → inspect shared/global styles and selector precedence next.
- GTM has separate UAT and prod containers — verify which container before touching tracking.
- For analytics explicitly added only as this task's experiment, remove that instrumentation before an authorized commit; preserve unrelated tracking and other sessions' work.

## Rules earned

