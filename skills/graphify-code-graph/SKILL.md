---
name: graphify-code-graph
description: Use when a question is about code structure across many files — who calls or imports a symbol, what a change impacts, which module owns a concern, how two things connect — in a repo with a graphify graph (graphify-out/graph.json), or when choosing between the code graph and ripgrep. Not for exact string/config lookups, secrets, or files outside the indexed corpus.
---

# graphify code graph

A tree-sitter AST graph of one repo, served by MCP as `mcp__graphify__*`. It answers structure questions in one call; it is never the source of truth for a symbol's text.

## Reach for the graph

- **Who calls / imports X** → `get_neighbors` with the node label; importers may sit on the file node.
- **Impact of changing X** → `get_neighbors` on `path::symbol`, then `query_graph` with `context_filter: ["call"]`.
- **Where a concern lives** → `query_graph` with plain keywords (BFS), then `get_community`.
- **How A connects to B** → `shortest_path`.
- **Architecture overview** → `god_nodes` / `graph_stats`, or the `graphify://report` resource.

Pass `project_path` to query another repo's graph; it must contain `<project>/graphify-out/graph.json`.

## Reach for ripgrep / ast-grep

- Exact literals, config values, `.env`, feature flags, error strings.
- Files outside the graph: untracked dirs, docs, fixtures, other repos.
- Confirming the line you are about to edit — every time, before editing.
- Dynamic `require`, string-built symbols, Mongoose models used by name: the graph lists the file node, not the runtime use.

## Read the result correctly

- `query_graph` is keyword-based: it splits the question into seeds and can explode at `depth` 2+. Keep `depth` ≤ 2 and a token budget, or use `get_neighbors`.
- Ambiguous names are refused with candidates; retry as `path::symbol` (e.g. `src/utils/objectid.js::convertObjectIdToString`).
- Anonymous default exports have no symbol node — anchor on the file name (`check-permission-member.js`).
- Check freshness: `graph_stats` prints built-at-commit vs HEAD. Stale → refresh before trusting impact answers.

## Refresh

```bash
~/ai-main/bin/gfy update .          # AST only, no LLM, no network
```

First build / full rebuild: `~/ai-main/bin/gfy extract . --exclude '*.md'` then `~/ai-main/bin/gfy cluster-only . --no-viz`. Only `bin/gfy` runs graphify here; the wrapper rejects `install`, `hook`, `add`, `prs`, `label`, `watch`, and any `--backend`.

Graph build is local; query results are sent to the model, so treat the graph like any other repo content.
