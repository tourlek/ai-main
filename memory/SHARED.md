# Shared Cross-Tool Memory

Distilled facts every AI tool loads at session start. Keep this file under ~40 lines —
details belong in `memory/claude/`, `memory/codex/`, or `knowledge/`.

- Commit messages: no `Co-Authored-By` / AI attribution lines — the user has rejected them repeatedly.
- Never push to `master`/`main` of work repos directly.
- `glab` JSON flag on this machine is `-F json`, not `--json`.
- Reports the user asks for go into a `.md` file at the repo root, not only the chat reply.
- The user runs multiple AI tools in parallel on the same repos — expect dirty worktrees and `.claude-worktrees/` dirs; never "clean up" work you didn't create.
- When spec/requirement documents are inaccessible, ask instead of guessing.
