---
name: feedback-commits
description: Never commit without explicit authorization; split commits by logical scope
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

Never create a commit until the user explicitly says `commit it`, `create commit ให้เลย`, or equivalent. When authorized and changes span multiple intents/risks, split into logical commits with clear revert boundaries instead of one bundled commit. Use conventional prefixes (`fix:`, `feat:`, `refactor:`, `chore:`, `docs:`, `test:`, `style:`, plus `core:` when the repo convention uses it).

**Why:** User said `อย่า commit ก่อนฉันสั่ง` and pushed back when AI made a single bundled commit instead of following the plan's logical splits (`Oh i think you commit by commit following plan why only one commit`).

**How to apply:** Even after a plan is agreed and the user says `go` / `do it`, that means execute the implementation — not commit. Wait for an explicit commit instruction. Defer to the `git-commit-helper` skill when classifying diffs. Canonical version lives at `~/ai-main/config/workflow.md`.
