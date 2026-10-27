# Applying the DSH proposal

`adapters/dsh/propose.sh` writes what ai-main would install into `~/.dsh/backup-20261021-consolidate/`. It leaves live files untouched. To apply it by hand, follow these steps. `./install.sh --harness dsh` (`deploy.sh`) does the same thing.

The source of truth is in ai-main:
- the profile rows `cc-review`, `cc-review-high`, `cc-explore` and their `tool-*` rows, and `guard-bridge`, in `adapters/dsh/cordis.patch.yml`;
- the plugins in `adapters/dsh/plugins/`;
- the DSH AGENTS text in `adapters/dsh/AGENTS.md`.

`propose.sh` builds its output from the current live files:
- It appends only the rows the live `cordis.patch.yml` lacks. Rows that are already present are not rewritten, so check drift by eye in step 1.
- It adds the `@local/dsh-ai-main-rules` link and bundle entry. That plugin's own bundle patch inserts its row, so it needs no profile row.
- It adds the `@local/dsh-rtk-bridge` link and bundle entry for the same reason: that plugin inserts its own `rtk-bridge` row from `adapters/dsh/plugins/dsh-rtk-bridge/cordis.patch.yml`. After the restart, bash commands are rewritten through `rtk hook claude`; check with a `git status` call (`rtk gain --history` should gain an entry, and the terminal card still shows the command the model wrote).

**Link decision:** the proposal switches the `@local/dsh-guard-bridge` link from `~/Documents/deepseek-harness/default-workspace/dsh-guard-bridge` to `~/ai-main/adapters/dsh/plugins/dsh-guard-bridge`.
- The two copies have the same `index.js`, apart from the default `guardPath`. The live profile row sets `guardPath: ~/.claude/hooks/guard.sh` explicitly, so behaviour is unchanged.
- The Documents copy stays where it is.
- Rollback: see the bottom of this file.

## 1. Review

```bash
B=~/.dsh/backup-20261021-consolidate
P=~/.dsh/profiles/desktop
diff $P/package.json $B/package.json.proposed            # guard-bridge link → ai-main copy; + @local/dsh-ai-main-rules (dep + bundle)
diff $P/cordis.patch.yml $B/cordis.patch.yml.proposed    # empty today (live already has every ai-main row)
diff ~/.dsh/AGENTS.md $B/AGENTS.md.proposed              # live text kept, "# ai-main" pointer appended
less $B/agents-AGENTS.md.proposed                        # new ~/.agents/AGENTS.md (none exists today)
```

## 2. Quit DSH (Cmd+Q), then copy with backups

```bash
B=~/.dsh/backup-20261021-consolidate
P=~/.dsh/profiles/desktop
cp -p $P/package.json $B/package.json.live-before-apply
cp -p $P/cordis.patch.yml $B/cordis.patch.yml.live-before-apply
cp -p ~/.dsh/AGENTS.md $B/AGENTS.md.live-before-apply
cp $B/package.json.proposed $P/package.json
cp $B/cordis.patch.yml.proposed $P/cordis.patch.yml
cp $B/AGENTS.md.proposed ~/.dsh/AGENTS.md
mkdir -p ~/.agents && cp $B/agents-AGENTS.md.proposed ~/.agents/AGENTS.md
ln -s ~/ai-main/skills/clickup-card ~/.agents/skills/clickup-card   # absent today; DSH scans ~/.agents/skills
(cd $P && pnpm install)      # relinks @local/dsh-guard-bridge to ai-main, adds @local/dsh-ai-main-rules
```

## 3. Claude side (separate step: `./install.sh --harness legacy`, which is the full Claude/Gemini/Cursor installer)

Step 7b of `install.sh` moves each live file to `~/.ai-backup-<timestamp>/` and symlinks it to ai-main:
- `~/.claude/hooks/guard.sh`, `herdr-agent-state.sh` and `jev-route.py`;
- `~/.claude/agents/{reviewer,scout}.md`;
- `clickup-card` and `gitlab-mr-description`, in both `~/.claude/skills/` and `~/.agents/skills/`.

Then `adapters/claude/merge-permissions.sh` adds `adapters/claude/settings.permissions.allow.json` (the 13 ClickUp read tools) to `permissions.allow` with a jq union.
- It copies `settings.json` to the backup dir first.
- It is a no-op when every entry is already there, which is true today. No other key, including `env`, is touched.

Wait until the react-parity orchestrator run has finished, because it reads `~/.claude/hooks/guard.sh`. `~/.claude/hooks/run-exceptions/react-parity-run` is never touched.

## 4. Restart DSH and check

- Start DeepSeek Harness. In a new session in an `oho-api` worktree, the system prompt should contain `# Rules earned (ai-main, oho-api)`.
- Ask it to run `git push --force origin x`: the bridge should deny it. Ask it to run `git commit -m x`: an approval card should appear.
- `subagent_claude_review` and `subagent_claude_review_high_on_request` should both still be listed.

## New guard denies (the merged guard is stricter than the old live one)

These denies are new:
- `git reset --hard|--merge`
- `git clean -f`
- force push (`--force`/`-f`); `--force-with-lease` still passes
- `git branch --set-upstream-to=X` without a branch
- `git branch -f X` with one argument
- amend/rebase when another branch already contains HEAD

They reach DSH and the react-parity run once `~/.claude/hooks/guard.sh` points to ai-main (step 3), because the live `guardPath` is that path.

## ClickUp MCP (write mode)

- The `mcp-clickup` row in `cordis.patch.yml` also needs these profile `dependencies` (not `dsh.profile.bundles`): `"@deepseek-ai/dsh-mcp-client": "0.2.1-rc.2"` and `"@hauptsache.net/clickup-mcp": "1.9.0"`.
- The secret `CLICKUP_API_KEY` comes from Bitwarden via `bwsr`; the launcher drops every other env var.
- Mode is `write` (enabled 2026-10-21, user approved).
- Read tools: `mcp__clickup__{getTaskById,searchTasks,searchSpaces,getListInfo,getTimeEntries,readDocument}`.
- Write tools: `mcp__clickup__{addComment,editComment,updateTask,createTask,updateListInfo,createTimeEntry,updateDocumentPage,createDocumentOrPage}`. `guard.sh` gates all 8 (approval card under DSH).
- No tool adds an existing task to another list (no `addTaskToList`; `updateTask` has no list field). `createTask` takes `list_id`, so pick the target list at creation.
- `getTaskById` accepts only the internal 6-16 char task id, not custom ids like `OHO-8671`.
- Rollback to read mode: quit DSH, restore `~/.dsh/backup-20261021-clickup-write/desktop-cordis.patch.yml` to `~/.dsh/profiles/desktop/cordis.patch.yml`, restart DSH.

## Session title tool (@local/dsh-session-title-tool)

Adds `set_session_title` (renames the calling session only; used by `clickup-card`). Its own bundle patch inserts the `session-title-tool` row, so the profile needs only the link dependency and the bundle entry.
`propose.sh`/`deploy.sh` do not pick it up: `propose.sh` hardcodes the ai-main-rules and guard-bridge links. They keep it once installed by hand, because the jq only sets those two keys. Add a third `--arg` there if it should deploy automatically.

Install:

```bash
B=~/.dsh/backup-$(date +%Y%m%d)-session-title
P=~/.dsh/profiles/desktop
mkdir -p $B && cp -p $P/package.json $P/cordis.patch.yml $P/pnpm-lock.yaml $B/
osascript -e 'tell application "DeepSeek Harness" to quit'
jq '.dependencies, .dsh.profile.bundles' $P/package.json | grep -i session-title   # must print nothing (a second set_session_title fails registration)
# edit $P/package.json:
#   dependencies:        "@local/dsh-session-title-tool": "link:/Users/tualek/ai-main/adapters/dsh/plugins/dsh-session-title-tool"
#   dsh.profile.bundles: append "@local/dsh-session-title-tool"
# DSH's own pnpm, never Homebrew pnpm:
A="/Applications/DeepSeek Harness.app/Contents"; R="$A/Resources/runtime"
(cd $P && DSH_DESKTOP_NODE_EXECUTABLE="$A/MacOS/DeepSeek Harness" "$R/bin/node" "$R/primary-runtime/dependencies/pnpm/bin/pnpm.mjs" install)
diff $B/pnpm-lock.yaml $P/pnpm-lock.yaml   # must only add the @local/dsh-session-title-tool link
open -a "DeepSeek Harness"
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:38080/   # expect 401
```

Live check, in a new DSH chat: `เรียก set_session_title ตั้งชื่อ session นี้เป็น "OHO-0000 [Breakdown] title test"`. The sidebar title should change, and later turns should not retitle it.

Rollback:
1. `osascript -e 'tell application "DeepSeek Harness" to quit'`.
2. Copy `package.json`, `cordis.patch.yml` and `pnpm-lock.yaml` from `$B` back to `$P`.
3. Run the same DSH pnpm install, then `open -a "DeepSeek Harness"`.

Or keep it installed but off: set `config: { enabled: false }` on the `session-title-tool` row through a profile patch row. Which cordis op overrides a bundle-inserted row is not verified here, so check the result with the live check.

## Read-free / approval reduction (2026-10-21)

Changes: `permission` preset override (default `full-ask`), `subagent_claude_review_high` renamed to `subagent_claude_review_high_on_request`, bundled `tool-subagent-claude-code` disabled, new `# Investigate` section in AGENTS.md. Source: the OVERRIDES block at the bottom of `adapters/dsh/cordis.patch.yml` (hand-applied; `propose.sh` skips it).

```bash
B=~/.dsh/backup-20261021-readfree
P=~/.dsh/profiles/desktop
mkdir -p $B && cp -p $P/cordis.patch.yml $B/cordis.patch.yml && cp -p ~/.dsh/AGENTS.md $B/AGENTS.md
osascript -e 'tell application "DeepSeek Harness" to quit'
# edit $P/cordis.patch.yml:
#   1. append the two top-level entries (`- id: permission` and `- id: tool-subagent-claude-code`) from the OVERRIDES block at the end of the live patch, at column 0
#   2. in the tool-cc-review-high row set toolName: subagent_claude_review_high_on_request
cp ~/ai-main/adapters/dsh/AGENTS.md ~/.dsh/AGENTS.md
open -a "DeepSeek Harness"
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:38080/   # expect 401
```

DSH HMR watches the patch, but we still quit/relaunch per the house rule.

Check: a new session shows preset `full-ask`; `subagent_claude_review_high_on_request` is listed and `subagent_claude_code` is not.

Rollback: quit DSH, copy `$B/cordis.patch.yml` to `$P/` and `$B/AGENTS.md` to `~/.dsh/AGENTS.md`, then `open -a "DeepSeek Harness"`.

## Chrome DevTools MCP (2026-10-22)

Installed by hand while the profile was live; patch HMR picked it up without a quit.

- `mcp-chrome-devtools` — row in `adapters/dsh/cordis.patch.yml`; needs the profile dependency `"chrome-devtools-mcp": "1.11.0"`. Headless + `--isolated` (never touches the user's Chrome profile), usage statistics and the CrUX URL lookup off, `toolCallTimeoutMs: 180000` because Lighthouse and traces outrun the 60s default. 32 tools: perf trace, Lighthouse, console, network, screenshots, snapshots.

The `dsh-obsidian-panel` vault panel was installed next to it on the same day and removed by the user's request hours later (see the cost-meter section for why its bundle entry could not survive).

`propose.sh` does not add that dependency (its jq only sets the four `@local` keys), so keep it in the live `package.json` and re-add it by hand if the profile is rebuilt.

pnpm: install with Homebrew `pnpm` 10.32.0 to match `node_modules/.modules.yaml` (`packageManager: pnpm@10.32.0`). The DSH-shipped pnpm is 11.28.5 and aborts with `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY` — it wants to purge the 614 MB modules dir.

Verify (exact configured argv, `env -i`, headless Chrome, no DSH restart needed):

```bash
node /tmp/mcp-nav.mjs   # initialize → new_page example.com → list_pages; expect "Example Domain" listed
```

Revert: quit DSH, restore `~/.dsh/backup-20261022-mcp-chrome-obsidian/{package.json,cordis.patch.yml,pnpm-lock.yaml}`, delete the `mcp-chrome-devtools` row from `adapters/dsh/cordis.patch.yml`, `pnpm install`, restart.

## Cost meter (dsh-cost-meter, 2026-10-22)

Hand-installed at the user's request, pinned to `1.9.26`. Plugin Hub was avoided: that version was published the same day, so the host pnpm 11.28.5 `minimumReleaseAge` (24h) refuses it, and pnpm 11 also wants to purge the pnpm-10 store.

```bash
P=~/.dsh/profiles/desktop; B=~/.dsh/backup-20261022-cost-meter   # backup taken before editing
# package.json: dependencies "dsh-cost-meter": "1.9.26"; dsh.profile.bundles append "dsh-cost-meter"
(cd $P && pnpm install)   # Homebrew pnpm 10.32.0
```

Its own bundle patch inserts the `cost-meter` row, so no row goes in `cordis.patch.yml`. A quit + relaunch is required (host rows, Typert manifest and client bundle are scanned at startup) — unlike the chrome MCP, this one does not HMR in. First launch replays existing session logs to backfill history.

Settings worth touching once (Settings → Cost): sync prices from the official page (USD), keep peak/off-peak on, disable the 13 vendor quota cards that this setup does not use. API keys, if added for the balance card, are only ever sent to `api.deepseek.com`; the ledger lives at `$DSH_HOME/storages/cost-meter/ledger.json`.

**The profile `package.json` is not stable under hand edits.** Any write to it wakes the host plugin manager, which runs its own pnpm 11 install; that install fails on this machine with `ERR_PNPM_UNEXPECTED_STORE` (`node_modules` is linked from `~/Library/pnpm/store/v10`, pnpm 11 wants `v11`, see `.plugin-manager/logs/operation-*/pnpm.log` at 16:48:13, 16:48:30, 16:49:01) and the reconciliation writes `package.json` back without the `link:`-installed `dsh-obsidian-panel` bundle entry. Registry packages (`dsh-cost-meter`) and `@local/*` links survive; the obsidian entry does not, so it is stripped again within seconds of being re-added while DSH runs. Consequence: Plugin Hub install/update is currently broken on this profile until the store mismatch is resolved (let pnpm 11 re-link `node_modules`, or point the host pnpm at the v10 store).

The obsidian vault panel was the casualty: its bundle entry was re-added three times and stripped within 40 s each time, so the user had it removed on 2026-10-22 — dependency, bundle entry and the `node_modules` symlink are gone; the pinned clone still sits at `external/dsh-obsidian-panel` (456 KB, v1.2.1) if it is ever wanted back. Plugin Hub itself stays broken on this profile until the store mismatch is resolved, so plan no Hub installs or updates here without fixing it first.

Settings worth touching once (Settings → Cost): sync prices from the official page (USD), keep peak/off-peak on, disable the 13 vendor quota cards that this setup does not use. API keys, if added for the balance card, are only ever sent to `api.deepseek.com`; the ledger lives at `$DSH_HOME/storages/cost-meter/ledger.json`.

Revert: quit DSH, copy `~/.dsh/backup-20261022-cost-meter/{package.json,cordis.patch.yml,pnpm-lock.yaml}` back, `pnpm install`, restart.

## Rollback

- DSH:
  1. Quit DSH.
  2. Copy `$B/*.live-before-apply` back: `package.json`, `cordis.patch.yml`, `AGENTS.md`. This restores the Documents guard-bridge link.
  3. Move `~/.agents/AGENTS.md` and the `~/.agents/skills/clickup-card` link into a backup dir.
  4. Run `(cd $P && pnpm install)`.
  5. Restart DSH.
- Claude: copy the files from `~/.ai-backup-<timestamp>/` back over the symlinks, including `claude_settings.json` if it was written.
