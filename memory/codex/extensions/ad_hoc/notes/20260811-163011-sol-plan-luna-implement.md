# Default model workflow preference

- Use `gpt-5.6-sol` as the primary conversation model for consultation, investigation, grilling, decision-making, planning, and final review.
- Once the user confirms the plan and authorizes implementation, hand implementation to a new Codex task using `gpt-5.6-luna` with reasoning effort `max`.
- Pass the approved contract, current working-tree state, completed partial work, tests, constraints, and no-commit rule to the Luna task.
- Sol should monitor/review Luna's result and report evidence back to the user.
- If `gpt-5.6-luna` with `max` is unavailable, stop and tell the user; do not silently substitute another model.
