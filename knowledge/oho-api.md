# Repo: oho-api

@{{AI_MAIN}}/knowledge/_ohochat-shared.md

## Stack

Node.js backend service. Deployed on Cloud Run.

## Notes

- `.claude-worktrees/` exists here — parallel AI sessions may hold worktrees; don't delete them.
- JERA integration: `contact_links` is the source of truth for retry/again and pending-verification — not `partner_link_tokens.used_at`.

## Agent skills

### Issue tracker

ClickUp (tickets) + GitLab (merge requests). See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles mapped to ClickUp activity comments. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. See `docs/agents/domain.md`.
