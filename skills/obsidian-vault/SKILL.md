---
name: obsidian-vault
description: Use for Obsidian work, curated long-term memory, or cross-repo knowledge missing from repo docs.
---

# Obsidian Vault

## Scope and authority

- Vault: `/Users/tualek/Tualek/`.
- Curated long-term memory starts at `AI Memory/Home.md`; capture and consolidation follow its linked workflow.
- OHO discovery starts at `OHO/Home.md` and follows only links relevant to the task.
- Repository documentation is canonical for code behavior, API contracts, setup, and release procedures.
- Obsidian owns curated long-term preferences, corrections, and cross-project decisions, plus cross-repo context and summaries.
- Link to canonical repository material instead of copying entire implementation documents into the vault.

## Primary workflow

Use the configured Obsidian MCP server when available:

1. List vaults when the vault id is unknown.
2. Search filenames/content/tags with a narrow query and bounded result count.
3. Read only the matching note or linked section; paginate bounded reads when needed.
4. When OHO vault context is needed, start at `OHO/Home.md`, then follow only the relevant link; ordinary local code work does not require a vault read.
5. Before editing an existing note, read it and pass its latest etag to the edit operation when supported.

Use MCP discovery when exact tool names are not visible.

## Write policy

- `create`, `edit`, and tag operations require an explicit user request to write or organize notes.
- `move` and `delete` always require tool approval.
- Never sync Obsidian content back over repository documentation automatically.
- Preserve the local folder's existing naming and frontmatter conventions.
- For a new standalone note without a local convention, use Title Case and add relevant `[[wikilinks]]`.
- Use index notes to expose navigation, but preserve structured OHO folders such as `OHO/Source Docs` and `OHO/Indexes`.

## Shell fallback

Use direct filesystem search only when the Obsidian MCP is unavailable. Keep searches bounded to the vault and exclude `.obsidian`, trash, caches, and generated/plugin state.

```bash
find "/Users/tualek/Tualek" -path '*/.obsidian' -prune -o -name '*.md' -iname '*keyword*' -print
rg -l --glob '*.md' --glob '!.obsidian/**' 'keyword' "/Users/tualek/Tualek"
```

Do not run an unbounded search from the user's home directory.
