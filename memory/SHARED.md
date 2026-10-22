# Shared Cross-Tool Memory

- Several AI sessions may share a dirty worktree. Re-read shared files before targeted edits and preserve concurrent changes.
- Current repo code/config establishes implementation facts; memories supply historical context. When required specs are inaccessible, ask instead of inventing requirements and continue checks that do not depend on them.

Project rules and corrections live in native auto memory (`~/.claude/projects/<repo>/memory/` -> `ai-main/memory/claude/`), loaded at session start; consult `~/Tualek/AI Memory/Home.md` (Obsidian) for prior-work recall.
