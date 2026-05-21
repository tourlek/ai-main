---
name: gitlab-mr-description
description: Create clear GitLab merge request descriptions from an MR link, branch diff, commits, issue context, or pasted notes. Use when the user sends a GitLab MR URL and asks an AI agent to draft, improve, standardize, or fill a merge request description, including summary, changes, testing, risk, rollout, and reviewer notes.
---

# GitLab MR Description

Use this shared skill to turn a GitLab MR link plus available repo context into a review-ready description. Prioritize factual evidence from the MR diff, commit history, issue references, and local code over generic prose.

## Workflow

1. Gather MR context.
   - If the user gives a GitLab MR URL, use `glab` first when available and authenticated.
   - Prefer `glab mr view <id-or-branch> -R <repo-url> -F json` for title, description, state, source branch, target branch, labels, reviewers, assignees, and metadata.
   - Use `glab mr diff <id-or-branch> -R <repo-url> --raw --color=never` for the actual patch.
   - Use `glab mr note list <id-or-branch> -R <repo-url>` when comments or reviewer discussions may affect the description.
   - Use `glab api` for fields not exposed by `glab mr view`, such as commits or detailed changes, after deriving project path and MR IID from the URL or local repo.
   - Identify source branch, target branch, title, commits, changed files, diff summary, linked issue or ticket, and existing MR description.
   - Fallback to browser access, local branch context, or pasted diff only when `glab` is unavailable, unauthenticated, or blocked.
   - If no reliable MR context is available, ask for the diff, branch name, or relevant notes instead of inventing details.

2. Inspect the implementation.
   - Review changed files and important diffs directly.
   - Separate user-facing behavior, API/data contract changes, UI changes, refactors, tests, docs, config, migrations, and generated artifacts.
   - Look for risk areas such as auth, permissions, schema changes, background jobs, data migration, caching, async flows, and feature flags.

3. Choose the template.
   - Read `template.md` in this directory for the standard MR description structure.
   - Keep only sections that are useful for the MR.
   - Preserve repo-specific MR template headings if an existing `.gitlab/merge_request_templates/` template is present.

4. Draft the description.
   - Write concise bullets using concrete behavior and file-level evidence.
   - Mention validation that was actually run. If validation was not run, state `Not run` with a short reason.
   - Keep Thai or English consistent with the user's request or repo convention.

5. Return a paste-ready block.
   - Provide the final MR description in Markdown.
   - If uncertainty remains, list it outside the paste-ready block as open questions.
   - Do not claim tests, screenshots, migrations, or compatibility checks were done unless verified.

## Output Rules

- Lead with the paste-ready MR description when the user asks for the description directly.
- Prefer bullets over long paragraphs.
- Keep summaries outcome-focused, not implementation-noise-focused.
- Call out breaking changes and data migrations explicitly.
- For frontend work, include screenshots or visual verification only if available.
- For backend/API work, include contract changes, permission changes, and migration notes when relevant.
