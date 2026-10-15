---
name: scrutinize
description: Use when the user requests an adversarial review of a plan or change.
---

# Scrutinize

1. State the intended outcome from available evidence. If unclear, ask about the uncertain decision and continue checks independent of it.
2. Consider whether a smaller approach achieves the same required behavior; retain security, compatibility, and recovery guarantees. Explain a materially better alternative without expanding implementation scope.
3. Trace the claimed behavior against real code/contracts within the approved scope, including directly affected unchanged paths.
4. Challenge assumptions with concrete counterexamples or focused checks, not an exhaustive checklist unrelated to the change.
5. Report each finding with evidence, consequence, and a minimal correction. Distinguish a spec claim from verified behavior; label uncertainty rather than forcing a verdict.

If `code-review` is already active, add this adversarial pass to its findings instead of restarting context gathering. This skill grants no edits, external posting, or deployment authority.
