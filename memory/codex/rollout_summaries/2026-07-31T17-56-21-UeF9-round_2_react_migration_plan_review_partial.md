thread_id: 019fb951-ea5f-7483-bc82-456377b2d2df
updated_at: 2026-07-31T18:07:44+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-56-21-019fb951-ea5f-7483-bc82-456377b2d2df.jsonl
cwd: /Users/tualek/ohochat/oho-backoffice
git_branch: master

# Round-2 review of the revised Nuxt-to-React migration plan was substantially investigated but not completed

Rollout context: Read the full 833-line plan and compared it read-only against `/Users/tualek/ohochat/oho-backoffice`.

## Task 1: Verify revised migration plan against the live repository

Outcome: partial

Preference signals:
- The user explicitly required the SHA result first, independent verification of all 18 claimed fixes, explicit answers to scrutiny points (a-e), file:line citations, and a plainly stated final verdict. Future reviews should preserve this exact structure and must not accept plan change-log claims without source verification.
- The user required a read-only consultation; no edits were made to the plan or repository.

Key steps:
- Read the entire plan at `docs/react-migration/backoffice-react-v2-plan.md` (833 lines), then inspected Git state, routes, components, styles, auth, endpoints, state, formatting, navigation, dependencies, and deployment files.
- Confirmed the live repository SHA and compared it with both user-mentioned SHAs.
- Traced active-menu matching, query serialization, route navigation, state coupling, and dependency usage rather than relying only on the plan text.

Reusable knowledge:
- Current worktree is `master@2f01fc94e906c8a33ff3634f65eaa648d2974ef1`, matching the round-1 SHA, not the plan’s stated baseline `27d674156fe47d402ed0fefa0bf168aee3b9dc08`. The plan author’s claimed verification against `27d674...` is therefore not grounded in the current checkout. The diff between the two SHAs adds the two external-message pages, helper/component, and endpoint/menu changes (1,216 lines).
- The live repo contains 12 page `.vue` files and 35 component `.vue` files. Plan §5.2 claims 34 components, so its “verified” inventory is wrong by one.
- `v-clipboard` is not actually used: `components/Business/ApiList.vue` and `ChannelTable.vue` call `navigator.clipboard.writeText` directly. Plan §5.5 incorrectly labels it as active, though retaining/replacing it is still unnecessary.
- The plan’s active-menu behavior is order-sensitive: `components/SubMenu.vue:121-131` compares raw query strings after removing `page`, while `layouts/default.vue:65-83` similarly reconstructs a string. A Zod passthrough schema preserves unknown keys but does not guarantee original query-key ordering or raw-string serialization. TanStack Router’s normal parse/validate/stringify path can normalize the query, so “passthrough” alone does not make this compatible. The plan needs an explicit raw-query/order-preservation or canonical set-comparison design plus tests.
- The live Axios dependency already preserves bracket syntax (`node_modules/axios/lib/helpers/buildURL.js:5-12`), contrary to the plan’s implication that a custom serializer is necessarily required; however, all `$populate[...]`, `$sort[...]`, `$gte/$lte`, and nested mutation requests still need per-page HAR verification.
- Navigation is broader than `Sidenav`/`SubMenu`: route changes also occur in `MyProfileDialog.vue:70`, `QuotaTable.vue:96`, `ApiList.vue:158`, payment detail, `WhitelistAppChecklist.vue:39`, `Payment/Dialog.vue`, and multiple page methods. Plan §13.2 only names a subset, so the shared `MIGRATED_PATHS` mechanism does not yet guarantee every Nuxt-to-React boundary, especially when `/business` and `/business/:id` flip at different times.
- Visual parity risk remains high. The live app uses a 488KB Element theme stylesheet and many Element-specific controls: `el-form`, `el-button`, `el-table`, `el-date-picker`, `el-dialog`, `el-upload`, `el-progress`, `el-switch`, etc. Re-skinning shadcn/Radix can reproduce tokens and primitives, but matching Element UI behavior and geometry—especially tables, date-range picker/sidebar, upload, select, dialog, pagination, and loading states—requires substantial custom wrappers and screenshot iteration. The plan’s style-guide gate is necessary but the estimate should not assume token porting is sufficient.
- The plan still leaves important decisions/audits open despite requiring a fully settled stack: §2.141-145 requires later extraction of theme metrics; §5.4 leaves `WEB_APP_URL`, `GTM_ID`, widget behavior, and runtime details to audit; §5.6 leaves multiple state modules and widget status to audit; §15.657-668 repeats “confirm/audit/decide” work. Appendix B explicitly leaves `refetchOnWindowFocus` undecided and says to change it if the team thinks it affects behavior.
- The live store has more active coupling than the proposed three Zustand fields suggest. `partners`, `business`, and `api_keys/api_keys_biz_id` are used across `business/_id.vue`, `create-api/_id.vue`, and `ApiList.vue`; `platforms.js` and `icon.js` provide active getters/assets. These cannot be dismissed as dead without completing the stated audit.
- The live plan’s “active endpoint inventory” omits important operation-level paths assembled at call sites, such as `/approve-payment/:id`, `/update-quota/:id`, `/api-key`, `/line-webhook/:id`, file upload/delete paths, and payment/business mutations. An endpoint-key inventory is not equivalent to a complete request-contract inventory.
- `CloseChatSchedulerConfigDialog.vue:43` imports `parseHTML` from jQuery but the inspected code does not use it; the plan correctly flags an audit, but this remains unresolved rather than verified.
- The plan’s “10 path” cutover count is plausible for top-level paths, but the migration also includes child routes and boundary navigation. Phase 5’s 3–4 weeks is only realistic if migration implementation, visual parity, HAR testing, UAT, bug bash, and production soak are heavily parallelized; the stated 20–30 working-day soak alone consumes most of that window. A conservative end-to-end estimate should be longer unless soak periods overlap.

Failures and how to do differently:
- The rollout stopped before producing the required final review. It did not complete the pass/fail list for all 18 fixes, the explicit a-e answers, or the final APPROVE/blocker verdict. Future work must finish those deliverables rather than stopping after exploratory evidence gathering.
- External web research on Element React, Zod, TanStack Router, cookies, and Error Reporting was exploratory and should support—not replace—repo-grounded citations. Avoid presenting proposals as verified facts.

References:
- `git rev-parse HEAD` → `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`; `git show -s` identifies `HEAD -> master, tag: v1.62.0, origin/master`.
- Plan baseline: `docs/react-migration/backoffice-react-v2-plan.md:7` → `27d674156fe47d402ed0fefa0bf168aee3b9dc08`.
- SHA diff: `git diff --stat 27d674...2f01fc...` → six files, 1,216 insertions; includes `pages/external-message-apps.vue`, `pages/external-message-whitelist.vue`, `api/externalMessageApps.js`, whitelist component, endpoint/menu changes.
- Plan sections requiring focused correction: §5.2 (34 vs 35 components), §5.3 (key inventory vs operation inventory), §5.5 (incorrect `v-clipboard` active claim), §5.6/§15 (unresolved audits), §7.4 (raw string active-menu matching plus Zod passthrough), §13.2 (incomplete navigation boundary coverage), §15 (timeline), Appendix B §823-833 (explicitly undecided query behavior).
