# OHO Workspace — Shared Domain Knowledge

Applies to every repo under `/Users/tualek/ohochat/`. Repo-specific files import this.

## Domain vocabulary

- **JERA** — feature/integration domain (JERA Cloud, JERA Dent). Custom Integration display names exist; do not invent alias rules like mapping `jera` → `jera-cloud` unless the product contract says so.
- **partner-connection** — member-facing route. Backoffice path is `/backoffice/partner-connection/jera`. Developer API has its own routes — keep contracts separate.
- **Smartchat** — messaging surface. Unread detection and mark-read are separate mechanics.
- **contact_links** — source of truth for JERA retry/again and pending-verification UI. Don't switch to `partner_link_tokens.used_at` unless the contract changes.
- **Sender IDs** — JERA message fallback uses `@jera-cloud` / `@jera-dent` rather than text/html heuristics.

## Infrastructure

- **Database**: MongoDB. Atlas Data Lake (Federated) is read-oriented — write endpoints require the real cluster, not the Data Lake. Verify the connected datasource in Compass before rewriting query syntax on write failures.
- **Deploy**: Cloud Run.
- **VCS**: GitLab self-hosted at `gitlab.boonmeelab.com`. Use `glab`; the working JSON flag is `-F json`.
- **Feature flags**: Firebase Remote Config (e.g. `rt_jera_feature_enabled`). Tracking via GTM.

## Cross-repo rules

- Frontend ask that needs a backend change → surface the dependency and ask before editing the backend repo.
- Never push to `master` directly.
- Worktrees: `.claude-worktrees/` exists in `oho-api` for parallel AI sessions.
