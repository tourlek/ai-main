---
name: code-first-refactor-qa
description: "Use for OHO refactors or API/data migrations when the user wants code-traced QA focus areas, owner verification, and browser screenshots with CSS overlays."
---

# Code-first refactor QA

Use this workflow when a refactor changes an API/data source, store, component, or page and the user wants to identify UI behavior to inspect. The skill does semantic tracing; `e2e/scripts/refactor-qa.mjs` owns repeatable capture mechanics. Start from changed code; screenshots confirm the map, they do not create it.

## 1. Bound the change

- Confirm the current repo, branch, and worktree state. Preserve concurrent and untracked user changes.
- Compare the requested base to the working tree. Include staged, unstaged, and relevant untracked source files.
- For changed exported symbols, use LSP references before searching/editing callers.
- Stay inside the requested repo. Read its local instructions before source files.

## 2. Trace code to visible behavior

For every changed contract or state value, follow the actual path:

`API/service → mapping/adapter → store or composable → caller → page/component/template → visible state`

Record one row per observable path with:

`changed file:symbol | old → new behavior/data | consumer page/route | exact DOM selector | expected request/state/role | edge or empty state`

Use precise source references and explain why each selector proves the changed behavior. Include permission gates, request routing, defaults/nulls, sorting/pagination, derived state, and errors only when changed code reaches them. Distinguish a data path with no rendered UI from a visible target; do not invent selectors for absent output.

## 3. Build the explicit capture map

- Copy `e2e/refactor-qa.template.mjs` to a per-refactor config. Define stable surface IDs, routes, ready selectors, necessary clicks, source-linked targets, expected requests, and Vuex state checks.
- Each target's `source` and `why` must connect the changed code to the expected rendered value; the runner cannot infer semantic impact from a diff.
- Set optional `expectedText` for exact rendered text (whitespace normalized) and `expectedValue` for an element's value. The runner checks each selected visible instance and records expected/actual values in the manifest. Derive these expected values from the pre-refactor UI or approved behavior; no baseline is inferred.
- Set feature flags in the config only when relevant. Assert the resulting store value and route/request so an injected flag alone is not counted as proof.
- Keep the capture read-only. Do not click mutating actions unless the task specifically requires an authorized write-flow test.

## 4. Run the shared capture runner

Run `npm run qa:refactor -- --config=e2e/refactor-qa.<scope>.mjs`. The runner enforces the OHO owner role from `oho_member.member.role` and business scope from `business._id`; it rejects non-owner expectations and exits nonzero on owner/business mismatch, failed UI/state/request checks, missing required selectors, or failed overlays. Do not weaken those gates to get screenshots.

The runner tags visible targets and draws outline boxes/chips as separate `div`s appended to `document.body`, positioned from `getBoundingClientRect()` plus scroll offsets. It redraws after scrolling before each viewport screenshot, then saves a clean full-page screenshot and a manifest under `test-results/refactor-qa/`. Reuse this runner rather than copying its screenshot/overlay logic into another feature script.

Use the intended owner session, normally `e2e/.auth/user-restricted.json`, then rely on the live role and business checks—not the filename—to establish identity. Capture every materially different state. For migrations, isolate unrelated flags and assert both the expected new route and absence of the obsolete route.

## 5. Inspect and report

- Open the generated point PNGs at native size. Verify every label encloses its intended field and the screenshot is readable; inspect the clean full-page image separately.
- Review each manifest `uiChecks` result alongside request and store-state checks. Treat mismatches, missing selectors, failed owner checks, and stale manifests as failures or `UNVERIFIED`, not passes.
- If app/API/auth setup is unavailable, finish the code-impact map, report the exact blocked proof and prerequisite, and do not restart shared services or claim old screenshots prove the refactor.

Leave a concise focus report in the existing QA pack: source-to-surface map, highest-risk checkpoints, output/manifest paths, checks actually run, and explicit unverified blockers. The report and config remain reviewable so a human can challenge the agent's semantic coverage.
