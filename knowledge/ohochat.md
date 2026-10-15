# Workspace: ohochat (multi-repo root)

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Repo map

- `oho-web-app` — Vue 2 / Nuxt 2, mid-migration to Nuxt 3. The most active repo.
- `oho-api` — backend service
- `oho-developer-api` — public/developer-facing API
- `oho-backoffice` — internal admin UI
- `oho-webhook` — webhook ingestion
- `oho-flutter-mobile` — Flutter mobile app
- `script-oho` — helper scripts
- `jeraspec-api` — Gemini-backed work

## Repository routing

Use this map to identify the requested repo(s); the workspace root is not blanket scope. Before acting, inspect each target's branch/worktree and applicable repo/folder instructions. For an ambiguous target, ask; for an out-of-scope dependency, request expansion rather than scanning sibling repos.

For document routing, read `CONTEXT-MAP.md` in the primary workspace when available. For a repo task, follow that repo's context/docs index and only the matching spec or handoff; the workspace map does not expand repository scope.

## Knowledge workflow

Repository code and docs are canonical for current behavior and contracts. Consult the Obsidian vault at `/Users/tualek/Tualek/OHO/` only for requested vault work or cross-repo decisions/incident history missing locally. Start at `OHO/Home.md` and follow only relevant links.

Use repository documentation as the canonical source for code-adjacent behavior, API contracts, setup, and release procedures. Use Obsidian for durable cross-repository knowledge and summaries; keep the two linked rather than duplicating entire implementation documents.

### Issue tracker

Issue specs and branch-local plans live under the owning repo's `.scratch/<feature-slug>/`. Named ClickUp/Orca trackers own task status; shared `.ai` holds decisions and handoff evidence pointers, not another task queue. Historical reports follow the locations indexed in `CONTEXT-MAP.md`.

### Triage labels

Use the canonical local status vocabulary. See `OHO/Source Docs/agents/triage-labels.md` in Obsidian.

### Domain docs

For domain terminology unresolved by the target repo, consult `OHO/Source Docs/agents/domain.md` in Obsidian; ordinary local changes do not require a vault visit.
