---
name: clickup-mr-crosslink
description: Use when linking a ClickUp card and GitLab MR while normalizing the MR description format.
---

# ClickUp ↔ GitLab MR crosslink

Use this workflow when a user gives a GitLab merge request and asks to update the card or make the MR description match the standard format.

## Workflow

1. Read the target MR with `glab mr view <iid> -R <repo> --output json`, then inspect `glab mr diff` and notes. Identify the source/target branches, actual change, validation already documented, and any existing ClickUp URL. Never invent a card ID.
2. Fetch the ClickUp card with the personal token from `~/.config/clickup/env` without printing the token. Use `include_markdown_description=true` and preserve the existing rendered Markdown.
3. Append a `## Merge Request` section to the parent card containing the MR title and URL. Keep the card status unchanged unless the user explicitly requests a status transition. Update with `PUT /api/v2/task/{id}` and the `markdown_description` JSON field; verify with a GET that includes `markdown_description`.
4. Normalize the MR body with factual, review-ready sections: `## Summary`, `## Changes`, `## Testing`, `## Risk / Impact`, `## Rollout / Migration`, `## Tracking`, and `## Reviewer Notes`. Preserve useful existing facts; do not claim tests, deploys, screenshots, or API checks that were not actually verified. Add the ClickUp parent/subtask links under `## Tracking`.
5. Update the MR with `glab mr update <iid> -R <repo> --description ... --yes`, then verify both the MR description and ClickUp card content. Do not push, merge, commit, or alter unrelated files unless separately requested.

## Safety

- Keep credentials and tokens out of command output and reports.
- Preserve existing card content and MR facts; make the smallest append/formatting change.
- Treat the MR description and ClickUp card as external writes; only perform them after the user explicitly requests the update.
- If the card link or required behavior is ambiguous, use the MR's existing description and branch context before asking.
