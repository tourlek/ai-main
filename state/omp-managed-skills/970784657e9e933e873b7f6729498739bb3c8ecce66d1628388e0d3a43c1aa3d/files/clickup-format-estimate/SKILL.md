---
name: clickup-format-estimate
description: Format ClickUp OHO parent/subtask card bodies and apply realistic per-scope estimates
---

## When
Formatting an OHO parent card + ordered subtasks in ClickUp, or applying estimates.

## Parent body skeleton
```
## Goal
## Subtasks (| # | Card | ทำอะไร |, links)
## Ordering (```01 → (02 + 03) → 04 → 05``` + bullets)
## Decisions (groups: Architecture / Meta API contract / flow_id & naming / Error handling / Trade-off / Scope)
## Solution (table Operation|Timeout|เหตุผล + starting-budget note)
## Source (full raw data ONLY here)
## Result (JSON)
## Acceptance (grouped by target subtask)
```

## Subtask body skeleton
```
## Goal
## Scope (bold sub-groups; BE/FE split where relevant)
## Acceptance (AC- prefixed lines)
## Source (one-liner ref to parent ## Source; omit if no source)
```

## Estimates (PUT ms, 1h = 3600000)
Estimate each subtask from its real scope — never a fixed set. Weigh: existing code to reuse vs new logic, hardest path (SDK hooks, race/rotation, unobserved payloads like revoke), verification cost (stg matrix, real-device/manual cases). Set estimates on subtasks only; leave the parent's `time_estimate` empty so ClickUp rolls up the total itself. Record the subtask breakdown in parent ## Result as `estimates_ms` (no `parent` key).

## Write + verify
- Body: `PUT /api/v2/task/{id}` with `{"markdown_content": md}` (never `description` — stores plain text).
- Estimate: `PUT /api/v2/task/{id}` with `{"time_estimate": ms}`; clear with `{"time_estimate": None}`.
- Verify: `GET /task/{id}?include_markdown_description=true` → name exact-match, `markdown_description` non-empty, `parent` correct, `status` unchanged.
- Tell user hard-refresh (`Cmd+Shift+R`) — subtask-list UI caches old names.
