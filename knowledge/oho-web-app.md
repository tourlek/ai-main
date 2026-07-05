# Repo: oho-web-app

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Vue 2 / Nuxt 2 with Vuex, mid-migration to Nuxt 3. The most active repo.

## Nuxt 2 → 3 migration rules

- Preserve existing UI, function, and feature behavior exactly. The user has said `i don't want change i want everything working same like a nuxt2 but use nuxt3` and pushed back when AI altered passing-QA behavior.
- Don't change test files during the migration unless explicitly asked.
- Compare performance across branches with the `branch-perf-compare` skill when asked.

## Known trouble spots

- Smartchat: unread detection and mark-read are separate mechanics; refetch-skip race conditions have bitten before (`filtered_list_refetch_fn`).
- UI bugs that survive a scoped-style fix → inspect shared/global styles and selector precedence next.
- GTM has separate UAT and prod containers — verify which container before touching tracking.
