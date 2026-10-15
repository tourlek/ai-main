---
name: qwen-agent
description: Use when the user requests Qwen delegation for a bounded, low-risk task.
---

# Qwen delegation

1. Verify the task is mechanical, self-contained, and low-risk; keep architectural, debugging, and security judgment with the parent.
2. Discover a supported Qwen runner/model through the active harness. Do not assume a shell alias, fixed context window, background API, or permission mode exists.
3. Supply exact input/output paths, allowed scope, acceptance criteria, and relevant facts; the child may lack conversation context. Bound input and output to the actual task.
4. Use the harness's approved delegation protocol and worktree isolation for concurrent writers. Do not add broad persistent allow rules to avoid approval prompts.
5. Observe every child result and verify its changed files and checks before reporting success.

A launch failure blocks the delegated lane; report the exact failure and partial state. Retry only through the same approved protocol, or ask before selecting a different execution mode. Generic requests for cheaper work or delegation do not automatically select Qwen.
