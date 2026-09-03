
## 2026-09 — Added unrequested Remote Config feature flag
- **Mistake**: hardened Meta Business AI with a Remote Config release gate even though the requested rollout does not use feature flags; user corrected: `remote config ไม่ต้องมีนะ เราไม่ทำ feature flag`.
- **Rule**: confirm rollout/configuration mechanisms before adding them; if the user says no feature flag, remove RC gates and preserve only the requested runtime behavior.
