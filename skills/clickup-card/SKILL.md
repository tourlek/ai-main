---
name: clickup-card
description: Use when starting a ClickUp card (breakdown, estimate, dates, sprint), running its implementation as ONE Sonnet implement thread per card in T3 (bound to the card worktree) with the plan thread spawning its own `reviewer` subagent directly (Sonnet per round, one Opus pass before the MR, independent of the implementer), or drafting the end-of-day progress and time log.
---

# clickup-card

Per-card workflow for Tualek. Two main T3 threads per card: the **plan thread** (this orchestrator: Claude Code on the Team account, T3 instance `Claude Team`, terminal alias `claude-team`, `CLAUDE_CONFIG_DIR=~/.claude-team`, effort medium: breakdown, brief, checks, ClickUp, mr.md) and ONE **implement thread** (Claude Sonnet on `claude-team`, top-level, bound to the card worktree so the user can use T3's git and MR UI). The plan thread (Claude Code on claude-team) spawns its own `reviewer` subagent directly (Sonnet per round; one Opus pass before the change request). The reviewer is independent of the implementer (never spawned by or reporting via the implementer). Review is not a third top-level thread. The orchestrator never edits code.

Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/skills/clickup-card/SKILL.md
Artifacts live in `<worktree>/.scratch/<CARD>/` (`breakdown.md`, `brief.md`, `done.md`, `review.md`, `mr.md`, `rounds.md`, `lessons-proposed.md`). Templates: `templates.md` in this folder. `<CARD>` is the card you are working on (parent or subcard); say which one in the first answer. Multi-repo card: each repo's worktree has its own `.scratch/<CARD>/`; list all paths in the first answer.

One plan thread plus one implement thread per card. State lives in `.scratch/<CARD>/` and ClickUp, not in chat: on start, read those files and `clickup_get_task` to find the stage (no breakdown.md = step 1, no brief.md = step 2, done.md without review.md = review, etc.) and resume from there. Also list existing local and remote branches, worktrees (`git worktree list`), T3 threads of the card (`t3_thread_list` or `t3 thread list --project <repo root>`; the ids are in `.scratch/<CARD>/rounds.md` as `plan_thread` / `impl_thread`, reuse them instead of launching new ones) and MRs for the card per repo (read MR descriptions in full, no `head -c`); flag local-only branches and tell the user before creating anything new.

## Hard rules

- Every ClickUp write = preview first, then explicit "confirm" from the user. No autopilot.
- Ponytail stays on (plugin `ponytail@ponytail`) in every step: breakdown, brief, executor, review, mr.md. Its hooks re-inject it at session start, after compaction and into every subagent; never say "stop ponytail" or "normal mode". If `~/.claude/.ponytail-active` is missing, tell the user to type `/ponytail`. Ponytail never overrides these Hard rules or brief acceptance.
- Write only subtasks assigned to the user. Preview must show task id, parent name, assignee; if assignee is not the user, refuse.
- Read ClickUp through the connected MCP (workspace_id `90182460598`), never curl + token. For many objects use `clickup_get_operators` / `clickup_execute_operator`, not one call per subtask.
- Read back after every write; `success:true` is not proof.
- No commit, push, MR, merge, reviewer, Draft removal, traffic switch unless the user says so for that action. `git revert`, `amend` and `cherry-pick` are commits.
- Approval gate: show the preview plus the exact word to type, then end the turn. guard.sh checks the user's last message (within 30 min): commit = `commit`/`คอมมิ`; push = `push`/`พุช`; `glab mr create/update/merge` = `MR` or `merge request`; ClickUp write = `confirm`/`ใส่ได้เลย`; worktree not from `origin/master` = `allow-worktree`. Prod **reads** via `~/ai-main/bin/mongo-ro prod …` need **no** chat phrase (2026-10-28). Raw prod `mongosh` stays denied. Prod **writes** stay forbidden. Loose phrases ("แบบที่ 2 น่าจะดีกว่า", "ได้เลย" to another question) are not approval. Each word covers only its action: "commit push" does not open an MR. Never call the tool to see if guard.sh lets it through.
- Files for the user to open (`mr.md`, `cs-review.md`, drafts): copy to `/Users/tualek/ohochat/.scratch/<CARD>/` first, then share that copy. Worktree paths are outside the session root and fail.
- Card links: always `https://app.clickup.com/t/90182460598/<CARD-ID>` (e.g. `OHO-8671`), never `/t/<internal id>`. ClickUp `assignees` are strings: `["113526352"]`.
- Implementation goes to the card's single implement thread (step 3): Sonnet on `claude-team`, top-level, bound to the card worktree; later rounds are `t3_thread_send` to the same thread. Fallbacks are listed in step 3. If asked to edit code here, dispatch instead. Never Codex: the user has no Codex subscription.
- Review budget: one pass plus re-checks on the new diff only, max 3 rounds per MR, then `Step back:` to the user. One reviewer per round; do not stack reviewers.
- Reviewer is always Claude (never Gemini): the `reviewer` subagent (Sonnet each round, fresh context, input = diff + `plan.md` only, never the implementer's reasoning), plus ONE Opus pass before the change request is opened. The plan thread spawns it directly; it is independent of the implementer (never spawned by or reporting via it). It edits only `review.md`.
- Do not add Claude/AI footers to MR text.
- Write findings to `breakdown.md` (Investigation) as soon as they are found; chat is lost on compaction.
- Investigate mode: reads are free (files, rg/git log/diff/blame, gcloud logs, ClickUp/MCP reads, staging/UAT DB reads via bwsr, scout/reviewer agents); go to root cause and report in one turn. Ask only before writes (repo edits, ClickUp, commit/push/MR, worktree). Prod reads via mongo-ro need no chat phrase; raw prod mongosh stays denied; prod writes stay forbidden.
- Code search goes through `Agent(subagent_type="scout")`. Do not run more than 2 rg/grep or 3 Read/cat/sed calls yourself in a row; delegate and keep only its file:line list.
- Never write `Verdict: ready`, never say an MR is ready ("พร้อม MR"), never draft the Slack review request without a `reviewer` result at the current head SHA recorded in `.scratch/<CARD>/review.md`.
- If the user approves a small post-review fix, dispatch it to `impl_thread` and run a delta re-review on `<prev>..<head>`, or record `Verdict: ready-with-unreviewed-user-fix` and ask the user before committing. The orchestrator never calls `Edit`/`Write` on repo source or docs files.

## Model split (company work, Claude Team, 2026-10-30)

| Role | Model | Notes |
|---|---|---|
| plan (breakdown, brief, checks, mr.md) | Opus or Sonnet, effort medium | this thread |
| implement | Sonnet | replaces pi + DeepSeek |
| small mechanical work (log summaries, rename, search, lint) | Haiku | `chore` agent (edits), `scout` agent (search only) |
| review | Sonnet, fresh context | `reviewer` agent; Opus for one pass before the change request |

## 1. Breakdown (read-only until confirm)

1. Read card + comments (`clickup_get_task`, `clickup_get_task_comments`).
   Then name the session `OHO-xxxx [<stage>] <card name>` (adhoc: `OHO-xxxx [<stage>] <what I do>`). Stage is one of `Breakdown`, `Brief`, `Impl`, `Review`, `MR`, `Done`, `Blocked`. In a T3 thread: `t3_thread_update` with `action: "rename"` and `title`. Terminal session: announce the stage in chat. Set it right after reading the card, then update only the stage at every change (breakdown confirmed -> Brief, round sent to the implement thread -> Impl, review started -> Review, MR opened -> MR, card closed -> Done), derived from the `.scratch/<CARD>/` files and MR state.
   Then call `scout` with the card's symbols, error codes and screens to get file:line before drafting; pass its list to the opus Agent in step 2.
   Before any estimate: `clickup_search` the card's keywords, check the Runbook list (`901819044120`) and repo docs (`README*`, `docs/`). Any number without evidence gets `(ยังไม่ verify)`.
2. Write `breakdown.md`: per subtask a title, 2-4 lines of what is done, start, due, estimate. Issue cards add an `Investigation` section (findings, evidence level VERIFIED/hypothesis, time spent) and a solutions-first list: options with trade-offs before any subtask is written.
   Planning model: draft `breakdown.md` through an Agent call with `model: opus` and `effort: medium` (pass the card, comments, repo paths and the scout list; it writes the file, you review and show it). Do not draft it on the session model.
3. Dates: max 8h of estimate per working day, working days only. Show the arithmetic; user checks holidays.
4. User edits/normalizes. Only then write via operators in one batch, including adding the card to the current sprint list (look the list id up with `clickup_get_workspace_hierarchy`; never reuse a remembered id). The preview names the target list and says sprint or backlog.
5. Adhoc work with no card: same flow starting from `clickup_create_task` (preview first), then draft a short message to the senior for the user to send.

## 2. Worktree and brief

- Branch name `<type>/oho-<number>-<slug>` (type = feature | fix), no `tk-sprint-*` layer for new branches; existing branches keep their name.
- Worktree path follows T3's own layout: `~/.t3/worktrees/<repo>/<branch with "/" replaced by "-">`, e.g. `~/.t3/worktrees/oho-api/feature-oho-8671-index-art-model`. Create it from `origin/master`, after a fetch:
  `cd <repo root> && git fetch origin master && git worktree add --no-track -b <branch> ~/.t3/worktrees/<repo>/<branch-slug> origin/master`
  **T3 worktree GC:** deleting (or GC of) a T3 thread bound to a `worktreePath` deletes that folder from disk. Never delete `impl_thread` before the card is merged or closed, never reuse the `worktreePath` of a deleted thread without binding a live thread to it, and mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/` after every round.
  Any other base needs `allow-worktree`; if the card worktree sits on another branch, write that in `review.md`. The branch must track its own remote branch only after the first push: `git push -u origin <own-branch>` (never track `origin/master`). MR target is `develop`; check with `git ls-remote --exit-code --heads origin develop` (no pipe to `head`; exit 2 = missing) and tell the user if missing.
- If the feature branch conflicts with `develop`, ask: merge into it, or a separate resolve branch. A master-based branch is also promoted to staging/master.
- `brief.md` (one per repo) is drafted by an Agent call with `model: opus`, `effort: medium`; you check it against the breakdown before showing the user. It holds: repo, files allowed, out of scope, acceptance, a test command that has been run once (full node/jest paths, Node 20, install state), lint command, the repo's `## Rules earned` lines that apply, "do not proceed past the plan without approval". Show brief.md to the user and wait for approval. First round is plan-only (executor writes the plan into `done.md` with `STATUS: plan-ready`); the implementation round is a new run after the user approves the plan.
  Node.js / Dockerfile / base-image upgrades: `scout` checks `package-lock.json` for native addons (`binding.gyp`, `node-gyp`, `prebuild-install`, `deasync`, `sharp`, `canvas`, `bcrypt`) and the brief records prebuild availability for the target OS/arch (`linux/amd64`, Alpine musl vs glibc) before round 1.

## 3. Implement and review: one implement thread per card (v4, 2026-10-27)

**Two main T3 threads per card, no more.** (1) **Plan thread** = this orchestrator (`claude-team`, effort medium): breakdown, subtasks, brief, checks, ClickUp, mr.md. (2) **Implement thread** = ONE top-level T3 thread, instance `claude-team`, model `claude-sonnet-5-5`, bound to the card worktree `~/.t3/worktrees/<repo>/<slug>`, so the user can use T3's git panel and MR UI on it. Review is not a third top-level thread: the plan thread spawns its own `reviewer` subagent directly (see 3e). The reviewer is independent of the implementer (never spawned by the implement thread and never reporting via it). Every round (plan-only, implement, each fix) goes to the same implement thread with `t3_thread_send`; never launch a second implement thread for a card unless the user asks.

**3a. Capabilities (once per plan thread).** Call `orchestrator_capabilities` and `t3_project_list`. Confirm instance `claude-team` with `claude-sonnet-5-5` is listed and that the repo has a T3 project (workspaceRoot = repo root). If something is missing, say so and use a fallback below; never switch silently. If the repo has no T3 project, ask before `t3_project_create`.

**3b. Create the implement thread (round 1 only).** The worktree exists first (step 2). Call `t3_thread_launch`:
```
projectId: <T3 project of the repo root>
title: "<CARD> impl <short>"
modelSelection: {instanceId: "claude-team", model: "claude-sonnet-5-5"}  // effort option ids from orchestrator_capabilities
runtimeMode: "full-access", interactionMode: "default"
workspaceStrategy: {type: "existing_worktree", worktreePath: "<worktree>", branch: "<branch>"}
message: <the round-1 handoff below>
```
`runtimeMode` cannot exceed the calling thread's mode; if refused, tell the user instead of lowering it. Save the result in `.scratch/<CARD>/rounds.md` as `impl_thread: <threadId>` (and `plan_thread: <this thread id>`), plus a line `r1: <launch time> plan-only`. Link it as `[title](t3-thread://v1/<threadId>)`. Rename the plan thread per step 1 stages; the implement thread keeps the title `<CARD> impl <short>`.

**3c. Handoff = the brief.** The plan thread sends the work; the message stays short because the brief carries the content: `Read .scratch/<CARD>/brief.md (round <N>). Work only in <worktree> (cd there and run pwd first; stop if it differs). Write .scratch/<CARD>/done.md last (STATUS: line at the end). Commit and push stay out of scope for this round.` Never put the words commit/push/confirm as bare approvals in a negated sentence ("Do not commit") — that used to unlock the guard. Add the lessons below when they apply. Before every round move the previous `done.md` to `done-r<N-1>.md`, so a stale file never counts as finished. Later rounds: `t3_thread_send` to the recorded `impl_thread` with the same shape and a one-line pointer to what changed (`review.md` findings to fix, or the user's approved plan). Append `rN: <time> <plan|impl|fix>` to `rounds.md`. Opus for a harder round needs a new model on the same thread (`t3_thread_send` does not switch models), so say so in the first answer and ask before starting a new thread.

**3d. Wait.** Wait for `done.md`, not for the thread going idle. `t3_thread_wait` on the implement thread (bounded timeout, repeat), or the watcher: Bash `run_in_background: true` with `D=<worktree>/.scratch/<CARD>/done.md; end=$(( $(date +%s) + 2400 )); while [ $(date +%s) -lt $end ]; do grep -q '^STATUS: ' "$D" 2>/dev/null && { echo DONE; tail -1 "$D"; exit 0; }; sleep 30; done; echo TIMEOUT; exit 3` and foreground waits of at most 570 s. TIMEOUT: `t3_thread_read` on the implement thread, report the last output and what is missing, stop; do not interrupt it without the user. `STATUS: blocked` = report the reason, no review. If the implement thread stopped on a transient `Connection error`/`api_error` after the edits and checks were done (confirm with `t3_thread_read` and `git status`), send one `t3_thread_send`: "Continue from the current worktree state and write .scratch/<CARD>/done.md" instead of re-running the round.

**3e. Check, then review (plan thread spawns the reviewer).** On `STATUS: complete`, first mirror `<worktree>/.scratch/<CARD>/` to `/Users/tualek/ohochat/.scratch/<CARD>/`; then the plan thread does the checks itself: `scout` maps every file:line in `done.md`, re-run each grep in `Grep proof`, the test and lint commands, `git log --oneline origin/master..HEAD` shows no executor commit, `git status --porcelain` and `git diff --stat` against Allowed files. Then review (this is the step-7 review): the plan thread spawns the `reviewer` subagent (`~/.claude/agents/reviewer.md`, read-only, adversarial) with the Agent tool, passing ONLY the diff (`git diff <base>..<head>` saved to `.scratch/<CARD>/diff-r<N>.patch`, or inline) and `plan.md` (the approved plan / `brief.md`). Never pass `done.md` narrative, the implementer's reasoning or transcript. Model: `sonnet` every round; **one** extra pass with `model: opus` (effort medium) on the final head before the change request is opened (never on every round, never stacked with the Sonnet pass of the same round). The reviewer answers the fixed checklist (edge cases, error paths, tests cover changed lines, security, blast radius) as pass/fail/N/A with file:line, drops findings without file:line or a failing test, and tags Important/Nit/Pre-existing with a final Verdict. The plan thread writes its output to `.scratch/<CARD>/review.md` (header `MR: <repo> !<iid>`, Head SHA, `Reviewer: <model>`), because the reviewer has no write tools. Use `delegate_task` to `claude-team` only if the review must run in a different thread; **never `delegate_task` across repo or worktree** (#17415) - for another checkout use `t3_thread_launch` + `workspaceStrategy: existing_worktree`. Ponytail check: flag code the acceptance does not need; never ask to cut validation, error handling, security or accessibility. One reviewer per round, fresh context each round, max 3 rounds per MR (round 2+ gets only the new diff and earlier findings). Confirm `review.md` `Head:` equals `git rev-parse HEAD` of the worktree; mismatch or missing = not reviewed. Fix findings by sending the implement thread the Important items; re-review checks the new diff only. Report to the user: acceptance map result, out-of-scope files, test/lint result, reviewer findings with Verdict, reviewer model and head SHA.

**Review fallback** (Claude quota out, `claude-team` not offered, or the delegate errors): the plan thread runs `cd <worktree> && agy -p --mode plan --model claude-opus-5-5-medium "<same review prompt>" > .scratch/<CARD>/review-raw.md` (or the `reviewer` agent in this thread) and pastes the result into `review.md` with `Reviewer: <model>`. Never Gemini as reviewer. No automatic extra high pass, even for high-risk MRs (auth, billing, data repair, CI, migrations); run opus high only when the user asks.

**Commit / MR.** Only after the user's approval word (Hard rules). The user can commit and open the MR from the implement thread's git panel in T3 (that is why the thread is bound to the worktree); `glab` from the plan thread works too. `mr.md` and the Slack draft stay with the plan thread.

**Lessons (2026-10-28 + OHO-8915).** Incremental `tsc -b` can report green while `tsc -b --force` is red — always force (or delete tsbuildinfo) before done.md. Never put bare commit/push/confirm words inside thread prompts as "Do not …" (negation used to unlock guard.sh); say "out of scope" instead. Grok Bot / box browser cannot open Figma (use MCP `get_design_context` + `get_screenshot`, or paste comments into `.scratch/`). **Lessons from OHO-8915 r2/r3.** A freshly recreated worktree has no `node_modules` and no `.env`: say so in the brief (`cp build.env.example .env`, git-ignored; `npm ci`). Executor exit codes must come from `set -o pipefail` or `${PIPESTATUS[0]}`, not `tee`. Take the test baseline on the unchanged code first (fail-22.txt) and diff failed-suite names, not counts. Health-check with `curl --retry 10 --retry-connrefused --retry-delay 3`; prove engines with `node -p` and `git diff --numstat`. A thread's `delegate_task` child inherits its runtime mode (observed `full-access`) and must do the work itself. An orchestrator once misread a child's `done.md` and claimed a Cloud Build run that never happened: grep the session or logs before repeating a claim like that. GitLab: `GITLAB_HOST=gitlab.boonmeelab.com` for `glab` (default host returns 401); outside the repo dir also pass `-R oho/<repo>`. Keep briefs small (one acceptance list per round); a long-lived implement thread accumulates context, so each message restates only the delta and points to the files.

**Fallbacks for the implement thread** (tell the user which one and why; never switch silently):
1. Plan thread has no `t3-code` MCP (plain terminal): `t3 thread start <repo root> "<prompt>" --provider claude-team --model claude-sonnet-5-5 --title "<CARD> impl" --wait --json`. The CLI cannot bind an existing worktree (only `--worktree <base> --branch <new>`, same `~/.t3/worktrees` layout); use it for round 1 with `--worktree origin/master --branch <branch>` (then `git branch --unset-upstream` and skip the manual `git worktree add`). Later rounds: `t3 thread send <threadId> "<message>"`. Review then runs from the plan thread (review fallback above).
2. `claude-team` implement thread unavailable: the plan thread's own Claude Agent subagent (`model: sonnet`, `effort: medium`). These nest under the plan thread, so the worktree is bound to the plan thread, not the implement thread; say so.
3. Last resort, headless: `cd <worktree> && CLAUDE_CONFIG_DIR=~/.claude-team gtimeout 2700 claude -p --model sonnet "<prompt>" > .scratch/<CARD>/impl-r<N>.log 2>&1`; record the log path in `rounds.md`.

- Never accept "done" from the executor. `done.md` must map every acceptance item in `brief.md` to file:line and list the grep pattern proving no occurrence of the old behavior remains; the reviewer re-runs that grep and the test command and diffs `git diff --stat` against Allowed files. Unmapped item = not done. Skip the mapping/grep check only for a trivial change (one file, no behavior or runtime impact); still read `git diff`.
- `review.md`: one file per MR, header `MR: <repo> !<iid>`; verdict, findings by severity with file:line, blocks-commit flag. Checklist: diff vs card scope, MR description vs code, MR sha (`glab`) == `git rev-parse HEAD`, tests and lint pass on Node 20, `CI: <status>` (unknown = not ready), no secrets in logs. Read the repo's `REVIEW.md` first (shared with `~/ai-main/config/review.md`). Only Important blocks.
- Multi-repo: add `Contract:` (producer file:line -> validator/passthrough -> consumer, with name, nesting, types) and `Deploy order:` (source: code or each MR's Rollout section; unknown = say unknown, never infer).
- Subagents (in `~/.claude/agents/`, read-only): `scout` (haiku) maps files/callers and every file:line in `done.md`; `reviewer.md` is the review spec for every reviewer. Do not use haiku for edits.
- Lessons: tag each Important finding `repeat` (matches `RULES.md` or the repo's `## Rules earned`: bump `hits:`) or `new`; append both to `.scratch/<CARD>/lessons-proposed.md` for end-of-day approval; never write `RULES.md` directly (`self-learning` skill).
- `mr.md`: invoke the `gitlab-mr-description` skill (Skill tool) before every `glab mr create/update`, then humanizer; regenerated after every commit, no "update per review" headings, keep numbers and bullets. Keep the Slack draft in a separate section of `mr.md` that regeneration does not overwrite.
  Every `mr.md` has `## Testing` (commands run + result at head SHA), `## Risk` (low/medium/high + why), `## How to revert` (one command or step).
- Slack review request (#dev-merge-request): draft only, never send without explicit confirm. Format confirmed by the user (memory `reference_slack_dev_mr_format.md`, do not invent another):
  ```
  [repo1, repo2]: <conventional title> (OHO-xxxx)
  card: https://app.clickup.com/t/90182460598/OHO-xxxx
  link: https://gitlab.boonmeelab.com/oho/<repo>/-/merge_requests/<n>
  @Tong (Sr. Fullstack) <short note if any>
  ```
  Header uses the room alias for the repo (oho-api shows as `core-api`). Several repos: `link [webhook]:` / `link [api]:` on separate lines. List only MRs whose `review.md` says `Verdict: ready` at the current head SHA; any other MR, and any repo the user says to skip, stays out of header and links.


## 3f. Long-running GOAL mode (multi-batch ports, keepalive)

Use when a workstream spans many batches under one `.scratch/.../GOAL.md` (e.g. React port) with keepalive/handoff scripts:

- **Implementer:** dedicated Sonnet thread bound to the worktree; runs batch after batch per GOAL; writes per-batch `done.md`.
- **Reviewer:** `reviewer` subagent (plan-spawned, Sonnet per batch; one Opus pass before the MR). One review pass per batch → `review.md` with `Verdict: ready|not-ready`. Implementer must **not** DM the reviewer thread and must **not** self-review.
- **Plan thread:** owns spawning reviewers and user-facing status. When the reviewer is rate-limited/offline, mark the batch **review-pending**, continue the next batch; handoff script holds review-requests until reset+buffer.
- **Handoff/keepalive:** automation messages are tagged `[review-handoff …]` / `[keepalive …]` so they never unlock guard magic words. Unattended >1h → `caffeinate`/holdmylid; keepalive logs `GAP` after sleep.
- **Gates:** forced typecheck, lint, tests; UI batches need mount/Playwright; shots ports 4191 (implement) vs 4192 (review).
- Still one writer per checkout. No force-push, no prod deploy, no secrets in logs.

## 4. eod (draft only)

Inputs: `git worktree list` + `git log --since=midnight` per worktree, T3 threads of the day (`t3_thread_list`), changed `done.md`/`review.md`/`rounds.md`, `clickup_get_time_entries` for today, and every `.scratch/<CARD>/lessons-proposed.md`.
Output: table per subtask: progress (1-2 lines), proposed hours, blocker; then the proposed lessons for approval. Write nothing.
Hours come only from `~/ai-main/core/checks/session-hours.py <orchestrator session id>` (gap 15 min, includes child subagent sessions). Show the real block intervals next to every number; never write an interval the script output lacks; split blocks across subtasks without overlap. Before `clickup_add_time_entry`, write the planned entries to a JSON file and run the script with `--entries <file>`; exit 1 = fix before the preview.
After the user fixes the numbers and says confirm: `clickup_add_time_entry` + `clickup_create_task_comment` per subtask, then read back. Put MR links in comments as plain text, not markdown links. Approved lessons go through `self-learning`.


## T3 sprint convention

For multi-card sprint coordination on T3 (title prefix + registry; T3 has no custom sprint sidebar groups):

1. Open card threads only via `sprint-spawn.sh <no> card <CARD-ID>` (optional flags: `--project`, `--worktree`, `--branch`, `--title-extra`).
2. Get card status only via `sprint-status.sh <no>` (optional `--thread` / `--json`). Never read card chats for status; use `.scratch/<CARD-ID>/status.json` and `~/.claude/sprints/S<no>/threads.json`.
3. Adhoc or personal work stays outside the sprint unless registered with `sprint-spawn.sh <no> adopt <threadId> <CARD-ID>`.

Coordinator default prompt (from `sprint-spawn.sh <no> coordinator`) embeds the same rules. See `~/.claude/sprints/README.md`.
