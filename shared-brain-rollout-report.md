# Shared brain — rollout and test report

## Verdict

**Configuration rollout and local checks passed; cross-harness readiness has NOT passed.** Live canaries exposed authentication/runtime blockers, a nested-instruction miss, and a wrong-directory test. A zero CLI exit code was not counted as behavioral success.

## Deployed and verified

- Ran `bash install.sh --sync`, followed by installed-file verification and `aimain doctor`; did not run the full installer, install dependencies, change credentials, or use a runner fallback.
- Updated Claude, Codex, Gemini, and Pi entries; checked the actual installed entries contain the exact generated shared source text for their tier.
- Updated OpenCode, Qwen, and Zcode adapter entries where detected. This is configuration evidence, not proof those runtimes work.
- Deployed managed knowledge to 11 registered workspaces, including ohochat and its registered repos. Preserved the repo-tracked `oho-api/CLAUDE.md`.
- Added Cursor's shared baseline at each managed workspace's `.cursor/rules/ai-main-shared.mdc` with `alwaysApply: true`; a home `.cursor/rules` file alone is not a documented global-rule deployment mechanism.
- Preserved 112 snapshotted local targets, including regular local skill directories and the tracked repo entry. No unexpected changes were found in those protected targets.
- Codex's reserved `.system` skill directory changed during CLI testing; it is runtime-owned, not an ai-main deployment target. Changed paths are recorded in the preservation artifact; no rollback was attempted.
- Existing global ignore patterns for AGENTS.md/CLAUDE.md/GEMINI.md remain untouched and are now reported as warnings rather than required checks.

Cursor reference: https://cursor.com/docs/context/rules (project `.mdc` rules, nested AGENTS.md, and UI-managed global User Rules).

## Local validation after final changes

| Check | Result |
| --- | --- |
| `bash eval/run.sh` | 55 assertions passed, including isolated suite gate |
| `eval/shared-brain.py` through the suite | 15 tests passed |
| Shell syntax: installer, aimain, verifier | Passed |
| `git diff --check` | Passed |
| `bash scripts/verify.sh` | Installed-file checks passed with explicit warnings |
| `aimain doctor` | 11 registered workspaces healthy; no generated-file leak reported |
| Installed Pi-owned context estimate | ~2,782 / 4,000 tokens; 15 visible skills |

Final profile estimates: full ~2,722 / 4,000; lean ~1,743 / 1,800; min ~1,108 / 1,200. These are estimates, not model-tokenizer measurements.

The isolated tests cover policy retention across tiers, compact descriptions/manual metadata, owned-first discovery, unmanaged/tracked/dangling-link preservation, unlink alias safety, adapter entry preservation, Cursor project rules, installer preservation of local skill directories, stale managed plugin-link retirement, and stubbed Hermes assembly. They do not prove live model compliance.

## Live canary results

One supervisor-managed workflow, run `775058bb-2d0f-4081-95ed-57f3d1f3d759`, launched six independent read-only lanes. Each had its own disposable Git directory on an unborn `canary` branch, with a web-only task, workspace/folder instruction markers, a misleading role comment, and a channel-authorization case. No fixture gained a commit or additional task file.

| Harness | Observed result | Status |
| --- | --- | --- |
| Codex CLI 0.152.0 | Correctly returned `guest`, traced missing `channel_id` to an empty non-admin authorization scope, and separated pure-function checks from unavailable service/database validation. Included workspace marker but omitted nested marker; transcript contains no read of `web/src/AGENTS.md`. | **Partial; nested-instruction criterion failed** |
| Pi native delegate | Provider returned `Invalid prompt: your prompt was flagged as potentially violating our usage policy`. No evidence-backed answer produced. | **Blocked; no bypass/rephrased retry** |
| Claude Code 2.1.227 | `Failed to authenticate: OAuth session expired and could not be refreshed`. Startup hook also injected Caveman full mode before authentication failed. | **Blocked** |
| Gemini CLI 0.44.1 | `IneligibleTierError` / `UNSUPPORTED_CLIENT`; provider says this client is no longer supported for the configured individual tier. Also reported untrusted fixture and invalid tools in the installed Caveman extension agents. | **Blocked** |
| Qwen Code 0.21.13 | Process completed, but result was `[API Error: 401 Incorrect API key provided...]`; initialization model label was `test`. | **Blocked, not a pass** |
| OpenCode 1.18.27 | Process completed, but tool calls inspected `/Users/tualek/ai-main` rather than the declared disposable cwd and concluded fixture source was absent. | **Invalid test / directory-routing failure** |
| Cursor | Project-rule deployment checked; `cursor-agent`/`agent` CLI unavailable. No live model run. | **Not behaviorally tested** |
| Hermes | Launcher exists, but `hermes --version` exits 126: `/Users/tualek/.hermes/hermes-agent/venv/bin/hermes` is missing. Live bridge/runtime rollout not attempted. | **Blocked** |
| Zcode / Antigravity | Configuration/skill paths only; no separate live canary. | **Not behaviorally tested** |

These results cover the configured runs, not every provider/model the team could select. Do not describe them as a GPT-6 Astra benchmark; the canary did not attest that model identity.

## Corrections made from observed evidence

1. `git check-ignore -v web/src/AGENTS.md` in the Codex fixture identified the legacy global ignore. Shared policy now explicitly requires direct instruction-filename checks even when Git ignores them; `rg --files` alone is insufficient.
2. Claude's startup-hook trace showed Caveman full activation despite the prose policy. Added `config/caveman.json` and installer merging of `defaultMode: off`, preserving other local options and session modes. Installed default is verified off; no environment override was present in the parent environment.
3. Strengthened installer preservation of regular/foreign skill entries and removal of only exact installer-owned upstream plugin links superseded by owned overrides.
4. Corrected Cursor deployment to the documented project-rule location and the verifier's false requirement for global instruction ignores.

Final local tests and installed-file checks passed after these corrections. **No post-correction live model rerun was performed**; failed lanes were not switched to a different runner or permission mode.

## Git/publication observation — requires owner attention

At the start of rollout ai-main HEAD was `1c37dcc`. During this session it advanced to `b4157a60a9f1de795a4d0fa7734767879838aa0d`, named `chore(memory): auto-sync 2026-09-09 02:36`, containing changes to `memory/SHARED.md` and `memory/lessons/RULES.md`.

Local `origin/main` matches that commit and its reflog records `update by push`. No direct `git commit` or `git push` command was issued by this assistant; the existing auto-sync path remains configured and is consistent with this commit. No reset/revert was attempted. Most configuration/skill changes remain uncommitted in the dirty worktree.

The existing scheduled auto-commit/push exception is still unresolved. Decide whether to disable it or explicitly retain its narrow authority before treating the shared-brain approval policy as end-to-end enforced.

## Remaining actions

- Re-authenticate Claude and correct Qwen provider credentials/model selection through their supported flows.
- Resolve Gemini client eligibility, compatible extension configuration, and explicit fixture trust without disabling safety globally.
- Restore/install the intended Hermes runtime if this Mac should run Hermes; do not infer that a launcher proves installation.
- Diagnose OpenCode directory routing through the same managed protocol before retrying its canary.
- Retry Codex nested-instruction behavior through the approved protocol after the direct-filename-check correction.
- Investigate the Pi provider rejection without bypassing the policy filter.
- Run Cursor desktop canary or install its supported CLI if automated coverage is required.
- Resolve the auto-sync publication decision; preserve all existing commits and concurrent work.

## Evidence locations

- Private local rollout snapshot/logs: `build/rollout-20260909-001339/`
- Machine-readable summary: `build/rollout-20260909-001339/results.json`
- Protected-target comparison: `build/rollout-20260909-001339/preservation.json`
- Copied raw canary outputs: `build/rollout-20260909-001339/canaries/`
- Workflow receipt: `/var/folders/mj/6y80z56d2pz8drt4ly3b8drw0000gn/T/pi-subagents-uid-501/async-subagent-runs/775058bb-2d0f-4081-95ed-57f3d1f3d759/workflow-receipt.json`
- Fixture root: `/private/var/folders/mj/6y80z56d2pz8drt4ly3b8drw0000gn/T/aimain-live-canary-3n6f4mn2`

`build/` artifacts are gitignored local evidence; this report is the durable repo-root summary. Source hashes are recorded by the profile/skill manifests; runtime/auth gaps are not silently scored as model passes.
