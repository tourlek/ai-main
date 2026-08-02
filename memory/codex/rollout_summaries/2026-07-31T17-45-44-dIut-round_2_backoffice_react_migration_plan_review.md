thread_id: 019fb948-34df-78c3-acf3-404943218769
updated_at: 2026-07-31T17:55:34+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-45-44-019fb948-34df-78c3-acf3-404943218769.jsonl
cwd: /Users/tualek/ohochat/oho-backoffice
git_branch: master

# Round-2 review of backoffice React migration plan was incomplete and did not produce a final verdict

Rollout context: Read-only adversarial review of `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md` (833 lines) against `/Users/tualek/ohochat/oho-backoffice`; no files were edited.

## Task 1: Verify revised React migration plan

Outcome: partial

Key findings:
- SHA mismatch is material. Current checkout is `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`, tagged `v1.62.0`; the plan claims baseline `27d674156fe47d402ed0fefa0bf168aee3b9dc08`. The current HEAD is a descendant of `27d6741`, but the plan’s claim that 12 routes were verified at that baseline is false: the two external-message pages and related files were added after `27d6741`. The prior round-1 SHA `2f01fc94e` is the actual current SHA.
- Inventory count is internally wrong: current source has 12 page routes and 35 Vue components, while §5.2 claims 34 components. The older `27d6741` tree had 10 pages and 34 components.
- Visual parity strategy is directionally sound but high-risk. shadcn’s open component code/Radix primitives permit direct styling, and the repo’s visual surface is much larger than the listed tokens: `assets/style/oho-theme/theme/index.css` is about 500 KB and contains hundreds of Element UI rules. Re-skinning shadcn/Radix to Element UI parity should be treated as a substantial design-system implementation, not a light theme pass; roughly 2–4 engineer-weeks for core primitives/style-guide, with additional page-by-page parity work. Directly porting existing theme CSS onto React markup or retaining an Element-like React component system would reduce visual risk, but neither is fully drop-in.
- §8.1 is not fully settled. It limits Zustand to three UI values, but live source also uses dashboard state (`time_period`, `channels`, `checked_channels`) in `store/modules/dashboard.js`, plus cross-route caches for `business`, `partners`, and `api_keys` between `pages/business/_id.vue`, `pages/create-api/_id.vue`, and `components/Business/ApiList.vue`. The plan defers these to a Phase-0 audit instead of choosing their final owners, contradicting the requirement that the stack be fully settled.
- §7.4 active-menu matching and passthrough can coexist only with an explicit raw-query preservation/canonicalization policy. Legacy matching compares the full query string after removing `page`, preserving order (`layouts/default.vue:65-83`, `components/SubMenu.vue:121-131`). TanStack Router’s default JSON-first serialization changes encoding/order, and Zod object schemas strip unknown keys by default; use a loose/passthrough schema plus custom query-string serialization and tests for exact legacy URLs. Otherwise the plan’s stated URL parity is not guaranteed.
- Additional uncovered contracts: `/external-message-apps` is a mutation-heavy page (create/edit/delete and duplicate validation) but is absent from §10’s mutation E2E list; `components/JeraForm.vue:652-664` performs a direct full-sync POST to a user-supplied JERA URL with `x-jera-api-key`, which is absent from the endpoint/contract inventory and §10 only lists connect/disconnect.
- Dependency audit claim is not fully grounded: `jquery` is imported at `components/Business/CloseChatSchedulerConfigDialog.vue:43`; `pretty-bytes` is imported in `pages/business/_id.vue`; `export-to-csv` is used in two pages; and several state/module usages remain active. These need explicit migration decisions rather than broad “audit” placeholders.
- Timeline is more realistic after changing Phase 5 to 3–4 weeks, but remains optimistic for a visual-parity migration of roughly 7,100 page LOC, 11,855 component LOC, a 500 KB Element theme, mutation-heavy screens, JERA integration, and production soak/rollback requirements. The plan needs explicit staffing/parallelism assumptions and a separate design-system contingency.

References:
- [1] `git rev-parse HEAD` -> `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`; `git describe --tags --exact-match HEAD` -> `v1.62.0`.
- [2] `git diff --stat 2f01fc94...27d6741` showed deletion/addition history for the two external-message pages; `git merge-base --is-ancestor 27d6741 HEAD` succeeded.
- [3] Plan sections: §5.1 routes, §5.2 components, §7.4 URL/Zod, §8.1 state, §10 mutation tests, §13 cutover, §15 timeline.
- [4] Ground-truth files: `layouts/default.vue:65-83`, `components/SubMenu.vue:121-131`, `store/modules/dashboard.js:4-29`, `pages/create-api/_id.vue:115-185,266-267`, `components/Business/ApiList.vue:136-177`, `components/JeraForm.vue:652-664`, `components/Business/CloseChatSchedulerConfigDialog.vue:43`, `assets/style/oho-theme/theme/index.css`.

Failures and how to do differently:
- The rollout stopped before completing all 18 claim checks, scrutiny answers, and the required explicit APPROVE/rejection verdict. Future review should finish the claim-by-claim table and state the final verdict at both the beginning and end.
- Do not treat the user’s revision changelog or baseline claim as verification; always compare the actual SHA, tree, imports, state consumers, and network calls.
