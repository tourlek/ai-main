---
name: tdd
description: Use when the user requests test-first implementation.
---

# Test-first implementation

1. Identify the requested behavior and existing public test boundary. An approved test plan counts as confirmation; ask about a new boundary only when it changes the interface or materially expands scope.
2. Write one focused failing test that exercises the real behavior with an independently known expected result. Respect explicit restrictions on test-file edits; an approved implementation plan alone does not waive them during refactors.
3. Run the test and observe the expected failure before the fix, then implement the smallest change and observe the pass.
4. Repeat for the agreed behaviors, using each result to guide the next slice. Run relevant existing checks after a coherent change.
5. Refactor only within the approved scope while preserving behavior; do not start a separate architecture/review workflow automatically.

Prefer observable behavior over internal call assertions and mocks that hide the failure path. If no suitable test seam exists, report the gap and ask before introducing a new interface or harness. If the runner is unavailable, report the blocked red/green evidence instead of claiming TDD completed.
