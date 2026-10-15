# Issue tracker: ClickUp (tickets) + GitLab (merge requests)

Work for `oho-api` is tracked in **ClickUp**, not GitLab Issues. Tickets use custom IDs like `OHO-5620` and live at `https://app.clickup.com/t/<task-id>`. Code and merge requests live on self-hosted GitLab: `https://gitlab.boonmeelab.com/oho/oho-api`.

## Conventions

- **Ticket IDs**: always refer to work by its ClickUp ID (`OHO-1234`). Put it in branch names (`fix/oho-1234-short-slug`) and MR titles.
- **Fetch a ticket**: use a ClickUp tool/MCP if this session has one. Otherwise ask the user to paste the ticket (title, description, subtasks, comments). Never guess ticket content.
- **Update the card's Activity (comments)**: post progress, triage, findings and handoff notes as a **comment on the ClickUp task** (it shows in the card's Activity). This is the default way to record anything on a ticket. Start each comment with a tag line, e.g. `[triage] ready-for-agent`, `[progress]`, `[root-cause]`, `[handoff]`, then 1–5 short lines.
- **No ClickUp tool in this session?** Write the exact comment text to `.scratch/<oho-id>/activity.md` and tell the user so Hub (which has ClickUp access) can post it.
- **Do not** create new tasks, change status, assignee, due date or tags without explicit approval. The user cannot add tags, so never rely on tags.
- **Merge requests**: GitLab via `glab` (`glab mr view`, `glab mr diff`, `glab mr note`). Never `glab mr create`, push, or merge without explicit approval. Never push to `master` or `main`.

## Merge requests as a triage surface

**MRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Post it as a comment in the existing ClickUp task's Activity. If it needs a brand-new task, write a draft under `.scratch/<slug>/` and ask the user first.

## When a skill says "fetch the relevant ticket"

Use ClickUp tooling if available; otherwise ask the user for the ticket content by ID.

## Wayfinding operations

Used by `/wayfinder`. Run it on local markdown (ClickUp is the source of truth only after the user copies it over):

- **Map**: `.scratch/<effort>/map.md`.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md` with `Type:` and `Status:` lines; link the ClickUp ID when one exists.
- **Blocking**: `Blocked by: NN, NN` near the top.
- **Claim / Resolve**: set `Status: claimed` / append `## Answer` and `Status: resolved`, then add a pointer to the map's Decisions-so-far.
