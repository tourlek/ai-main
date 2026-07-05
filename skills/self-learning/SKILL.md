---
name: self-learning
description: Capture mistakes and user corrections as permanent lessons shared across every AI tool. Use whenever the user corrects you, pushes back (`บอกแล้วว่า`, `Why you revert code ???`, `i don't want change`, repeated correction), when you discover your own mistake, or after a debugging post-mortem reveals a wrong assumption you held.
---

# Self-Learning

## Overview

Every AI tool (Claude Code, Codex, Cursor, Gemini) loads `~/.ai-memory/lessons/LESSONS.md` at session start. Writing a lesson there means no tool repeats the mistake — on any machine, since the file lives in the `ai-main` git repo and syncs automatically.

## When to write a lesson

- The user corrects the same thing a second time, or says `บอกแล้วว่า X`.
- The user pushes back on something you did (`i don't want change`, `style is broken`, `Why you revert code ???`).
- You discover mid-task that an assumption you acted on was wrong and it cost rework.
- A post-mortem (`/post-mortem`, `debug-mantra`) identifies a wrong step you took.

Do NOT write a lesson for: one-off typos, things the repo/docs already state, or task-specific facts (those go to project memory instead).

## How to write it

1. Read `~/.ai-memory/lessons/LESSONS.md` first — if an existing lesson covers it, sharpen that entry instead of appending a duplicate.
2. Append at the end, newest last:

```markdown
## <YYYY-MM> — <short title of the mistake>
- **Mistake**: <what actually happened, one sentence, quote the user's words if they corrected you>
- **Rule**: <the behavior to follow from now on, one imperative sentence>
```

3. Tell the user in one line that the lesson was saved.

## Consolidation

When the file exceeds ~50 lessons (or the user asks to consolidate): merge duplicates, delete lessons made obsolete by newer rules or tooling changes, and compress each survivor to its Rule line where the Mistake context no longer adds value. Never silently drop a lesson the user explicitly asked to remember.

## Scope boundary

Lessons are cross-tool behavior rules. Repo facts go to `ai-main/knowledge/<repo>.md`; personal/project facts go to the tool's own memory dir (already synced under `ai-main/memory/`).
