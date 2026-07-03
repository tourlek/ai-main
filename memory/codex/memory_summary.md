v1

## User Profile

The current durable memory set is intentionally narrow. The only surviving evidence-backed user context after this consolidation is personal-finance planning in `/Users/tualek/life`, anchored by authoritative `ad_hoc` notes from 2026-05-12. Those notes show the user wants conservative monthly cash-flow planning based on their own net salary, with tuition saving, utilities, and Paynext all kept visible in the baseline instead of being hand-waved away. Reusable workflow helpers still exist under `skills/` for OHO Git, MR, Smartchat, and JERA work, but the old rollout-backed narrative memory for those areas was pruned because the source summaries were deleted.

## User preferences

- For finance planning, do not count wife monthly support as income; keep the baseline conservative and salary-based. [ad-hoc note]
- For finance planning, include tuition saving and water/electric in the monthly baseline by default; do not treat them as optional extras. [ad-hoc note]
- For finance planning, keep `Paynext 3,300/month` in the expense baseline, but remember it can temporarily substitute cash for fuel, food, or 7-Eleven spending when cash is tight. [ad-hoc note]
- When current memory support has been deleted, do not revive older advice from habit; prefer the surviving authoritative notes and existing skill files until new rollout evidence exists.

## General Tips

- `raw_memories.md` is currently empty and `rollout_summaries/` is empty, so older handbook claims were intentionally removed rather than preserved speculatively.
- Search `MEMORY.md` first for current personal-finance baseline numbers.
- Search `skills/` directly for reusable workflows that still exist as first-class artifacts: git commits, GitLab MR descriptions, OHO Smartchat debugging, OHO JERA debugging, and OHO web-app branch handling.
- Treat any missing older context as intentionally forgotten, not as hidden elsewhere in this memory repo.

## What's in Memory

### /Users/tualek/life

#### 2026-05-12

- Monthly finance baseline from ad-hoc notes: net salary 37950, tuition saving, utilities 4500, Paynext 3300, wife monthly support
  - desc: Search first for the current personal-finance baseline and planning constraints when the user asks for monthly cash-flow help in `cwd=/Users/tualek/life`. [ad-hoc note]
  - learnings: The surviving authoritative baseline is conservative: no wife support counted as income, utilities and tuition are mandatory, and the plan is still short roughly `18,014-18,714/month`. [ad-hoc note]

### Older Memory Topics

#### /Users/tualek/.codex/memories/skills

- Git commit workflow skill: git-commit-workflow, conventional commits, split or combine, index.lock
  - desc: Use `skills/git-commit-workflow/SKILL.md` for commit-boundary inspection, subject/body drafting, and post-commit verification.

- GitLab MR description workflow skill: gitlab-mr-description-workflow, glab -F json, base_sha, head_sha
  - desc: Use `skills/gitlab-mr-description-workflow/SKILL.md` for paste-ready MR descriptions with `glab`-first and local-git fallback behavior.

- OHO Smartchat debugging skill: oho-smartchat-debugging, filtered_list_refetch_fn, sale_owner, is_dummy
  - desc: Use `skills/oho-smartchat-debugging/SKILL.md` for Smartchat/groupchat search, ordering, duplicate-message, and visibility debugging in `/Users/tualek/ohochat/oho-web-app`.

- OHO JERA integration debugging skill: oho-jera-integration-debugging, contact-link, partner-connection, x-oho-api-key
  - desc: Use `skills/oho-jera-integration-debugging/SKILL.md` for cross-repo JERA integration debugging in the OHO workspace.

- OHO web-app branch workflow skill: oho-web-app-git-branch-workflow, cherry-pick, revert latest commit, develop sync
  - desc: Use `skills/oho-web-app-git-branch-workflow/SKILL.md` for branch comparison, MR base validation, squash feasibility, and narrow revert workflows in `/Users/tualek/ohochat/oho-web-app`.
