---
name: self-learning
description: Use to record durable, non-duplicate lessons from repeated corrections or costly mistakes.
---

# Self-Learning

## Overview

Curated long-term memory lives in Obsidian at `~/Tualek/AI Memory/Home.md`. Read its linked workflow before capturing or consolidating a lesson; it owns the storage, review, and promotion process.

## When to write a lesson

- The user corrects the same thing a second time, or says `บอกแล้วว่า X`.
- The user pushes back on something you did (`i don't want change`, `style is broken`, `Why you revert code ???`).
- You discover mid-task that an assumption you acted on was wrong and it cost rework.
- A post-mortem (`/post-mortem`, `debug-mantra`) identifies a wrong step you took.

One-off typos and existing repo contracts do not need another memory. Task status stays in the user-named tracker.

## Capture and review

1. If the user has not authorized memory writes, propose the lesson in chat. A correction alone does not authorize a vault write.
2. With authorization, read `~/Tualek/AI Memory/Home.md` and follow `AI Memory/Workflow.md` for duplicate search, candidate capture, evidence, curation, and index updates.
3. Tell the user the saved note's path and review status.

If the vault is inaccessible, return the candidate in chat with the missing path; do not create a second curated journal in ai-main or tool memory.

## Prompt rules (RULES.md and `## Rules earned`)

The vault is the journal; the rule lines agents load are short pointers to it.

- Format, one line: `- [*] When <trigger>, <do/don't> — <why> (src: CU-xxx / !MR, date; hits:N)`.
- Cross-repo rules go to `memory/lessons/RULES.md` (keep it ≤ 2 KB); rules for one repo go to that `knowledge/<repo>.md` under `## Rules earned`; rules for every OHO repo go to `knowledge/_ohochat-shared.md`.
- Reviewers tag each Important finding `repeat` (matches an existing line: propose `hits:N+1`) or `new` (propose a line), appended to `.scratch/<CARD>/lessons-proposed.md`. Nobody writes RULES.md or knowledge files from a review.
- At end of day (`clickup-card` step 9) the user approves, edits or drops each proposal; only then apply approved lines and bumps.
- Promotion: `hits` ≥ 3 and mechanically checkable (a command, path or pattern) → write a `core/checks/` script or guard rule with a test, add a `memory/lessons/COVERAGE.md` row, then remove the prompt line. Not checkable → keep it as a prompt rule.

## Source boundary

ai-main owns executable policies, skills, and checks; repository docs own code contracts. Tool-native memory may retain heuristic recall aids, but it is not the canonical curated source. The former `memory/lessons/LESSONS.md` is now a navigation pointer, not an append target.
