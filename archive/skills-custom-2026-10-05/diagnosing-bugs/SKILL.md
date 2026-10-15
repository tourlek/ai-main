---
name: diagnosing-bugs
description: Use for unresolved or intermittent failures that need a dedicated reproduction harness.
---

# Dedicated diagnosis

Use the shared [debugging workflow](../debug-mantra/SKILL.md), then its [reproduction branch](../debug-mantra/references/reproduction.md) for harness decisions. If the primary debugging skill is already loaded, continue its investigation rather than starting a second workflow.

Agree on scope before creating instrumentation or new harness files. A diagnosis-only request authorizes investigation, not a production fix. Report the best supported explanation, experiment results, and unresolved validation; no fixed hypothesis count or reproduction-rate threshold is required.
