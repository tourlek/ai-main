---
name: clickup-card
description: Use when starting a ClickUp card (breakdown, estimate, dates, sprint), dispatching its implementation to DSH worktree sessions, or drafting the end-of-day progress and time log.
---

# clickup-card

Per-card workflow for Tualek. The DSH coordinator session drives the card; plan and review go through the Claude subagent `cc-review` (Opus, read-only), search through `cc-explore` (Haiku, read-only), and implementation runs in one DSH session per worktree. The coordinator never edits code.
Artifacts live in `<worktree>/.scratch/<CARD>/` (`breakdown.md`, `brief.md`, `done.md`, `review.md`, `mr.md`, `lessons-proposed.md`). Templates: `templates.md` in this folder. `<CARD>` is the card you are working on (parent or subcard); say which one in the first answer. Multi-repo card: each repo's worktree has its own `.scratch/<CARD>/`; list all paths in the first answer.

One coordinator session per card. State lives in `.scratch/<CARD>/` and ClickUp, not in chat: on start, read those files and `clickup_get_task` to find the step (no breakdown.md = step 1, no brief.md = step 5, done.md without review.md = step 7, etc.) and resume from there. Also list existing local and remote branches, worktrees (`git worktree list`, `orca worktree ps` if Orca is in use) and MRs for the card per repo (read MR descriptions in full, no `head -c`); flag local-only branches and tell the user before creating anything new.

## Hard rules

- Every ClickUp write = preview first, then explicit "confirm" from the user. No autopilot.
- Ponytail stays on in every step: breakdown, brief, executor, review, mr.md. Never say "stop ponytail" or "normal mode". Ponytail never overrides these Hard rules or brief acceptance.
- Write only subtasks assigned to the user. Preview must show task id, parent name, assignee; if assignee is not the user, refuse.
- Read ClickUp through the connected MCP (workspace_id `90182460598`), never curl + token. Claude Code: claude.ai ClickUp MCP, names as in this file; for many objects use `clickup_get_operators` / `clickup_execute_operator`, not one call per subtask. DSH: `mcp__clickup__getTaskById`, `searchTasks`, `searchSpaces`, `getListInfo`, `getTimeEntries`, `readDocument`; map `clickup_get_task` + `clickup_get_task_comments` -> `getTaskById`, `clickup_search` -> `searchTasks`, `clickup_get_time_entries` -> `getTimeEntries`, hierarchy/list lookup -> `searchSpaces` + `getListInfo`. DSH tools take only the internal id from the task URL (e.g. `86ey29bp1`); `searchTasks` does not index custom ids. Resolve `OHO-xxxx` first: ask the user for the card URL / internal id, or have `cc-explore` (claude.ai ClickUp MCP) look it up read-only. Do not guess.
- DSH writes go through the `mcp__clickup__*` write tools (`createTask` with `list_id`, `updateTask`, `addComment`, `editComment`, `createTimeEntry`, `updateListInfo`, `updateDocumentPage`, `createDocumentOrPage`) only after the preview and the user's `confirm`/`ใส่ได้เลย`; `guard.sh` gates each call (approval card in DSH); read back with `getTaskById` after writing. DSH cannot add an existing task to a second list (e.g. sprint list): put it in the target list at `createTask` time, or do that one step from Claude Code (claude.ai MCP) after confirm. Never curl.
- Read back after every write; `success:true` is not proof.
- No commit, push, MR, merge, reviewer, Draft removal, traffic switch unless the user says so for that action. `git revert`, `amend` and `cherry-pick` are commits.
- Approval gate: show the preview plus the exact word to type, then end the turn. The guard (`ai-main/core/hooks/guard.sh`, run by the DSH guard bridge and the Claude PreToolUse hook) checks for: commit = `commit`/`คอมมิ`; push = `push`/`พุช`; `glab mr create/update/merge` = `MR` or `merge request`; ClickUp write = `confirm`/`ใส่ได้เลย`; worktree not from `origin/master` = `allow-worktree` (Claude Code only; under DSH that worktree, including the `create_worktree` tool, gets a DSH approval card instead). Under DSH the bridge turns those into an approval prompt. Never switch tools to get around a guard denial. PROD query = `PROD ok` (skill rule, not guard-enforced; covers only the queries in the preview). Loose phrases ("แบบที่ 2 น่าจะดีกว่า", "ได้เลย" to another question) are not approval. Each word covers only its action: "commit push" does not open an MR. Never call the tool to see if the guard lets it through.
- Files for the user to open (`mr.md`, `cs-review.md`, drafts): copy to `/Users/tualek/ohochat/.scratch/<CARD>/` first, then share that copy.
- Card links: always `https://app.clickup.com/t/90182460598/<CARD-ID>` (e.g. `OHO-8671`), never `/t/<internal id>`. ClickUp `assignees` are strings: `["113526352"]`.
- Implementation goes to a DSH worktree session (step 6). If asked to edit code in the coordinator, dispatch instead.
- Review follows `~/ai-main/config/review.md`: Opus only (never Gemini), one reviewer per round, re-checks on the new diff only, max 3 rounds per MR, then `Step back:` to the user. Only Important findings block.
- Do not add Claude/AI footers to MR text.
- Write findings to `breakdown.md` (Investigation) as soon as they are found; chat is lost on compaction.
- Investigate mode: reads are free (files, rg/git log/diff/blame, gcloud logs, ClickUp/MCP reads, staging/UAT DB reads via bwsr, explore/review subagents); go to root cause and report in one turn. Ask only before writes (repo edits, ClickUp, commit/push/MR, worktree) and PROD queries.
- Code search goes through `cc-explore` (`subagent_claude_explore`). Do not run more than 2 rg/grep or 3 file reads yourself in a row; delegate and keep only its file:line list.
- Wait for `subagent*` results through the runtime completion notification; never `sleep` loops to wait for a subagent (the step 6 `done.md` poll runs as a background job and stays).
- Never write `Verdict: ready`, never say an MR is ready ("พร้อม MR"), never draft the Slack review request without a `cc-review` result at the current head SHA recorded in `.scratch/<CARD>/review.md`.

## 1. Read the card

Read card + comments (`clickup_get_task`, `clickup_get_task_comments`). Right after reading, name the session `OHO-xxxx [<stage>] <card name>` (adhoc: `OHO-xxxx [<stage>] <what I do>`), stage one of `Breakdown`, `Brief`, `Impl`, `Review`, `MR`, `Done`, `Blocked`: DSH `set_session_title`, Claude Code `mcp__ccd_session_mgmt__set_session_title` (load via ToolSearch). Update only the stage at every change (breakdown confirmed → Brief, dispatch → Impl, review started → Review, MR opened → MR, card closed → Done, blocked → Blocked), derived from `.scratch/<CARD>/` files and MR state. No title tool: announce the stage in chat. Then call `cc-explore` with the card's symbols, error codes and screens to get file:line before drafting; pass its list to `cc-review` in step 2.
Before any estimate: `clickup_search` the card's keywords, check the Runbook list (`901819044120`) and repo docs (`README*`, `docs/`). Any number without evidence gets `(ยังไม่ verify)`.

## 2. Breakdown (read-only until confirm)

Write `breakdown.md`: per subtask a title, 2-4 lines of what is done, start, due, estimate. Issue cards add an `Investigation` section (findings, evidence level VERIFIED/hypothesis, time spent) and a solutions-first list: options with trade-offs before any subtask is written.
Planning model: draft it through `cc-review` (`subagent_claude_review`, Opus, plan mode; pass the card, comments, repo paths and the `cc-explore` list). It is read-only, so it returns the draft; you write the file, check it and show it. Do not draft it on the coordinator model.

## 3. Dates

Max 8h of estimate per working day, working days only. Show the arithmetic; user checks holidays.

## 4. Write to ClickUp

User edits/normalizes. Only then write via operators in one batch, including adding the card to the current sprint list (look the list id up with `clickup_get_workspace_hierarchy`; never reuse a remembered id). The preview names the target list and says sprint or backlog.
Adhoc work with no card: same flow starting from `clickup_create_task` (preview first), then draft a short message to the senior for the user to send.

## 5. Worktree and brief

- Branch name `<type>/oho-<number>-<slug>` (type = feature | fix), no `tk-sprint-*` layer for new branches; existing branches keep their name.
- Worktree from `origin/master`, named after the card (`git worktree add -b <branch> <path> origin/master`, or `orca worktree create --base-branch origin/master`; check the resulting branch and tell the user if a tool added its own prefix). If the card worktree sits on another branch, write that in `review.md`. Branch must track its own remote branch: `git config branch.autoSetupMerge false` (or `--no-track`), push with `git push -u origin <own-branch>`. MR target is `develop`; check with `git ls-remote --exit-code --heads origin develop` (no pipe to `head`; exit 2 = missing) and tell the user if missing.
- If the feature branch conflicts with `develop`, ask: merge into it, or a separate resolve branch. A master-based branch is also promoted to staging/master.
- `brief.md` (one per repo) is drafted by `cc-review`; you check it against the breakdown before showing the user. It holds: repo, files allowed, out of scope, acceptance, a test command that has been run once (full node/jest paths, Node 20, install state), lint command, the repo's `## Rules earned` lines that apply, "do not proceed past the plan without approval". Show it and wait for approval.

## 6. Implement: one DSH session per worktree

- One fresh DSH session per round (plan, implement, each fix), working directory = the card worktree. Its whole prompt: `Read .scratch/<CARD>/brief.md (round <N>); write .scratch/<CARD>/done.md last.` The first round is plan-only (the session writes the plan into `done.md` with `STATUS: plan-ready`); implementation is a new session after the user approves the plan.
- Record each round in `.scratch/<CARD>/rounds.md` (`rN: <session id> <start time>`; not in review.md, whose presence marks step 7). Before each round move the previous `done.md` to `done-r<N-1>.md`, so a stale file never counts as finished. Never send a new fix into an old executor session.
- Wait for `done.md`, not for the session going idle. Poll `grep -q '^STATUS: ' <worktree>/.scratch/<CARD>/done.md` every 30 s for up to 40 min; on timeout, report the session's last output and what is missing, and stop. Do not relaunch or close it without the user.
- `STATUS: blocked`: report the reason; no review. `STATUS: complete`: `cc-explore` maps every file:line in `done.md`; re-run each grep in `Grep proof`, the test and lint commands; compare `git status --porcelain` and `git diff --stat` against Allowed files; then step 7.
- Never accept "done" from the executor. `done.md` must map every acceptance item in `brief.md` to file:line, and list the grep pattern proving no occurrence of the old behavior remains. Unmapped item = not done. Skip the mapping/grep check only for a trivial change: one file, no behavior or runtime impact (remove comment, remove debug log, format only). Still read `git diff` before accepting; if the diff touches logic, strings users see, config or more than one file, run the full check. Keep briefs small (one acceptance list per round).
- GitLab: set `GITLAB_HOST=gitlab.boonmeelab.com` for `glab` (default host is gitlab.com and returns 401); outside the repo dir also pass `-R oho/<repo>`.

## 7. Review (cc-review, read-only)

- Reviewer: `cc-review` (`subagent_claude_review`, Opus, plan mode), fresh per round: "Follow `~/ai-main/config/review.md` and ./REVIEW.md. Repo <path>, range <base>..<head>, acceptance .scratch/<CARD>/brief.md and done.md. Ponytail check: flag code the acceptance does not need; never ask to cut validation, error handling, security or accessibility." High-risk MR (auth, billing, data repair, CI, migrations): one extra Opus pass at higher effort (`subagent_claude_review_high_on_request`; high variant only on explicit user ask or high-risk MR). In a Claude Code session the `reviewer` agent is the same spec.
- Write `review.md`, one file per MR (header `MR: <repo> !<iid>`): findings with tags and file:line, `Verdict:`, head SHA, `Reviewer: <model>`, blocks-commit flag. Checklist: diff vs card scope, MR description vs code, MR sha (`glab`) == `git rev-parse HEAD` of the reviewed worktree (re-check after every push), tests and lint pass on Node 20, `CI: <status>` (unknown = not ready), no secrets in logs.
- Multi-repo: add `Contract:` (producer file:line -> validator/passthrough file:line -> consumer file:line, with name, nesting, types) and `Deploy order:` (source: code or each MR's Rollout section; if not stated, say unknown, never infer).
- Lessons: each Important finding is tagged `repeat` (matches a line in `RULES.md` or the repo's `## Rules earned`: bump its `hits:` in the proposal) or `new`. Append both to `.scratch/<CARD>/lessons-proposed.md` for end-of-day approval; never write `RULES.md` or knowledge files directly (`self-learning` skill).

## 8. MR and review request

- `mr.md`: invoke the `gitlab-mr-description` skill before every `glab mr create/update`; regenerated after every commit, no "update per review" headings, keep numbers and bullets. Keep the Slack draft in a separate section of `mr.md` that regeneration does not overwrite.
  Every `mr.md` has `## Testing` (commands run + result at head SHA), `## Risk` (low/medium/high + why), `## How to revert` (one command or step).
- Slack review request (#dev-merge-request): draft only, never send without explicit confirm. Format confirmed by the user (do not invent another):
  ```
  [repo1, repo2]: <conventional title> (OHO-xxxx)
  card: https://app.clickup.com/t/90182460598/OHO-xxxx
  link: https://gitlab.boonmeelab.com/oho/<repo>/-/merge_requests/<n>
  @Tong (Sr. Fullstack) <short note if any>
  ```
  Header uses the room alias for the repo (oho-api shows as `core-api`). Several repos: `link [webhook]:` / `link [api]:` on separate lines. List only MRs whose `review.md` says `Verdict: ready` at the current head SHA; any other MR, and any repo the user says to skip, stays out of header and links.

## 9. eod (draft only)

Inputs: worktree list, `git log --since=midnight` per worktree, changed `done.md`/`review.md`, `clickup_get_time_entries` for today, and every `.scratch/<CARD>/lessons-proposed.md`.
Output: table per subtask: progress (1-2 lines), proposed hours, blocker; then the proposed lessons for approval. Write nothing.
Hours come only from `~/ai-main/core/checks/session-hours.py <coordinator session id>` (gap 15 min, includes child subagent sessions). Show the real block intervals next to every number; never write an interval the script output lacks; split blocks across subtasks without overlap.
Before `clickup_add_time_entry`, write the planned entries to a JSON file and run the script with `--entries <file>`; exit 1 = fix before the preview. ClickUp MCP under DSH cannot edit or delete time entries, so a wrong entry needs the user to fix it in the UI. After the user fixes the numbers and says confirm: `clickup_add_time_entry` + `clickup_create_task_comment` per subtask, then read back. Put MR links in comments as plain text, not markdown links. Approved lessons go through `self-learning`.
