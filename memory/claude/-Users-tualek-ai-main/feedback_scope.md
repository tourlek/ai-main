---
name: feedback-scope
description: "Stay strictly within the asked scope; don't change passing-QA UI/function during migration"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

When the user names a repo (`focus แค่ oho-web-app`, `อ่านแค่ web`, `เอาแค่ oho-webapp ไม่เอา backoffice มันแยก repo`), stay inside it until they re-expand scope. During refactors and the Nuxt 2 → 3 migration, preserve existing UI, function, and feature behavior. Don't change test files unless asked.

**Why:** User has repeatedly pushed back when AI changed style/function unnecessarily during the Nuxt migration: `i don't want change i want everything working same like a nuxt2 but use nuxt3`, `style is broken can recheck it`, `Why you revert code ???`. Once QA passed an existing behavior, do not "improve" it.

**How to apply:** If a frontend ask appears to need a backend change, surface the dependency and ask before editing the backend. For tracking/analytics added "only for testing", remove before commit. Never `git revert` prior work to clean up — only when explicitly asked. Canonical version lives at `~/ai-main/config/workflow.md`.
