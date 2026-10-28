# pi adapter (direct, 2026-10-26)

Plain `pi` (`@earendil-works/pi-coding-agent` 1.4.0, nvm node v24.14.0) with the default agent dir `~/.pi/agent`.
No launcher, no alias, no `PI_CODING_AGENT_DIR`. Replaces the pi-trial setup (launcher + `~/.pi/agent-trial`).

## What is wired into `~/.pi/agent`
| Item | How |
|---|---|
| Model | `settings.json`: `defaultProvider: deepseek`, `defaultModel: deepseek-flash`, `enableInstallTelemetry: false`, skills `~/.hermes/skills-aimain`, `~/.hermes/skills`; `-builtin:mcp` removed so MCP is on. Existing packages / subagents kept. |
| DeepSeek key | `auth.json` → `"deepseek": {"type":"api_key","key":"!PATH=… ~/.local/bin/bwsr --shell bash --project-id 33d132a6-… -- 'printf %s \"$DEEPSEEK_API_KEY\"'"}`. pi runs the command (`/bin/sh`, 10 s timeout) the first time the key is needed and keeps stdout in memory for the process lifetime. `bwsr` reads the bws token from the Keychain; `bws run` puts the project secrets only in that short-lived child, which prints just the one key. Nothing written to disk, nothing exported; pi's env holds no bws secret (MONGO_URI_*, STREAM_*, CLICKUP_API_KEY, DEEPSEEK_API_KEY, BWS_ACCESS_TOKEN). Empty output / timeout / non-zero exit → key unresolved until pi restarts. |
| Shared brain | `extensions/ai-main-brain.ts` → `adapters/pi/extensions/ai-main-brain.ts`. On every `before_agent_start` it reads `agent/APPEND_SYSTEM.md` (adapter note), `~/.hermes/state/ORACLE.md`, `~/ai-main/build/full/SYSTEM.md` fresh and sets them as prompt sections `ai_main_note` / `ai_main_oracle` / `ai_main_system` (live, no copies; `oracle-recap --install` unchanged). `AIMAIN_BRAIN=0` disables. `~/.pi/agent/APPEND_SYSTEM.md` (RTK rules etc.) still loads as before. |
| Guard | `extensions/guard.ts` → `adapters/pi/extensions/guard.ts`: `tool_call` → `~/.claude/hooks/guard.sh`, fail-closed (bash / codemode / `*clickup_*` / `mcp__graphify__*`). Log: `$PI_CODING_AGENT_DIR/logs/guard.log`, default `~/.pi/agent/logs/guard.log`. Env `AIMAIN_GUARD`, `AIMAIN_GUARD_LOG`. |
| MCP | `mcp.json` (copy of `agent/mcp.json`): context7 (direct), open-design (deferred), graphify (direct), clickup (deferred, OAuth). `mcp-auth.json` (600) holds the ClickUp OAuth token, carried over from the trial dir. |
| Other | Existing `extensions/` (gemini-antigravity.ts, herdr, holdmylid, usage-footer), `sessions/`, anthropic login in `auth.json` kept. `provider-keys.json` now 600. |
Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/adapters/pi/README.md

## Layout here
| Path | What |
|---|---|
| `extensions/guard.ts` | Guard extension (symlinked into `~/.pi/agent/extensions/`). Keep. |
| `extensions/ai-main-brain.ts` | Brain extension (symlinked). Keep. |
| `agent/APPEND_SYSTEM.md` | Adapter note read live by ai-main-brain.ts. Keep. |
| `agent/settings.json`, `agent/mcp.json` | Reference templates. |
| `test/selftest.sh` | Deterministic wiring test with a mock LLM: `git push origin master` (expect block), `ls` (pass), context7 call. No key. `AIMAIN_GUARD=/nonexistent test/selftest.sh` checks fail-closed. `PI_BIN=…` to test another pi binary. |

## Use
```sh
pi                       # interactive
pi -p "..."              # one-shot
pi mcp list              # expect 4 connected
pi mcp login clickup     # only if the ClickUp OAuth token expires
~/ai-main/adapters/pi/test/selftest.sh
```

## Rollback
```sh
B=~/.hermes/backups/20261026-pi-direct
cp -p $B/pi-agent/settings.json $B/pi-agent/auth.json ~/.pi/agent/        # anthropic default, MCP off, no deepseek key cmd
mv ~/.pi/agent/extensions/guard.ts ~/.pi/agent/extensions/ai-main-brain.ts $B/   # (symlinks)
mv ~/.pi/agent/mcp.json ~/.pi/agent/mcp-auth.json $B/
# pi-trial back: launcher + alias + agent dir
cp -p $B/ai-main-adapters-pi/pi-trial.moved ~/ai-main/adapters/pi/pi-trial
cp -p $B/zshrc ~/.zshrc
mv ~/Archive/pi-agent-trial-20261026 ~/.pi/agent-trial
cp -p $B/ai-main-adapters-pi/extensions/guard.ts ~/ai-main/adapters/pi/extensions/guard.ts          # old log path
cp -p $B/ai-main-adapters-pi/agent/APPEND_SYSTEM.md ~/ai-main/adapters/pi/agent/APPEND_SYSTEM.md
cp -p $B/ai-main-adapters-pi/test/selftest.sh ~/ai-main/adapters/pi/test/selftest.sh
```
Change log: `~/.hermes/backups/20261026-pi-direct/CHANGES.md` (trial history: `~/.hermes/backups/20261026-pi-trial/CHANGES.md`).
