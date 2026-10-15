# Dedicated OMP review and verification sessions

The normal OMP session remains the implementer/source owner. Requested code review and validation run in fresh visible Orca terminals in the same workspace, not separate Git worktrees and not hidden in-process substitutes.

## Entry points

`install.sh` installs ownership-safe links in `~/.local/bin`:

- `omp-review`: Sol (`openai-codex/gpt-6.1-sol`), high thinking, review-only role.
- `omp-verify`: GLM (`zai/glm-5.3-flash`), high thinking, validation-only role.
- `omp-orca-role`: opens, dispatches, collects and releases Orca role workers.

`config/omp-roles.json` is the role/model/tool source; role prompts live in `config/omp-roles/`. Both preserve cwd, start new sessions and leave the normal OMP default/auth/config untouched. Use `omp-review --describe` or `omp-verify --describe` to inspect configuration without a model call. Arbitrary model/tool/prompt overrides and resume flags are rejected so a launcher cannot silently stop being its role.

Standalone launchers open interactive OMP roles. They are not automatically supervised: without a live Orca Dispatch preamble, they must not emit lifecycle messages or reuse old task IDs.

## Main-session workflow

Read the version-matched `orca-cli` and `orchestration` guides before controlling sessions. Resolve the selected Orca executable once and keep it for the job; do not silently change execution hosts or CLI builds.

1. Inspect the exact current workspace and the diff/target paths. Obtain the requirements and acceptance; user requests to review/validate are stage authorization, not approval for fixes, Git writes or remote/data mutations.
2. Prepare a self-contained task file with Target, Requirements, Constraints and Observable acceptance. Include relevant staged, unstaged and untracked changes, but not the entire parent conversation or secrets.
3. For verification, inspect the project's existing check scripts for autofix, snapshot updates, dependency installs and external/data side effects. Choose explicit safe commands; pass each as `--check`. Do not authorize a broad npm/node/shell wildcard.
4. Start the requested role in the current workspace. The controller creates a terminal using the role launcher, proves TUI readiness, and binds that exact terminal with `worker-start --terminal`. OMP model selection happens in the launcher; `worker-start --model` does not configure OMP.
5. Pause source edits while the worker checks its snapshot. Only one role check at a time in this shared workspace; do not race review against ongoing implementation or tests against shared build outputs.
6. Wait for authoritative completion and process the detailed role report, questions/escalations and source-change verdict. Return findings/failures to the main implementer; re-check affected changes after approved fixes.

Example from the source workspace (replace the task/path values with real in-scope inputs):

```bash
omp-orca-role start review \
  --task-file /absolute/review-task.md \
  --scope src/payment.ts \
  --scope tests/payment.test.ts

omp-orca-role start verify \
  --task-file /absolute/verify-task.md \
  --scope src/payment.ts \
  --scope tests/payment.test.ts \
  --check "npm run typecheck" \
  --check "npm run test -- tests/payment.test.ts"

omp-orca-role wait /absolute/job-directory
omp-orca-role status /absolute/job-directory
omp-orca-role release /absolute/job-directory
```

The start receipt identifies the job directory, workspace, terminal and Task/Dispatch. `--from` can explicitly name the proven main/coordinator terminal handle; never pick an arbitrary active pane. `--run` can name the existing coordinator Run. Read `omp-orca-role --help` for the exact supported interface.

## Evidence and result semantics

State and handoff artifacts stay under checkout-local `.scratch/omp-orca-roles/`, not shared `.ai`. Source/HEAD fingerprints guard the review/verification baseline. A changed snapshot is stale even when a command passed; this is detection, not an OS lock on the checkout.

Workers send a complete JSON role report as an Orca `status` message with subject `omp-role-report`, using the active Dispatch's identity. Then they send `worker_done` exactly once with the required executive summary and explicit lifecycle outcome. A status report, heartbeat, idle terminal or accepted prompt is not completion.

- Review lifecycle success means the review finished. Its code verdict can still be `findings` with blockers; preserve all severity/file/line/trigger/impact/evidence and reviewed coverage.
- Verify reports exact commands and exit codes, relevant runtime smoke, and missing prerequisites. Failed checks or unavailable required role/environment proof are not a pass. Builds/tests alone are not delivery evidence.
- Parent handles every delivered question/escalation and only acknowledges messages already processed. No blind retry, invented approval, or false completion from timeout/contact loss.

Settled terminals are retained for the user's inspection and follow-up. Explicit release uses Orca's lifecycle receipt: pre-existing/reused/user-taken-over terminals may remain open by native design. Report that fact, not a fabricated close. Never replace uncertain release with broad terminal close, workspace deletion or orchestration reset.

## Permissions

Source edits remain with the main OMP. Workers do not fix source/tests, update snapshots, install packages, commit, push or deploy. Verifier may produce ordinary build/test artifacts and run isolated test writes only within the authorized check/environment.

Roles omit edit/write/delegation tools and run authorized work unattended, without asking the human to approve ordinary calls. Role-local policies allow read tools, scoped Git/Orca coordination and exact `--check` commands; other Bash is denied. Explicit user denies are preserved; prompt-only command restrictions become denies for these unattended roles. Bash and approved test programs are not an OS sandbox: inspect scripts, isolate targets/restricted accounts, and return changed scope or unsafe/external work to the main coordinator rather than silently authorizing it. The main OMP approval mode/config is unchanged.

Run workers only for requested review/verification; small tasks can remain main OMP plus targeted smoke. Fresh role sessions carry startup/context costs and do not automatically save tokens.

## Observed smoke evidence

On Orca 1.4.218 / OMP 18.4.4, task-owned Node fixtures exercised real fresh terminals in the existing ai-main workspace (HEAD `e9fa1af` plus dirty setup changes), without new worktrees or setup hooks:

| Stage | Model | Observed result |
| --- | --- | --- |
| Review of quantity bug | Sol high | Major finding at fixture line 2; no build/test/source edit |
| Verify of quantity bug | GLM high, unattended role | Approved `node --test` exited 1; one pass/one fail; report and failed Task received |
| Review after implementation-owner fixture fix | Sol high, unattended role | Clean source review received without local approval actions |
| Verify after fixture fix | GLM high, unattended role | Same approved test command exited 0; two pass/zero fail; passed report received |

All four reports correlated with their exact active Task/Dispatch and sender. Before/after scoped fingerprints matched for every worker, reports were retained and acknowledged, and the main global `config.yml` stayed byte-identical. This proves role routing/transport and the controlled checks, not readiness of an OHO application or all future model behavior. Fixture code/test files and task-owned smoke terminals were cleaned up; native Orca history keeps the completed dispatch outcomes.

Two compatibility details are role-local: the installed Orca OMP hook starts publishing readiness on the first actual turn, so an otherwise-empty interactive role receives a short no-tools `READY` startup handshake before its assignment. Automated roles also use `paste.largeMenuThreshold: 0` so complete large handoffs do not stop at a local paste-choice dialog. The main OMP's startup/paste settings and Orca-managed hook files are unchanged. Startup handshakes incur one small model turn per otherwise-empty interactive role session.
