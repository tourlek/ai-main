# Repo: oho-api

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Node.js backend service. Deployed on Cloud Run.

## Notes

- `.claude-worktrees/` exists here — parallel AI sessions may hold worktrees; don't delete them.
- JERA integration: `contact_links` is the source of truth for retry/again and pending-verification — not `partner_link_tokens.used_at`.
