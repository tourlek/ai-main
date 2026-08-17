# Repo: {{WORKSPACE_NAME}}

No dedicated knowledge file for this workspace yet.

Detected stack: {{DETECTED_STACK}}

- Global rules (style, workflow, profile, lessons) already load from the tool's own home config — this file carries repo-specific facts only, so nothing is duplicated.
- To give this workspace real knowledge: create `ai-main/knowledge/{{WORKSPACE_NAME}}.md`, then re-run `aimain link "{{WORKSPACE_PATH}}"`.
- Until then, treat the repo's own README / package manifest as the source of truth and ask before assuming conventions.
