# Lessons — mistakes every AI tool must not repeat

Loaded into every session of every tool. Append via the `self-learning` skill.
Format: one `##` entry per lesson — newest last. When this file exceeds ~50 lessons,
consolidate: merge duplicates, drop obsolete ones, keep the rule one line each.

## 2026-05 — Reverted user code to "clean up"
- **Mistake**: undid prior user work during a refactor; user: `Why you revert code ???`
- **Rule**: never revert or reset work you didn't create; only revert when asked.

## 2026-05 — Altered passing-QA behavior during Nuxt 3 migration
- **Mistake**: "improved" UI/logic while migrating; QA-passed behavior changed.
- **Rule**: migrations preserve behavior exactly; improvements need a separate ask.

## 2026-06 — Added Co-Authored-By to commits
- **Mistake**: appended AI attribution lines; user removed them repeatedly.
- **Rule**: no Co-Authored-By or AI-attribution lines in commit messages.

## 2026-06 — Used `--json` with glab
- **Mistake**: `glab ... --json` fails on this machine.
- **Rule**: use `glab ... -F json`.

## 2026-06 — Committed without being asked
- **Mistake**: auto-committed after finishing a change.
- **Rule**: commit only after explicit `commit it` / `create commit ให้เลย`. (Exception: `ai-main` auto-sync of `memory/` + `logs/` via sync.sh is authorized.)

## 2026-07 — Shipped negation query on array field (unread incident, prod slowdown)
- **Mistake**: unread feature counted with `read_by: {$nin: [null, id]}` — negation on a multikey field can't use any index, forcing a fetch of every contact in the business per poll; flag-on melted the prod Mongo cluster (8 Jul 2026).
- **Rule**: for hot-path queries on array fields, design for equality membership (store the inverse set, e.g. `unread_by`) — never `$ne`/`$nin`; verify with `explain()` that `docsExamined` scales with the answer, not the collection.

## 2026-07 — Unbounded countDocuments on a polled endpoint
- **Mistake**: badge-count `countDocuments` had no `maxTimeMS` and ran on every chat-list poll; slow counts (up to 173s) piled up and starved the cluster, and a count failure 500'd the whole list response.
- **Rule**: every query added to a polled/high-QPS path gets `maxTimeMS` + fail-soft (auxiliary data returns null, never fails the main response), sized against the biggest tenant, not the average.

## 2026-07 — Feature flag flipped for all tenants at once
- **Mistake**: `rt_unread_feature_enabled` was enabled globally at night with no per-business targeting; the flag check also cached one evaluated config for the whole process, so per-tenant conditions couldn't work anyway.
- **Rule**: DB-heavy features roll out behind per-tenant (business_id) targeting — canary a small tenant first and watch p95 + slow-query logs before widening.

## 2026-07 — One flag silently gated two independent features
- **Mistake**: `rt_unread_feature_enabled` gated both "unread" (read_by/unread_by) and "unresponded" (is_unresponded) writes/reads bundled together, and several write sites (customer message, member/bot reply, case close) weren't gated by the flag at all — they wrote unconditionally even when the feature was "off". User: `ปิด flag ก็ต้องไม่ทำงานเลย ... ต้องทำงานได้ปกติเหมือนเวอร์ชันก่อนหน้าที่ไม่มี feature นี้อยู่`.
- **Rule**: when a task names two sub-features together ("unread/unresponded"), give each its own independent flag/gate from the start, and grep every write path (not just the ones already touched) before declaring a flag-gating task done — "off must behave exactly like the feature never existed" includes writes, not just reads.

## 2026-07 — Deleted backfill scripts, blanking every existing unread badge
- **Mistake**: renamed `read_by`→`unread_by` (absent field = "not unread") and deleted the old `migrate-contact-read-by`/`backfill-contact-unread-30d`-style scripts, reasoning "no real data existed so no backfill needed" — but that assumption was already disproven the same day by a live incident showing `read_by` had real accumulated data in prod. Result: every pre-existing chat lost its unread state on deploy (badge silently went to zero for the whole install base) because nothing populated `unread_by` for history, only for messages arriving after deploy.
- **Rule**: renaming/inverting a field that gates user-visible state (badges, counters) always needs a backfill for existing documents, even when told "no real data" — verify that claim against production directly (e.g. `countDocuments` on the old field) before deleting the migration tooling that would have covered it; a field being absent is not the same as it being safe to leave unpopulated.

## 2026-07 — Reviewed the wrong branch worktree
- **Mistake**: reviewed `hotfix/v2.24.1/oho-unread-unresponded-flag-gate` when the intended scope was `feature/tk-sprint-2613/oho-1018-unrespone`; user: `focus review ที่ brach feature/tk-sprint-2613/oho-1018-unrespone รึป่าว`.
- **Rule**: before reviewing a multi-worktree repo, identify and confirm the target branch from the request and inspect only that branch's worktree.

## 2026-07 — Dismissed "last night's release" by checking too narrow a git window
- **Mistake**: while diagnosing a prod deep-link bug ("worked before, broke today"), I told the user twice it was NOT from last night's release — I checked `git log --since="<yesterday evening>"` on a few files, saw nothing, and concluded the release was innocent. The real culprit was a commit authored ~3 weeks earlier that sat in develop/release and only shipped to prod in last night's tag. Diffing the actual release tags (`git diff v1.112.0 v1.113.0 -- <path>`) immediately showed the regressing line (a removed `channel_id` param on the direct contact fetch, commit 2692b732).
- **Rule**: "did release X cause it?" is answered by diffing the deployed tags/revisions (`git diff <prev_prod_tag> <new_prod_tag>`), NOT by `git log --since=<deploy time>` — a release bundles commits authored long before it deploys. Also confirm what actually deployed (Cloud Run `gcloud run revisions list` for BOTH frontend and backend) before clearing a release; a backend deploy can hide behind a frontend-looking incident. And a log-line count "0 before / N after" is not proof of a behavior change if that log line itself only shipped in the new release.

## 2026-07 — Removed a request param that doubled as a permission scope
- **Mistake**: `channel_id` on `contact/chat/search` is both a UI filter ("which channels am I viewing") and the backend permission scope — `validateMemberChannelPermission` intersects the request's `channel_id` with the member's `allow_list` and, when it is absent, defaults it to `[]` → intersection empty → forces `$limit=0` → 200 with empty data. A frontend commit removed the param from the direct/deep-link contact fetch to "bypass the channel filter"; for `is_allowed_all` members the gate short-circuits so it looked fine, but every channel-restricted member silently lost the ability to open a room via link/refresh.
- **Rule**: before removing/omitting a request param, grep the server side for it — if any hook reads it for authorization/scoping, omitting it is a permission change, not a filter change. Widen the scope (send the member's full allowed set) instead of dropping the param. Absent-means-deny-all defaults are landmines: prefer a backend default of "the caller's allowed set", and make the deny path return an explicit error (403) rather than a 200 with empty data — a silent empty result is indistinguishable from "not found" and costs hours to diagnose.

## 2026-07 — Verified a permission change using only an admin account
- **Mistake**: a change to data-scoping was validated with an `is_allowed_all` admin, whose first-line short-circuit (`if (channelPermission?.is_allowed_all === true) return context`) skips the entire permission gate — so the broken code path was never executed in testing and shipped to prod, where it only hit channel-restricted members.
- **Rule**: any change touching data scoping, filters-that-are-also-permissions, or visibility must be exercised with a *restricted* account (limited `channel_permission.allow_list`, non-admin role, team-scoped `sale_visibility`), not just an admin — an admin run proves nothing about the gated path. Ask which account class the QA/verification used before calling such a change verified.

## 2026-07 — Rewrote a commit that was already merged into three branches
- **Mistake**: user asked to squash a branch's work into its previous commit; I checked only whether that commit was pushed (`git ls-remote`), saw it matched origin, amended it — then found `96554599` was already merged into `feature/tk-sprint-2614/develop`, `staging-4`, and another feature branch, so the amend orphaned a commit that three branches referenced and would have duplicated its content on the next merge.
- **Rule**: before amending/rebasing/squashing any commit, run `git branch --contains <sha>` (and `git branch -r --contains <sha>`) — "it's only pushed to my own branch" is not the same as "nothing else has merged it"; if anything else contains it, refuse the squash and add a new commit on top instead.

## 2026-07 — Ran a git command with an implicit target after the branch had changed under me
- **Mistake**: ran `git branch --set-upstream-to=origin/<feature>` with no branch argument to fix the feature branch's upstream, but the user had switched HEAD to `master` mid-session — so it set **local master** to track the feature branch. Caught it only because `git status -sb` printed `## master...` in the output. Earlier in the same session I also read `git rev-parse @{u}` as the feature branch's upstream when HEAD was already on master.
- **Rule**: git commands that default to "current branch" (`branch --set-upstream-to`, `reset`, `push`, `branch -f`) always take an explicit branch argument, and check `git branch --show-current` before any config/ref write — the user runs parallel AI tools and switches branches mid-session, so HEAD is never assumed to be where you left it.
