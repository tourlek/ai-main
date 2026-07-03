---
name: oho-nuxt-migration
description: "oho-web-app is mid-migration from Nuxt 2 to Nuxt 3 — preserve UI/function, compare perf between branches"
metadata: 
  node_type: memory
  type: project
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

`oho-web-app` (the biggest project, ~62% of Claude prompts) is being migrated from Vue 2 / Nuxt 2 to Nuxt 3. Active perf-comparison branches include `origin/uat`, `origin/nuxt3`, `perf/nuxt3-ram-reductions`, and `feature/tk-4160-upgrade-nuxt-version`.

**Why:** The migration started broken — user merged main → nuxt3 manually then asked AI to finish it. Style and feature regressions are the biggest pain. The `perf/nuxt3-ram-reductions` branch exists because Nuxt 3 was using more RAM locally than the running Nuxt 2 UAT.

**How to apply:** For any `oho-web-app` change during this period, the default expectation is "must behave the same as the QA-passed Nuxt 2 UAT". Use the `branch-perf-compare` skill (in `~/ai-main/skills/`) when asked to compare perf across branches. The good-style reference branch was once `backup/nuxt3-pre-master-merge-2026-05-08`. Senior reviewer comments on `oho-web-app` MRs (e.g. MR 844, 846) are the implementation scope — read them via `glab mr note list` before changing code.
