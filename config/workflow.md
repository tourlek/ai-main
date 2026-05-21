# Working Rules

## Scope discipline

- When the user names a repo (`focus แค่ oho-web-app`, `อ่านแค่ web`, `เอาแค่ oho-webapp ไม่เอา backoffice มันแยก repo`), stay inside that repo until they re-expand scope explicitly.
- Don't add features, refactors, or "while I'm here" cleanup beyond the asked change. Three similar lines is better than a premature abstraction.
- If a frontend ask appears to need a backend change, surface the dependency and ask before editing the backend.
- For tracking/analytics changes that were "only for testing", remove the experimental code before commit instead of leaving it in.

## Plan-first, then execute

- For non-trivial changes the user typically wants a plan first (often saved to `plan.md` at repo root). Confirm the plan, then execute.
- Once a plan is agreed, short imperative commands like `go`, `do it`, `start #1`, `commit it` mean "execute the next step of the agreed plan" — don't re-prompt for clarification.
- If the user says `working until is X`, `don't need to ask me`, or `/loop`, run autonomously until the goal is met or a blocker appears.

## Commits

- **Never commit without explicit authorization** (`อย่า commit ก่อนฉันสั่ง`). Commit only after the user says `commit it`, `create commit ให้เลย`, or equivalent.
- When committing is authorized and changes span multiple intents/risks, split into logical commits with clear revert boundaries — not one bundled commit.
- Use conventional prefixes: `fix:`, `feat:`, `refactor:`, `chore:`, `docs:`, `test:`, `style:`, plus `core:` when the repo convention uses it.
- Defer to `git-commit-helper` skill when present.

## Refactors and migrations

- During Nuxt 2 → Nuxt 3 (or similar) migrations: preserve existing UI, function, and feature behavior. The user has explicitly said `i don't want change i want everything working same like a nuxt2 but use nuxt3` and pushed back when AI altered passing-QA behavior.
- Don't change test files during refactors unless the user explicitly asks (`ไม่ต้องแก้ test file`).
- Don't `git revert` or undo prior user work to "clean up". Only revert when the user asks.

## Code review of GitLab MRs

- Always try `glab` first (`glab mr view`, `glab mr diff`, `glab mr note list`). On this machine the JSON flag is `-F json`, not `--json`.
- Use the GitLab MR description / comment skills (`gitlab-mr-description`, `gitlab-mr-comment-reply`) when present.
- If `glab` is blocked by config permission or DNS, fall back to local `git diff`/`git log` against the MR branch or `base_sha`/`head_sha`. Only claim tests/screenshots/validation that actually ran.
- Treat senior reviewer comments as the implementation scope. Anchor any plan to the literal GitLab discussion position; verify `old_path`/`new_path` and line range before adjacent cleanup.

## Debugging

- When the user pastes a stack trace or error, trace the literal error path and auth/validation chain first. Don't jump into implementation changes unless asked.
- For UI bugs that persist after a Vue-only scoped-style fix, inspect shared/global styles and selector precedence next.
- For MongoDB Compass write failures, verify the connected datasource (Atlas Data Lake vs real cluster) before rewriting query syntax.
- Defer to `debug-mantra` skill when present.

## Reports and write-ups

- The user often wants summaries saved as `.md` files at repo root (e.g. `jera-performance-review.md`), not only chat replies. When they ask for a report, write the file.
- For performance reviews / comparisons: include before/after numbers, trade-offs, scope of impact, and explicit `Not run: <reason>` if a measurement wasn't actually taken.

## Tooling

- Wrap shell commands with `rtk` per `RTK.md` (auto-rewritten via Claude hook; manual prefix for Codex/Gemini).
- `glab` is the GitLab CLI of choice.
- Use `find . -name 'pattern'` from a specific path, not from `/`.

## When the user pushes back

- `Why you revert code ???` / `i don't want change` / `style is broken` → stop, audit what changed, restore the user's original behavior, then explain the deviation.
- `บอกแล้วว่า X` / repeated correction → save a feedback memory so the correction is permanent.
