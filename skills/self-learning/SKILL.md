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

## Capture (standing permission: create-only in AI Inbox)

The user granted a standing permission (2026-10-25): any agent may **create new notes** in `/Users/tualek/Tualek/AI Inbox/` without asking each time. Nothing else is covered.

- Allowed: create a new file `AI Inbox/<YYYY-MM-DD> - <Short Title>.md`. If that name exists, append ` (2)`, ` (3)`… — never overwrite.
- Not allowed without explicit approval: editing or deleting any existing note (including `AI Inbox/Home.md` and other candidates), writing anywhere else in the vault, promoting to `AI Memory/`, editing `RULES.md` / `knowledge/*` / `config/*`, or committing.
- One lesson per note. Before creating, search `AI Inbox/` and `AI Memory/Lessons.md` by keyword; if a match exists, still create a new note and put `related: [[<existing note>]]` in it (curation merges later; you do not edit the old one).
- Never include credentials, tokens, customer PII, sensitive payloads or raw transcripts.

Note template (fill every field; write `unknown` rather than inventing):

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/skills/self-learning/SKILL.md

```markdown
---
type: memory
status: candidate
scope: <global | workspace | repo:<name>>
created: <YYYY-MM-DD HH:MM +07>
agent: <claude-code | cursor-cli | grok-bot>
model: <provider/model id actually running>
source: <session id / card CU-xxx / MR !nnn / file path>
related: <[[existing note]] or none>
---

# <Short Title>

## Claim
<One self-contained lesson or preference.>

## Evidence
<User's words (quoted) or source path + heading; branch/HEAD/env if relevant.>

## Proposed rule
- [*] When <trigger>, <do/don't> — <why> (src: <source>, <date>; hits:1)

## Applies When
<Trigger, scope, exceptions.>
```

After creating it, tell the user the path and that it is a candidate awaiting review. Do not add it to `AI Inbox/Home.md`; curation links candidates. If the vault is not reachable, return the filled template in chat with the missing path; do not create a second journal in ai-main or tool memory.

## Review and promotion (needs user approval)

Read `~/Tualek/AI Memory/Home.md` and follow `AI Memory/Workflow.md` for verifying, merging, promoting and indexing. Promotion into `AI Memory/`, `RULES.md` or `knowledge/`, and any status change on an existing note, happen only after the user approves that specific change. Candidates are never deleted: they become `status: promoted | superseded | dropped` (or are moved to an archive folder with approval).

## Prompt rules (RULES.md and `## Rules earned`)

The vault is the journal; the rule lines agents load are short pointers to it.

- Format, one line: `- [*] When <trigger>, <do/don't> — <why> (src: CU-xxx / !MR, date; hits:N)`.
- Cross-repo rules go to `memory/lessons/RULES.md` (keep it ≤ 2 KB); rules for one repo go to that `knowledge/<repo>.md` under `## Rules earned`; rules for every OHO repo go to `knowledge/_ohochat-shared.md`.
- Reviewers tag each Important finding `repeat` (matches an existing line: propose `hits:N+1`) or `new` (propose a line), appended to `.scratch/<CARD>/lessons-proposed.md`. Nobody writes RULES.md or knowledge files from a review.
- At end of day (`clickup-card` step 9) the user approves, edits or drops each proposal; only then apply approved lines and bumps.
- Promotion: `hits` ≥ 3 and mechanically checkable (a command, path or pattern) → write a `core/checks/` script or guard rule with a test, add a `memory/lessons/COVERAGE.md` row, then remove the prompt line. Not checkable → keep it as a prompt rule.

## Source boundary

ai-main owns executable policies, skills, and checks; repository docs own code contracts. Tool-native memory may retain heuristic recall aids, but it is not the canonical curated source. The former `memory/lessons/LESSONS.md` is now a navigation pointer, not an append target.
