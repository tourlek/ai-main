---
name: ponytail
description: Use when the user requests Ponytail or minimal-diff simplification.
---

# Ponytail

1. Identify the exact requested behavior and approved scope.
2. Choose the smallest change that preserves required behavior; reuse existing paths before adding abstractions.
3. Remove only complexity shown to be unnecessary within the approved scope. Preserve user work, security checks, recovery guarantees, and required contracts.
4. Do not prescribe watchers, caching, retries, timeouts, or fail-soft behavior universally; consult relevant repo guidance only when those paths change.
5. Validate the affected behavior and report the actual checks and remaining gaps.

Done when the requested change is covered without unrelated cleanup; a smaller diff is not success if it drops a required protection.
