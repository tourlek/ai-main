# Dedicated reproduction branch

Use only when the basic trace cannot distinguish the failure and a harness is justified.

- Prefer an existing failing test, captured-request replay, or a small isolated script that reaches the actual symptom.
- Use the relevant public boundary; do not introduce architecture changes merely to obtain a test seam.
- For timing bugs, record the observed failure rate and use bounded repeated runs only in an approved safe environment. A low rate is evidence, not grounds for declaring the bug undebuggable.
- For performance, establish the requested baseline before tuning; do not add unrelated metrics or load tests.
- Pin controllable inputs where useful. Minimize only elements that narrow the investigation; exhaustive minimization is not a mandatory gate.
- Escalate from source/log inspection to a debugger or targeted instrumentation according to availability and risk, not a fixed tool sequence.
- Before production replay, stress, or instrumentation, confirm target, side effects, redaction, and explicit approval. Missing access blocks those actions, not independent read-only investigation.
- A valid regression check exercises the real failure pattern with an independent expected result. If unavailable, report the gap rather than writing a tautological test.
