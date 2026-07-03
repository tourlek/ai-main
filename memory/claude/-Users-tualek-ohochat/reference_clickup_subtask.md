---
name: reference-clickup-subtask
description: "How to create ClickUp subtasks via MCP — parent field, list_id, and the time_estimate-in-milliseconds gotcha"
metadata: 
  node_type: memory
  type: reference
  originSessionId: e20e5802-de92-4c22-9e4b-1e3f91b86bc4
---

## Creating a subtask
- Use `clickup_create_task` with `parent: <parent_task_id>` (internal id, not custom id like OHO-718).
- `list_id` is required even for subtasks — use the parent's `list.id` (get it from `clickup_get_task`).
- Resolve parent by custom_id: pass `OHO-XXX` to `clickup_get_task` with `subtasks: true` to also see existing children.

## Workspace
- OHO workspace_id: `90182460598`. Don't pass workspace_id directly to `clickup_get_task` using the workspace id as task_id — it errors "Team not authorized". Use the task's `custom_id` (`OHO-XXX`) or internal id.

## time_estimate gotcha
- The MCP tool description says "numeric value in minutes" — **it lies**. The ClickUp API stores time_estimate in **milliseconds**.
- Pass the value as ms: `"3600000"` = 1h, `"10800000"` = 3h, `"5400000"` = 1.5h.
- If you pass minutes, it silently saves (returns success) but shows 0 in the UI with the "Use natural language..." placeholder.

## Assigning
- `assignees` takes an array of numeric user IDs as strings. Tualek = `"113526352"`.
- Already-assigned-on-create means no second update needed.

## Deleting before recreating
- User said "ลบ subtask เดิมสร้างใหม่ได้เลย" counts as explicit authorization for that batch — no extra confirm needed.
