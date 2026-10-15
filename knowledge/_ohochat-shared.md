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
- **VCS**: GitLab self-hosted at `gitlab.boonmeelab.com`.
- **Feature flags**: Firebase Remote Config (e.g. `rt_jera_feature_enabled`). Tracking via GTM.

## Workspace layout

- Worktrees: `.claude-worktrees/` exists in `oho-api` for parallel AI sessions.

## Hard-won constraints (from production incidents)

- When changing hot-path array queries, preserve membership semantics (`unread_by: id`) and verify selectivity with `explain()` on representative tenant data; `$ne`/`$nin` can be poorly selective. Do not replace a required predicate just to follow a blanket indexing rule.
- When adding auxiliary queries to polled endpoints, bound their duration with `maxTimeMS` and preserve the endpoint's degradation contract. Fail-soft applies only to optional data, not authorization or required results; size against the biggest relevant tenant.
- DB-heavy features roll out per-tenant (`business_id`), canarying one small tenant while watching p95 and slow-query logs. A flag flipped globally at night is how the cluster melted on 8 Jul 2026.
- One flag gates exactly one feature, and "off" must behave like the feature never shipped — that includes every write path, not just reads.
- Renaming or inverting a field that gates user-visible state (badges, counters) needs a backfill for existing documents; verify the old field's real volume in production before deleting the migration tooling.
