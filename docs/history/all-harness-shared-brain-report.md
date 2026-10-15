# All-harness shared-brain implementation report

## Current status

No model task or live canary ran in this implementation. Configuration readiness, runtime readiness, and live-behavior verification remain distinct. The prior four-run scoped Codex/Pi live pass remains the only current live evidence for those two harnesses.

Starting/final Git: `main` at `b4157a60a9f1de795a4d0fa7734767879838aa0d`, with the pre-existing dirty worktree preserved and no staged files, commit, push, reset, revert, auth change, trust change, or sync/publication-policy change. Initial private snapshots: diff `8d29fa4c9ffca6e4dc4f794b04cae0db7bf4dd874246fd45a11d5b799e3cf765`, status `b47b52ce22302b45e368824757a4e843472d2648c39f5cd2f27e1d65fbdcc7c8`.

## Corrected Antigravity facts

Official [Antigravity CLI migration](https://antigravity.google/docs/cli/gcli-migration/) states that `agy` enforces global `~/.gemini/GEMINI.md` and workspace `GEMINI.md`/`AGENTS.md`; [IDE rules](https://antigravity.google/docs/ide/rules/) independently documents the same global Gemini rule path for the native IDE. The current installed `agy` is 1.1.28, and `agy plugin install <target>` plus `agy plugin validate <path>` are available.

The official plugin documentation describes `~/.gemini/antigravity-cli/plugins/<name>/`, but this installed 1.1.28 build staged the validated `ai-main-shared` plugin at `~/.gemini/config/plugins/ai-main-shared/`. That version-specific observed path is recorded rather than treated as a contradiction or as proof that Gemini CLI and agy share every plugin registry behavior.

`agy plugin list` confirms both the pre-existing `agent-skills` import and the new owned `ai-main-shared` import. The existing import was not changed. The registered owned plugin contains 28 ai-main skills and no external-pack import. This is **configuration-ready**; loading/behavior remains untested.

## Generated and installed hashes

| Item | Previous SHA-256 | Current SHA-256 |
| --- | --- | --- |
| `build/full/SYSTEM.md` | `8a9618c935593068cd3da5dc29e75bd220122a5810e86d3f65d437682fa131d2` | `d2decee5c23f9f93fe787bc44a3b480f44aee663b6091e987f22824d18a492f1` |
| `build/lean/SYSTEM.md` | `6fd2ad291d6d0e7e8869e472b5a50fb876d986a18938d766a1934aa589c914f9` | unchanged |
| `build/min/SYSTEM.md` | `e589cb56be8b8ea59b5d965fb84b9ef52067556a59c5db8b111cac7d925901d8` | unchanged |
| profile manifest | `16679ec18b2ed2acb7bb6bfc82ed4e7973c8f82b45cf35863844538ae912544b` | `92746fcb5e6a5276a61d90117cbd9546dd4f3544865a6593093ec8542d7ddb24` |
| Claude entry | `103beb208d264e87c69f186af6f775470470a635cfe76411db771ca6c93b5579` | `103738698a13f9e5cbd8c090c1c93f236c1f24c70c86106d9ee96a9c06d5d091` |
| Codex entry | `b6184d36b46b6e877e5106e71ada543631890b370ede70b9edce801869dcd9d4` | `ec01b322831387d17f3e159a1f18634d4aa6b0daf87dd5f4aaa46f25098b094a` |
| Gemini / agy global rule | `b6184d36b46b6e877e5106e71ada543631890b370ede70b9edce801869dcd9d4` | `ec01b322831387d17f3e159a1f18634d4aa6b0daf87dd5f4aaa46f25098b094a` |
| Pi APPEND_SYSTEM | `3837b261b246f2813061dc5a116098de1f121782a708c78727f9c3185362b4e4` | unchanged |
| OpenCode / Zcode entries | `dc19acee72cf7024ce68345ed8d7960707431766c16db18a62214d1db30c2451` | `6137f371b4f61ab896456b837e6026b083fd065b541458d95302f9a83bfd37ac` |
| Qwen entry | `f61edf561ed85b1e1cc26f5268dc32f92187965b1d1b5107ba1f8f2b3aeebc48` | unchanged |
| agy `ai-main-shared/plugin.json` | absent | `7e07c6d4b76a1a874088a12a3eca1c61b6486d417db3c406585f02630d93510c` |

Affected entries were refreshed only after exact previous-hash ownership/concurrency guards passed. Durable copies are at `/Users/tualek/.ai-backup-20260909_131008-all-harness-followup/`. Existing workspace rules, user settings, credentials, trust decisions, foreign links, tracked instructions, and the `agent-skills` registry entry were preserved.

## Harness readiness

| Harness | Installed/native rule path | State |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | configuration-ready; prior OAuth live blocker remains |
| Codex | `~/.codex/AGENTS.md` | configuration-ready; prior focused live behavior verified |
| Pi native | `~/.pi/agent/APPEND_SYSTEM.md`, ancestor AGENTS/CLAUDE native discovery | configuration-ready; prior focused live behavior verified |
| Gemini CLI | `~/.gemini/GEMINI.md`, `~/.gemini/config/plugins/*` | configuration-ready; prior client-tier blocker remains |
| Antigravity native IDE / agy | `~/.gemini/GEMINI.md`; agy plugin registry has `ai-main-shared` | configuration-ready; live behavior untested |
| Cursor | managed workspace `.cursor/rules/ai-main-shared.mdc` | configuration-ready; desktop/CLI behavior untested |
| OpenCode | `~/.config/opencode/AGENTS.md` | configuration-ready; prior canary had wrong cwd |
| Qwen | `~/.qwen/QWEN.md` | configuration-ready; prior provider 401 remains |
| Zcode | `~/.zcode/AGENTS.md` and native `~/.agents/skills` adapter surface | configuration-ready; behavior untested |
| Hermes | intended `~/.hermes/SOUL.md` bridge | blocked: launcher target missing; bridge now safely refuses mutation |

## Incremental source change

1. Corrected `config/profile.md` to cite verified agy and native-IDE rule paths rather than treating loading as unverified.
2. Corrected Gemini CLI plugin success text and added owned-only agy plugin validation/registration while preserving existing registry imports.
3. Added focused regression assertions covering native agy paths, absence of the unsupported assertion, Gemini success labels, and the owned agy registration command.
4. Updated adapter documentation for official rule/plugin paths, installed version-specific registry evidence, and shared plugin storage.
5. Fixed `install.sh` `sync_agy_owned_plugin` to track owned skill hashes via `.ai-main-skill-hashes`, propagating skill updates and new skills on subsequent syncs while strictly preserving local user modifications and foreign same-name plugins without aborting sync of remaining sibling skills.
6. Corrected `~/.agents/skills` labels and comments in `install.sh` to Zcode / generic agents, matching observed shared registry behavior.
7. Added isolated regression test `test_antigravity_plugin_sync_propagates_updates_and_preserves_local_overrides` in `eval/shared-brain.py` verifying update propagation on second sync, preservation of local modifications alongside sibling and new skill propagation, and preservation of foreign plugins.
8. Completed canary agent definitions in `/tmp/aimain-parent-canary-20260909/.pi/agents/` using supported Markdown frontmatter format (`antigravity-readonly.md`, `opencode-readonly.md` with explicit `--agent plan`), removing unsupported `.json` files.
9. Prepared 7-file unborn canary repositories on branch `canary` in `/tmp/aimain-parent-canary-20260909/fixtures/{antigravity,opencode}` with outside SHA-256 manifests (`before.json`, `antigravity.sha256`, `opencode.sha256`).

## Validation actually run

- `rtk bash eval/run.sh`: 55 assertions passed; 17 isolated tests passed.
- `rtk bash -n install.sh scripts/hermes-sync.sh`: passed.
- `rtk git diff --check`: passed.
- `rtk agy plugin validate build/antigravity-plugin`: 28 skills processed.
- `rtk agy plugin install /Users/tualek/ai-main/build/antigravity-plugin`: passed.
- `rtk agy plugin list`: confirmed preserved `agent-skills` plus `ai-main-shared` skills registration.
- Verified fixture git status: 0 commits, unborn branch `canary`, 7 untracked files matching source SHA-256 manifest.
- Official docs fetched: CLI migration, CLI plugins, IDE rules. No model task ran.

## Parent-managed canary preparation

Prepared outside the shared project at `/tmp/aimain-parent-canary-20260909/.pi/agents/`, with unborn 7-file canary fixtures at `/tmp/aimain-parent-canary-20260909/fixtures/{antigravity,opencode}` and external manifests:

- `antigravity-readonly.md`: external CLI `/Users/tualek/.local/bin/agy`, stdin delivery, `--mode plan --model gemini-3.8-flash-high --output-format json --print`, no permission bypass or native-Pi model override.
- `opencode-readonly.md`: external CLI `/Users/tualek/.opencode/bin/opencode`, stdin delivery, `run --agent plan --dir /tmp/aimain-parent-canary-20260909/fixtures/opencode --format json`; uses `--agent plan` per specification.
- Fixtures: unborn repositories on branch `canary` with zero commits, 7 fixture files matching parent source `codex` fixture, SHA256 manifests saved in `/tmp/aimain-parent-canary-20260909/fixtures/{before.json,antigravity.sha256,opencode.sha256}`.

These are preparation artifacts only. Parent can discover the runner schema and launch under the managed protocol with a read-only fixture prompt; no unsafe permission mode is configured.
