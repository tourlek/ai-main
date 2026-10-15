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

## Source boundary

ai-main owns executable policies, skills, and checks; repository docs own code contracts. Tool-native memory may retain heuristic recall aids, but it is not the canonical curated source. The former `memory/lessons/LESSONS.md` is now a navigation pointer, not an append target.
