# Claude Code dual account: Personal Pro + Team (2026-10-27, Asia/Bangkok)

Official `claude` 2.1.311 (`~/.local/bin/claude`), no proxy, no ANTHROPIC_BASE_URL.

## Credential isolation (verified from the binary, no keychain read)
- Keychain service = `Claude Code` + `-credentials` + (only if CLAUDE_CONFIG_DIR is set) `-` + first 8 hex of sha256(config dir path). Default `~/.claude` with no CLAUDE_CONFIG_DIR has no suffix. So the two logins use different keychain items and do not clash.
- With CLAUDE_CONFIG_DIR set, the global config is `$CLAUDE_CONFIG_DIR/.claude.json` (not `~/.claude.json`). Confirmed: `~/.claude-team/.claude.json` was created on first run.
- Warning: do NOT set CLAUDE_CONFIG_DIR=~/.claude for Personal. It would add the hash suffix and look for a different keychain item, so Personal would appear logged out. T3 instance `claude-personal` therefore has an empty homePath.
- Credentials file fallback and the symlink: the binary refuses to follow a symlinked credentials file, so credentials were NOT linked.

## Changes
| What | Path | Backup |
|---|---|---|
| New config dir (chmod 700) | `~/.claude-team/` | n/a (new) |
| Symlinks to `~/.claude/`: CLAUDE.md, RTK.md, shared, agents, skills, commands, hooks, settings.json, plugins | `~/.claude-team/*` | n/a (links) |
| T3 providerInstances `claude-personal`, `claude-team` (driver claudeAgent) | `~/.t3/userdata/settings.json` | `settings.json.backup-20261027-claude` |
| alias `claude-team` | `~/.zshrc` | `~/.zshrc.backup-20261027-claude-team` |
Not linked on purpose: .claude.json, credentials, projects, history, sessions, session-env, shell-snapshots, todos, statsig, telemetry, policy-limits/remote-settings (account specific).
Personal `~/.claude` and `~/.claude.json` were not modified (earlier backup: `~/.claude/backup-20261027-team/claude.json`).

T3 instance shape (claudeAgent): `{driver, displayName, enabled, config:{binaryPath, homePath, launchArgs, customModels}}`. `homePath` becomes CLAUDE_CONFIG_DIR (a leading `~` is expanded). `claude-personal` homePath is empty; `claude-team` homePath is `~/.claude-team`. Optional fields: `autoCompactWindow`, `idleCompaction`.

## Verification
- `CLAUDE_CONFIG_DIR=~/.claude-team claude auth status`: loggedIn false, configDirectory `/Users/tualek/.claude-team`.
- `claude auth status` (default): loggedIn true, claude.ai, subscription pro, configDirectory `/Users/tualek/.claude`.
- `zsh -ic 'type claude-team'`: alias to `CLAUDE_CONFIG_DIR=$HOME/.claude-team claude`.
- T3 settings JSON re-parsed OK; diff vs backup = only the two added instances.

## Shared-by-symlink caveats
- settings.json is shared: any change on one side applies to both. If Claude rewrites it atomically it may replace the symlink with a regular file in `~/.claude-team`; re-link if that happens.
- plugins/ is shared (installed_plugins.json, cache): installs by either instance affect both. Plugin auth (e.g. context7) is per instance.
- The settings env block (CLAUDE_AUTOCOMPACT_PCT_OVERRIDE, ponytail vars) and hooks apply to Team too.

## MCP servers the Team instance lacks
Personal `~/.claude.json` user-scoped mcpServers (not copied): `codegraph` (stdio: `codegraph serve --mcp`) and `open-design` (stdio, the Open Design.app daemon-cli, has 2 env vars, not printed). Also claude.ai connectors (Gmail, Calendar, Drive, ClickUp, Docs) are per account/org; Team gets its own set. To add on Team (run yourself, in Team):
`CLAUDE_CONFIG_DIR=$HOME/.claude-team claude mcp add --scope user codegraph -- codegraph serve --mcp`
For open-design, copy the entry from `~/.claude.json` by hand (it includes env values).

## Login (user does this)
`claude-team auth login` (or run `claude-team` then `/login`) and choose the Team account. Check: `claude-team auth status`.

## Revert
- Remove Team: `mv ~/.claude-team ~/.claude-team.removed-$(date +%Y%m%d)` (links only, no data in the targets). Keychain item (`Claude Code-credentials-<hash>`) can be removed by the user in Keychain Access after logout (`claude-team auth logout`).
- T3: `cp -p ~/.t3/userdata/settings.json.backup-20261027-claude ~/.t3/userdata/settings.json`, then restart T3.
- zsh: `cp -p ~/.zshrc.backup-20261027-claude-team ~/.zshrc`.
