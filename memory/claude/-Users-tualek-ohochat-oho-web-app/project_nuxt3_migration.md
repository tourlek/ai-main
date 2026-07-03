---
name: Nuxt 2 → Nuxt 3 migration in progress
description: oho-web-app is mid-migration from Nuxt 2 to Nuxt 3 on the `nuxt3` branch; parity with Nuxt 2 behavior is the success bar
type: project
originSessionId: 725d8dce-950e-49e0-b12f-2bd510788937
---
oho-web-app is being migrated from Nuxt 2 to Nuxt 3 / Vue 3 / Vuex 4 on branch `nuxt3` (master is the Nuxt 2 baseline). The user's explicit success criterion is full UI / function / feature parity with the Nuxt 2 build — no behavioral regressions.

**Why:** This is a framework upgrade, not a redesign. Users should not notice the migration.

**How to apply:**
- When fixing migration bugs, prefer minimal-change fixes that restore Nuxt 2 behavior over refactors or "improvements."
- Watch for Nuxt 2 → 3 hazards that produce silent breakage rather than build errors:
  - Plugin ordering: Nuxt 3 loads `plugins/*` in alphabetical filename order (no `nuxt.config.js` plugin array). Numbered prefixes like `07.auth.js` run before unprefixed files like `date-format.js`. Already bit us once: `informAlertShow` called `$formatDate.date()` before the provider plugin had run — fixed by renaming to `00.date-format.js`.
  - `useNuxtApp()` / `useRuntimeConfig()` only work inside the Nuxt context (plugins, composables, setup, dispatched-from-plugin actions). Calls during module load fail.
  - Vuex 4 actions: `$nuxt`, `this.$axios`, `context.app` no longer exist — store code must use `useNuxtApp()` / `useRuntimeConfig()`.
  - Auth module differences: `@nuxtjs/auth-next` ≠ `@sidebase/nuxt-auth`; `$auth.strategy.token.get()` shape may differ.
  - `process.client` / `process.server` → `import.meta.client` / `import.meta.server` (old form still works but is deprecated).
- Recent fix landed at commit a951dab6 ("test: restore jest suite under nuxt 3 / vue 3 / vuex 4") — tests are running again, treat them as a regression net.
