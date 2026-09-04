
## 2026-09 — Added unrequested Remote Config feature flag
- **Mistake**: hardened Meta Business AI with a Remote Config release gate even though the requested rollout does not use feature flags; user corrected: `remote config ไม่ต้องมีนะ เราไม่ทำ feature flag`.
- **Rule**: confirm rollout/configuration mechanisms before adding them; if the user says no feature flag, remove RC gates and preserve only the requested runtime behavior.

## 2026-09 — Reviewed the working tree instead of the named remote branch
- **Mistake**: started framing the Meta Business AI review around local uncommitted changes instead of `origin/tk-sprint-2616/feature/oho-1802-meta-biz-ai`.
- **Rule**: when the user names a review branch, pin that remote ref as the review subject and report local working-tree changes separately.

## 2026-09 — Expanded debugging scope beyond the named environment
- **Mistake**: investigated staging-3/production routing even after the useful evidence was available in staging-1; user corrected: `ดูแค่ใน staging-1 ก็พอ`.
- **Rule**: stay inside the explicitly named environment and stop once its root cause is established.
