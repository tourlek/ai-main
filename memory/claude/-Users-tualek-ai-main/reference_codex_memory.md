---
name: codex-memory-summary
description: Codex maintains a detailed user-preferences profile at ~/.codex/memories/memory_summary.md
metadata: 
  node_type: memory
  type: reference
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

Codex stores an auto-maintained user profile at `~/.codex/memories/memory_summary.md` plus per-task entries at `~/.codex/memories/MEMORY.md` and `raw_memories.md`. These contain many specific preferences (Smartchat handling, JERA contract truths, MongoDB Compass debugging conventions, MR review workflow nuances) that may not be reflected in `~/ai-main/config/`.

**When to consult:** Before answering a question about OHO / JERA / Smartchat / specific oho-web-app internals where the user has likely set a contract or convention in past Codex sessions. Search the file for the relevant feature name or repo path.

**How to apply:** Treat memory_summary.md as historical — the user may have changed their mind since. If a memory contradicts current code or a fresh user instruction, trust the user/code over the memory and consider updating `~/ai-main/config/workflow.md` to capture the canonical version for all tools.

Session transcripts are at `~/.codex/sessions/<year>/<month>/<day>/*.jsonl` for deeper digging.
