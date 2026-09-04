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

When the user names a repo, stay inside that repo until they re-expand scope explicitly.

## Agent skills

## Knowledge workflow

The Obsidian vault at `/Users/tualek/Tualek/OHO/` is the OHO second brain. For cross-repository/domain/architecture/incident/runbook work, use the Obsidian MCP to start at `OHO/Home.md` and read only the relevant linked notes before changing code.

Use repository documentation as the canonical source for code-adjacent behavior, API contracts, setup, and release procedures. Use Obsidian for durable cross-repository knowledge and summaries; keep the two linked rather than duplicating entire implementation documents.

### Issue tracker

Issues and specs live as local Markdown under `.scratch/<feature-slug>/`. See `OHO/Source Docs/agents/issue-tracker.md` in Obsidian.

### Triage labels

Use the canonical local status vocabulary. See `OHO/Source Docs/agents/triage-labels.md` in Obsidian.

### Domain docs

This is a multi-context workspace. Start at `OHO/Home.md`, then read the context relevant to the task. See `OHO/Source Docs/agents/domain.md` in Obsidian.
