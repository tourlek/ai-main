thread_id: 019f6506-8353-7c13-9dda-4d97fcfab9ad
updated_at: 2026-07-15T09:18:31+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/15/rollout-2026-07-15T16-05-53-019f6506-8353-7c13-9dda-4d97fcfab9ad.jsonl
cwd: /Users/tualek/ohochat/oho-api
git_branch: feature/tk-sprint-2613/oho-1018-unrespone

# Review of unread/unresponded diff in `oho-api` found one blocking startup regression plus several behavior-preserving refactors.

Rollout context: The user asked for a read-only review of the uncommitted diff on branch `feature/tk-sprint-2613/oho-1018-unrespone` in `/Users/tualek/ohochat/oho-api`, with explicit instructions to inspect only the listed non-comment changes, verify each item with exact file/line evidence, and not edit files or write Git state. The rollout also had to avoid attributing pre-existing failing tests to this diff.

## Task 1: Review the 7 targeted diff items

Outcome: partial

Preference signals:
- The user explicitly said: “Review the UNCOMMITTED working-tree changes … This is a REVIEW ONLY task. Do not edit any files.” -> future similar work should stay strictly read-only and evidence-led.
- The user asked for itemized verification of each numbered change and required exact file paths + line numbers in claims -> future reviews should answer in the same structured, citation-heavy style.
- The user called out pre-existing failing suites that must not be blamed on this diff -> future reviewers should separate repo noise from diff-caused regressions.

Key steps:
- Confirmed the active branch/worktree and inspected `git status` / `git diff` for the real target.
- Traced the diff for items 1–7 and checked surrounding source files plus generated/transpiled behavior where needed.
- Verified `config/default.json` for `paginate.max = 50`, searched for all callers of the changed helpers, and checked Feathers hook registration behavior in the installed package.
- Attempted focused Jest and `tsc --noEmit`; Jest was blocked by the read-only sandbox / duplicate-worktree haste-map collisions, and `tsc` showed unrelated existing errors.

Failures and how to do differently:
- The biggest regression is `contact-send-message.service.js:12`: passing the whole hooks module to `service.hooks(hooks)` is not safe here because `contact-send-message.hooks.js` still exports `getContactSendMessagePreviewText`. Feathers 4 rejects extra enumerable keys as invalid hook types, so startup fails before the service is usable.
- `notify.service.js:15` is fine because its hooks module only exports lifecycle keys.
- The review could not rely on Jest for runtime confirmation because the sandbox prevented haste-map persistence; static tracing plus small runtime checks were the usable verification path.

Reusable knowledge:
- Feathers 4 `service.hooks()` validates hook-module keys; a whole-module registration only works when the module exports lifecycle keys (`before/after/error/finally`) and nothing else.
- `config/default.json` sets `paginate.max` to 50, so the new `context.app?.get('paginate')?.max ?? 50` fallback preserves current behavior when config is present or missing.
- `buildClearUnreadUnrespondedPayload()` treats omitted, `undefined`, and `null` member IDs the same; call sites switching from `undefined` to `()` do not change payload shape.
- `getMessagePreviewText()` now safely ignores non-string `data.label` values from `qs.parse` and falls back to `message.text` or `กดปุ่ม`.
- The diff removed named exports from several local hook files, but those functions are still invoked from their local hook arrays; repository search found no surviving external imports of those hook helpers.

References:
- [1] Branch/worktree verified: `feature/tk-sprint-2613/oho-1018-unrespone`, main worktree at `/Users/tualek/ohochat/oho-api`.
- [2] Blocking regression evidence: `src/services/contact-send-message/contact-send-message.service.js:12`, `src/services/contact-send-message/contact-send-message.hooks.js:497`, Feathers error `'getContactSendMessagePreviewText' is not a valid hook type`.
- [3] Config evidence: `config/default.json:6-8` shows `paginate.max: 50`.
- [4] Runtime confirmation snippets: `buildClearUnreadUnrespondedPayload()` produced identical outputs for absent/undefined/null member IDs; `getMessagePreviewText()` returned string labels and fell back for object labels.
- [5] Call-site evidence: `contact-send-message.hooks.js:497-500`, `member-send-message.hooks.js:1246-1255`, `end-case.hooks.js:457`, `no-case.hooks.js:448`, and the local hook-array registrations in bot/member/contact/group-member files.

## Task 2: Capture repo/workflow facts from review evidence

Outcome: success

Preference signals:
- The user preferred a “review only” pass and explicitly forbade edits, commits, or write git commands -> keep future similar sessions read-only unless the user changes scope.
- The user wanted pre-existing failing tests excluded from findings unless directly caused by the diff -> future review memory should preserve that separation rule.

Key steps:
- Checked the installed Feathers hook registration implementation to verify the startup failure, rather than assuming “extra keys are ignored.”
- Confirmed the repository uses `allowJs: true` but `checkJs: false`, so the new TypeScript interface in `get-message-preview-text.ts` does not statically validate the JavaScript callers.

Failures and how to do differently:
- Jest in this sandbox is noisy because multiple worktrees create duplicate mock/path collisions and the environment cannot persist haste-map files. Future reviews should not over-interpret those failures as diff regressions.

Reusable knowledge:
- `service.hooks(hooks)` is only safe when the hooks module is a pure hook registry; if the module also exports utility functions, switch back to `{ before, after, error }` or split the utilities into a separate module.
- `tsconfig.json` has `allowJs: true` and `checkJs: false`, so JS callers are not typechecked even when a utility adds a TS interface.

References:
- [1] `tsconfig.json:9-10,17` (`allowJs: true`, `checkJs: false`, includes only TS sources).
- [2] Feathers implementation evidence: `node_modules/@feathersjs/feathers/lib/hooks/index.js:141-166` rejects unknown hook types during registration.
- [3] `src/services/index.js:439` configures `contactSendMessages`, so the service-startup regression is immediately user-visible.

