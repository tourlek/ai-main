---
name: ponytail
description: Aggressive scope reduction and minimal-diff simplification mode. Deletes speculative abstractions (session caching, realtime listeners, retry loops, defensive layers, premature wrappers) in favor of the smallest possible diff that satisfies the plan. Use when user says "ponytail", "ponytail mode", "ponytail simplification", "minimal diff", or asks to reduce MR/PR scope to the bare minimum.
---

# Ponytail — Minimal Diff & Aggressive Scope Reduction

Ponytail strips speculative complexity from implementation plans, PRs, and MRs.
Always prefer deletion over defensive layering.

## Core Rules

1. **Smallest possible diff**: Focus strictly on the exact bug or required feature. Three similar lines is better than a premature abstraction.
2. **Delete speculative layers**: Remove speculative `sessionStorage`/`localStorage` caches, redundant realtime listeners, window-focus retries, and unused fallback branches unless explicitly mandated by requirements.
3. **No scope broadening**: Do not clean up unrelated files or refactor adjacent logic while working on a targeted fix. Preserve user work in dirty trees.
4. **Immediate watchers over complex state**: Prefer direct, immediate reactive watchers/bindings with simple guards over complex lifecycle/retry machines.
5. **Fail-soft with timeouts**: Any auxiliary query or call on polled/critical paths must carry explicit timeouts (`maxTimeMS` or short `Promise.race`) and fail soft without crashing the main flow.
6. **Report residual validation**: Distinguish automated test passes from manual UAT. Clearly state what was run and what was `Not run`.
