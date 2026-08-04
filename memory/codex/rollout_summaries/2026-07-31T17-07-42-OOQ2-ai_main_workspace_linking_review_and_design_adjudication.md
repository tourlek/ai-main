thread_id: 019fb925-627a-7253-bc76-6715214f2a22
updated_at: 2026-07-31T17:26:31+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T00-07-42-019fb925-627a-7253-bc76-6715214f2a22.jsonl
cwd: /Users/tualek/ai-main
git_branch: main

# Read-only review of ai-main workspace-linking implementation and design adjudication

Rollout context: The user requested a strictly read-only review of the newly shipped workspace-linking implementation in `/Users/tualek/ai-main`, plus six concise architecture verdicts comparing the prior Codex proposal with a competing Fable design. No files were modified and no write-capable test commands were run.

## Task 1: Review shipped workspace-linking code

Outcome: success

Preference signals:
- The user explicitly required “READ-ONLY” investigation and asked not to run `link`, `unlink`, `install.sh`, or `verify.sh` because they could write filesystem state -> future reviews should distinguish static verification from dynamic test claims and avoid mutating commands unless explicitly authorized.
- The user requested worst-first findings with concrete file/line references and focus on failures affecting a daily-use fleet, not cosmetic concerns -> prioritize automation, rollback, data-loss, and false-green issues.

Key steps:
- Read `bin/aimain`, `config/workspaces.json`, `knowledge/_generic.md`, `install.sh` section 10b, and registry-based workspace checks in `scripts/verify.sh`.
- Confirmed the exclude-path code is `git -C "$ws" rev-parse --git-path info/exclude` at `bin/aimain:164`; the competing claim that shipped code used `--git-dir` for this path was false. `--git-dir` appears only in `doctor` at line 322.
- Inspected the current dirty worktree and found new workspace-linking files untracked plus modified installer/verifier files; dynamic claims such as “verify fully green” and “byte-identical” could not be independently proven from static review.

Failures and how to do differently:
- `bin/aimain:215-224` uses `deploy_one "$abs" "$kname" || true`, so batch deployment suppresses failures; `install.sh` and `sync.sh` can report successful redeployment while workspaces were skipped or broken. Do not swallow deployment errors in the six-hour redeploy path.
- `bin/aimain:159-170` adds `.git/info/exclude` entries, but `cmd_unlink` at `bin/aimain:262-286` never removes them. This is not a clean round trip, and unanchored entries like `AGENTS.md` can hide nested legitimate files. Either manage/removal safely or explicitly accept persistent repository-level exclusions.
- `scripts/verify.sh:197-210` silently skips missing workspace directories and only warns for missing knowledge files, allowing an invalid registry to appear green. Missing required entries should fail verification; optional/nonexistent paths need an explicit distinction.
- `bin/aimain:229-255` writes the registry before `deploy_one`; `--force` bypasses an early tracked-file check but `deploy_one` still refuses tracked `AGENTS.md`, leaving a broken registry entry after failure. Validate fully before registry mutation or roll back the registry on deployment failure.
- `bin/aimain:120-142` warns on missing `@` imports but still writes an incomplete generated file; `scripts/verify.sh:206-210` checks only the marker, so broken imports can pass. Compilation should fail on required import errors and verification should inspect generated content/import completeness.
- Outside sync mode, `bin/aimain:186-205` automatically moves unmanaged handwritten instruction files to backups without requiring `--force`; ordinary deploy should refuse unmanaged files by default.
- `doctor` at `bin/aimain:316-332` can print drift while returning success because it returns only Git-leak status; list/ownership/alias drift should affect the exit code.

Reusable knowledge:
- The implementation intentionally writes a real workspace `AGENTS.md` and creates `CLAUDE.md`/`GEMINI.md` symlinks to it, rather than putting only cache symlinks in the repo.
- Registry entries currently contain 11 workspaces in `config/workspaces.json:3-48`; a claimed five-workspace equivalence test would not cover the full registry.
- `install.sh:337-355` delegates workspace deployment to `bin/aimain`; `scripts/sync.sh:53-58` invokes `install.sh --sync`, so swallowed deployment errors directly affect launchd/session-start reliability.

References:
- `bin/aimain:151-156` — current ownership heuristic: alias symlink must target exactly `AGENTS.md`; regular generated file must contain the marker on line 1.
- `bin/aimain:161-169` — correct linked-worktree-aware exclude computation using `git rev-parse --git-path info/exclude`.
- `bin/aimain:215-224` — batch error suppression via `|| true`.
- `bin/aimain:262-286` — unlink removes generated files/registry only, not exclude entries.
- `scripts/verify.sh:185-220` — registry-driven verification and its skip/warn behavior.

## Task 2: Adjudicate competing designs

Outcome: success

Key decisions:
- Real workspace `AGENTS.md` wins over cache-only symlinks for readability, debuggability, and tools that mishandle symlinks; exact-target alias symlinks remain a practical compromise.
- The `--git-dir` bug claim was rejected because shipped code uses `--git-path`; stateful hashes/refcounts were judged excessive for this single-user setup unless shared-worktree exclusion cleanup becomes necessary.
- The existing exact-target-plus-marker ownership heuristic was preferred over a separate `~/.local/state` ledger for current needs.
- Recommended prompt budgets were `full=3200`, `lean=1400`, `minimal=500`, with compilation failure on overrun and retention of the last-known-good generated prompt for live installs.
- Recommended keeping the smaller implementation: registry CLI, generic knowledge, tracked/unmanaged-file guards, correct exclude handling, tier compiler, and stronger verification; defer multi-module adapters, cache/state layers, and task-contract orchestration until a real additional tool requires them.
- For current Claude Code/Codex/opencode/Qwen usage, plain Git hooks and a `glab` PATH shim are realistically enforceable; a full immutable task-contract orchestrator is not currently available across the fleet and is unnecessary for the specific `glab --json` check.
