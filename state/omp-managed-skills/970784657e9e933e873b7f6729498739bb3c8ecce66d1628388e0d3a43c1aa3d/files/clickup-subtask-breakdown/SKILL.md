---
name: clickup-subtask-breakdown
description: Break down a ClickUp OHO card into ordered dev subtasks via API with correct markdown rendering
---

# ClickUp Subtask Breakdown (OHO)

Use when user asks to break down / แตก subtask a ClickUp card (e.g. OHO-xxxx) into dev subtasks.

## Prerequisites
- Token lives in `~/.config/clickup/env` as `export CLICKUP_TOKEN=...` (chmod 600, sourced from `~/.zshrc`). Never print the token; verify with length only.
- Direct `app.clickup.com` links are login-walled and unreadable via `read`. Always use the API.
- Team `90182460598`; Dev Backlog list id must be read from the parent task's `list.id`, never hardcoded from memory.

## Read first (grounding)
1. `GET /api/v2/task/{id}` with header `Authorization: $CLICKUP_TOKEN`. Get: `name`, `custom_id`, `parent`, `list.id`, `assignees`, `url`, `subtasks`.
2. Parent description/AC/TCs come from the user pasting the card body (API `text_content` is often empty). If scope is ambiguous, ask before creating.
3. Check repo seams before writing subtasks: Mongoose schemas (`oho-api/src/models/`), Joi validators (`*.hooks.js` — unknown keys are rejected by default), existing UI entry points (e.g. `oho-web-app/pages/business/_biz_id/auto-reply/`), permission patterns (`$permission.validate`).

## Design the breakdown
- Split by **state transition**, not by layer (BE/FE) or by test case. Each subtask must be independently testable. Typical shape: `01 Foundation (model+client+observability, blocks rest) → 02/03 toggle transitions → 04 edit/sync+converter → 05 permission/UI → 06 matrix/E2E+DoD`.
- Naming: `NN [SCOPE] Short title` where SCOPE is `[BE]`, `[FE]`, `[BE+FE]`, or `[QA]`; `NN` = `01..0N` for ordering. No `[DEV] OHO-xxxx` prefix.
- Keep cross-cutting decisions in 01 (storage location, write rules, reconcile, logging/redaction). Surface card contradictions explicitly (e.g. Scope says update-in-place but TC says delete+recreate) instead of silently picking one.
- Storage rule of thumb: sync state (`flow_id`) lives on the `channels` doc (1 doc = 1 Page), written server-side via `channelModel` only after Meta confirms — never through `PATCH /channel`. Content/draft reuses existing fields; `is_used_in_ad` is read live, never cached.

## Write via API
- Create: `POST /api/v2/list/{list_id}/task` with `{"name", "markdown_content", "parent"}`.
- **Gotcha:** `description` param stores plain text (markdown shows raw). Always use `markdown_content` for formatted bodies.
- Headings are English only, no emoji/icons: subtask uses `## Goal` / `## Scope` / `## Acceptance`. Body details are Thai by default (concise, code identifiers in backticks). Never use Thai or emoji headings unless the user explicitly asks.
- Parent card body follows the same rule: headings `## Goal` / `## Subtasks` / `## Ordering` / `## Decisions` / `## Acceptance`, no emoji; details Thai by default.
- Verify after write: `GET /task/{id}?include_markdown_description=true`, confirm `name` exact-match, `markdown_description` non-empty, and `parent` == intended parent id.

## After delivery
- Tell user to hard-refresh the card (`Cmd+Shift+R`) — ClickUp subtask-list UI caches old names.
- Reply with one bullet per subtask: number + scope + what + link. Note ordering/parallelism (01 first, 02+03 parallel-safe) and any locked decisions or open questions.
