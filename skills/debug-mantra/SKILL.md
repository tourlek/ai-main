---
name: debug-mantra
description: Use to investigate a reported failure through evidence, reproduction, and targeted checks.
---

# Evidence-led debugging

1. Confirm the reported symptom, target repo/ref, and available evidence. Trace the literal failure and authorization/validation path before adjacent code.
2. Attempt the smallest safe reproduction when the environment permits. Without a repro, continue read-only code/log/diff investigation; label hypotheses unverified and request only the missing evidence or access.
3. Choose a hypothesis supported by the trace and a check that could disprove it. Add alternatives when evidence is ambiguous, not to satisfy a fixed count.
4. Record each meaningful experiment's input, result, and what it rules out. Compare conclusions against earlier observations.
5. If a fix is requested and its plan approved, make the smallest change and run relevant existing checks. Respect restrictions on test edits; request approval before instrumentation or production actions.
6. Remove only temporary instrumentation created by this task when cleanup is approved. Report the cause, evidence strength, changes, checks run, and blocked acceptance criteria separately.

Apply these checks silently; recite a checklist only when requested. Missing reproduction limits certainty, not all investigation. Never claim a fix is validated without relevant observed results.

For intermittent failures needing a dedicated harness, read [reproduction.md](references/reproduction.md). Redact credentials and sensitive captured payloads before presenting evidence.
