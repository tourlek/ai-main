# @local/dsh-ai-main-rules

Adds one system-prompt section, `ai-main-rules`, to every DSH prompt assembly. The text is rebuilt on each assembly from files under `~/ai-main`. It makes no LLM or network calls.

- The working directory comes from the session (`workingDirectory`) and is matched to the deepest workspace in `config/workspaces.json`. That picks `knowledge/<name>.md`, so a worktree under `oho-api/` gets `oho-api`. A linked worktree elsewhere (`~/orca/workspaces/oho-api/x`, `~/ohochat/oho-api-worktrees/x`) is first mapped to its main checkout through its `.git` file (`gitdir: …/.git/worktrees/<n>`).
- Rule lines (`- [*] ...`) are collected most specific first: the repo's `## Rules earned`, then the files it imports (`_ohochat-shared.md`), then `build/full/RULES.md` (falling back to `memory/lessons/RULES.md`).
- The section is capped at `maxBytes` (2048), cut on whole lines so Thai UTF-8 never splits. Global rules are dropped first; they are also in `~/.agents/AGENTS.md`.
- `interpolate: false`, so `{{...}}` in a rule stays literal.

To disable it, set `enabled: false` in the `ai-main-rules` config, or remove the row from `cordis.patch.yml`.
Test: `node test.mjs`
