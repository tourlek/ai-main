---
name: gitlab-mr-description-workflow
description: Draft paste-ready GitLab merge request descriptions when the user sends an MR link or IID, using `glab` first and falling back to local git evidence when host/auth access is blocked.
argument-hint: "[mr url or iid] [repo]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# GitLab MR Description Workflow

## When to Use

Use this when the user:

- sends a GitLab MR URL and wants a ready-to-paste description
- invokes a GitLab MR description skill/workflow
- wants the description grounded in the real MR metadata, diff, and repo state

Do not use this for general code review or branch surgery unless the request is specifically about the MR description.

## Inputs and Context to Gather

1. Confirm the target repo and git root. Keep the description scoped to that repo only.
2. Check whether the request is for a full description draft, a template, or skill maintenance.
3. Verify GitLab access path:
   - `glab auth status --hostname <host>` when auth state is uncertain
   - `glab mr view <iid or url> -R <group/repo or host/group/repo> -F json`
4. If `glab` metadata works, gather:
   - `glab mr view ... -F json`
   - `glab mr note list ...`
   - `glab mr diff ... --raw --color=never`
5. If diff retrieval is blocked, gather local repo evidence:
   - `git status --short --branch`
   - `git remote -v`
   - `git log --oneline <base>..<head>`
   - `git diff --stat <base>..<head>`
   - targeted `git diff --name-only <base>..<head>`

## Procedure

1. Identify the MR and repo scope.
   - Prefer the user-provided URL or IID.
   - Keep the final write-up inside the named repo; do not mix other repos' changes or validation.
2. Try `glab` first.
   - On this machine, the installed CLI uses `-F json`, not `--json`.
   - Useful commands are `glab mr view`, `glab mr diff`, `glab mr note list`, and `glab api`.
3. If `glab` metadata succeeds but diff access fails:
   - Extract `base_sha`, `head_sha`, source branch, target branch, title, and change count from MR JSON.
   - Reconstruct the patch from the local repo with `git diff <base_sha>..<head_sha>` and `git log`.
4. If `glab` is blocked by config/DNS/auth:
   - State that limitation internally and pivot quickly to local repo evidence.
   - Use the local branch range only if it matches the MR branch/SHA evidence.
5. If `glab mr view` / `glab mr diff` work but `glab api .../commits` fails with `Unauthenticated`:
   - Treat the commits endpoint as optional, not required.
   - Keep drafting from MR JSON, raw diff, notes, local branch, and local `git diff --stat` / `git diff --check`.
6. Draft a paste-ready Markdown description.
   - Default sections: `Summary`, `Changes`, `Testing`, `Risk / Impact`, `Reviewer Notes`
   - Add `Rollout / Migration` only when the change actually needs it.
   - Keep `Testing` honest: use `Not run`, partial test results, or `git diff --check` only if that is all that actually happened.
7. If the task is skill maintenance instead of a single MR:
   - Keep the durable rule set: `glab` first, local git fallback, repo-scoped output, honest testing, and shared template sections.

## Efficiency Plan

- Start with `glab mr view ... -F json`; it gives the fastest truth for title, branches, SHAs, and change count.
- If `glab mr diff` fails, do not keep retrying the same path; pivot to local `git diff` using `base_sha` and `head_sha`.
- If only `glab api .../commits` fails with `Unauthenticated`, stop calling that endpoint and continue with `mr view` / `mr diff` evidence.
- Use `git diff --stat` before reading full diffs to frame the description.
- Reuse the same section structure across MRs to reduce drafting churn.

## Pitfalls and Fixes

- Symptom: `Unknown flag: --json.` Likely cause: local `glab` version does not support that flag. Fix: use `-F json`.
- Symptom: `operation not permitted` opening `~/Library/Application Support/glab-cli/.config.yml`. Likely cause: local config permission issue. Fix: pivot to local git evidence or another `glab` path instead of re-debugging the flag.
- Symptom: `dial tcp: lookup gitlab... no such host`. Likely cause: DNS/network failure. Fix: keep MR metadata if already retrieved, then use local `git diff`/`git log` against `base_sha` and `head_sha`.
- Symptom: `ERROR  Unauthenticated.` from `glab api projects/.../merge_requests/.../commits`. Likely cause: the endpoint needs auth that the current session does not have even though `mr view` / `mr diff` still work. Fix: skip the commits endpoint and draft from MR JSON, raw diff, notes, and local repo checks.
- Symptom: description claims tests passed when only lint or diff checks ran. Likely cause: template autopilot. Fix: report exactly what verification completed.
- Symptom: output mixes repos. Likely cause: reading multiple worktrees from a combined workspace. Fix: lock the description to the single repo named by the MR.

## Verification Checklist

- The repo scope is explicit and matches the MR.
- `glab` was tried first unless unavailable by context.
- If `glab` failed, the fallback evidence path is explicit.
- Branches, SHAs, or local diff range are named when relevant.
- The description is paste-ready Markdown.
- `Testing` reflects only commands that actually ran.
- No unrelated repo changes or validation are included.
