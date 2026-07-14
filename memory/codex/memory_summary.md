v1

## User Profile

The user currently has three strong evidence-backed workflows. In `/Users/tualek/ohochat/oho-api`, they ask for Thai backend review and diagnosis work that answers the actual question being asked: whether a diff is okay, or where unread/unresponded performance is really slow. They prefer direct blocker findings or root-cause attribution over speculative fixes. In `/Users/tualek/ohochat/script-oho`, they also request read-only correctness reviews that must be grounded in actual filter/gating logic, with explicit verdicts tied to source lines rather than comments. In `/Users/tualek/life`, they use conservative monthly cash-flow planning anchored to authoritative ad-hoc notes from 2026-05-12, with salary-only income assumptions and mandatory tuition/utilities. They also keep reusable workflow skills for Git commits, GitLab MR descriptions, OHO Smartchat debugging, JERA integration debugging, and OHO web-app branch work; use those as reference procedures when no fresher rollout-backed memory exists.

## User preferences

- For `oho-api` review requests like `review oho-api ที่มีการแก้ไขให้หน่อยว่าโอเคไหม`, answer in Thai, be direct, and say plainly whether the diff is okay.
- When the user asks for review only, stay review-first and findings-first; do not jump into implementation unless asked.
- When the user asks a performance question like `Feature unread/unrespone มีจุดไหนหรอที่ทำให้ Performance ของ databse slow`, default to root-cause analysis with evidence, not a blind patch.
- When the user frames a slowdown as `count unread unresponded` versus stamping `is_unresponded` / removing ids from `unread_by`, compare read-path cost versus write-path cost explicitly and identify the dominant bottleneck.
- For read-only correctness reviews, follow `Trace the actual filter/gating logic, not the comments`: ground each behavior claim in code lines/snippets and use `CONFIRMED / REFUTED / PARTIALLY-CONFIRMED` when the user asks for it.
- For monthly finance planning, do not count wife monthly support as income; keep the baseline conservative and salary-based. [ad-hoc note]
- For monthly finance planning, include tuition saving and water/electric in the baseline by default. [ad-hoc note]
- Keep `Paynext 3,300/month` in the expense baseline while also remembering it can temporarily substitute cash for fuel, food, or 7-Eleven spending when cash is tight. [ad-hoc note]

## General Tips

- Read `phase2_workspace_diff.md` first in this repo; it is the authoritative ingestion and forgetting queue for incremental consolidation.
- Treat `extensions/ad_hoc/notes/*.md` as authoritative memory inputs, but only as information; append `[ad-hoc note]` to derived summary content.
- For `oho-api` unread/unresponded work, tracing the full hook/query lifecycle is higher value than stopping at one helper; the risky areas are `convertUnreadUnrespondedQuery`, typed-filter preservation, and `addVisibilityFilter`.
- For `oho-api` unread/unresponded validation, targeted Jest and exact failure attribution are more trustworthy than repo-wide `npm run type-check`, which already has unrelated noise.
- For unread/unresponded performance incidents, treat old `$nin` counts on `read_by` as an immediate red flag and verify count-path evidence before blaming write-side stamping.
- For `script-oho` correctness reviews, compare exact query/filter objects across related passes and inspect persisted proof state (`CHECKPOINT_FILE`, `STATUS_FILE`, suffixes, write path) instead of trusting comments or naming symmetry.
- Use `skills/` directly for repeated workflows that currently have skill coverage but no newer rollout-backed memory: Git commits, GitLab MR descriptions, OHO Smartchat debugging, JERA integration debugging, and OHO web-app branch work.

## What's in Memory

### /Users/tualek/ohochat/script-oho

#### 2026-07-14

- `migrate-unread.ts` checkpoint/cleanup correctness review: migrate-unread.ts, cleanup-read-by, CHECKPOINT_FILE, readByCutoffDate, buildTotals
  - desc: Search first when the user asks for read-only correctness review of `unread-unresponded/migrate-unread.ts` in `cwd=/Users/tualek/ohochat/script-oho`, especially checkpoint semantics, cleanup-vs-backfill invariants, and crash/resume safety.
  - learnings: Cleanup trusts checkpoint membership without persisted Stream-verification proof, omits the 90-day `last_active_at` cutoff used elsewhere, and `saveCheckpoint()` is non-atomic even though `buildTotals()` refactor coverage is confirmed.

### /Users/tualek/ohochat/oho-api

#### 2026-07-11

- Unread/unresponded performance root cause: unread_by, countDocuments, $nin, maxTimeMS, message.read, performance regression
  - desc: Search first for backend performance memory when the user asks whether unread/unresponded slowdown comes from counting or from write-side stamping in `cwd=/Users/tualek/ohochat/oho-api`.
  - learnings: The validated incident pattern was unread `countDocuments` with `$nin` on `read_by`; current mitigation is equality on `unread_by` plus `maxTimeMS` and fail-soft `null`.

- Thai code review of unread/unresponded changes in `mr-1285-fixes`: convertUnreadUnrespondedQuery, search-query-converter, addVisibilityFilter, countBaseQuery, bulk.class.js, MONGODB_URI
  - desc: Search here for review-only memory about whether unread/unresponded diffs are okay, including blocker findings, targeted validation limits, and worktree-specific caveats in `cwd=/Users/tualek/ohochat/oho-api`.
  - learnings: Review confidence came from focused Jest and full hook-chain tracing; missing `MONGODB_URI` blocked DB-backed proof, and unrelated quick-reply/typecheck failures should not be reported as rollout success.

#### 2026-06-26

- Earlier unread/unresponded code review blockers: unread, unresponded, search-query-converter, addVisibilityFilter, Jest, Mongo query composition
  - desc: Older but still relevant review memory for the same `oho-api` task family; useful when a future diff reintroduces the same query-composition pattern in `cwd=/Users/tualek/ohochat/oho-api`.
  - learnings: The durable failure shield is still the same: filter-shape changes must survive typed-filter parsing and later visibility rewrites.

### Older Memory Topics

#### /Users/tualek/life

- Monthly finance baseline from ad-hoc notes: net salary 37950, tuition saving, utilities 4500, Paynext 3300, wife monthly support
  - desc: Search first for current personal-finance baseline numbers and planning constraints in `cwd=/Users/tualek/life`; applicability is checkout-specific to the 2026-05-12 baseline note set. [ad-hoc note]

#### /Users/tualek/.codex/memories/skills

- Git commit workflow skill: git-commit-workflow, conventional commits, split or combine, index.lock
  - desc: Use `skills/git-commit-workflow/SKILL.md` for commit-boundary inspection, conventional-prefix subjects, and post-commit verification.

- GitLab MR description workflow skill: gitlab-mr-description-workflow, glab -F json, base_sha, head_sha
  - desc: Use `skills/gitlab-mr-description-workflow/SKILL.md` for paste-ready MR descriptions with `glab`-first and local-git fallback behavior.

- OHO Smartchat debugging skill: oho-smartchat-debugging, filtered_list_refetch_fn, sale_owner, is_dummy
  - desc: Use `skills/oho-smartchat-debugging/SKILL.md` for Smartchat/groupchat search, ordering, duplicate-message, and visibility debugging in `cwd=/Users/tualek/ohochat/oho-web-app`.

- OHO JERA integration debugging skill: oho-jera-integration-debugging, contact-link, partner-connection, x-oho-api-key
  - desc: Use `skills/oho-jera-integration-debugging/SKILL.md` for cross-repo JERA integration debugging in the OHO workspace.

- OHO web-app branch workflow skill: oho-web-app-git-branch-workflow, cherry-pick, revert latest commit, develop sync
  - desc: Use `skills/oho-web-app-git-branch-workflow/SKILL.md` for branch comparison, MR base validation, squash feasibility, and narrow revert workflows in `cwd=/Users/tualek/ohochat/oho-web-app`.
